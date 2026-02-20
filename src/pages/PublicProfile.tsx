import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { userAPI } from '../services/api';
import Loader from '../components/Loader';

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
    const [profile, setProfile] = useState<PublicUser | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    useEffect(() => {
        fetchPublicProfile();
    }, [userId]);

    const fetchPublicProfile = async () => {
        if (!userId) return;
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
                <div className="max-w-xl mx-auto mb-16">
                    <div className="bg-white rounded-[2rem] shadow-xl shadow-gray-200/50 p-8 border border-gray-100 flex flex-col items-center text-center relative overflow-hidden">
                        {/* Decorative bg */}
                        <div className="absolute top-0 left-0 right-0 h-32 bg-gray-50 rounded-t-[2rem]"></div>

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
                                            const label = typeof value === 'string' ? value : '';
                                            if (!label) return null;
                                            return (
                                                <span key={key} className="px-3 py-1 bg-black text-white text-[10px] font-bold rounded-full uppercase tracking-wider">
                                                    {label.replace('_', ' ')}
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
        </div>
    );
};

export default PublicProfile;
