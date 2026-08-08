import React, { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { tripsAPI } from '../services/api';
import AdminShell from '../components/AdminShell';

const AdminTrips: React.FC = () => {
    const { user, isLoading } = useAuth(); const navigate = useNavigate(); const [trips, setTrips] = useState<any[]>([]); const [search, setSearch] = useState(''); const [busy, setBusy] = useState(false); const [error, setError] = useState('');
    useEffect(() => { if (!isLoading && user?.role !== 'admin') navigate('/'); }, [user, isLoading, navigate]);
    const load = async () => { setBusy(true); try { const result = await tripsAPI.getAll(); setTrips(result.trips || []); } catch (e: any) { setError(e.message); } finally { setBusy(false); } };
    useEffect(() => { if (user?.role === 'admin') load(); }, [user]);
    const shown = useMemo(() => trips.filter(t => `${t.title} ${t.destination} ${t.creator?.name} ${t.category}`.toLowerCase().includes(search.toLowerCase())), [trips, search]);
    const remove = async (trip: any) => { if (!confirm(`ลบทริป “${trip.title}” อย่างถาวรใช่หรือไม่?`)) return; try { await tripsAPI.delete(trip.id); setTrips(v => v.filter(t => t.id !== trip.id)); } catch (e: any) { alert(e.message); } };
    if (isLoading || user?.role !== 'admin') return null;
    return <AdminShell title="จัดการทริป" subtitle="ตรวจสอบรายละเอียดและจัดการทริปในระบบ">
        <div className="mb-4 rounded-2xl border border-blue-100 bg-white p-4"><input value={search} onChange={e => setSearch(e.target.value)} placeholder="ค้นหาชื่อทริป สถานที่ ผู้สร้าง หรือหมวดหมู่" className="w-full rounded-xl border border-blue-100 px-4 py-3 outline-none focus:border-[#2563EB]" /></div>
        {error && <div className="mb-4 rounded-xl bg-red-50 p-4 text-red-700">{error}</div>}
        <div className="grid gap-4 lg:grid-cols-2">
            {shown.map(t => <article key={t.id} className="flex gap-4 rounded-2xl border border-[#E1DED7] bg-white p-4 shadow-sm">
                <div className="h-28 w-28 shrink-0 overflow-hidden rounded-xl bg-blue-100">{t.imageUrl ? <img src={t.imageUrl} className="h-full w-full object-cover" /> : <div className="flex h-full items-center justify-center text-3xl">⌖</div>}</div>
                <div className="min-w-0 flex-1"><div className="flex items-start justify-between gap-2"><div><h2 className="truncate font-bold">{t.title}</h2><p className="text-sm text-slate-500">{t.destination}</p></div><span className="rounded-full bg-blue-50 px-2 py-1 text-[10px] font-bold text-[#1E3A8A]">{t.category || 'ทั่วไป'}</span></div>
                    <p className="mt-2 text-xs text-slate-500">ผู้สร้าง: {t.creator?.name || 'ไม่ระบุ'} · สมาชิก {t.participants?.length || 0}/{t.maxParticipants}</p>
                    <p className="mt-1 text-xs text-slate-500">เริ่ม {new Date(t.startDate).toLocaleDateString('th-TH')} · งบ {Number(t.budget || 0).toLocaleString()} บาท</p>
                    <div className="mt-3 flex gap-2"><Link to={`/trip/${t.id}`} className="rounded-lg bg-blue-50 px-3 py-2 text-xs font-bold text-[#1E3A8A]">ดูรายละเอียด</Link><button onClick={() => remove(t)} className="rounded-lg bg-red-50 px-3 py-2 text-xs font-bold text-red-700">ลบทริป</button></div>
                </div>
            </article>)}
        </div>
        {!busy && shown.length === 0 && <p className="rounded-2xl bg-white p-12 text-center text-slate-500">ไม่พบทริป</p>}{busy && <p className="p-12 text-center text-slate-500">กำลังโหลด...</p>}
    </AdminShell>;
};
export default AdminTrips;
