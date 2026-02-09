import { authFetch } from './api';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

export interface Notification {
    id: string;
    title: string;
    message: string;
    type: 'alert' | 'trip' | 'system';
    targetId?: string;
    createdAt: string;
    isRead: boolean;
}

export interface CreateNotificationRequest {
    title: string;
    message: string;
    type: string;
    targetId?: string;
}

export const notificationService = {
    // Get notifications with optional 'all' flag for admins
    async getNotifications(all: boolean = false): Promise<Notification[]> {
        const response = await authFetch(`${API_BASE_URL}/notifications${all ? '?all=true' : ''}`);
        return response;
    },

    // Get unread notification count
    async getUnreadCount(): Promise<number> {
        const data = await authFetch(`${API_BASE_URL}/notifications/unread-count`);
        return data.count;
    },

    // Mark notification as read
    async markAsRead(id: string): Promise<void> {
        await authFetch(`${API_BASE_URL}/notifications/${id}/read`, {
            method: 'PUT',
        });
    },

    // Create notification (admin only)
    async createNotification(data: CreateNotificationRequest): Promise<Notification> {
        return authFetch(`${API_BASE_URL}/notifications`, {
            method: 'POST',
            body: JSON.stringify(data),
        });
    },

    // Delete single notification
    async deleteNotification(id: string): Promise<void> {
        await authFetch(`${API_BASE_URL}/notifications/${id}`, {
            method: 'DELETE',
        });
    },

    // Clear notifications (can be system-wide for admins)
    async clearAllNotifications(all: boolean = false): Promise<void> {
        await authFetch(`${API_BASE_URL}/notifications/clear-all${all ? '?scope=all' : ''}`, {
            method: 'DELETE',
        });
    },
};
