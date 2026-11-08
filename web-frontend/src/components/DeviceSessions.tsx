import React, { useEffect, useState } from 'react';
import { authAPI, DeviceSession } from '../services/api';

export default function DeviceSessions() {
  const [sessions, setSessions] = useState<DeviceSession[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const load = async () => {
    try { const result = await authAPI.getSessions(); setSessions(result.sessions); }
    catch (error) { setError(error instanceof Error ? error.message : 'โหลดอุปกรณ์ไม่สำเร็จ'); }
  };
  useEffect(() => { void load(); }, []);
  const revoke = async (id?: string) => {
    setBusy(true); setError('');
    try {
      if (id) await authAPI.revokeSession(id); else await authAPI.logoutOthers();
      await load();
    } catch (error) { setError(error instanceof Error ? error.message : 'ออกจากระบบอุปกรณ์ไม่สำเร็จ'); }
    finally { setBusy(false); }
  };
  return <section className="bg-white rounded-2xl border border-gray-200 p-6 my-6">
    <h2 className="text-lg font-bold mb-2">อุปกรณ์ที่เข้าสู่ระบบ</h2>
    <p className="text-sm text-gray-500 mb-4">ใช้ได้สูงสุด 3 อุปกรณ์ต่อบัญชี แท็บในเบราว์เซอร์เดียวกันนับเป็นอุปกรณ์เดียว</p>
    {error && <p role="alert" className="text-red-600 text-sm mb-3">{error}</p>}
    <ul className="divide-y divide-gray-100">{sessions.map(session => <li key={session.id} className="flex items-center justify-between gap-3 py-3">
      <div><p className="font-medium">{session.deviceName}{session.isCurrent ? ' (เครื่องนี้)' : ''}</p>
        <p className="text-xs text-gray-500">ใช้งานล่าสุด {new Date(session.lastSeenAt).toLocaleString('th-TH')}</p></div>
      <button disabled={busy} onClick={() => session.isCurrent ? authAPI.logout() : revoke(session.id)} className="text-sm text-red-600 disabled:opacity-50">ออกจากระบบ</button>
    </li>)}</ul>
    <button disabled={busy || !sessions.some(session => !session.isCurrent)} onClick={() => revoke()} className="mt-4 text-sm font-bold text-red-600 disabled:opacity-50">ออกจากระบบอุปกรณ์อื่นทั้งหมด</button>
  </section>;
}
