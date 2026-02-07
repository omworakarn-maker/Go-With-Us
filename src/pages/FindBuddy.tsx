import React from "react";
import { Link } from "react-router-dom";

export const FindBuddy: React.FC = () => {
    return (
        <div className="min-h-screen bg-white flex flex-col items-center justify-center px-6 text-center">
            <div className="max-w-md w-full animate-in fade-in zoom-in duration-500">
                <div className="w-24 h-24 bg-black rounded-full flex items-center justify-center mx-auto mb-8 shadow-2xl shadow-black/20 text-white">
                    <svg className="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-.1283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                    </svg>
                </div>

                <h1 className="text-4xl font-black text-black mb-4 tracking-tight">
                    Find Your Buddy
                    <br />
                    <span className="text-gray-200">Coming Soon</span>
                </h1>

                <p className="text-gray-500 font-medium text-lg mb-10 leading-relaxed">
                    เรากำลังพัฒนาระบบจับคู่เพื่อนเที่ยวด้วย AI
                    <br />
                    ที่จะช่วยให้คุณเจอเพื่อนที่ "เคมีตรงกัน" ที่สุด
                </p>

                <div className="p-6 bg-gray-50 rounded-3xl border border-gray-100 mb-8">
                    <h3 className="font-bold text-black mb-2">✨ ฟีเจอร์ที่จะมาเร็วๆ นี้</h3>
                    <ul className="text-sm text-gray-500 space-y-2 text-left px-4">
                        <li className="flex items-center gap-2">
                            <span className="w-1.5 h-1.5 bg-black rounded-full"></span>
                            ระบบจับคู่ด้วย AI จากไลฟ์สไตล์การเที่ยว
                        </li>
                        <li className="flex items-center gap-2">
                            <span className="w-1.5 h-1.5 bg-black rounded-full"></span>
                            โปรไฟล์ผู้ใช้ที่ยืนยันตัวตนแล้ว
                        </li>
                        <li className="flex items-center gap-2">
                            <span className="w-1.5 h-1.5 bg-black rounded-full"></span>
                            ระบบแชทและกลุ่มแบบอัจฉริยะ
                        </li>
                    </ul>
                </div>

                <Link
                    to="/"
                    className="inline-flex items-center justify-center px-8 py-3 bg-black text-white font-bold rounded-full hover:bg-gray-800 transition-all active:scale-95 shadow-lg shadow-black/20"
                >
                    กลับสู่หน้าหลัก
                </Link>
            </div>
        </div>
    );
};
