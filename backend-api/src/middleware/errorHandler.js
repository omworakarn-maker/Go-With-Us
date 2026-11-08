// Global error handler middleware
export const errorHandler = (err, req, res, next) => {
    console.error('Error:', err);

    if (err.code === 'DEVICE_LIMIT_REACHED') {
        return res.status(409).json({ error: err.message, code: err.code, maxDevices: 3, sessions: err.sessions });
    }
    if (err.code === 'SESSION_REVOKED' || err.code === 'SESSION_NOT_FOUND') {
        return res.status(err.status).json({ error: err.message, code: err.code });
    }

    // Prisma errors
    if (err.code === 'P2002') {
        return res.status(400).json({ error: 'This email already exists.' });
    }

    if (err.code === 'P2025') {
        return res.status(404).json({ error: 'Record not found.' });
    }

    // Default error
    res.status(err.status || 500).json({
        error: err.message || 'Internal server error',
    });
};
