import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { userAPI } from '../services/api';
import AdminShell from '../components/AdminShell';

type Overview = { totalUsers: number; bannedUsers: number; verifiedUsers: number; pendingVerifications: number; pendingReports: number; totalTrips: number };

const AdminDashboard: React.FC = () => {
    const { user, isLoading } = useAuth();
    const navigate = useNavigate();
    const [data, setData] = useState<Overview | null>(null);
    const [error, setError] = useState('');
    useEffect(() => { if (!isLoading && user?.role !== 'admin') navigate('/'); }, [user, isLoading, navigate]);
    useEffect(() => { if (user?.role === 'admin') userAPI.getAdminOverview().then(setData).catch((e) => setError(e.message)); }, [user]);
    if (isLoading || user?.role !== 'admin') return null;

    const cards = [
        ['ผู้ใช้ทั้งหมด', data?.totalUsers, '/admin/users', '#111111'],
        ['ทริปทั้งหมด', data?.totalTrips, '/admin/trips', '#333333'],
        ['รอยืนยันตัวตน', data?.pendingVerifications, '/admin/verify', '#555555'],
        ['รายงานที่รอตรวจสอบ', data?.pendingReports, '/admin/reports', '#777777'],
        ['ยืนยันแล้ว', data?.verifiedUsers, '/admin/users?status=verified', '#999999'],
        ['บัญชีถูกระงับ', data?.bannedUsers, '/admin/users?status=banned', '#BBBBBB'],
    ];
    return <AdminShell title="ภาพรวมระบบ" subtitle="ข้อมูลสำคัญและรายการที่ต้องดำเนินการ">
        {error && <div className="mb-5 rounded-xl bg-red-50 p-4 text-sm text-red-700">โหลดข้อมูลไม่สำเร็จ: {error}</div>}
        <div className="grid grid-cols-2 gap-4 xl:grid-cols-3">
            {cards.map(([label, value, to, color]) => <Link to={String(to)} key={String(label)} className="rounded-2xl border border-[#E1DED7] bg-white p-5 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
                <span className="mb-5 block h-2 w-10 rounded-full" style={{ background: String(color) }} />
                <p className="text-sm text-slate-500">{label}</p><p className="mt-2 text-3xl font-bold">{data ? value : '–'}</p>
            </Link>)}
        </div>
        <section className="mt-6 rounded-2xl border border-[#E1DED7] bg-white p-6">
            <h2 className="font-bold">งานที่ควรตรวจสอบ</h2>
            <div className="mt-4 grid gap-3 lg:grid-cols-3">
                <Link to="/admin/verify" className="rounded-xl bg-gray-100 p-4 text-sm"><b className="block text-black">คำขอยืนยันตัวตน</b><span>{data?.pendingVerifications ?? '–'} รายการรอดำเนินการ</span></Link>
                <Link to="/admin/reports" className="rounded-xl bg-gray-100 p-4 text-sm"><b className="block text-black">รายงานผู้ใช้</b><span>{data?.pendingReports ?? '–'} รายการรอตรวจสอบ</span></Link>
                <Link to="/admin/alerts" className="rounded-xl bg-gray-100 p-4 text-sm"><b className="block text-black">ประกาศระบบ</b><span>สร้างข้อความแจ้งเตือนผู้ใช้</span></Link>
            </div>
        </section>
    </AdminShell>;
};
export default AdminDashboard;
