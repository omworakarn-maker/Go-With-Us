import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';

const links = [
    ['/admin', 'ภาพรวม', '▦'],
    ['/admin/users', 'จัดการผู้ใช้', '♙'],
    ['/admin/trips', 'จัดการทริป', '⌖'],
    ['/admin/reports', 'รายงานผู้ใช้', '!'],
    ['/admin/verify', 'ยืนยันตัวตน', '✓'],
    ['/admin/alerts', 'แจ้งเตือน', '◉'],
];

const AdminShell: React.FC<React.PropsWithChildren<{ title: string; subtitle?: string }>> = ({ title, subtitle, children }) => {
    const navigate = useNavigate();
    return (
        <div className="min-h-screen bg-[#F7F7F7] text-black">
            <div className="mx-auto flex min-h-screen max-w-[1500px]">
                <aside className="hidden w-64 shrink-0 border-r border-gray-200 bg-white p-5 md:block">
                    <button onClick={() => navigate('/')} className="mb-9 flex items-center gap-3 text-left">
                        <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-black text-lg font-bold text-white">G</span>
                        <span><b className="block">GoWithUs</b><small className="text-slate-500">Admin Console</small></span>
                    </button>
                    <nav className="space-y-1.5">
                        {links.map(([to, label, icon]) => (
                            <NavLink key={to} to={to} end={to === '/admin'} className={({ isActive }) => `flex items-center gap-3 rounded-xl px-4 py-3 text-sm font-semibold transition ${isActive ? 'bg-black text-white shadow-sm' : 'text-gray-600 hover:bg-gray-100'}`}>
                                <span className="w-5 text-center">{icon}</span>{label}
                            </NavLink>
                        ))}
                    </nav>
                </aside>
                <main className="min-w-0 flex-1 p-4 md:p-8">
                    <header className="mb-6 flex items-center justify-between">
                        <div><h1 className="text-2xl font-bold">{title}</h1>{subtitle && <p className="mt-1 text-sm text-slate-500">{subtitle}</p>}</div>
                        <button onClick={() => navigate('/')} className="rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-semibold hover:bg-gray-100">กลับหน้าแอป</button>
                    </header>
                    <div className="mb-5 flex gap-2 overflow-x-auto pb-2 md:hidden">
                        {links.map(([to, label]) => <NavLink key={to} to={to} end={to === '/admin'} className={({ isActive }) => `whitespace-nowrap rounded-full px-4 py-2 text-xs font-bold ${isActive ? 'bg-black text-white' : 'bg-white text-gray-600'}`}>{label}</NavLink>)}
                    </div>
                    {children}
                </main>
            </div>
        </div>
    );
};

export default AdminShell;
