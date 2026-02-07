import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const MobileHeader = () => {
    const { user } = useAuth();

    return (
        <div
            className="md:hidden bg-white sticky top-0 z-40 shadow-sm px-6 pb-2"
            style={{
                paddingTop: 'max(env(safe-area-inset-top), 25px)'
            }}
        >
            <div className="flex justify-between items-center mb-4">
                <div>
                    <p className="text-gray-400 text-xs font-bold uppercase tracking-widest mb-1">Welcome back</p>
                    <h1 className="text-3xl font-black tracking-tighter">GoWithUs.</h1>
                </div>
                <div className="flex items-center gap-3">
                    <Link to="/chat" className="w-10 h-10 bg-white border border-gray-100 rounded-full flex items-center justify-center relative active:scale-95 transition-transform">
                        <svg className="w-5 h-5 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>
                        <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full border border-white"></span>
                    </Link>
                    <Link to="/profile" className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center border border-gray-200 overflow-hidden active:scale-95 transition-transform">
                        {user?.imageUrl ? (
                            <img src={user.imageUrl} className="w-full h-full object-cover" alt="Profile" />
                        ) : (
                            <span className="text-lg font-bold">{user?.name?.charAt(0).toUpperCase() || 'G'}</span>
                        )}
                    </Link>
                </div>
            </div>

            {/* Search Bar Mobile */}
            <Link to="/search" className="block relative">
                <div className="w-full bg-gray-100/80 border-none rounded-2xl py-3.5 pl-11 pr-4 text-sm font-medium text-gray-500 flex items-center">
                    ค้นหาทริป, เพื่อน, สถานที่...
                </div>
                <svg className="w-5 h-5 text-gray-400 absolute left-4 top-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
            </Link>
        </div>
    );
};

export default MobileHeader;
