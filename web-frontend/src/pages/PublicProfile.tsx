import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { userAPI } from '../services/api';
import Loader from '../components/Loader';
import { useAuth } from '../contexts/AuthContext';

interface PublicUser {
    id: string;
    name: string;
    role: string;
    email?: string;
    gender?: string;
    age?: number;
    bio?: string;
    profileImage?: string;
    interests?: string[];
    travelStyle?: any;
    createdAt: string;
    trips: any[];
    isProfilePublic: boolean;
}

const PublicProfile: React.FC = () => {
    const { userId } = useParams<{ userId: string }>();
    const navigate = useNavigate();
    const { user: currentUser } = useAuth();
    const [profile, setProfile] = useState<PublicUser | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    // Moderation States
    const [showMenu, setShowMenu] = useState(false);
    const [showReportModal, setShowReportModal] = useState(false);
    const [reportReason, setReportReason] = useState("");
    const [actionMsg, setActionMsg] = useState("");
    const [showWarnModal, setShowWarnModal] = useState(false);
    const [warningMsg, setWarningMsg] = useState("");

    useEffect(() => {
        fetchPublicProfile();
    }, [userId]);

    const fetchPublicProfile = async () => {
        if (!userId) return;

        // Bypass public API restrictions if viewing own profile
        if (currentUser && currentUser.id === userId) {
            setProfile(currentUser as any);
            setLoading(false);
            return;
        }

        try {
            setLoading(true);
            const response = await fetch(`/api/users/${userId}/public`);
            if (!response.ok) {
                if (response.status === 403) {
                    setError('This profile is private');
                } else {
                    setError('User not found');
                }
                return;
            }
            const data = await response.json();
            setProfile(data);
        } catch (err) {
            console.error('Failed to fetch public profile:', err);
            setError('Failed to load profile');
        } finally {
            setLoading(false);
        }
    };

    const handleReport = async () => {
        if (!reportReason.trim() || !userId) return;
        try {
            await userAPI.reportUser(userId, reportReason);
            setActionMsg("ส่งรายงานปัญหาสำเร็จ! แอดมินจะตรวจสอบเร็วๆนี้");
            setShowReportModal(false);
            setReportReason("");
        } catch (err) {
            setActionMsg("เกิดข้อผิดพลาดในการรายงาน");
        }
    };

    const handleBan = async () => {
        if (!userId) return;
        if (!window.confirm("คุณต้องการแบนผู้ใช้นี้ใช่หรือไม่?")) return;
        try {
            await userAPI.banUser(userId, true);
            setActionMsg("ทำการแบนผู้ใช้ท่านนี้เรียบร้อยแล้ว");
        } catch (err) {
            setActionMsg("เกิดข้อผิดพลาดในการแบนผู้ใช้");
        }
    };

    const handleWarn = async () => {
        if (!warningMsg.trim() || !userId) return;
        try {
            await userAPI.warnUser(userId, warningMsg);
            setActionMsg("ส่งคำเตือนไปยังผู้ใช้เรียบร้อยแล้ว");
            setShowWarnModal(false);
            setWarningMsg("");
        } catch (err) {
            setActionMsg("เกิดข้อผิดพลาดในการส่งคำเตือน");
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center min-h-screen bg-gray-50/50">
                <Loader variant="dots" />
            </div>
        );
    }

    if (error) {
        return (
            <div className="min-h-screen bg-white pb-20">
                <div className="max-w-6xl mx-auto px-6 pt-8">
                    <button
                        onClick={() => navigate(-1)}
                        className="mb-6 text-gray-600 hover:text-black transition-colors"
                    >
                        ← ย้อนกลับ
                    </button>
                    <div className="max-w-xl mx-auto text-center">
                        <div className="bg-red-50 border border-red-200 rounded-2xl p-8">
                            <p className="text-red-600 font-bold text-lg">{error}</p>
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    if (!profile) return null;

    return (
        <div className="min-h-screen bg-white pb-20">
            <div className="max-w-6xl mx-auto px-6 pt-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
                {/* Back Button */}
                <button
                    onClick={() => navigate(-1)}
                    className="mb-6 text-gray-600 hover:text-black transition-colors font-medium"
                >
                    ← ย้อนกลับ
                </button>

                {/* Profile Card */}
                <div className="max-w-xl mx-auto mb-16 relative">
                    <div className="bg-white rounded-[2rem] shadow-xl shadow-gray-200/50 p-8 border border-gray-100 flex flex-col items-center text-center relative overflow-hidden">
                        {/* Decorative bg */}
                        <div className="absolute top-0 left-0 right-0 h-32 bg-gray-50 rounded-t-[2rem]"></div>

                        {/* Action Menu button top right */}
                        {currentUser && currentUser.id !== profile.id && (
                            <div className="absolute top-4 right-4 z-20">
                                <button
                                    onClick={() => setShowMenu(!showMenu)}
                                    className="w-10 h-10 bg-white/20 backdrop-blur-md rounded-full flex items-center justify-center text-white hover:bg-white/40 transition-colors"
                                >
                                    <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                                        <path d="M6 10a2 2 0 11-4 0 2 2 0 014 0zM12 10a2 2 0 11-4 0 2 2 0 014 0zM16 12a2 2 0 100-4 2 2 0 000 4z" />
                                    </svg>
                                </button>
                                {showMenu && (
                                    <div className="absolute top-12 right-0 bg-white rounded-xl shadow-xl border border-gray-100 w-48 text-left overflow-hidden">
                                        <button
                                            onClick={() => { setShowMenu(false); setShowReportModal(true); }}
                                            className="w-full px-4 py-3 text-sm font-medium text-red-600 hover:bg-red-50 transition-colors text-left"
                                        >
                                            รายงานผู้ใช้ (Report)
                                        </button>
                                        {currentUser.role === 'admin' && (
                                            <>
                                                <button
                                                    onClick={() => { setShowMenu(false); handleBan(); }}
                                                    className="w-full px-4 py-3 text-sm font-medium text-red-600 hover:bg-red-50 border-t border-gray-100 transition-colors text-left"
                                                >
                                                    แบนผู้ใช้ (Ban)
                                                </button>
                                                <button
                                                    onClick={() => { setShowMenu(false); setShowWarnModal(true); }}
                                                    className="w-full px-4 py-3 text-sm font-medium text-blue-600 hover:bg-blue-50 border-t border-gray-100 transition-colors text-left"
                                                >
                                                    ตักเตือนผู้ใช้ (Warn)
                                                </button>
                                            </>
                                        )}
                                    </div>
                                )}
                            </div>
                        )}

                        {/* Avatar */}
                        <div className="w-32 h-32 bg-black rounded-full border-4 border-white shadow-lg overflow-hidden relative z-10 mb-4 flex items-center justify-center text-5xl font-bold text-white">
                            {profile.profileImage ? (
                                <img src={profile.profileImage} alt="" className="w-full h-full object-cover" />
                            ) : (
                                profile.name.charAt(0).toUpperCase()
                            )}
                        </div>

                        <div className="w-full z-10">
                            <h1 className="text-3xl font-black text-gray-900 mb-1">{profile.name}</h1>
                            {profile.email && (
                                <p className="text-gray-500 font-medium mb-4">{profile.email}</p>
                            )}

                            <div className="flex flex-col items-center gap-2 mb-6">
                                <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest ${profile.role === 'admin' ? 'bg-black text-white' : 'bg-gray-100 text-gray-600'}`}>
                                    {profile.role}
                                </span>
                            </div>

                            {/* Basic Info Cards */}
                            {(profile.gender || profile.age) && (
                                <div className="space-y-3 mb-6 border-t border-gray-100 pt-6">
                                    <div className="grid grid-cols-2 gap-3">
                                        {profile.gender && (
                                            <div className="bg-gray-50 rounded-lg p-3">
                                                <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest mb-1">เพศ</p>
                                                <p className="text-sm font-bold text-black">
                                                    {profile.gender === 'male' ? 'ชาย' : profile.gender === 'female' ? 'หญิง' : 'อื่นๆ'}
                                                </p>
                                            </div>
                                        )}
                                        {profile.age && (
                                            <div className="bg-gray-50 rounded-lg p-3">
                                                <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest mb-1">อายุ</p>
                                                <p className="text-sm font-bold text-black">{profile.age} ปี</p>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}

                            {/* Bio */}
                            {profile.bio && (
                                <div className="bg-gray-50 rounded-lg p-4 mb-6">
                                    <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest mb-2">ประวัติส่วนตัว</p>
                                    <p className="text-sm text-gray-700 leading-relaxed">{profile.bio}</p>
                                </div>
                            )}

                            {/* Travel Style */}
                            {profile.travelStyle && (
                                <div className="mb-6 border-t border-gray-100 pt-6">
                                    <h3 className="text-sm font-bold text-black mb-3">สไตล์การเดินทาง</h3>
                                    <div className="flex flex-wrap justify-center gap-2">
                                        {Object.entries(profile.travelStyle).map(([key, value]) => {
                                            if (key === 'interests') return null;

                                            const keyLabels: { [key: string]: string } = {
                                                budget: 'งบประมาณ',
                                                activityStyle: 'สไตล์กิจกรรม',
                                                pace: 'ความเร็วทริป',
                                                adventure: 'แอดเวนเจอร์',
                                                food: 'เน้นกิน',
                                                social: 'ปาร์ตี้/สังคม',
                                                photography: 'ถ่ายรูป'
                                            };
                                            const timeLabels: { [key: string]: string } = {
                                                morning: 'เช้า',
                                                noon:    'กลางวัน',
                                                evening: 'เย็น',
                                                night:   'มืด/ราตรี',
                                            };

                                            // timeOfDay is stored as string[]
                                            if (key === 'timeOfDay' && Array.isArray(value)) {
                                                return (value as string[]).map(slot => (
                                                    <span key={`time-${slot}`} className="px-3 py-1 bg-black text-white text-[10px] font-bold rounded-full uppercase tracking-wider">
                                                        {timeLabels[slot] || slot}
                                                    </span>
                                                ));
                                            }

                                            let label = '';
                                            if (typeof value === 'number') {
                                                const thaiKey = keyLabels[key] || key;
                                                label = `${thaiKey}: ${value}/10`;
                                            } else if (typeof value === 'string') {
                                                label = value.replace('_', ' ');
                                            }
                                            if (!label) return null;
                                            return (
                                                <span key={key} className="px-3 py-1 bg-black text-white text-[10px] font-bold rounded-full uppercase tracking-wider">
                                                    {label}
                                                </span>
                                            );
                                        })}
                                    </div>
                                </div>
                            )}

                            {/* Interests */}
                            {profile.interests && profile.interests.length > 0 && (
                                <div className="mb-6 border-t border-gray-100 pt-6">
                                    <h3 className="text-sm font-bold text-black mb-3">ความสนใจ</h3>
                                    <div className="flex flex-wrap justify-center gap-2">
                                        {profile.interests.map(interest => (
                                            <span key={interest} className="px-3 py-1 bg-black text-white text-[10px] font-bold rounded-full">
                                                {interest}
                                            </span>
                                        ))}
                                    </div>
                                </div>
                            )}

                            {/* Trips */}
                            {profile.trips && profile.trips.length > 0 && (
                                <div className="border-t border-gray-100 pt-6">
                                    <h3 className="text-sm font-bold text-black mb-3">ทริปล่าสุด ({profile.trips.length})</h3>
                                    <div className="space-y-3">
                                        {profile.trips.map(trip => (
                                            <div key={trip.id} className="bg-gray-50 rounded-lg p-3 text-left cursor-pointer hover:bg-gray-100 transition-colors">
                                                <p className="font-bold text-black text-sm">{trip.title}</p>
                                                <p className="text-xs text-gray-500">{trip.destination}</p>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>
                </div>
            </div>

            {/* Warn Modal */}
            {showWarnModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in">
                    <div className="bg-white rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                        <h3 className="text-xl font-bold mb-2">ตักเตือนผู้ใช้นี้</h3>
                        <p className="text-sm text-gray-500 mb-6">ข้อความนี้จะถูกส่งไปยังผู้ใช้ในรูปแบบการแจ้งเตือนจากระบบ</p>

                        <textarea
                            value={warningMsg}
                            onChange={(e) => setWarningMsg(e.target.value)}
                            placeholder="ระบุข้อความตักเตือน"
                            className="w-full bg-gray-50 border border-gray-200 rounded-xl p-4 text-sm focus:outline-none focus:ring-2 focus:ring-black mb-6 min-h-[100px]"
                        ></textarea>

                        <div className="flex gap-3">
                            <button
                                onClick={() => { setShowWarnModal(false); setWarningMsg(""); }}
                                className="flex-1 py-3 bg-black text-white rounded-xl font-bold hover:bg-gray-800 transition-colors"
                            >
                                ยกเลิก
                            </button>
                            <button
                                onClick={handleWarn}
                                disabled={!warningMsg.trim()}
                                className="flex-1 py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition-colors disabled:opacity-50"
                            >
                                ส่งคำเตือน
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Action Message Toast */}
            {actionMsg && (
                <div className="fixed bottom-10 left-1/2 transform -translate-x-1/2 bg-gray-900 text-white px-6 py-3 rounded-full text-sm font-medium shadow-2xl z-50 animate-in fade-in slide-in-from-bottom-4">
                    {actionMsg}
                    <button onClick={() => setActionMsg("")} className="ml-4 text-gray-400 hover:text-white">&times;</button>
                </div>
            )}

            {/* Report Modal */}
            {showReportModal && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in">
                    <div className="bg-white rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                        <h3 className="text-xl font-bold mb-2">รายงานผู้ใช้นี้</h3>
                        <p className="text-sm text-gray-500 mb-6">โปรดระบุเหตุผลที่คุณต้องการรายงานผู้ใช้คนนี้ ข้อมูลจะถูกส่งไปยังแอดมินเพื่อตรวจสอบ</p>

                        <textarea
                            value={reportReason}
                            onChange={(e) => setReportReason(e.target.value)}
                            placeholder="ระบุเหตุผล (เช่น สแปม, ก้าวร้าว)"
                            className="w-full bg-gray-50 border border-gray-200 rounded-xl p-4 text-sm focus:outline-none focus:ring-2 focus:ring-black mb-6 min-h-[100px]"
                        ></textarea>

                        <div className="flex gap-3">
                            <button
                                onClick={() => { setShowReportModal(false); setReportReason(""); }}
                                className="flex-1 py-3 bg-black text-white rounded-xl font-bold hover:bg-gray-800 transition-colors"
                            >
                                ยกเลิก
                            </button>
                            <button
                                onClick={handleReport}
                                disabled={!reportReason.trim()}
                                className="flex-1 py-3 bg-red-600 text-white rounded-xl font-bold hover:bg-red-700 transition-colors disabled:opacity-50"
                            >
                                ส่งรายงาน
                            </button>
                        </div>
                    </div>
                </div>
            )}

        </div>
    );
};

export default PublicProfile;
