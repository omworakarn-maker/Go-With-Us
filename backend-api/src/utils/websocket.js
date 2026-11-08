import { WebSocketServer, WebSocket } from 'ws';
import { authenticateToken } from '../middleware/auth.js';
import prisma from './prismaClient.js';
import { sessionEvents } from './deviceSessions.js';

let wss;
const clients = new Map();

export const initWebSocketServer = server => {
    wss = new WebSocketServer({ server, maxPayload: 64 * 1024 });
    const closeSession = sessionId => {
        for (const ws of wss.clients) {
            if (ws.sessionId === sessionId) {
                if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ type: 'session_revoked' }));
                ws.close(4001, 'Session revoked');
            }
        }
    };
    sessionEvents.on('revoked', closeSession);
    wss.on('connection', (ws, req) => {
        ws.isAlive = true;
        const authDeadline = setTimeout(() => { if (!ws.userId) ws.terminate(); }, 10_000);
        ws.on('pong', () => { ws.isAlive = true; });
        ws.on('error', () => ws.terminate());
        ws.on('message', async message => {
            if (ws.userId || ws.authenticating) return;
            ws.authenticating = true;
            try {
                const data = JSON.parse(message.toString());
                if (data.type !== 'auth' || !data.token) { ws.close(4001, 'Authentication required'); return; }
                const claims = await authenticateToken(data.token, req);
                if (ws.readyState !== WebSocket.OPEN) return;
                ws.userId = claims.userId;
                ws.sessionId = claims.sid;
                ws.sessionVersion = claims.sessionVersion;
                ws.expiresAt = claims.exp * 1000;
                // Reconnecting the same installation must not leave a stale socket behind.
                const sockets = clients.get(ws.userId) || new Set();
                for (const old of sockets) if (old.sessionId === ws.sessionId) old.close(4000, 'Connection replaced');
                sockets.add(ws);
                clients.set(ws.userId, sockets);
                clearTimeout(authDeadline);
                ws.send(JSON.stringify({ type: 'auth_success' }));
            } catch (error) {
                const invalidSession = error.status === 401 || ['JsonWebTokenError', 'TokenExpiredError', 'NotBeforeError'].includes(error.name);
                if (invalidSession) {
                    if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ type: 'session_revoked' }));
                    ws.close(4001, 'Authentication failed');
                } else {
                    // A database outage must not sign the user out on all devices.
                    ws.close(1013, 'Session verification temporarily unavailable');
                }
            } finally { ws.authenticating = false; }
        });
        ws.on('close', () => {
            clearTimeout(authDeadline);
            const sockets = clients.get(ws.userId);
            sockets?.delete(ws);
            if (sockets?.size === 0) clients.delete(ws.userId);
        });
    });
    let checking = false;
    const heartbeat = setInterval(async () => {
        const ids = new Set();
        for (const ws of wss.clients) {
            if (!ws.isAlive || (ws.expiresAt && ws.expiresAt <= Date.now())) { ws.terminate(); continue; }
            ws.isAlive = false;
            ws.ping();
            if (ws.sessionId) ids.add(ws.sessionId);
        }
        if (checking || !ids.size) return;
        checking = true;
        try {
            // One batched check also detects revocations made on another server instance.
            const sessions = await prisma.deviceSession.findMany({ where: { id: { in: [...ids] }, revokedAt: null, expiresAt: { gt: new Date() } }, select: { id: true, version: true } });
            const versions = new Map(sessions.map(session => [session.id, session.version]));
            for (const ws of wss.clients) {
                if (ws.sessionId && versions.get(ws.sessionId) !== ws.sessionVersion) ws.close(4001, 'Session revoked');
            }
        } catch (error) { console.warn('WebSocket session check failed', { code: error.code }); }
        finally { checking = false; }
    }, 30_000);
    heartbeat.unref();
    wss.on('close', () => { clearInterval(heartbeat); sessionEvents.off('revoked', closeSession); });
    return wss;
};

export const sendMessageToUser = (userId, messageObj) => {
    const sockets = clients.get(userId);
    if (!sockets?.size) return;
    const payload = JSON.stringify({ type: 'new_message', message: messageObj });
    for (const ws of sockets) if (ws.readyState === WebSocket.OPEN) ws.send(payload);
};
