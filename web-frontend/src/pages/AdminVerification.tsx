import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { userAPI } from '../services/api';

interface VerificationRequest {
    id: string;
    name: string;
    email: string;
    profileImage: string | null;
    faceScanImage: string;
    isEmailVerified: boolean;
    updatedAt: string;
}

const AdminVerification: React.FC = () => {
    const navigate = useNavigate();
    const { user, isLoading: authLoading } = useAuth();
    const [requests, setRequests] = useState<VerificationRequest[]>([]);
    const [isLoading, setIsLoading] = useState(false);

    useEffect(() => {
        if (!authLoading && user?.role !== 'admin') {
            navigate('/');
            return;
        }
        if (user?.role === 'admin') {
            loadRequests();
        }
    }, [user, authLoading, navigate]);

    const loadRequests = async () => {
        setIsLoading(true);
        try {
            const data = await userAPI.getVerificationRequests();
            setRequests(data.requests || []);
        } catch (err) {
            console.error('Error loading verification requests:', err);
        } finally {
            setIsLoading(false);
        }
    };

    const handleVerify = async (userId: string, status: 'verified' | 'rejected') => {
        const actionText = status === 'verified' ? 'ยืนยันตัวตน' : 'ปฏิเสธคำขอ';
        if (!window.confirm(`คุณแน่ใจหรือไม่ที่จะ ${actionText} ผู้ใช้นี้?`)) return;

        try {
            await userAPI.verifyUser(userId, status);
            alert(`${actionText} สำเร็จ`);
            loadRequests();
        } catch (error) {
            console.error('Error verifying user:', error);
            alert('เกิดข้อผิดพลาดในการทำรายการ');
        }
    };

    if (authLoading) return null;
    if (user?.role !== 'admin') return null;

    return (
        <div className="min-h-screen bg-gray-50 py-8">
            <div className="max-w-5xl mx-auto px-4">
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
                    <div className="flex items-center justify-between mb-8">
                        <div>
                            <h1 className="text-xl font-bold text-gray-900">ตรวจสอบการยืนยันตัวตน</h1>
                            <p className="text-sm text-gray-500 mt-1">ตรวจรูปใบหน้าจากขั้นตอนตรวจการเคลื่อนไหวของบัญชีที่ยืนยันอีเมลแล้ว</p>
                        </div>
                        <button
                            onClick={() => navigate(-1)}
                            className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-black hover:text-white transition-colors"
                        >
                            ✕
                        </button>
                    </div>

                    <div className="space-y-6 max-h-[750px] overflow-y-auto pr-2 custom-scrollbar">
                        {isLoading ? (
                            <div className="py-20 flex flex-col items-center justify-center space-y-4">
                                <div className="w-8 h-8 border-2 border-gray-100 border-t-black rounded-full animate-spin"></div>
                                <div className="text-[10px] font-bold uppercase tracking-widest text-gray-300">กำลังโหลด...</div>
                            </div>
                        ) : requests.length === 0 ? (
                            <div className="py-12 text-center text-gray-400 font-medium">ไม่มีคำขอรอการตรวจสอบ</div>
                        ) : (
                            requests.map((req) => (
                                <div key={req.id} className="p-6 bg-white rounded-2xl border border-gray-200 hover:border-indigo-500/30 transition-all flex flex-col gap-6 shadow-sm relative overflow-hidden">
                                    <div className="absolute top-0 right-0 px-4 py-1.5 bg-yellow-100 text-yellow-700 text-[10px] font-bold uppercase tracking-wider rounded-bl-lg">
                                        รอตรวจสอบ
                                    </div>

                                    <div className="flex items-center gap-4">
                                        <div className="w-14 h-14 rounded-full bg-gray-100 flex items-center justify-center overflow-hidden border-2 border-white shadow-sm">
                                            {req.profileImage ? (
                                                <img src={req.profileImage} alt="" className="w-full h-full object-cover" />
                                            ) : (
                                                "👤"
                                            )}
                                        </div>
                                        <div>
                                            <p className="text-base font-bold text-gray-900">{req.name}</p>
                                            <p className="text-xs text-gray-500">{req.email}</p>
                                        </div>
                                        <div className="ml-auto text-right">
                                            <p className="text-xs font-semibold text-gray-400">ส่งคำขอเมื่อ</p>
                                            <p className="text-sm font-bold">{new Date(req.updatedAt).toLocaleString('th-TH')}</p>
                                        </div>
                                    </div>

                                    <div className="flex flex-wrap gap-2">
                                        <span className={`px-3 py-1.5 rounded-full text-xs font-bold ${req.isEmailVerified ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`}>
                                            {req.isEmailVerified ? '✓ ยืนยันอีเมลแล้ว' : 'ยังไม่ยืนยันอีเมล'}
                                        </span>
                                        <span className="px-3 py-1.5 rounded-full bg-indigo-100 text-indigo-700 text-xs font-bold">
                                            ✓ ส่งรูปผ่านขั้นตอนตรวจการเคลื่อนไหวแล้ว
                                        </span>
                                    </div>

                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                        {/* Existing profile image for visual comparison */}
                                        <div className="space-y-2">
                                            <p className="text-[11px] font-bold text-gray-500 uppercase tracking-widest flex items-center gap-2">
                                                รูปโปรไฟล์ปัจจุบัน
                                            </p>
                                            <div className="w-full aspect-[4/3] bg-gray-100 rounded-xl overflow-hidden border border-gray-200 group relative">
                                                {req.profileImage ? (
                                                    <img src={req.profileImage} alt="รูปโปรไฟล์" className="w-full h-full object-cover transition-transform group-hover:scale-105" />
                                                ) : (
                                                    <div className="w-full h-full flex items-center justify-center text-gray-400">ไม่มีรูปโปรไฟล์</div>
                                                )}
                                            </div>
                                        </div>

                                        {/* Face Scan */}
                                        <div className="space-y-2">
                                            <p className="text-[11px] font-bold text-gray-500 uppercase tracking-widest flex items-center gap-2">
                                                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                                                รูปจากการตรวจการเคลื่อนไหวใบหน้า
                                            </p>
                                            <div className="w-full aspect-[4/3] bg-gray-100 rounded-xl overflow-hidden border border-gray-200 group relative">
                                                <img src={req.faceScanImage} alt="Face Scan" className="w-full h-full object-cover transition-transform group-hover:scale-105" />
                                            </div>
                                        </div>
                                    </div>

                                    {/* Action Buttons */}
                                    <div className="flex gap-4 items-center justify-end pt-4 border-t border-gray-100">
                                        <button
                                            onClick={() => handleVerify(req.id, 'rejected')}
                                            className="px-6 py-2.5 bg-white border-2 border-red-500 text-red-500 text-sm font-bold rounded-xl hover:bg-red-50 transition-all active:scale-95"
                                        >
                                            ปฏิเสธคำขอ
                                        </button>
                                        <button
                                            onClick={() => handleVerify(req.id, 'verified')}
                                            className="px-6 py-2.5 bg-green-500 text-white text-sm font-bold rounded-xl hover:bg-green-600 transition-all shadow-md active:scale-95 flex items-center gap-2"
                                        >
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7" /></svg>
                                            อนุมัติการยืนยันตัวตน
                                        </button>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminVerification;
