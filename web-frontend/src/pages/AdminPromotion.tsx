import React, { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import AdminShell from '../components/AdminShell';
import { useAuth } from '../contexts/AuthContext';
import { authFetch } from '../services/api';

type Promotion = {
    enabled: boolean;
    image: string;
    title: string;
    frequency: 'daily' | 'launch' | 'once';
    targetType: 'none' | 'url' | 'trip';
    target: string;
};
const empty: Promotion = { enabled: false, image: '', title: '', frequency: 'daily', targetType: 'none', target: '' };
const endpoint = (import.meta.env.VITE_API_URL || '/api') + '/promotions/settings';
const inputClass = 'mt-2 w-full rounded-xl border border-gray-200 bg-white px-4 py-3 focus:outline-none focus:ring-2 focus:ring-black';

async function prepareImage(file: File): Promise<string> {
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
        throw new Error('กรุณาเลือกรูป JPEG, PNG หรือ WebP');
    }
    if (file.size > 15 * 1024 * 1024) throw new Error('รูปต้นฉบับต้องมีขนาดไม่เกิน 15 MB');
    const url = URL.createObjectURL(file);
    try {
        const image = new Image();
        image.src = url;
        await image.decode();
        const scale = Math.min(1, 1400 / Math.max(image.naturalWidth, image.naturalHeight));
        const canvas = document.createElement('canvas');
        canvas.width = Math.max(1, Math.round(image.naturalWidth * scale));
        canvas.height = Math.max(1, Math.round(image.naturalHeight * scale));
        const context = canvas.getContext('2d');
        if (!context) throw new Error('ไม่สามารถประมวลผลรูปได้');
        context.fillStyle = '#ffffff';
        context.fillRect(0, 0, canvas.width, canvas.height);
        context.drawImage(image, 0, 0, canvas.width, canvas.height);
        const result = canvas.toDataURL('image/jpeg', 0.8);
        if (result.length > 2.7 * 1024 * 1024) throw new Error('รูปยังใหญ่เกินไป กรุณาเลือกรูปขนาดเล็กลง');
        return result;
    } finally { URL.revokeObjectURL(url); }
}

