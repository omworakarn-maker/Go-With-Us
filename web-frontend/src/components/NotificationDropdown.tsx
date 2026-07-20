import React, { useState, useEffect, useRef } from 'react';
import { notificationService, Notification } from '../services/notificationService';

interface NotificationDropdownProps {
    isOpen: boolean;
    onClose: () => void;
}

const NotificationDropdown: React.FC<NotificationDropdownProps> = ({ isOpen, onClose }) => {
    const [notifications, setNotifications] = useState<Notification[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const dropdownRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (isOpen) {
            loadNotifications();
        }
    }, [isOpen]);

    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
                onClose();
            }
        };

        if (isOpen) {
            document.addEventListener('mousedown', handleClickOutside);
        }

        return () => {
            document.removeEventListener('mousedown', handleClickOutside);
        };
    }, [isOpen, onClose]);

    const loadNotifications = async () => {
        setIsLoading(true);
        try {
            const data = await notificationService.getNotifications();
            setNotifications(data);
        } catch (error) {
            console.error('Error loading notifications:', error);
        } finally {
            setIsLoading(false);
        }
    };

    const handleMarkAsRead = async (id: string) => {
        try {
            await notificationService.markAsRead(id);
            setNotifications((prev) =>
                prev.map((n) => (n.id === id ? { ...n, isRead: true } : n))
            );
        } catch (error) {
            console.error('Error marking as read:', error);
        }
    };

    const handleDelete = async (id: string, e: React.MouseEvent) => {
        e.stopPropagation(); // Prevent marking as read when deleting
        try {
            await notificationService.deleteNotification(id);
            setNotifications((prev) => prev.filter((n) => n.id !== id));
        } catch (error) {
            console.error('Error deleting notification:', error);
        }
    };

    const handleClearAll = async () => {
        if (!window.confirm('Confirm clear all notifications?')) return;
        try {
            await notificationService.clearAllNotifications();
            loadNotifications();
        } catch (error) {
            console.error('Error clearing all notifications:', error);
        }
    };

    const getIcon = (type: string) => {
        switch (type) {
            case 'alert':
                return (
                    <svg className="w-5 h-5 text-gray-400 group-hover:text-black transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                    </svg>
                );
            case 'trip':
                return (
                    <svg className="w-5 h-5 text-gray-400 group-hover:text-black transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                );
            default:
                return (
                    <svg className="w-5 h-5 text-gray-400 group-hover:text-black transition-colors" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                );
        }
    };

    const formatTimeAgo = (dateString: string) => {
        const date = new Date(dateString);
        const now = new Date();
        const seconds = Math.floor((now.getTime() - date.getTime()) / 1000);

        if (seconds < 60) return 'เมื่อสักครู่';
        if (seconds < 3600) return `${Math.floor(seconds / 60)} นาทีที่แล้ว`;
        if (seconds < 86400) return `${Math.floor(seconds / 3600)} ชั่วโมงที่แล้ว`;
        return `${Math.floor(seconds / 86400)} วันที่แล้ว`;
    };

    if (!isOpen) return null;

    return (
        <div
            ref={dropdownRef}
            className="absolute right-0 mt-2 w-96 bg-white rounded-2xl shadow-2xl border border-gray-100 z-50 overflow-hidden animate-in fade-in zoom-in-95 duration-200 origin-top-right"
        >
            <div className="p-4 border-b border-gray-50 flex justify-between items-center bg-white px-6">
                <h3 className="text-sm font-bold text-gray-900">การแจ้งเตือน</h3>
                {notifications.length > 0 && (
                    <button
                        onClick={handleClearAll}
                        className="text-xs font-bold text-red-500 hover:text-red-600 transition-colors"
                    >
                        ลบทั้งหมด
                    </button>
                )}
            </div>

            <div className="max-h-[480px] overflow-y-auto custom-scrollbar">
                {isLoading ? (
                    <div className="p-20 flex flex-col items-center justify-center space-y-4">
                        <div className="w-6 h-6 border-2 border-gray-100 border-t-black rounded-full animate-spin"></div>
                        <div className="text-[10px] font-bold uppercase tracking-widest text-gray-300">Loading...</div>
                    </div>
                ) : notifications.length === 0 ? (
                    <div className="p-16 text-center flex flex-col items-center">
                        <div className="w-16 h-16 bg-gray-50 border border-gray-100 rounded-full flex items-center justify-center mb-5 shadow-sm">
                            <svg className="w-8 h-8 text-gray-200" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.5" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                            </svg>
                        </div>
                        <div className="text-[10px] font-bold uppercase tracking-widest text-gray-300">No new notifications</div>
                    </div>
                ) : (
                    <div className="divide-y divide-gray-50">
                        {notifications.map((notification) => (
                            <div
                                key={notification.id}
                                onClick={() => !notification.isRead && handleMarkAsRead(notification.id)}
                                className="group w-full p-5 text-left hover:bg-gray-50/50 transition-all cursor-pointer relative"
                            >
                                <div className="flex items-start gap-4">
                                    <div className="w-10 h-10 bg-gray-50 border border-gray-100 rounded-full flex items-center justify-center shadow-sm group-hover:bg-white transition-colors">
                                        {getIcon(notification.type)}
                                    </div>
                                    <div className="flex-1 min-w-0 pr-6">
                                        <div className="flex items-start justify-between gap-2">
                                            <h4
                                                className={`text-sm text-gray-900 leading-snug ${!notification.isRead ? 'font-bold' : 'font-medium opacity-70'
                                                    }`}
                                            >
                                                {notification.title}
                                            </h4>
                                            {!notification.isRead && (
                                                <div className="w-2 h-2 bg-red-500 rounded-full flex-shrink-0 mt-1 shadow-[0_0_8px_rgba(239,68,68,0.4)]" />
                                            )}
                                        </div>
                                        {notification.message && (
                                            <p className="text-xs text-gray-500 mt-1 line-clamp-2 leading-relaxed opacity-80">
                                                {notification.message}
                                            </p>
                                        )}
                                        <p className="text-[10px] text-gray-400 mt-2 font-bold uppercase tracking-wider opacity-60">
                                            {formatTimeAgo(notification.createdAt)}
                                        </p>
                                    </div>

                                    <button
                                        onClick={(e) => handleDelete(notification.id, e)}
                                        className="absolute top-5 right-5 text-gray-300 hover:text-red-500 opacity-0 group-hover:opacity-100 transition-all p-1"
                                        title="Delete"
                                    >
                                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M6 18L18 6M6 6l12 12" />
                                        </svg>
                                    </button>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
            {notifications.length > 5 && (
                <div className="p-4 bg-gray-50/50 text-center border-t border-gray-50">
                    <button className="text-[10px] font-black text-gray-400 hover:text-black transition-colors uppercase tracking-widest">
                        View More
                    </button>
                </div>
            )}
        </div>
    );
};

export default NotificationDropdown;
