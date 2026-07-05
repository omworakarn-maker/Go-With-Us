import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const MobileHeader = () => {
    const { user } = useAuth();

    return (
        <div
            className="md:hidden bg-white/80 backdrop-blur-2xl sticky top-0 z-40 border-b border-gray-100/50 px-4 pb-3"
            style={{
                paddingTop: 'max(env(safe-area-inset-top), 16px)'
            }}
        >
            {/* Top row: logo left, icons right */}
            <div className="flex justify-between items-center mb-3">
                <span className="text-xl font-black tracking-tighter text-black">
                    GoWithUs<span className="text-gray-300">.</span>
                </span>

                <div className="flex items-center gap-2.5">
                    <Link
                        to="/chat"
                        className="w-9 h-9 bg-gray-100 rounded-full flex items-center justify-center relative active:scale-95 transition-transform"
                    >
                        <svg className="w-4.5 h-4.5 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                        </svg>
                        <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border border-white" />
                    </Link>

                    <Link
                        to="/profile"
                        className="w-9 h-9 bg-gray-100 rounded-full flex items-center justify-center border border-gray-200 overflow-hidden active:scale-95 transition-transform"
                    >
                        {user?.imageUrl ? (
                            <img src={user.imageUrl} className="w-full h-full object-cover" alt="Profile" />
                        ) : (
                            <span className="text-sm font-black text-gray-600">
                                {user?.name?.charAt(0).toUpperCase() || 'G'}
                            </span>
                        )}
                    </Link>
                </div>
            </div>

            {/* Search Bar */}
            <Link to="/search" className="block relative">
                <div className="w-full bg-gray-100/80 rounded-2xl py-3 pl-10 pr-4 text-sm font-medium text-gray-400 flex items-center">
                    ค้นหาทริป, เพื่อน, สถานที่...
                </div>
                <svg className="w-4.5 h-4.5 text-gray-400 absolute left-3.5 top-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
            </Link>
        </div>
    );
};

export default MobileHeader;