const AdminPromotion: React.FC = () => {
    const { user, isLoading: authLoading } = useAuth();
    const navigate = useNavigate();
    const [form, setForm] = useState<Promotion>(empty);
    const [loading, setLoading] = useState(true);
    const [loadFailed, setLoadFailed] = useState(false);
    const [saving, setSaving] = useState(false);
    const [processing, setProcessing] = useState(false);
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const [preview, setPreview] = useState(false);
    const [retry, setRetry] = useState(0);
    const imageSequence = useRef(0);
    const closePreview = useRef<HTMLButtonElement>(null);
    const update = (patch: Partial<Promotion>) => {
        setForm(previous => ({ ...previous, ...patch }));
        setSuccess('');
    };

    useEffect(() => {
        if (!authLoading && user?.role !== 'admin') navigate('/', { replace: true });
    }, [authLoading, user?.role, navigate]);
    useEffect(() => {
        if (user?.role !== 'admin') return;
        let active = true;
        setLoading(true);
        setLoadFailed(false);
        setError('');
        authFetch(endpoint).then(data => {
            if (!active) return;
            if (data.promotion) {
                const { enabled, image, title, frequency, targetType, target } = data.promotion;
                setForm({ enabled, image, title, frequency, targetType, target });
            } else setForm(empty);
        }).catch(e => {
            if (active) { setError(e.message || 'โหลดโปรโมชันไม่สำเร็จ'); setLoadFailed(true); }
        }).finally(() => { if (active) setLoading(false); });
        return () => { active = false; imageSequence.current++; };
    }, [user?.id, user?.role, retry]);

    useEffect(() => {
        if (!preview) return;
        const previouslyFocused = document.activeElement instanceof HTMLElement ? document.activeElement : null;
        const close = (event: KeyboardEvent) => {
            if (event.key === 'Escape') setPreview(false);
            if (event.key === 'Tab') {
                event.preventDefault();
                closePreview.current?.focus();
            }
        };
        window.addEventListener('keydown', close);
        const oldOverflow = document.body.style.overflow;
        document.body.style.overflow = 'hidden';
        return () => {
            window.removeEventListener('keydown', close);
            document.body.style.overflow = oldOverflow;
            previouslyFocused?.focus();
        };
    }, [preview]);

    async function chooseImage(file?: File) {
        if (!file) return;
        const sequence = ++imageSequence.current;
        setProcessing(true); setError(''); setSuccess('');
        try {
            const image = await prepareImage(file);
            if (sequence === imageSequence.current) update({ image });
        } catch (e) {
            if (sequence === imageSequence.current) setError(e instanceof Error ? e.message : 'อ่านรูปไม่สำเร็จ');
        } finally { if (sequence === imageSequence.current) setProcessing(false); }
    }

    async function save(event: React.FormEvent) {
        event.preventDefault();
        setError(''); setSuccess('');
        if (!form.image) { setError('กรุณาเลือกรูปก่อนบันทึก'); return; }
        const target = form.target.trim();
        if (form.targetType === 'url') {
            try {
                const url = new URL(target);
                if (url.protocol !== 'https:' || url.username || url.password) throw new Error();
            } catch { setError('กรุณาใส่ลิงก์ HTTPS ที่ถูกต้อง'); return; }
        }
        if (form.targetType === 'trip' && !target) { setError('กรุณาใส่ Trip ID'); return; }
        setSaving(true);
        try {
            await authFetch(endpoint, { method: 'PUT', body: JSON.stringify({ ...form, target }) });
            setForm(previous => ({ ...previous, target }));
            setSuccess('บันทึกแล้ว แอปจะใช้ค่านี้เมื่อตรวจโปรโมชันในการเปิดครั้งถัดไป');
        } catch (e) { setError(e instanceof Error ? e.message : 'บันทึกไม่สำเร็จ'); }
        finally { setSaving(false); }
    }

    if (authLoading || user?.role !== 'admin') return null;
    const busy = loading || saving || processing || loadFailed;
    return <AdminShell title="ป๊อปอัปโปรโมชัน" subtitle="จัดการแบนเนอร์ที่แสดงหลังเปิดแอป iOS">
        {error && <div role="alert" className="mb-5 rounded-xl bg-red-50 p-4 text-red-700">{error}
            {loadFailed && <button className="ml-3 underline" onClick={() => setRetry(v => v + 1)}>ลองโหลดใหม่</button>}
        </div>}
        {success && <div role="status" className="mb-5 rounded-xl bg-green-50 p-4 text-green-800">{success}</div>}
        {loading ? <p role="status">กำลังโหลดการตั้งค่า…</p> : <div className="grid gap-6 lg:grid-cols-2">
            <form onSubmit={save} className="rounded-2xl border border-gray-200 bg-white p-6">
                <fieldset disabled={busy} className="space-y-6 disabled:opacity-60">
                    <label className="flex items-center justify-between gap-4 font-semibold">
                        เปิดแสดงป๊อปอัป
                        <input type="checkbox" className="h-5 w-5 accent-black" checked={form.enabled} onChange={e => update({ enabled: e.target.checked })} />
                    </label>
                    <label className="block text-sm font-semibold">ชื่อโปรโมชัน
                        <input className={inputClass} maxLength={120} value={form.title} onChange={e => update({ title: e.target.value })} placeholder="เช่น ทริปแนะนำประจำเดือน" />
                    </label>
                    <label className="block text-sm font-semibold">รูปแบนเนอร์
                        <input type="file" accept="image/jpeg,image/png,image/webp" className={inputClass} onChange={e => { void chooseImage(e.target.files?.[0]); e.target.value = ''; }} />
                        <span className="mt-2 block text-xs font-normal text-gray-500">JPEG, PNG หรือ WebP สูงสุด 15 MB ระบบย่อรูปให้อัตโนมัติและคงสัดส่วนเดิม</span>
                    </label>
                    <label className="block text-sm font-semibold">ความถี่
                        <select className={inputClass} value={form.frequency} onChange={e => update({ frequency: e.target.value as Promotion['frequency'] })}>
                            <option value="daily">วันละครั้ง</option><option value="launch">ทุกครั้งที่เปิดแอปใหม่</option><option value="once">ครั้งเดียวต่อโปรโมชัน</option>
                        </select>
                    </label>
                    <label className="block text-sm font-semibold">เมื่อกดรูป
                        <select className={inputClass} value={form.targetType} onChange={e => update({ targetType: e.target.value as Promotion['targetType'], target: '' })}>
                            <option value="none">ไม่เปิดปลายทาง</option><option value="url">เปิดเว็บไซต์</option><option value="trip">เปิดทริป</option>
                        </select>
                    </label>
                    {form.targetType !== 'none' && <label className="block text-sm font-semibold">{form.targetType === 'url' ? 'ลิงก์เว็บไซต์ (HTTPS)' : 'Trip ID ของทริปสาธารณะ'}
                        <input className={inputClass} required maxLength={2048} type={form.targetType === 'url' ? 'url' : 'text'} value={form.target} onChange={e => update({ target: e.target.value })} placeholder={form.targetType === 'url' ? 'https://example.com' : 'ใส่รหัสทริป'} />
                    </label>}
                    <p className="text-xs leading-relaxed text-gray-500">ความถี่นับแยกตามบัญชีบนแต่ละเครื่อง การเปลี่ยนรูป ชื่อ ความถี่ หรือปลายทางจะเริ่มโปรโมชันรอบใหม่ การเปิด–ปิดอย่างเดียวจะไม่ล้างประวัติการแสดง</p>
                    <button disabled={!form.image} type="submit" className="w-full rounded-xl bg-black px-5 py-3 font-semibold text-white disabled:opacity-40">{saving ? 'กำลังบันทึก…' : 'บันทึกการตั้งค่า'}</button>
                </fieldset>
                {processing && <p role="status" className="mt-3 text-sm">กำลังเตรียมรูป…</p>}
            </form>
            <section className="h-fit rounded-2xl border border-gray-200 bg-white p-6">
                <div className="mb-4 flex items-center justify-between"><h2 className="font-bold">ตัวอย่างแบนเนอร์</h2><span className="text-sm text-gray-500">{form.enabled ? 'เปิดใช้งาน' : 'ปิดใช้งาน'}</span></div>
                {form.image ? <img src={form.image} alt={form.title || 'ตัวอย่างโปรโมชัน'} className="mx-auto max-h-[500px] rounded-2xl object-contain" /> : <div className="flex h-64 items-center justify-center rounded-2xl bg-gray-100 text-gray-500">เลือกรูปเพื่อดูตัวอย่าง</div>}
                <button disabled={!form.image} onClick={() => setPreview(true)} className="mt-5 w-full rounded-xl border border-gray-200 px-4 py-3 font-semibold disabled:opacity-40">ดูตัวอย่างป๊อปอัป</button>
                <p className="mt-3 text-xs text-gray-500">ตัวอย่างนี้ไม่บันทึกและไม่นับจำนวนการแสดง</p>
            </section>
        </div>}
        {preview && <div role="dialog" aria-modal="true" aria-label="ตัวอย่างป๊อปอัปโปรโมชัน" className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 p-6">
            <div className="w-full max-w-sm"><div className="mb-3 flex justify-end">
                <button ref={closePreview} autoFocus onClick={() => setPreview(false)} aria-label="ปิดตัวอย่าง" className="h-11 w-11 rounded-full bg-black/60 text-xl text-white">×</button>
            </div><img src={form.image} alt={form.title || 'โปรโมชัน'} className="max-h-[75vh] w-full rounded-[22px] object-contain" /></div>
        </div>}
    </AdminShell>;
};
export default AdminPromotion;
