import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { userAPI } from '../services/api';
import { resizeImage } from '../utils/imageResizer';

const VerificationForm: React.FC = () => {
    const navigate = useNavigate();
    const { user, refreshUser, isLoading } = useAuth();
    const [idCardImage, setIdCardImage] = useState<string | null>(null);
    const [faceScanImage, setFaceScanImage] = useState<string | null>(null);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState('');

    const handleImageUpload = async (e: React.ChangeEvent<HTMLInputElement>, setter: React.Dispatch<React.SetStateAction<string | null>>) => {
        const file = e.target.files?.[0];
        if (file) {
            try {
                // Compress image before setting it to state (prevents Payload Too Large)
                const uri = await resizeImage(file);
                setter(uri);
            } catch (err) {
                console.error("Error resizing image:", err);
                setError("เกิดข้อผิดพลาดในการประมวลผลรูปภาพ กรุณาลองใหม่อีกครั้ง");
            }
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError('');

        if (!idCardImage || !faceScanImage) {
            setError('กรุณาอัปโหลดทั้งรูปบัตรประชาชนและรูปถ่ายใบหน้า');
            return;
        }

        try {
            setIsSubmitting(true);
            await userAPI.requestVerification({
                idCardImage,
                faceScanImage
            });
            await refreshUser();
            alert('ส่งคำขอยืนยันตัวตนเรียบร้อยแล้ว แอดมินจะตรวจสอบในภายหลัง');
            navigate('/profile');
        } catch (err: any) {
            console.error('Verify error:', err);
            // Show more specific error message based on the thrown error
            if (err.message && err.message.toLowerCase().includes('large')) {
                setError('รูปภาพของคุณมีขนาดใหญ่เกินไป กรุณาใช้รูปภาพที่มีขนาดเล็กลง');
            } else {
                setError(err.message || 'ไม่สามารถส่งคำขอได้ กรุณาลองใหม่อีกครั้ง');
            }
        } finally {
            setIsSubmitting(false);
        }
    };

    if (isLoading) {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-black"></div>
            </div>
        );
    }

    if (user?.verificationStatus === 'verified') {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
                <div className="max-w-md w-full bg-white rounded-3xl p-10 shadow-sm border border-gray-100 text-center relative">
                    <button
                        onClick={() => navigate(-1)}
                        className="absolute top-6 right-6 w-8 h-8 rounded-full hover:bg-gray-100 flex items-center justify-center transition-colors"
                    >
                        ✕
                    </button>
                    <div className="w-20 h-20 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-6">
                        <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M5 13l4 4L19 7" />
                        </svg>
                    </div>
                    <h1 className="text-2xl font-bold text-gray-900 mb-2">ยืนยันเรียบร้อยแล้ว</h1>
                    <p className="text-gray-500 mb-8">บัญชีของคุณได้รับการยืนยันตัวตนแล้ว</p>
                    <button
                        onClick={() => navigate('/profile')}
                        className="w-full py-4 bg-black text-white rounded-xl font-bold hover:bg-gray-800 transition-all active:scale-95 text-base"
                    >
                        กลับไปยังโปรไฟล์
                    </button>
                </div>
            </div>
        );
    }

    if (user?.verificationStatus === 'pending') {
        return (
            <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
                <div className="max-w-md w-full bg-white rounded-3xl p-10 shadow-sm border border-gray-100 text-center relative">
                    <button
                        onClick={() => navigate(-1)}
                        className="absolute top-6 right-6 w-8 h-8 rounded-full hover:bg-gray-100 flex items-center justify-center transition-colors"
                    >
                        ✕
                    </button>
                    <div className="w-20 h-20 bg-blue-100 text-blue-600 rounded-full flex items-center justify-center mx-auto mb-6">
                        <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                    <h1 className="text-2xl font-bold text-gray-900 mb-2">กำลังรอการตรวจสอบ</h1>
                    <p className="text-gray-500 mb-8">เราได้รับข้อมูลของคุณแล้ว แอดมินจะดำเนินการตรวจสอบข้อมูลและแจ้งผลให้ทราบโดยเร็วที่สุด</p>
                    <button
                        onClick={() => navigate('/profile')}
                        className="w-full py-4 bg-black text-white rounded-xl font-bold hover:bg-gray-800 transition-all active:scale-95 text-base"
                    >
                        กลับไปยังโปรไฟล์
                    </button>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4 py-12">
            <div className="max-w-xl w-full bg-white rounded-3xl p-8 shadow-sm border border-gray-100 relative">
                <button
                    onClick={() => navigate(-1)}
                    className="absolute top-6 right-6 w-8 h-8 rounded-full hover:bg-gray-100 flex items-center justify-center transition-colors"
                >
                    ✕
                </button>

                <div className="mb-8 text-center pt-4">
                    <div className="w-16 h-16 bg-black text-white rounded-full flex items-center justify-center mx-auto mb-4">
                        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>
                    </div>
                    <h1 className="text-2xl font-bold text-gray-900 mb-2">ยืนยันตัวตนเพื่อความปลอดภัย</h1>
                    <p className="text-sm text-gray-500">กรุณาอัปโหลดรูปภาพเพื่อยืนยันว่าคุณมีตัวตนอยู่จริง<br />ข้อมูลนี้จะถูกตรวจสอบโดยแอดมินและจะลบทันทีหลังตรวจสอบเสร็จสิ้น</p>
                </div>

                {error && (
                    <div className="mb-6 p-4 bg-red-50 text-red-600 text-sm font-bold rounded-xl text-center border border-red-100">
                        {error}
                    </div>
                )}

                <form onSubmit={handleSubmit} className="space-y-6">
                    {/* ID Card */}
                    <div className="space-y-3">
                        <label className="text-xs font-bold text-gray-700 uppercase tracking-widest block">1. รูปถ่ายบัตรประชาชน หรือ Passport</label>
                        <div className="w-full aspect-[16/9] bg-gray-50 border-2 border-dashed border-gray-300 rounded-2xl flex flex-col items-center justify-center relative overflow-hidden group hover:border-black transition-colors">
                            {idCardImage ? (
                                <>
                                    <img src={idCardImage} alt="ID Card" className="w-full h-full object-cover" />
                                    <div className="absolute inset-0 bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                        <p className="text-white font-bold text-sm">คลิกเพื่อเปลี่ยนรูป</p>
                                    </div>
                                </>
                            ) : (
                                <div className="text-center p-6 cursor-pointer">
                                    <svg className="w-8 h-8 text-gray-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                                    <p className="font-bold text-sm text-gray-600">อัปโหลดรูปบัตร</p>
                                </div>
                            )}
                            <input
                                type="file"
                                accept="image/*"
                                onChange={(e) => handleImageUpload(e, setIdCardImage)}
                                className="absolute inset-0 opacity-0 cursor-pointer"
                            />
                        </div>
                    </div>

                    {/* Face Scan */}
                    <div className="space-y-3">
                        <label className="text-xs font-bold text-gray-700 uppercase tracking-widest block">2. รูปถ่ายใบหน้า (เซลฟี่)</label>
                        <div className="w-full aspect-square md:aspect-[4/3] bg-gray-50 border-2 border-dashed border-gray-300 rounded-2xl flex flex-col items-center justify-center relative overflow-hidden group hover:border-black transition-colors">
                            {faceScanImage ? (
                                <>
                                    <img src={faceScanImage} alt="Face Scan" className="w-full h-full object-cover" />
                                    <div className="absolute inset-0 bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                        <p className="text-white font-bold text-sm">คลิกเพื่อเปลี่ยนรูป</p>
                                    </div>
                                </>
                            ) : (
                                <div className="text-center p-6 cursor-pointer">
                                    <svg className="w-8 h-8 text-gray-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>
                                    <p className="font-bold text-sm text-gray-600">ถ่ายเซลฟี่ใบหน้า</p>
                                </div>
                            )}
                            <input
                                type="file"
                                accept="image/*"
                                onChange={(e) => handleImageUpload(e, setFaceScanImage)}
                                className="absolute inset-0 opacity-0 cursor-pointer"
                            />
                        </div>
                    </div>

                    <button
                        type="submit"
                        disabled={isSubmitting}
                        className="w-full py-4 bg-black text-white rounded-xl font-bold hover:bg-gray-800 transition-all active:scale-95 disabled:opacity-50 mt-4 text-base"
                    >
                        {isSubmitting ? 'กำลังส่งคำขอ...' : 'ส่งคำขอยืนยันตัวตน'}
                    </button>

                    <p className="text-[10px] text-center text-gray-400 mt-4 px-4">
                        *รูปภาพของคุณจะถูกจัดเก็บไว้ชั่วคราวและลบออกเมื่อการตรวจสอบเสร็จสิ้น เราใช้สำหรับการยืนยันตัวตนกับทางระบบเพื่อป้องกันสแปมและบัญชีปลอมเท่านั้น
                    </p>
                </form>
            </div>
        </div>
    );
};

export default VerificationForm;
