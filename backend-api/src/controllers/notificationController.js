import prisma from '../utils/prismaClient.js';
import { sendPushNotification } from '../utils/firebase.js';

// Get all notifications for current user
export const getNotifications = async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;
        const { all, includeMessages } = req.query;

        let where = {
            OR: [
                { userId: userId },
                { userId: null },
            ],
        };

        // If admin and requesting all
        if (userRole === 'admin' && all === 'true') {
            where = {}; // No filter = all notifications
        } else if (includeMessages !== 'true') {
            where.type = { notIn: ['message', 'trip_message', 'private_chat', 'chat'] };
        }

        const notifications = await prisma.notification.findMany({
            where,
            orderBy: { createdAt: 'desc' },
        });
        res.json(notifications);
    } catch (error) {
        next(error);
    }
};

// Get unread notification count
export const getUnreadCount = async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const count = await prisma.notification.count({
            where: {
                userId: userId,
                isRead: false,
                type: { notIn: ['message', 'trip_message', 'private_chat', 'chat'] },
            },
        });
        res.json({ count });
    } catch (error) {
        next(error);
    }
};

// Mark notification as read
export const markAsRead = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;

        const notification = await prisma.notification.update({
            where: { id, userId },
            data: { isRead: true },
        });

        res.json(notification);
    } catch (error) {
        next(error);
    }
};

export const reportSupportIssue = async (req, res, next) => {
    const message = typeof req.body?.message === 'string' ? req.body.message.trim() : '';
    if (!message || [...message].length > 1000) {
        return res.status(400).json({ error: 'Enter a report between 1 and 1000 characters.' });
    }

    const reporterId = req.user.userId;
    try {
        const result = await prisma.$transaction(async (tx) => {
            const recentReport = await tx.notification.findFirst({
                where: {
                    type: 'support_report',
                    targetId: reporterId,
                    createdAt: { gte: new Date(Date.now() - 60_000) },
                },
                select: { id: true },
            });
            if (recentReport) return 'rate_limited';

            const admins = await tx.user.findMany({
                where: { role: 'admin' },
                select: { id: true },
            });
            if (admins.length === 0) return 'unavailable';

            await tx.notification.createMany({
                data: admins.map(({ id }) => ({
                    userId: id,
                    targetId: reporterId,
                    type: 'support_report',
                    title: 'แจ้งปัญหา Gowithus',
                    message,
                })),
            });
            return 'sent';
        }, { isolationLevel: 'Serializable' });

        if (result === 'rate_limited') {
            return res.status(429).json({ error: 'Please wait a minute before sending another report.' });
        }
        if (result === 'unavailable') {
            return res.status(503).json({ error: 'Support is temporarily unavailable.' });
        }
        return res.status(201).json({ message: 'Report sent.' });
    } catch (error) {
        if (error.code === 'P2034') {
            return res.status(429).json({ error: 'Please wait a minute before sending another report.' });
        }
        return next(error);
    }
};

// Create notification (Admin only)
export const createNotification = async (req, res, next) => {
    try {
        const userRole = req.user.role;

        if (userRole !== 'admin') {
            return res.status(403).json({ error: 'Permission denied. Admin role required.' });
        }

        const { title, message, type, targetId, userId } = req.body;

        const notification = await prisma.notification.create({
            data: {
                title,
                message,
                type,
                targetId,
                userId: userId || null, // null for global notifications
            },
        });

        // Send Push Notification
        if (userId) {
            const user = await prisma.user.findUnique({
                where: { id: userId },
                select: { fcmToken: true }
            });

            if (user?.fcmToken) {
                // Import dynamically or at top level. Top level is better.
                // Assuming imported at top: import { sendPushNotification } from '../utils/firebase.js';
                await sendPushNotification(user.fcmToken, title, message, {
                    type,
                    targetId: targetId || '',
                    notificationId: notification.id
                });
            }
        }

        res.status(201).json(notification);
    } catch (error) {
        next(error);
    }
};

// Delete single notification
export const deleteNotification = async (req, res, next) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;

        const notification = await prisma.notification.findUnique({
            where: { id },
        });

        if (!notification) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        if (userRole !== 'admin' && notification.userId !== userId) {
            return res.status(403).json({ error: 'Permission denied' });
        }

        await prisma.notification.delete({
            where: { id },
        });

        res.json({ message: 'Notification deleted successfully' });
    } catch (error) {
        next(error);
    }
};

// Clear all notifications for user
export const clearAllNotifications = async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;
        const { scope } = req.query;

        let where = { userId: userId };

        if (userRole === 'admin' && scope === 'all') {
            where = {};
        }

        await prisma.notification.deleteMany({
            where,
        });

        res.json({
            message: scope === 'all' ? 'All system notifications cleared' : 'All private notifications cleared',
        });
    } catch (error) {
        next(error);
    }
};
