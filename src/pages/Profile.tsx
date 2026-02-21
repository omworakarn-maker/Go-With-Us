import React, { useState, useEffect } from 'react';
import { TripCard } from '../components/TripCard';
import { useAuth } from '../contexts/AuthContext';
import { userAPI } from '../services/api';
import { Trip } from '../types';
import { TRIP_CATEGORIES } from '../constants/categories';
import Loader from '../components/Loader';
import { TravelStyleQuizModal } from '../components/TravelStyleQuizModal';

interface ExtendedUser {
    id: string;
    email: string;
    name: string;
    role: string;
    gender?: string;
    age?: number;
    bio?: string;
    birthDate?: string;
    profileImage?: string;
    interests: string[];
    createdAt: string;
    createdTrips: Trip[];
    participatedTrips: { trip: Trip }[];
    travelStyle?: any;
    isProfilePublic?: boolean;
    showGender?: boolean;
    showAge?: boolean;
    showBio?: boolean;
    showInterests?: boolean;
    showEmail?: boolean;
    isVerified?: boolean;
    verificationStatus?: string;
}

const Profile: React.FC = () => {
    const { logout, refreshUser } = useAuth();
    const [profile, setProfile] = useState<ExtendedUser | null>(null);
    const [loading, setLoading] = useState(true);
    const [isEditing, setIsEditing] = useState(false);
    const [showQuiz, setShowQuiz] = useState(false);

    // Edit Form States
    const [newName, setNewName] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [newInterests, setNewInterests] = useState<string[]>([]);
    const [newGender, setNewGender] = useState('');
    const [newAge, setNewAge] = useState('');
    const [newBio, setNewBio] = useState('');
    const [newBirthDate, setNewBirthDate] = useState('');
    const [newProfileImage, setNewProfileImage] = useState<string | null>(null);

    const [saving, setSaving] = useState(false);
    const [privacySettings, setPrivacySettings] = useState({
        isProfilePublic: true,
        showGender: true,
        showAge: true,
        showBio: true,
        showInterests: true,
        showEmail: false,
    });

    const [activeTab, setActiveTab] = useState<'my-trips' | 'joined-trips'>('my-trips');
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');

    useEffect(() => {
        fetchProfile();
    }, []);

    const fetchProfile = async () => {
        try {
            const data = await userAPI.getProfile();
            setProfile(data);
            setNewName(data.name);
            setNewInterests(data.interests || []);
            setNewGender(data.gender || '');
            setNewAge(data.age ? String(data.age) : '');
            setNewBio(data.bio || '');
            setNewBirthDate(data.birthDate ? data.birthDate.split('T')[0] : '');
            // Load privacy settings from API (not hardcoded defaults)
            setPrivacySettings({
                isProfilePublic: data.isProfilePublic ?? true,
                showGender: data.showGender ?? true,
                showAge: data.showAge ?? true,
                showBio: data.showBio ?? true,
                showInterests: data.showInterests ?? true,
                showEmail: data.showEmail ?? false,
            });
        } catch (error) {
            console.error('Failed to fetch profile:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateProfile = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');
        setSuccess('');

        if (newPassword && newPassword !== confirmPassword) {
            setError('รหัสผ่านไม่ตรงกัน');
            return;
        }

        try {
            setSaving(true);
            const updateData: any = {
                name: newName,
                interests: newInterests,
                gender: newGender || undefined,
                age: newAge ? parseInt(newAge) : undefined,
                bio: newBio || undefined,
                birthDate: newBirthDate || undefined,
                travelStyle: profile.travelStyle,
                profileImage: newProfileImage !== null ? newProfileImage : undefined
            };
            if (newPassword) updateData.password = newPassword;

            // Update both profile and privacy settings
            await Promise.all([
                userAPI.updateProfile(updateData),
                userAPI.updatePrivacySettings(privacySettings)
            ]);

            await fetchProfile(); // Refresh local profile data
            await refreshUser(); // Refresh global auth context

            setSuccess('บันทึกข้อมูลสำเร็จ');
            setNewPassword('');
            setConfirmPassword('');
            setIsEditing(false);

            setTimeout(() => setSuccess(''), 3000);
        } catch (error) {
            console.error('Failed to update profile:', error);
            setError('ไม่สามารถอัปเดตข้อมูลได้');
        } finally {
            setSaving(false);
        }
    };

    const toggleInterest = (categoryLabel: string) => {
        setNewInterests(prev => {
            if (prev.includes(categoryLabel)) {
                return prev.filter(i => i !== categoryLabel);
            } else {
                return [...prev, categoryLabel];
            }
        });
    };


    if (loading) {
        return (
            <>
                <div className="flex items-center justify-center min-h-screen bg-gray-50/50">
                    <Loader variant="dots" />
                </div>
            </>
        );
    }

    if (!profile) return null;

    return (
        <div className="min-h-screen bg-white pb-20">

            <div className="max-w-6xl mx-auto px-6 pt-8 animate-in fade-in slide-in-from-bottom-4 duration-700">
                {/* Profile Card - Centered */}
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

                        {!isEditing ? (
                            <div className="w-full z-10">
                                <h1 className="text-3xl font-black text-gray-900 mb-1">{profile.name}</h1>
                                <p className="text-gray-500 font-medium mb-4">{profile.email}</p>

                                <div className="flex flex-col items-center gap-2 mb-6">
                                    <div className="flex gap-2">
                                        <span className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-widest ${profile.role === 'admin' ? 'bg-black text-white' : 'bg-gray-100 text-gray-600'}`}>
                                            {profile.role}
                                        </span>
                                        {profile.isVerified ? (
                                            <span className="px-3 py-1 bg-green-100 text-green-700 rounded-full text-[10px] font-bold tracking-widest flex items-center gap-1">
                                                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7" /></svg>
                                                ยืนยันตัวตนแล้ว
                                            </span>
                                        ) : profile.verificationStatus === 'pending' ? (
                                            <span className="px-3 py-1 bg-yellow-100 text-yellow-700 rounded-full text-[10px] font-bold tracking-widest">
                                                รอตรวจสอบข้อมูล
                                            </span>
                                        ) : (
                                            <a href="/verify" className="px-3 py-1 bg-red-100 text-red-600 rounded-full text-[10px] font-bold tracking-widest hover:bg-red-200 transition-colors flex items-center gap-1 cursor-pointer">
                                                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
                                                ยังไม่ยืนยันตัวตน
                                            </a>
                                        )}
                                    </div>
                                    {/* Display Interests - Black Theme */}
                                    {profile.interests && profile.interests.length > 0 && (
                                        <div className="flex flex-wrap justify-center gap-1.5 mt-2">
                                            {profile.interests.map(interest => (
                                                <span key={interest} className="px-3 py-1 bg-black/5 text-black text-[10px] font-bold rounded-full border border-black/10">
                                                    {interest}
                                                </span>
                                            ))}
                                        </div>
                                    )}
                                </div>

                                <div className="grid grid-cols-2 gap-4 w-full max-w-xs mx-auto mb-8 border-t border-gray-100 pt-6">
                                    <div>
                                        <p className="text-3xl font-black text-black">{profile.createdTrips.length}</p>
                                        <p className="text-xs text-gray-400 font-bold uppercase tracking-widest mt-1">ทริปที่สร้าง</p>
                                    </div>
                                    <div>
                                        <p className="text-3xl font-black text-black">{profile.participatedTrips.length}</p>
                                        <p className="text-xs text-gray-400 font-bold uppercase tracking-widest mt-1">ที่เข้าร่วม</p>
                                    </div>
                                </div>

                                {/* Profile Info Cards */}
                                <div className="w-full space-y-3 mb-6 border-t border-gray-100 pt-6">
                                    {(profile.gender || profile.age) && (
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
                                    )}

                                    {profile.bio && (
                                        <div className="bg-gray-50 rounded-lg p-4">
                                            <p className="text-[10px] text-gray-400 font-bold uppercase tracking-widest mb-2">ประวัติส่วนตัว</p>
                                            <p className="text-sm text-gray-700 leading-relaxed">{profile.bio}</p>
                                        </div>
                                    )}
                                </div>

                                <div className="flex flex-wrap justify-center gap-3">
                                    <button
                                        onClick={() => setIsEditing(true)}
                                        className="px-6 py-2 bg-black text-white rounded-full font-bold text-sm hover:bg-gray-800 transition-all active:scale-95 shadow-lg shadow-black/10"
                                    >
                                        แก้ไขโปรไฟล์
                                    </button>
                                    <button
                                        onClick={logout}
                                        className="px-6 py-2 border border-gray-200 text-red-500 rounded-full font-bold text-sm hover:bg-red-50 hover:border-red-100 transition-all active:scale-95"
                                    >
                                        ออกจากระบบ
                                    </button>
                                </div>
                            </div>
                        ) : (
                            <form onSubmit={handleUpdateProfile} className="w-full max-w-sm z-10 text-left space-y-4">
                                <h2 className="text-xl font-bold text-center mb-6">แก้ไขข้อมูลส่วนตัว</h2>

                                {/* Profile Image Upload */}
                                <div className="flex flex-col items-center mb-4">
                                    <div className="w-24 h-24 bg-black rounded-full border-4 border-white shadow-lg overflow-hidden flex items-center justify-center text-3xl font-bold text-white mb-3">
                                        {newProfileImage ? (
                                            <img src={newProfileImage} alt="" className="w-full h-full object-cover" />
                                        ) : profile.profileImage ? (
                                            <img src={profile.profileImage} alt="" className="w-full h-full object-cover" />
                                        ) : (
                                            profile.name.charAt(0).toUpperCase()
                                        )}
                                    </div>
                                    <label className="px-4 py-1.5 bg-gray-100 hover:bg-gray-200 text-gray-700 text-xs font-bold rounded-full cursor-pointer transition-colors">
                                        เปลี่ยนรูปโปรไฟล์
                                        <input
                                            type="file"
                                            accept="image/*"
                                            className="hidden"
                                            onChange={(e) => {
                                                const file = e.target.files?.[0];
                                                if (file) {
                                                    const reader = new FileReader();
                                                    reader.onload = (ev) => {
                                                        setNewProfileImage(ev.target?.result as string);
                                                    };
                                                    reader.readAsDataURL(file);
                                                }
                                            }}
                                        />
                                    </label>
                                    {(newProfileImage || profile.profileImage) && newProfileImage !== '' && (
                                        <button
                                            type="button"
                                            onClick={() => setNewProfileImage('')}
                                            className="px-4 py-1.5 bg-red-50 hover:bg-red-100 text-red-500 text-xs font-bold rounded-full cursor-pointer transition-colors mt-2"
                                        >
                                            ลบรูปโปรไฟล์
                                        </button>
                                    )}
                                </div>

                                {error && <div className="text-red-500 text-xs text-center font-bold bg-red-50 p-2 rounded-lg">{error}</div>}

                                <div>
                                    <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest pl-3 mb-1 block">ชื่อที่แสดง</label>
                                    <input
                                        type="text"
                                        value={newName}
                                        onChange={(e) => setNewName(e.target.value)}
                                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-black focus:bg-white transition-all font-medium"
                                        required
                                    />
                                </div>

                                <div className="grid grid-cols-2 gap-3">
                                    <div>
                                        <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest pl-3 mb-1 block">เพศ</label>
                                        <select
                                            value={newGender}
                                            onChange={(e) => setNewGender(e.target.value)}
                                            className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-black focus:bg-white transition-all font-medium"
                                        >
                                            <option value="">เลือกเพศ</option>
                                            <option value="male">ชาย</option>
                                            <option value="female">หญิง</option>
                                            <option value="other">อื่นๆ</option>
                                        </select>
                                    </div>

                                    <div>
                                        <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest pl-3 mb-1 block">อายุ</label>
                                        <input
                                            type="number"
                                            min="13"
                                            max="120"
                                            value={newAge}
                                            onChange={(e) => setNewAge(e.target.value)}
                                            className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-black focus:bg-white transition-all font-medium"
                                            placeholder="เช่น 25"
                                        />
                                    </div>
                                </div>

                                <div>
                                    <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest pl-3 mb-1 block">วันเกิด</label>
                                    <input
                                        type="date"
                                        value={newBirthDate}
                                        onChange={(e) => setNewBirthDate(e.target.value)}
                                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-black focus:bg-white transition-all font-medium"
                                    />
                                </div>

                                <div>
                                    <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest pl-3 mb-1 block">ประวัติส่วนตัว (Bio)</label>
                                    <textarea
                                        value={newBio}
                                        onChange={(e) => setNewBio(e.target.value)}
                                        placeholder="บอกเล่าเกี่ยวกับตัวคุณ..."
                                        rows={4}
                                        maxLength={500}
                                        className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-black focus:bg-white transition-all font-medium resize-none"
                                    />
                                    <p className="text-[9px] text-gray-400 mt-1 pl-1">{newBio.length} / 500</p>
                                </div>

                                <div>
                                    <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest pl-3 mb-2 block">สิ่งที่สนใจ (เลือกได้หลายข้อ)</label>
                                    <div className="flex flex-wrap gap-2 max-h-48 overflow-y-auto p-1 custom-scrollbar">
                                        {TRIP_CATEGORIES.map(cat => {
                                            const isSelected = newInterests.includes(cat.label);
                                            return (
                                                <button
                                                    key={cat.id}
                                                    type="button"
                                                    onClick={() => toggleInterest(cat.label)}
                                                    className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all border flex items-center gap-2 group ${isSelected
                                                        ? 'bg-black text-white border-black shadow-md'
                                                        : 'bg-white text-gray-500 border-gray-200 hover:border-gray-300'
                                                        }`}
                                                >
                                                    {isSelected && (
                                                        <span className="w-3 h-3 bg-white text-black rounded-full flex items-center justify-center text-[8px] group-hover:bg-red-500 group-hover:text-white transition-colors">
                                                            <span className="group-hover:hidden">✓</span>
                                                            <span className="hidden group-hover:inline">✕</span>
                                                        </span>
                                                    )}
                                                    {cat.label}
                                                </button>
                                            );
                                        })}
                                    </div>
                                    <p className="text-[10px] text-gray-400 mt-1 pl-1">* ระบบจะนำไปช่วยแนะนำทริปที่คุณน่าจะชอบ</p>
                                </div>

                                {/* Travel Style Display (ReadOnly in Edit Mode) */}
                                <div className="pt-4 border-t border-gray-100">
                                    <div className="flex justify-between items-center mb-3">
                                        <h3 className="text-sm font-bold text-black text-center w-full">Lifestyle & Travel Style</h3>
                                    </div>

                                    <button
                                        type="button"
                                        onClick={() => setShowQuiz(true)}
                                        className="w-full py-3 mb-4 bg-black text-white rounded-xl font-bold text-xs flex items-center justify-center gap-2 hover:bg-gray-800 transition-all"
                                    >
                                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                                        </svg>
                                        ทำแบบสำรวจไลฟ์สไตล์ใหม่
                                    </button>

                                    {/* Display Tags */}
                                    {profile.travelStyle && (
                                        <div className="flex flex-wrap gap-2 justify-center">
                                            {Object.entries(profile.travelStyle).map(([key, value]) => {
                                                if (key === 'interests') return null; // Skip interests array here
                                                const label = typeof value === 'string' ? value : '';
                                                if (!label) return null;
                                                return (
                                                    <span key={key} className="px-3 py-1 bg-black text-white text-[10px] font-bold rounded-full uppercase tracking-wider border border-white shadow-sm">
                                                        {label.replace('_', ' ')}
                                                    </span>
                                                );
                                            })}
                                        </div>
                                    )}
                                </div>

                                <div className="pt-2 border-t border-gray-100 mt-2">
                                    <p className="text-xs text-center text-gray-400 mb-4">เปลี่ยนรหัสผ่าน (เว้นว่างไว้หากไม่ต้องการเปลี่ยน)</p>
                                    <div className="space-y-3">
                                        <div>
                                            <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest pl-3 mb-1 block">รหัสผ่านใหม่</label>
                                            <input
                                                type="password"
                                                value={newPassword}
                                                onChange={(e) => setNewPassword(e.target.value)}
                                                className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-black focus:bg-white transition-all font-medium"
                                            />
                                        </div>
                                        <div>
                                            <label className="text-[10px] font-bold text-gray-400 uppercase tracking-widest pl-3 mb-1 block">ยืนยันรหัสผ่านใหม่</label>
                                            <input
                                                type="password"
                                                value={confirmPassword}
                                                onChange={(e) => setConfirmPassword(e.target.value)}
                                                className="w-full px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:border-black focus:bg-white transition-all font-medium"
                                            />
                                        </div>
                                    </div>
                                </div>

                                <div className="pt-6 border-t border-gray-100 mt-4">
                                    <h3 className="text-sm font-bold text-black text-center mb-4">ตั้งค่าความเป็นส่วนตัว</h3>
                                    <div className="space-y-3">
                                        <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                                            <label className="text-xs font-bold text-gray-700">เปิดโปรไฟล์สาธารณะ</label>
                                            <input
                                                type="checkbox"
                                                checked={privacySettings.isProfilePublic}
                                                onChange={(e) =>
                                                    setPrivacySettings({
                                                        ...privacySettings,
                                                        isProfilePublic: e.target.checked
                                                    })
                                                }
                                                className="w-5 h-5 cursor-pointer accent-black"
                                            />
                                        </div>

                                        <div className="grid grid-cols-1 gap-2">
                                            {[
                                                { key: 'showGender', label: 'แสดงเพศ' },
                                                { key: 'showAge', label: 'แสดงอายุ' },
                                                { key: 'showBio', label: 'แสดงประวัติส่วนตัว' },
                                                { key: 'showInterests', label: 'แสดงความสนใจ' },
                                                { key: 'showEmail', label: 'แสดงอีเมล' },
                                            ].map(({ key, label }) => (
                                                <div key={key} className="flex items-center justify-between px-4 py-2 hover:bg-gray-50 rounded-lg transition-colors border border-transparent hover:border-gray-100">
                                                    <label className="text-[13px] text-gray-600 font-medium">{label}</label>
                                                    <input
                                                        type="checkbox"
                                                        checked={privacySettings[key as keyof typeof privacySettings] as boolean}
                                                        onChange={(e) =>
                                                            setPrivacySettings({
                                                                ...privacySettings,
                                                                [key]: e.target.checked
                                                            })
                                                        }
                                                        className="w-4 h-4 cursor-pointer accent-black"
                                                    />
                                                </div>
                                            ))}
                                        </div>
                                    </div>
                                </div>

                                <div className="flex gap-3 justify-center pt-4">
                                    <button
                                        type="button"
                                        onClick={() => {
                                            setIsEditing(false);
                                            setError('');
                                            setNewPassword('');
                                            setConfirmPassword('');
                                            setNewName(profile.name);
                                            setNewInterests(profile.interests || []);
                                            setNewGender(profile.gender || '');
                                            setNewAge(profile.age ? String(profile.age) : '');
                                            setNewBio(profile.bio || '');
                                            setNewBirthDate(profile.birthDate ? profile.birthDate.split('T')[0] : '');
                                        }}
                                        className="flex-1 py-3 border border-gray-200 text-gray-500 rounded-xl font-bold text-sm hover:bg-gray-50 transition-all"
                                    >
                                        ยกเลิก
                                    </button>
                                    <button
                                        type="submit"
                                        disabled={saving}
                                        className="flex-1 py-3 bg-black text-white rounded-xl font-bold text-sm hover:bg-gray-800 transition-all shadow-lg shadow-black/10 disabled:opacity-50"
                                    >
                                        {saving ? 'กำลังบันทึก...' : 'บันทึก'}
                                    </button>
                                </div>
                            </form>
                        )}

                        {success && (
                            <div className="absolute top-4 right-4 bg-black text-white px-4 py-2 rounded-full text-xs font-bold shadow-lg animate-in slide-in-from-top-2">
                                {success}
                            </div>
                        )}
                    </div>
                </div>

                {/* Tabs & Content */}
                <div className="space-y-8 max-w-4xl mx-auto">
                    <div className="flex justify-center">
                        <div className="bg-white p-1.5 rounded-full shadow-sm border border-gray-200 inline-flex">
                            <button
                                onClick={() => setActiveTab('my-trips')}
                                className={`px-8 py-2.5 rounded-full text-xs font-bold transition-all ${activeTab === 'my-trips' ? 'bg-black text-white shadow-md' : 'text-gray-400 hover:text-black'}`}
                            >
                                ทริปของฉัน ({profile.createdTrips.length})
                            </button>
                            <button
                                onClick={() => setActiveTab('joined-trips')}
                                className={`px-8 py-2.5 rounded-full text-xs font-bold transition-all ${activeTab === 'joined-trips' ? 'bg-black text-white shadow-md' : 'text-gray-400 hover:text-black'}`}
                            >
                                ที่เข้าร่วม ({profile.participatedTrips.length})
                            </button>
                        </div>
                    </div>

                    <div className="animate-in slide-in-from-bottom-4 duration-700 delay-100 flex flex-col gap-6">
                        {activeTab === 'my-trips' ? (
                            <>
                                {profile.createdTrips.length > 0 ? (
                                    profile.createdTrips.map(trip => (
                                        <TripCard key={trip.id} trip={trip} />
                                    ))
                                ) : (
                                    <div className="col-span-full py-20 text-center bg-white rounded-[2rem] border border-dashed border-gray-200">
                                        <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                            <svg className="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                                            </svg>
                                        </div>
                                        <p className="text-gray-400 font-medium">คุณยังไม่ได้สร้างทริป</p>
                                        <a href="/" className="text-sm font-bold text-black mt-2 inline-block hover:underline">ไปสร้างทริปกันเถอะ!</a>
                                    </div>
                                )}
                            </>
                        ) : (
                            <>
                                {profile.participatedTrips.length > 0 ? (
                                    profile.participatedTrips.map(({ trip }) => (
                                        <TripCard key={trip.id} trip={trip} />
                                    ))
                                ) : (
                                    <div className="col-span-full py-20 text-center bg-white rounded-[2rem] border border-dashed border-gray-200">
                                        <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-4">
                                            <svg className="w-8 h-8 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                                            </svg>
                                        </div>
                                        <p className="text-gray-400 font-medium">คุณยังไม่ได้เข้าร่วมทริปใดๆ</p>
                                        <a href="/explore" className="text-sm font-bold text-black mt-2 inline-block hover:underline">ค้นหาทริปน่าสนใจ</a>
                                    </div>
                                )}
                            </>
                        )}
                    </div>
                </div>
            </div>


            <TravelStyleQuizModal
                isOpen={showQuiz}
                onClose={() => setShowQuiz(false)}
                initialData={profile?.travelStyle}
                onSave={async (newStyle) => {
                    await fetchProfile(); // Refresh profile to show new tags
                    setShowQuiz(false);
                }}
            />
        </div >
    );
};

export default Profile;
