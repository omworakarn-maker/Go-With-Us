import { listDeviceSessions, revokeDeviceSessions, MAX_DEVICES } from '../utils/deviceSessions.js';

export const getSessions = async (req, res, next) => {
    try {
        res.json({ sessions: await listDeviceSessions(req.user.userId, req.user.sid), maxDevices: MAX_DEVICES });
    } catch (error) { next(error); }
};

export const revokeSession = async (req, res, next) => {
    try {
        await revokeDeviceSessions(req.user.userId, req.params.id, req.user.sid);
        res.json({ message: 'ออกจากระบบอุปกรณ์แล้ว' });
    } catch (error) { next(error); }
};

export const logoutOthers = async (req, res, next) => {
    try {
        await revokeDeviceSessions(req.user.userId, null, req.user.sid, true);
        res.json({ message: 'ออกจากระบบอุปกรณ์อื่นแล้ว' });
    } catch (error) { next(error); }
};

export const logout = async (req, res, next) => {
    try {
        await revokeDeviceSessions(req.user.userId, req.user.sid, req.user.sid);
        res.json({ message: 'ออกจากระบบแล้ว' });
    } catch (error) { next(error); }
};
