import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useModal } from '../contexts/ModalContext';
import { useAuth } from '../contexts/AuthContext';

const MobileBottomNav = () => {
    const navigate = useNavigate();
    const location = useLocation();
    const { openCreateModal } = useModal();
    const { isAuthenticated } = useAuth();

    const isActive = (path: string) => location.pathname === path;

    // เมนูพร้อมไอคอนสวยๆ
    const menus = [
        {
            label: 'Home',
            path: '/',
            icon: (active: boolean) => (
                <svg className={`w-6 h-6 transition-all ${active ? 'fill-black' : 'stroke-gray-400'}`} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                    <polyline points="9 22 9 12 15 12 15 22"></polyline>
                </svg>
            )
        },
        {
            label: 'Buddy',
            path: '/find-buddy',
            icon: (active: boolean) => (
                <svg className={`w-6 h-6 transition-all ${active ? 'fill-black' : 'stroke-gray-400'}`} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                    <circle cx="9" cy="7" r="4"></circle>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
                </svg>
            )
        },
        {
            isCreate: true, // 
            icon: () => (
                <div className="w-12 h-12 bg-black rounded-full flex items-center justify-center shadow-lg shadow-black/20 hover:scale-105 transition-transform">
                    <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M12 4v16m8-8H4" />
                    </svg>
                </div>
            )
        },
        {
            label: 'Chat',
            path: '/chat',
            icon: (active: boolean) => (
                <svg className={`w-6 h-6 transition-all ${active ? 'fill-black' : 'stroke-gray-400'}`} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
                </svg>
            )
        },
        {
            label: 'Profile',
            path: '/profile',
            icon: (active: boolean) => (
                <svg className={`w-6 h-6 transition-all ${active ? 'fill-black' : 'stroke-gray-400'}`} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                </svg>
            )
        }
    ];

    return (
        <div
            className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100 pt-2 px-6 z-[1000] md:hidden shadow-[0_-5px_20px_rgba(0,0,0,0.03)]"
            style={{
                paddingBottom: 'env(safe-area-inset-bottom)'
            }}
        >
            <div className="grid grid-cols-5 items-end h-full pb-2">
                {menus.map((menu, index) => {
                    if (menu.isCreate) {
                        return (
                            <div key={index} className="relative flex justify-center h-full">
                                <button
                                    onClick={() => {
                                        if (!isAuthenticated) navigate('/login');
                                        else openCreateModal();
                                    }}
                                    className="absolute -top-6 w-14 h-14 bg-black rounded-full flex items-center justify-center shadow-lg shadow-black/30 hover:scale-105 transition-transform active:scale-95 border-4 border-white"
                                >
                                    <svg className="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="3" d="M12 4v16m8-8H4" />
                                    </svg>
                                </button>
                            </div>
                        );
                    }

                    return (
                        <button
                            key={index}
                            onClick={() => navigate(menu.path || '/')}
                            className="flex flex-col items-center gap-1 justify-end pb-1"
                        >
                            {menu.icon(menu.path ? isActive(menu.path) : false)}
                            <span className={`text-[10px] font-bold ${isActive(menu.path || '') ? 'text-black' : 'text-gray-400'}`}>
                                {menu.label}
                            </span>
                        </button>
                    );
                })}
            </div>
        </div>
    );
};

export default MobileBottomNav;
