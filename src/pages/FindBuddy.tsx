import React, { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { matchAPI, MatchUser } from "../services/matchService";
import { UserCircleIcon, ChatBubbleLeftIcon, ArrowPathIcon } from "@heroicons/react/24/outline";

export const FindBuddy: React.FC = () => {
    const [matches, setMatches] = useState<MatchUser[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState("");

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
            // setError("ไม่สามาถค้นหาเพื่อนได้ในขณะนี้"); 
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-gray-50 flex flex-col items-center pb-24">
            {/* Header */}
            <div className="w-full bg-white shadow-sm pt-8 pb-6 px-6 mb-6">
                <div className="max-w-md mx-auto flex items-center justify-between">
                    <div>
                        <h1 className="text-3xl font-black text-black tracking-tight">
                            Find Buddy
                        </h1>
                        <p className="text-gray-500 text-sm">
                            เพื่อนเที่ยวที่ "เคมีตรงกัน" กับคุณ
                        </p>
                    </div>
                    <button
                        onClick={fetchMatches}
                        disabled={loading}
                        className="p-2 bg-gray-100 rounded-full hover:bg-gray-200 transition-colors"
                    >
                        <ArrowPathIcon className={`w-6 h-6 text-gray-700 ${loading ? 'animate-spin' : ''}`} />
                    </button>
                </div>
            </div>

            <div className="w-full max-w-md px-6 space-y-4">
                {loading && matches.length === 0 ? (
                    // Loading State
                    [1, 2, 3].map(i => (
                        <div key={i} className="bg-white p-6 rounded-3xl shadow-sm border border-gray-100 animate-pulse flex items-center gap-4">
                            <div className="w-16 h-16 bg-gray-200 rounded-full"></div>
                            <div className="flex-1 space-y-2">
                                <div className="h-4 bg-gray-200 rounded w-1/2"></div>
                                <div className="h-3 bg-gray-200 rounded w-3/4"></div>
                            </div>
                        </div>
                    ))
                ) : matches.length > 0 ? (
                    matches.map(user => (
                        <div key={user.id} className="bg-white p-6 rounded-3xl shadow-sm border border-gray-100 flex items-center gap-5 transition-all hover:shadow-md hover:scale-[1.02]">
                            {/* Avatar / Score */}
                            <div className="relative">
                                <div className="w-16 h-16 bg-gradient-to-br from-indigo-500 to-purple-500 rounded-full flex items-center justify-center text-white font-bold text-2xl shadow-lg shadow-indigo-200">
                                    {user.name.charAt(0).toUpperCase()}
                                </div>
                                <div className="absolute -bottom-2 -right-2 bg-black text-white text-[10px] font-bold px-2 py-1 rounded-full border-2 border-white shadow-sm">
                                    {user.matchScore}%
                                </div>
                            </div>

                            {/* Info */}
                            <div className="flex-1 min-w-0">
                                <h3 className="font-bold text-lg text-gray-900 truncate">{user.name}</h3>
                                <div className="flex flex-wrap gap-1 mt-1">
                                    {(user.interests || []).slice(0, 3).map((interest, i) => (
                                        <span key={i} className="text-[10px] bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md">
                                            {interest}
                                        </span>
                                    ))}
                                    {(user.interests || []).length > 3 && (
                                        <span className="text-[10px] bg-gray-100 text-gray-600 px-2 py-0.5 rounded-md">
                                            +{(user.interests || []).length - 3}
                                        </span>
                                    )}
                                </div>
                            </div>

                            {/* Action */}
                            <button className="p-3 bg-black text-white rounded-2xl hover:bg-gray-800 transition-colors shadow-lg shadow-black/10 active:scale-95">
                                <ChatBubbleLeftIcon className="w-5 h-5" />
                            </button>
                        </div>
                    ))
                ) : (
                    <div className="text-center py-20">
                        <UserCircleIcon className="w-20 h-20 text-gray-300 mx-auto mb-4" />
                        <h3 className="text-lg font-bold text-gray-900">ยังไม่พบเพื่อนที่ตรงกัน</h3>
                        <p className="text-gray-500 text-sm mt-2 max-w-xs mx-auto">
                            ลองเพิ่มความสนใจในโปรไฟล์ของคุณเพื่อให้เราจับคู่ได้แม่นยำขึ้น
                        </p>
                        <Link to="/profile" className="mt-6 inline-block px-6 py-2 bg-black text-white rounded-full text-sm font-bold">
                            แก้ไขโปรไฟล์
                        </Link>
                    </div>
                )}
            </div>
        </div>
    );
};
