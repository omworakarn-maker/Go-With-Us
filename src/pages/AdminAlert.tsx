import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { notificationService, Notification } from '../services/notificationService';

const AdminAlert: React.FC = () => {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({
        title: '',
        message: '',
        type: 'alert',
        targetId: '',
    });
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState(false);

    // Management State
    const [allNotifications, setAllNotifications] = useState<Notification[]>([]);
    const [isLoading, setIsLoading] = useState(false);

    useEffect(() => {
        loadAllNotifications();
    }, []);

    const loadAllNotifications = async () => {
        setIsLoading(true);
        try {
            const data = await notificationService.getNotifications(true);
            setAllNotifications(data);
        } catch (err) {
            console.error('Error loading all notifications:', err);
        } finally {
            setIsLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSubmitting(true);
        setError(null);

        try {
            await notificationService.createNotification({
                title: formData.title,
                message: formData.message,
                type: formData.type,
                targetId: formData.targetId || undefined,
            });
            setSuccess(true);
            setFormData({ title: '', message: '', type: 'alert', targetId: '' });
            loadAllNotifications(); // Refresh list
            setTimeout(() => setSuccess(false), 3000);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'เกิดข้อผิดพลาด');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm('คุณต้องการลบการแจ้งเตือนนี้ใช่หรือไม่?')) return;
        try {
            await notificationService.deleteNotification(id);
            setAllNotifications(prev => prev.filter(n => n.id !== id));
        } catch (err) {
            alert('ลบไม่สำเร็จ');
        }
    };

    const handleClearSystem = async () => {
        if (!window.confirm('⚠️ คำเตือน: คุณกำลังจะลบการแจ้งเตือนทั้งหมดของ "ทุกคน" ในระบบ ยืนยันใช่หรือไม่?')) return;
        try {
            await notificationService.clearAllNotifications(true);
            loadAllNotifications();
        } catch (err) {
            alert('ล้างระบบไม่สำเร็จ');
        }
    };

    return (
        <div className="min-h-screen bg-gray-50 py-8">
            <div className="max-w-4xl mx-auto px-4">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    {/* Create Notification Form */}
                    <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 h-fit">
                        <div className="flex items-center justify-between mb-8">
                            <h1 className="text-xl font-bold text-gray-900">สร้างการแจ้งเตือนใหม่</h1>
                            <button
                                onClick={() => navigate(-1)}
                                className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-black hover:text-white transition-colors"
                            >
                                ✕
                            </button>
                        </div>

                        {success && (
                            <div className="mb-6 p-4 bg-black text-white rounded-xl text-sm font-bold flex items-center gap-2 animate-in fade-in slide-in-from-top-4 duration-300">
                                <span>✓</span>
                                <span>ส่งการแจ้งเตือนสำเร็จ</span>
                            </div>
                        )}

                        {error && (
                            <div className="mb-6 p-4 bg-red-50 border border-red-100 rounded-xl text-red-700 text-sm font-medium">
                                {error}
                            </div>
                        )}

                        <form onSubmit={handleSubmit} className="space-y-6">
                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                                    หัวข้อ
                                </label>
                                <input
                                    type="text"
                                    value={formData.title}
                                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                                    className="w-full px-4 py-3 bg-gray-50 border-transparent rounded-xl focus:bg-white focus:ring-2 focus:ring-black focus:border-transparent transition-all outline-none"
                                    placeholder="เช่น ประกาศอัพเดทระบบ"
                                    required
                                />
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                                    ข้อความ
                                </label>
                                <textarea
                                    value={formData.message}
                                    onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                                    rows={4}
                                    className="w-full px-4 py-3 bg-gray-50 border-transparent rounded-xl focus:bg-white focus:ring-2 focus:ring-black focus:border-transparent transition-all outline-none resize-none"
                                    placeholder="ใส่รายละเอียดที่นี่ (ถ้ามี)..."
                                />
                            </div>

                            <div>
                                <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                                    ประเภท
                                </label>
                                <div className="grid grid-cols-3 gap-3">
                                    {['alert', 'trip', 'system'].map((type) => (
                                        <button
                                            key={type}
                                            type="button"
                                            onClick={() => setFormData({ ...formData, type })}
                                            className={`py-3 rounded-xl text-xs font-bold border-2 transition-all ${formData.type === type
                                                ? 'bg-black border-black text-white'
                                                : 'bg-white border-gray-100 text-gray-400 hover:border-gray-200'
                                                }`}
                                        >
                                            {type === 'alert' ? 'ทั่วไป' : type === 'trip' ? 'ทริป' : 'ระบบ'}
                                        </button>
                                    ))}
                                </div>
                            </div>

                            {formData.type === 'trip' && (
                                <div>
                                    <label className="block text-xs font-bold text-gray-400 uppercase tracking-widest mb-2">
                                        Trip ID
                                    </label>
                                    <input
                                        type="text"
                                        value={formData.targetId}
                                        onChange={(e) => setFormData({ ...formData, targetId: e.target.value })}
                                        className="w-full px-4 py-3 bg-gray-50 border-transparent rounded-xl focus:bg-white focus:ring-2 focus:ring-black focus:border-transparent transition-all outline-none"
                                        placeholder="ใส่รหัสทริป"
                                    />
                                </div>
                            )}

                            <button
                                type="submit"
                                disabled={isSubmitting}
                                className="w-full bg-black text-white py-4 rounded-xl font-bold hover:bg-gray-800 disabled:bg-gray-200 disabled:text-gray-400 transition-all shadow-lg shadow-black/10 active:scale-[0.98]"
                            >
                                {isSubmitting ? 'กำลังส่ง...' : 'ส่งแจ้งเตือน'}
                            </button>
                        </form>
                    </div>

                    {/* Notification Management List */}
                    <div className="space-y-6">
                        <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
                            <div className="flex items-center justify-between mb-8">
                                <h1 className="text-xl font-bold text-gray-900">จัดการแจ้งเตือนทั้งหมด</h1>
                                <button
                                    onClick={handleClearSystem}
                                    className="px-4 py-2 bg-red-50 text-red-500 text-xs font-bold rounded-lg hover:bg-red-500 hover:text-white transition-all"
                                >
                                    ล้างระบบทั้งหมด
                                </button>
                            </div>

                            <div className="space-y-4 max-h-[600px] overflow-y-auto pr-2 custom-scrollbar">
                                {isLoading ? (
                                    <div className="py-20 flex flex-col items-center justify-center space-y-4">
                                        <div className="w-8 h-8 border-2 border-gray-100 border-t-black rounded-full animate-spin"></div>
                                        <div className="text-[10px] font-bold uppercase tracking-widest text-gray-300">กำลังโหลดข้อมูล...</div>
                                    </div>
                                ) : allNotifications.length === 0 ? (
                                    <div className="py-12 text-center text-gray-400 font-medium">ไม่มีประวัติการแจ้งเตือน</div>
                                ) : (
                                    allNotifications.map((notif) => (
                                        <div key={notif.id} className="p-4 bg-white rounded-xl border border-gray-100 hover:border-black/10 transition-all group relative">
                                            <div className="flex justify-between items-start mb-1">
                                                <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded-md bg-gray-100 text-gray-500 flex items-center gap-1.5 opacity-80">
                                                    {notif.type === 'alert' ? (
                                                        <svg className="w-2.5 h-2.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" /></svg>
                                                    ) : notif.type === 'trip' ? (
                                                        <svg className="w-2.5 h-2.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                                                    ) : (
                                                        <svg className="w-2.5 h-2.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                                                    )}
                                                    {notif.type}
                                                </span>
                                                <button
                                                    onClick={() => handleDelete(notif.id)}
                                                    className="opacity-0 group-hover:opacity-100 w-6 h-6 rounded-md bg-white border border-gray-100 shadow-sm flex items-center justify-center text-gray-400 hover:text-red-500 hover:border-red-100 transition-all"
                                                >
                                                    <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M6 18L18 6M6 6l12 12" />
                                                    </svg>
                                                </button>
                                            </div>
                                            <h3 className="text-sm font-bold text-gray-900 line-clamp-1">{notif.title}</h3>
                                            {notif.message && <p className="text-xs text-gray-500 line-clamp-2 mt-1">{notif.message}</p>}
                                            <div className="mt-3 text-[10px] text-gray-400 font-medium flex items-center justify-between">
                                                <span>{notif.userId ? 'Direct' : 'Public'}</span>
                                                <span>{new Date(notif.createdAt).toLocaleDateString('th-TH')}</span>
                                            </div>
                                        </div>
                                    ))
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminAlert;
