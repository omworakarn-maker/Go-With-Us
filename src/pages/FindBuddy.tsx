import React, { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { matchAPI, MatchUser } from "../services/matchService";
import { messagesAPI } from "../services/api";
import { UserCircleIcon, ChatBubbleLeftIcon, ArrowPathIcon, SparklesIcon } from "@heroicons/react/24/outline";

export const FindBuddy: React.FC = () => {
    const [matches, setMatches] = useState<MatchUser[]>([]);
    const [loading, setLoading] = useState(true);
    const navigate = useNavigate();

    const handleGreet = async (userId: string) => {
        try {
            await matchAPI.likeUser(userId, 'like');
            // Visual feedback (like a toast or button state change) can go here
            console.log("Liked user:", userId);
        } catch (error) {
            console.error("Failed to like user:", error);
        }
    };

    useEffect(() => {
        fetchMatches();
    }, []);

    const fetchMatches = async () => {
        try {
            setLoading(true);
            const data = await matchAPI.getBuddyMatches();
            setMatches(data.matches || []);
        } catch (err: any) {
            console.error("Failed to fetch buddy matches:", err);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center pb-24">
            {/* Header */}
            <div className="w-full bg-white shadow-sm pt-8 pb-6 px-6 mb-6 rounded-b-3xl relative overflow-hidden">
                <div className="absolute top-0 right-0 w-32 h-32 bg-gray-100 rounded-full blur-3xl -mr-10 -mt-10 opacity-50"></div>
                <div className="max-w-md mx-auto flex items-center justify-between relative z-10">
                    <div>
                        <h1 className="text-3xl font-black text-black tracking-tight flex items-center gap-2">
                            Find Buddy <SparklesIcon className="w-6 h-6 text-black" />
                        </h1>
                        <p className="text-gray-500 text-sm mt-1">
                            เพื่อนเที่ยวที่ "เคมีตรงกัน" กับคุณ
                        </p>
                    </div>
                    <button
                        onClick={fetchMatches}
                        disabled={loading}
                        className="p-3 bg-gray-100 text-black rounded-full hover:bg-gray-200 transition-colors shadow-sm"
                    >
                        <ArrowPathIcon className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
                    </button>
                </div>
            </div>

            <div className="w-full max-w-md px-4">
                {loading && matches.length === 0 ? (
                    // Loading State Grid
                    <div className="grid grid-cols-2 gap-4">
                        {[1, 2, 3, 4].map(i => (
                            <div key={i} className="bg-white rounded-3xl h-64 shadow-sm border border-gray-100 animate-pulse flex flex-col p-4 relative overflow-hidden">
                                <div className="absolute top-0 right-0 w-16 h-16 bg-gray-50 rounded-bl-full"></div>
                                <div className="w-16 h-16 bg-gray-200 rounded-full mx-auto mt-4 mb-4"></div>
                                <div className="h-4 bg-gray-200 rounded w-3/4 mx-auto mb-2"></div>
                                <div className="h-3 bg-gray-200 rounded w-1/2 mx-auto mb-4"></div>
                                <div className="mt-auto h-10 bg-gray-100 rounded-2xl w-full"></div>
                            </div>
                        ))}
                    </div>
                ) : matches.length > 0 ? (
                    <div className="grid grid-cols-2 gap-3 md:gap-4">
                        {matches.map((user, idx) => {
                            // Determine glow based on score
                            const isHighMatch = user.matchScore !== undefined && user.matchScore >= 80;
                            const glowClass = isHighMatch ? 'ring-2 ring-black shadow-gray-200' : 'border-gray-100';

                            return (
                                <div 
                                    key={user.id} 
                                    className={`bg-white rounded-3xl shadow-sm border flex flex-col p-4 transition-all duration-300 hover:shadow-xl hover:-translate-y-1 relative overflow-hidden group ${glowClass}`}
                                    style={{ animationDelay: `${idx * 100}ms` }}
                                >
                                    {/* Match Badge */}
                                    <div className="absolute top-3 left-3 z-10">
                                        <div className={`px-2 py-1 rounded-xl text-[10px] font-black shadow-sm border border-white flex items-center gap-1 ${isHighMatch ? 'bg-black text-white' : 'bg-gray-100 text-gray-700'}`}>
                                            {user.matchScore}% Match
                                        </div>
                                    </div>

                                    {/* Avatar */}
                                    <div className="relative mx-auto mt-8 mb-3">
                                        <div className="w-20 h-20 rounded-full p-1 bg-gray-100">
                                            {user.profileImage ? (
                                                <img src={user.profileImage} alt={user.name} className="w-full h-full rounded-full object-cover border-2 border-white shadow-sm" />
                                            ) : (
                                                <div className="w-full h-full bg-black rounded-full flex items-center justify-center text-white font-bold text-3xl shadow-inner border-2 border-white">
                                                    {user.name.charAt(0).toUpperCase()}
                                                </div>
                                            )}
                                        </div>
                                    </div>

                                    {/* Info */}
                                    <div className="text-center flex-1 flex flex-col min-h-0">
                                        <h3 className="font-bold text-sm md:text-base text-gray-900 truncate px-2">{user.name}</h3>
                                        
                                        <div className="flex flex-wrap justify-center gap-1 mt-2 mb-4 overflow-hidden h-[44px]">
                                            {(user.interests || []).slice(0, 3).map((interest, i) => (
                                                <span key={i} className="text-[9px] md:text-[10px] bg-gray-50 border border-gray-100 text-gray-600 px-2 py-1 rounded-lg truncate max-w-[80px]">
                                                    {interest}
                                                </span>
                                            ))}
                                        </div>
                                        
                                        {/* Action */}
                                        <button 
                                            onClick={() => handleGreet(user.id)}
                                            className="mt-auto w-full py-2.5 bg-black text-white rounded-2xl text-xs font-bold hover:bg-gray-800 transition-colors shadow-md active:scale-95 flex items-center justify-center gap-2 group-hover:bg-gray-800"
                                        >
                                            <ChatBubbleLeftIcon className="w-4 h-4" /> ทักทาย
                                        </button>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                ) : (
                    <div className="text-center py-20 px-6 bg-white rounded-3xl border border-gray-100 shadow-sm">
                        <div className="w-24 h-24 bg-gray-50 rounded-full flex items-center justify-center mx-auto mb-6">
                            <UserCircleIcon className="w-12 h-12 text-gray-300" />
                        </div>
                        <h3 className="text-xl font-black text-gray-900 mb-2">ยังไม่พบเพื่อนที่ตรงกัน</h3>
                        <p className="text-gray-500 text-sm mb-8 leading-relaxed">
                            ดูเหมือนว่าไลฟ์สไตล์ของคุณจะเป็นเอกลักษณ์มาก ลองเพิ่มความสนใจในโปรไฟล์เพื่อให้เราจับคู่ได้แม่นยำขึ้นนะครับ
                        </p>
                        <Link to="/profile" className="inline-block w-full py-3 bg-black text-white rounded-2xl text-sm font-bold shadow-lg hover:shadow-xl transition-all hover:-translate-y-0.5">
                            แก้ไขโปรไฟล์
                        </Link>
                    </div>
                )}
            </div>
        </div>
    );
};
