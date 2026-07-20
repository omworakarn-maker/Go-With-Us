import prisma from '../utils/prismaClient.js';
import { sendPushNotification } from '../utils/firebase.js';

// Get all notifications for current user
export const getNotifications = async (req, res, next) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;
        const { all } = req.query;

        let where = {
            OR: [
                { userId: userId },
                { userId: null },
            ],
        };

        // If admin and requesting all
        if (userRole === 'admin' && all === 'true') {
            where = {}; // No filter = all notifications
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
