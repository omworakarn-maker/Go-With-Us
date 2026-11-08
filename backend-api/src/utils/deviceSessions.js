import crypto from 'crypto';
import { EventEmitter } from 'events';
import prisma from './prismaClient.js';

export const MAX_DEVICES = 3;
export const SESSION_LIFETIME_SECONDS = 7 * 24 * 60 * 60;
export const sessionEvents = new EventEmitter();

export class SessionError extends Error {
    constructor(code, message, status = 401, sessions = []) {
        super(message);
        this.code = code;
        this.status = status;
        this.sessions = sessions;
    }
}

const hash = value => crypto.createHash('sha256').update(value).digest('hex');
const activeWhere = (userId, now = new Date()) => ({ userId, revokedAt: null, expiresAt: { gt: now } });
const summary = session => ({
    id: session.id, deviceName: session.deviceName,
    createdAt: session.createdAt, lastSeenAt: session.lastSeenAt, expiresAt: session.expiresAt
});
const isActive = (session, now = new Date()) => session && !session.revokedAt && session.expiresAt > now;
const cleanLabel = value => typeof value === 'string' ? value.replace(/[\x00-\x1f\x7f]/g, '').trim().slice(0, 120) : '';

export function deviceIdentity(req, legacyToken) {
    const deviceId = req.body?.deviceId || req.headers?.['x-device-id'];
    const userAgent = cleanLabel(req.headers?.['user-agent']);
    return {
        deviceKey: hash(typeof deviceId === 'string' && deviceId.length >= 16 && deviceId.length <= 200
            ? `device:${deviceId}` : `legacy:${legacyToken || crypto.randomUUID()}`),
        deviceName: cleanLabel(req.body?.deviceName) || userAgent || 'อุปกรณ์เดิม',
        userAgent
    };
}

// The row lock serializes logins/revocations for this account, across server instances.
async function withUserLock(userId, operation) {
    return prisma.$transaction(async tx => {
        const users = await tx.$queryRaw`SELECT "id" FROM "users" WHERE "id" = ${userId} FOR UPDATE`;
        if (!users.length) throw new SessionError('SESSION_REVOKED', 'บัญชีนี้ไม่พร้อมใช้งาน กรุณาเข้าสู่ระบบใหม่');
        return operation(tx);
    });
}

export async function createDeviceSession(userId, req) {
    const identity = deviceIdentity(req);
    const revoked = [];
    const session = await withUserLock(userId, async tx => {
        const now = new Date();
        // Expired token records cannot authenticate again, so they can be pruned safely.
        await tx.deviceSession.deleteMany({ where: { userId, expiresAt: { lte: now } } });
        const existing = await tx.deviceSession.findUnique({
            where: { userId_deviceKey: { userId, deviceKey: identity.deviceKey } }
        });
        if (!isActive(existing, now)) {
            const sessions = await tx.deviceSession.findMany({ where: activeWhere(userId, now), orderBy: { lastSeenAt: 'desc' } });
            if (sessions.length >= MAX_DEVICES) {
                const replacement = sessions.find(item => item.id === req.body?.replaceSessionId);
                if (!replacement) {
                    throw new SessionError('DEVICE_LIMIT_REACHED', 'เข้าสู่ระบบครบ 3 อุปกรณ์แล้ว กรุณาเลือกออกจากอุปกรณ์หนึ่งก่อน', 409, sessions.map(summary));
                }
                await tx.deviceSession.update({ where: { id: replacement.id }, data: { revokedAt: now } });
                revoked.push(replacement.id);
            }
        } else {
            // Re-login on the same installation replaces its old token, not another device.
            revoked.push(existing.id);
        }
        const data = { ...identity, revokedAt: null, lastSeenAt: now,
            expiresAt: new Date(now.getTime() + SESSION_LIFETIME_SECONDS * 1000) };
        return tx.deviceSession.upsert({
            where: { userId_deviceKey: { userId, deviceKey: identity.deviceKey } },
            create: { userId, ...data },
            update: { ...data, version: { increment: 1 } }
        });
    });
    for (const id of revoked) sessionEvents.emit('revoked', id);
    return session;
}

// Adopt old JWTs lazily; this lets existing app builds keep working without bypassing revocation.
export async function resolveDeviceSession(claims, token, req = { headers: {} }) {
    if (claims.sid) {
        const session = await prisma.deviceSession.findUnique({ where: { id: claims.sid } });
        if (!isActive(session) || session.userId !== claims.userId || session.version !== claims.sessionVersion) {
            throw new SessionError('SESSION_REVOKED', 'อุปกรณ์นี้ออกจากระบบแล้ว กรุณาเข้าสู่ระบบใหม่');
        }
        return session;
    }
    const identity = deviceIdentity({ headers: { 'user-agent': req.headers?.['user-agent'] } }, token);
    const known = await prisma.deviceSession.findUnique({
        where: { userId_deviceKey: { userId: claims.userId, deviceKey: identity.deviceKey } }
    });
    if (known) {
        if (!isActive(known)) throw new SessionError('SESSION_REVOKED', 'อุปกรณ์นี้ออกจากระบบแล้ว กรุณาเข้าสู่ระบบใหม่');
        return known;
    }
    return withUserLock(claims.userId, async tx => {
        const existing = await tx.deviceSession.findUnique({
            where: { userId_deviceKey: { userId: claims.userId, deviceKey: identity.deviceKey } }
        });
        if (existing) {
            if (!isActive(existing)) throw new SessionError('SESSION_REVOKED', 'อุปกรณ์นี้ออกจากระบบแล้ว กรุณาเข้าสู่ระบบใหม่');
            return existing;
        }
        const count = await tx.deviceSession.count({ where: activeWhere(claims.userId) });
        if (count >= MAX_DEVICES) throw new SessionError('SESSION_REVOKED', 'เข้าสู่ระบบครบ 3 อุปกรณ์แล้ว กรุณาเข้าสู่ระบบใหม่เพื่อเลือกอุปกรณ์');
        return tx.deviceSession.create({ data: { userId: claims.userId, ...identity,
            expiresAt: new Date(claims.exp * 1000) } });
    });
}

export async function touchDeviceSession(session) {
    const now = new Date();
    if (now.getTime() - session.lastSeenAt.getTime() < 5 * 60 * 1000) return;
    await prisma.deviceSession.updateMany({
        where: { id: session.id, revokedAt: null, lastSeenAt: { lt: new Date(now.getTime() - 5 * 60 * 1000) } },
        data: { lastSeenAt: now }
    });
}

export async function listDeviceSessions(userId, currentSessionId) {
    const sessions = await prisma.deviceSession.findMany({ where: activeWhere(userId), orderBy: { lastSeenAt: 'desc' } });
    return sessions.map(session => ({ ...summary(session), isCurrent: session.id === currentSessionId }));
}

export async function revokeDeviceSessions(userId, sessionId, currentSessionId, others = false) {
    const ids = await withUserLock(userId, async tx => {
        const where = { ...activeWhere(userId), ...(others ? { id: { not: currentSessionId } } : { id: sessionId }) };
        const sessions = await tx.deviceSession.findMany({ where, select: { id: true } });
        if (!others && !sessions.length) throw new SessionError('SESSION_NOT_FOUND', 'ไม่พบอุปกรณ์นี้', 404);
        await tx.deviceSession.updateMany({ where, data: { revokedAt: new Date() } });
        return sessions.map(item => item.id);
    });
    for (const id of ids) sessionEvents.emit('revoked', id);
    return ids;
}
