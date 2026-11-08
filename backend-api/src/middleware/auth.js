import jwt from 'jsonwebtoken';
import { resolveDeviceSession, touchDeviceSession, SessionError } from '../utils/deviceSessions.js';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

export async function authenticateToken(token, req = { headers: {} }) {
    const claims = jwt.verify(token, JWT_SECRET);
    if (!claims.userId || !Number.isFinite(claims.exp)) throw new SessionError('INVALID_TOKEN', 'Invalid or expired token.');
    const session = await resolveDeviceSession(claims, token, req);
    // A failed last-seen update must not turn a successful authentication into a logout.
    touchDeviceSession(session).catch(error => console.warn('Session activity update failed', { code: error.code }));
    return { ...claims, sid: session.id, sessionVersion: session.version };
}

const respondToAuthError = (error, res, next) => {
    if (error instanceof SessionError) return res.status(error.status).json({ error: error.message, code: error.code });
    if (['JsonWebTokenError', 'TokenExpiredError', 'NotBeforeError'].includes(error.name)) {
        return res.status(401).json({ error: 'Invalid or expired token.', code: 'INVALID_TOKEN' });
    }
    // Database/connection failures are server errors, never invalid credentials.
    return next(error);
};

export const verifyToken = async (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return res.status(401).json({ error: 'Access denied. No token provided.', code: 'INVALID_TOKEN' });
    try {
        req.user = await authenticateToken(token, req);
        return next();
    } catch (error) {
        return respondToAuthError(error, res, next);
    }
};

export const isAdmin = (req, res, next) => {
    if (req.user.role !== 'admin') return res.status(403).json({ error: 'Access denied. Admin only.' });
    next();
};

export const verifyTokenOptional = async (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) return next();
    try {
        req.user = await authenticateToken(token, req);
        return next();
    } catch (error) {
        return respondToAuthError(error, res, next);
    }
};
