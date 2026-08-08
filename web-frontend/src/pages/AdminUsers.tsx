import React, { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { userAPI } from '../services/api';
import AdminShell from '../components/AdminShell';

type AdminUser = { id: string; name: string; username?: string; email: string; role: string; profileImage?: string; isBanned: boolean; isVerified: boolean; verificationStatus: string; createdAt: string; _count: { trips: number; joinedTrips: number; reportsReceived: number } };

const AdminUsers: React.FC = () => {
    const { user, isLoading } = useAuth(); const navigate = useNavigate(); const [params] = useSearchParams();
    const [users, setUsers] = useState<AdminUser[]>([]); const [search, setSearch] = useState(''); const [status, setStatus] = useState(params.get('status') || 'all'); const [busy, setBusy] = useState(false); const [error, setError] = useState('');
    useEffect(() => { if (!isLoading && user?.role !== 'admin') navigate('/'); }, [user, isLoading, navigate]);
    const load = async () => { setBusy(true); setError(''); try { const result = await userAPI.getAdminUsers({ search, status }); setUsers(result.users || []); } catch (e: any) { setError(e.message); } finally { setBusy(false); } };
    useEffect(() => { if (user?.role === 'admin') { const timer = setTimeout(load, 250); return () => clearTimeout(timer); } }, [user, search, status]);
    const toggleBan = async (item: AdminUser) => { if (!confirm(`${item.isBanned ? 'ปลดระงับ' : 'ระงับ'}บัญชี ${item.name} ใช่หรือไม่?`)) return; await userAPI.banUser(item.id, !item.isBanned); load(); };
    if (isLoading || user?.role !== 'admin') return null;
    return <AdminShell title="จัดการผู้ใช้" subtitle="ค้นหา ตรวจสอบสถานะ และระงับบัญชีผู้ใช้">
        <div className="mb-4 flex flex-col gap-3 rounded-2xl border border-[#E1DED7] bg-white p-4 sm:flex-row">
            <input value={search} onChange={e => setSearch(e.target.value)} placeholder="ค้นหาชื่อ อีเมล หรือชื่อผู้ใช้" className="min-w-0 flex-1 rounded-xl border border-blue-100 px-4 py-3 outline-none focus:border-[#2563EB]" />
            <select value={status} onChange={e => setStatus(e.target.value)} className="rounded-xl border border-[#DAD8D1] bg-white px-4 py-3"><option value="all">ทุกสถานะ</option><option value="active">ใช้งานปกติ</option><option value="verified">ยืนยันตัวตนแล้ว</option><option value="banned">ถูกระงับ</option></select>
        </div>
        {error && <div className="mb-4 rounded-xl bg-red-50 p-4 text-red-700">{error}</div>}
        <div className="overflow-hidden rounded-2xl border border-[#E1DED7] bg-white">
            <div className="overflow-x-auto"><table className="w-full min-w-[850px] text-left text-sm"><thead className="bg-blue-50 text-xs uppercase text-slate-600"><tr><th className="p-4">ผู้ใช้</th><th>สถานะ</th><th>กิจกรรม</th><th>รายงาน</th><th>วันที่สมัคร</th><th className="pr-4 text-right">จัดการ</th></tr></thead><tbody>
                {users.map(item => <tr key={item.id} className="border-t border-blue-50 hover:bg-[#F4F8FC]"><td className="p-4"><div className="flex items-center gap-3"><span className="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-full bg-blue-100 font-bold">{item.profileImage ? <img src={item.profileImage} className="h-full w-full object-cover" /> : item.name.charAt(0)}</span><span><b className="block">{item.name} {item.role === 'admin' && <small className="text-[#1E3A8A]">ADMIN</small>}</b><small className="text-slate-500">{item.email}</small></span></div></td>
                    <td><span className={`rounded-full px-2.5 py-1 text-xs font-bold ${item.isBanned ? 'bg-red-50 text-red-700' : item.isVerified ? 'bg-emerald-50 text-emerald-700' : 'bg-gray-100 text-gray-600'}`}>{item.isBanned ? 'ถูกระงับ' : item.isVerified ? 'ยืนยันแล้ว' : 'ใช้งานปกติ'}</span></td>
                    <td>{item._count.trips} ทริป · เข้าร่วม {item._count.joinedTrips}</td><td>{item._count.reportsReceived}</td><td>{new Date(item.createdAt).toLocaleDateString('th-TH')}</td><td className="pr-4 text-right">{item.role !== 'admin' && <button onClick={() => toggleBan(item)} className={`rounded-lg px-3 py-2 text-xs font-bold ${item.isBanned ? 'bg-blue-50 text-[#1E3A8A]' : 'bg-red-50 text-red-700'}`}>{item.isBanned ? 'ปลดระงับ' : 'ระงับบัญชี'}</button>}</td></tr>)}
            </tbody></table></div>
            {!busy && users.length === 0 && <p className="p-12 text-center text-slate-500">ไม่พบผู้ใช้</p>}{busy && <p className="p-12 text-center text-slate-500">กำลังโหลด...</p>}
        </div>
    </AdminShell>;
};
export default AdminUsers;
