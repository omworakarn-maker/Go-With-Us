import express from 'express';
import {
    getNotifications,
    getUnreadCount,
    markAsRead,
    createNotification,
    deleteNotification,
    clearAllNotifications,
} from '../controllers/notificationController.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

// All routes require authentication
router.use(verifyToken);

// Get all notifications for current user
router.get('/', getNotifications);

// Get unread notification count
router.get('/unread-count', getUnreadCount);

// Clear all notifications (private ones)
router.delete('/clear-all', clearAllNotifications);

// Mark notification as read
router.put('/:id/read', markAsRead);

// Delete single notification
router.delete('/:id', deleteNotification);

// Create notification (admin only)
router.post('/', createNotification);

export default router;
