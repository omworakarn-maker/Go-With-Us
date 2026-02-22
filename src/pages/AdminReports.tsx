import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { userAPI } from '../services/api';

interface Report {
    id: string;
    reason: string;
    status: string;
    createdAt: string;
    reporter: {
        id: string;
        name: string;
        email: string;
        profileImage: string | null;
    };
    reported: {
        id: string;
        name: string;
        email: string;
        profileImage: string | null;
        isBanned: boolean;
    };
}

const AdminReports: React.FC = () => {
    const navigate = useNavigate();
    const { user, isLoading: authLoading } = useAuth();
    const [reports, setReports] = useState<Report[]>([]);
    const [isLoading, setIsLoading] = useState(false);
    const [showWarnModal, setShowWarnModal] = useState(false);
    const [warningMsg, setWarningMsg] = useState("");
    const [targetUserId, setTargetUserId] = useState("");

    useEffect(() => {
        if (!authLoading && user?.role !== 'admin') {
            navigate('/');
            return;
        }
        if (user?.role === 'admin') {
            loadReports();
        }
    }, [user, authLoading, navigate]);

    const loadReports = async () => {
        setIsLoading(true);
        try {
            const data = await userAPI.getAllReports();
            setReports(data.reports || []);
        } catch (err) {
            console.error('Error loading reports:', err);
        } finally {
            setIsLoading(false);
        }
    };

    const handleBanUser = async (userId: string, isBanned: boolean) => {
        const actionText = isBanned ? 'ระงับบัญชี (Ban)' : 'ปลดระงับบัญชี (Unban)';
        if (!window.confirm(`คุณแน่ใจหรือไม่ที่จะ ${actionText} ผู้ใช้นี้?`)) return;

        try {
            await userAPI.banUser(userId, isBanned);
            alert(`${actionText} สำเร็จ`);
            loadReports(); // Refresh the list to show updated status
        } catch (error) {
            console.error('Error banning user:', error);
            alert('เกิดข้อผิดพลาดในการทำรายการ');
        }
    };

    const handleWarnUser = async () => {
        if (!warningMsg.trim() || !targetUserId) return;
        try {
            await userAPI.warnUser(targetUserId, warningMsg);
            alert("ส่งคำเตือนไปยังผู้ใช้เรียบร้อยแล้ว");
            setShowWarnModal(false);
            setWarningMsg("");
            setTargetUserId("");
        } catch (err) {
            console.error('Error warning user:', err);
            alert("เกิดข้อผิดพลาดในการส่งคำเตือน");
        }
    };

    if (authLoading) return null;
    if (user?.role !== 'admin') return null;

    return (
        <div className="min-h-screen bg-gray-50 py-8">
            <div className="max-w-4xl mx-auto px-4">
                <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
                    <div className="flex items-center justify-between mb-8">
                        <h1 className="text-xl font-bold text-gray-900">จัดการรายงานบัญชี (Reports)</h1>
                        <button
                            onClick={() => navigate(-1)}
                            className="w-8 h-8 rounded-full bg-gray-100 flex items-center justify-center text-gray-500 hover:bg-black hover:text-white transition-colors"
                        >
                            ✕
                        </button>
                    </div>

                    <div className="space-y-4 max-h-[700px] overflow-y-auto pr-2 custom-scrollbar">
                        {isLoading ? (
                            <div className="py-20 flex flex-col items-center justify-center space-y-4">
                                <div className="w-8 h-8 border-2 border-gray-100 border-t-black rounded-full animate-spin"></div>
                                <div className="text-[10px] font-bold uppercase tracking-widest text-gray-300">กำลังโหลด...</div>
                            </div>
                        ) : reports.length === 0 ? (
                            <div className="py-12 text-center text-gray-400 font-medium">ไม่มีรายงานในขณะนี้</div>
                        ) : (
                            reports.map((report) => (
                                <div key={report.id} className="p-5 bg-white rounded-xl border border-gray-100 hover:border-black/10 transition-all flex flex-col gap-4 shadow-sm">
                                    <div className="flex justify-between items-start">
                                        <div>
                                            <span className="text-xs font-bold text-gray-400">วันที่รายงาน:</span>
                                            <p className="text-sm font-semibold">{new Date(report.createdAt).toLocaleString('th-TH')}</p>
                                        </div>
                                        <div className="text-right">
                                            <span className="text-[10px] font-bold uppercase px-2 py-0.5 rounded-md bg-red-100 text-red-500">
                                                รอตรวจสอบ
                                            </span>
                                        </div>
                                    </div>

                                    <div className="p-3 bg-red-50 rounded-lg border border-red-100/50">
                                        <p className="text-xs font-bold text-red-400 uppercase tracking-widest mb-1">เหตุผลที่ถูกรายงาน</p>
                                        <p className="text-sm text-gray-800">{report.reason}</p>
                                    </div>

                                    <div className="flex gap-4 items-center pt-2">
                                        {/* Reported User */}
                                        <div className="flex-1 flex items-center gap-3">
                                            <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center text-lg overflow-hidden border-2 border-red-200">
                                                {report.reported.profileImage ? (
                                                    <img src={report.reported.profileImage} alt="" className="w-full h-full object-cover" />
                                                ) : (
                                                    "👨‍💻"
                                                )}
                                            </div>
                                            <div>
                                                <p className="text-xs font-bold text-gray-400">ผู้ถูกรายงาน</p>
                                                <p className="text-sm font-bold text-gray-900 line-clamp-1">{report.reported.name}</p>
                                            </div>
                                        </div>

                                        {/* Action Button */}
                                        <div className="flex gap-2">
                                            {report.reported.isBanned ? (
                                                <button
                                                    onClick={() => handleBanUser(report.reported.id, false)}
                                                    className="px-4 py-2 bg-gray-100 text-gray-700 text-xs font-bold rounded-lg hover:bg-gray-200 transition-all"
                                                >
                                                    ปลดแบน
                                                </button>
                                            ) : (
                                                <>
                                                    <button
                                                        onClick={() => {
                                                            setTargetUserId(report.reported.id);
                                                            setShowWarnModal(true);
                                                        }}
                                                        className="px-4 py-2 bg-blue-50 text-blue-600 text-xs font-bold rounded-lg hover:bg-blue-100 transition-all border border-blue-100"
                                                    >
                                                        ตักเตือน
                                                    </button>
                                                    <button
                                                        onClick={() => handleBanUser(report.reported.id, true)}
                                                        className="px-4 py-2 bg-black text-white text-xs font-bold rounded-lg hover:bg-red-600 transition-all shadow-md"
                                                    >
                                                        แบนผู้ใช้
                                                    </button>
                                                </>
                                            )}
                                        </div>
                                    </div>

                                    <div className="pt-2 border-t border-gray-100/60 mt-2 flex items-center gap-2">
                                        <span className="text-xs text-gray-400">ผู้รายงาน: {report.reporter.name}</span>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>
            </div>

            {/* Warn Modal */}
            {showWarnModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in">
                    <div className="bg-white rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                        <h3 className="text-xl font-bold mb-2 text-gray-900">ตักเตือนผู้ใช้</h3>
                        <p className="text-sm text-gray-500 mb-6">ข้อความนี้จะถูกส่งไปยังผู้ใช้ที่ถูกรายงานเพื่อเตือนพฤติกรรม</p>

                        <textarea
                            value={warningMsg}
                            onChange={(e) => setWarningMsg(e.target.value)}
                            placeholder="ระบุข้อความตักเตือน..."
                            className="w-full bg-gray-50 border border-gray-200 rounded-xl p-4 text-sm focus:outline-none focus:ring-2 focus:ring-black mb-6 min-h-[100px]"
                        ></textarea>

                        <div className="flex gap-3">
                            <button
                                onClick={() => { setShowWarnModal(false); setWarningMsg(""); setTargetUserId(""); }}
                                className="flex-1 py-3 bg-gray-100 text-gray-700 rounded-xl font-bold hover:bg-gray-200 transition-colors"
                            >
                                ยกเลิก
                            </button>
                            <button
                                onClick={handleWarnUser}
                                disabled={!warningMsg.trim()}
                                className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition-colors disabled:opacity-50"
                            >
                                ส่งคำเตือน
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default AdminReports;
