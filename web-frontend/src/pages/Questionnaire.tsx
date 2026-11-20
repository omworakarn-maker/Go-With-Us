import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { BrandLogo } from '../components/BrandLogo';
import { useAuth } from '../contexts/AuthContext';
import { userAPI } from '../services/api';
import { resizeImage } from '../utils/imageResizer';

const BUDGET_STEPS = [100, 300, 500, 800, 1000, 1500, 2000, 3000, 4000, 5000];
const INTEREST_LIMIT = 5;
const TIME_SLOTS = [
    ['morning', 'ช่วงเช้า (06:00 - 11:00 น.)', 'เหมาะสำหรับคนที่ชอบออกจากที่พักเร็ว เช่น ดูพระอาทิตย์ขึ้น เดินตลาดเช้า หรือรับประทานอาหารเช้า'],
    ['noon', 'ช่วงกลางวัน (11:00 - 16:00 น.)', 'เหมาะสำหรับคนที่ชอบเที่ยวช่วงสายถึงบ่าย เช่น เข้าชมสถานที่ท่องเที่ยว แวะคาเฟ่ หรือรับประทานอาหารกลางวัน'],
    ['evening', 'ช่วงเย็น (16:00 - 20:00 น.)', 'เหมาะสำหรับคนที่ชอบเที่ยวช่วงเย็นก่อนค่ำ เช่น เดินเล่น ชมพระอาทิตย์ตก หรือรับประทานอาหารเย็น'],
    ['night', 'ช่วงกลางคืน (20:00 น. เป็นต้นไป)', 'เหมาะสำหรับคนที่ชอบออกเที่ยวหลังค่ำ เช่น เดินตลาดกลางคืน ชมแสงไฟในเมือง หรือฟังดนตรีสด'],
];
const INTEREST_SECTIONS = [
    { title: '🍃 สายธรรมชาติ & ผจญภัย', options: [['ทะเล', '🏖️'], ['ภูเขา', '🏔️'], ['แคมป์ปิ้ง', '🏕️'], ['ผจญภัย', '🧗']] },
    { title: '🏙️ สายเมือง & ไลฟ์สไตล์', options: [['เที่ยวเมือง', '🏙️'], ['คาเฟ่', '☕️'], ['อาหาร', '🍜'], ['ช้อปปิ้ง', '🛍️']] },
    { title: '🎨 สายศิลปะ & บันเทิง', options: [['ถ่ายรูป', '📸'], ['คอนเสิร์ต', '🎫'], ['แฮงเอาต์', '🍻'], ['ไหว้พระ', '🏛️']] },
];
const STEPS = [
    ['👤 ข้อมูลส่วนตัวของคุณ', 'ข้อมูลนี้ช่วยให้ผู้ร่วมทริปรู้จักคุณ และใช้สร้างโปรไฟล์ของคุณ'],
    ['💰 งบประมาณเฉลี่ยต่อทริป (Budget per Trip)', 'ระบุงบประมาณที่คุณสะดวกใช้จ่ายสำหรับหนึ่งทริป (บาท)'],
    ['🎯 จำนวนสถานที่ท่องเที่ยวต่อวัน (Places per Day)', 'เลือกจำนวนสถานที่ที่คุณสะดวกเที่ยวในหนึ่งวัน'],
    ['🕘 ช่วงเวลาที่ชอบท่องเที่ยว (Time of Day)', 'เลือกช่วงเวลาที่คุณชอบออกไปทำกิจกรรมหรือท่องเที่ยว (เลือกได้มากกว่า 1 ช่วง)'],
    ['✨ ความสนใจด้านการท่องเที่ยว (Travel Interests)', 'เลือกหมวดหมู่ที่คุณสนใจได้สูงสุด 5 ข้อ เพื่อให้เราแนะนำทริปที่เหมาะกับคุณ'],
];

const fieldClass = 'w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-slate-900';
const optionClass = (selected: boolean) => `rounded-xl border px-4 py-3 text-left transition-colors ${selected ? 'border-black bg-black text-white' : 'border-slate-200 bg-slate-50 hover:border-slate-500'}`;

function budgetFromProfile(budget: number) {
    // Match the backend's conversion for legacy scores stored by the old web form.
    if (budget > 10 || budget === 0) return budget;
    if (budget <= 2) return 500;
    if (budget <= 4) return 1000;
    if (budget <= 6) return 2000;
    if (budget <= 8) return 5000;
    return 8000;
}

export default function Questionnaire() {
    const navigate = useNavigate();
    const [params] = useSearchParams();
    const isOnboarding = params.get('onboarding') === 'true';
    const { user, refreshUser } = useAuth();
    const firstStep = isOnboarding ? 0 : 1;
    const returnPath = isOnboarding ? '/' : '/profile';
    const [step, setStep] = useState(firstStep);
    const [budget, setBudget] = useState('1500');
    const [activityStyle, setActivityStyle] = useState(3);
    const [times, setTimes] = useState<string[]>([]);
    const [interests, setInterests] = useState<string[]>([]);
    const [username, setUsername] = useState('');
    const [birthDate, setBirthDate] = useState('');
    const [profileImage, setProfileImage] = useState('');
    const [readingImage, setReadingImage] = useState(false);
    const [profileStatus, setProfileStatus] = useState<'loading' | 'ready' | 'error'>('loading');
    const [loadAttempt, setLoadAttempt] = useState(0);
    const [busy, setBusy] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        let ignore = false;
        userAPI.getProfile().then((profile) => {
            if (ignore) return;
            const style = profile.travelStyle;
            if (Number.isFinite(style?.budget) && style.budget >= 0) setBudget(String(budgetFromProfile(style.budget)));
            if (Number.isInteger(style?.activityStyle) && style.activityStyle >= 1 && style.activityStyle <= 10) {
                setActivityStyle(style.activityStyle);
            }
            if (Array.isArray(style?.timeOfDay)) {
                setTimes(TIME_SLOTS.map(([key]) => key).filter(key => style.timeOfDay.includes(key)));
            }
            if (Array.isArray(profile.interests)) {
                const existing = profile.interests.map((interest: string) => interest === 'เมือง' ? 'เที่ยวเมือง' : interest);
                setInterests(INTEREST_SECTIONS.flatMap(section => section.options.map(([label]) => label))
                    .filter(label => existing.includes(label)).slice(0, INTEREST_LIMIT));
            }
            if (isOnboarding) {
                setBirthDate(profile.birthDate?.split('T')[0] ?? '');
                setProfileImage(profile.profileImage ?? '');
            }
            setProfileStatus('ready');
        }).catch(() => {
            if (!ignore) setProfileStatus('error');
        });
        return () => { ignore = true; };
    }, [isOnboarding, loadAttempt]);

    const now = new Date();
    const today = [now.getFullYear(), String(now.getMonth() + 1).padStart(2, '0'), String(now.getDate()).padStart(2, '0')].join('-');
    const age = now.getFullYear() - Number(birthDate.slice(0, 4)) - (today.slice(5) < birthDate.slice(5) ? 1 : 0);
    const amount = Number(budget);
    const validBudget = budget !== '' && Number.isSafeInteger(amount) && amount >= 0;
    const sliderIndex = BUDGET_STEPS.reduce((nearest, value, index) =>
        Math.abs(value - amount) < Math.abs(BUDGET_STEPS[nearest] - amount) ? index : nearest, 0);
    const [heading, description] = STEPS[step];
    const lastStep = step === STEPS.length - 1;
    const validStep = [
        Boolean(profileImage && birthDate && birthDate <= today && !readingImage),
        validBudget,
        true,
        times.length > 0,
        interests.length > 0 && interests.length <= INTEREST_LIMIT,
    ][step];

    const next = async () => {
        if (busy || profileStatus !== 'ready' || !validStep) return;
        setError('');
        setBusy(true);
        try {
            const cleanedUsername = username.trim();
            if ((step === 0 || (isOnboarding && lastStep)) && cleanedUsername) {
                if (!/^[A-Za-z0-9_]{3,}$/.test(cleanedUsername)) {
                    setStep(0);
                    throw new Error('Username ต้องมีอย่างน้อย 3 ตัวอักษร ใช้ตัวอักษรอังกฤษ ตัวเลข หรือขีดล่าง');
                }
                const result = await userAPI.checkUsername(cleanedUsername, user?.id);
                if (!result.available) {
                    setStep(0);
                    throw new Error(result.message);
                }
            }
            if (!lastStep) {
                setStep(step + 1);
                return;
            }
            await userAPI.updateProfile({
                travelStyle: { budget: amount, activityStyle, timeOfDay: times },
                interests: [...interests].sort(),
                ...(isOnboarding ? { username: cleanedUsername || undefined, profileImage, birthDate, age } : {}),
            });
            await refreshUser();
            navigate(returnPath, { replace: true });
        } catch (err) {
            setError(err instanceof Error ? err.message : 'เกิดข้อผิดพลาดในการบันทึกแบบสอบถาม');
        } finally {
            setBusy(false);
        }
    };

    return (
        <main className="min-h-screen bg-slate-50 px-4 py-8">
            <div className="mx-auto max-w-xl rounded-3xl border border-slate-100 bg-white p-5 shadow-sm sm:p-8">
                <header className="mb-6 flex items-center justify-between gap-3">
                    <div className="flex items-center gap-2 font-bold">
                        <BrandLogo className="h-8 w-10" /> แบบสอบถาม
                    </div>
                    {!isOnboarding && <button type="button" disabled={busy} onClick={() => navigate(returnPath)} className="text-sm text-slate-600">ปิด</button>}
                </header>
                <div className="mb-6 space-y-2">
                    <p className="text-sm text-slate-600">ขั้นตอน {step - firstStep + 1} จาก {STEPS.length - firstStep}</p>
                    <progress className="block h-2 w-full accent-blue-600" aria-label="ความคืบหน้า" value={step - firstStep + 1} max={STEPS.length - firstStep} />
                </div>
                {error && <p role="alert" className="mb-4 rounded-xl bg-red-50 p-3 text-sm text-red-700">{error}</p>}
                {profileStatus === 'loading' && <p role="status">กำลังโหลดแบบสอบถาม…</p>}
                {profileStatus === 'error' && (
                    <div role="alert" className="space-y-3">
                        <p>โหลดข้อมูลแบบสอบถามไม่ได้</p>
                        <button type="button" className="text-sm font-semibold text-blue-700" onClick={() => {
                            setProfileStatus('loading');
                            setLoadAttempt(attempt => attempt + 1);
                        }}>ลองอีกครั้ง</button>
                    </div>
                )}
                {profileStatus === 'ready' && (
                    <>
                        <h1 className="mb-2 text-xl font-bold sm:text-2xl">{heading}</h1>
                        <p className="mb-5 text-sm text-slate-600">{description}</p>
                        {step === 0 && (
                            <div className="space-y-4">
                                <label className="block space-y-2 text-sm font-medium">
                                    <span>{profileImage ? 'เปลี่ยนรูปโปรไฟล์' : 'เลือกรูปโปรไฟล์'}</span>
                                    <input type="file" accept="image/*" disabled={busy || readingImage} className={fieldClass} onChange={async (event) => {
                                        const file = event.currentTarget.files?.[0];
                                        if (!file) return;
                                        setError('');
                                        setReadingImage(true);
                                        try { setProfileImage(await resizeImage(file)); }
                                        catch { setError('ไม่สามารถเปิดรูปที่เลือกได้'); }
                                        finally { setReadingImage(false); }
                                    }} />
                                </label>
                                {profileImage
                                    ? <img src={profileImage} alt="รูปโปรไฟล์ที่เลือก" className="h-20 w-20 rounded-full object-cover" />
                                    : <p className="text-sm text-slate-600">จำเป็นต้องเลือกรูปโปรไฟล์ก่อนดำเนินการต่อ</p>}
                                <label className="block space-y-2 text-sm font-medium">
                                    <span>Username</span>
                                    <input className={fieldClass} value={username} onChange={event => setUsername(event.target.value)} autoCapitalize="none" spellCheck={false} disabled={busy} />
                                    <span className="block text-slate-600">เว้นว่างได้ ระบบจะสร้าง Username ที่ไม่ซ้ำให้อัตโนมัติ</span>
                                </label>
                                <label className="block space-y-2 text-sm font-medium">
                                    <span>วันเกิด</span>
                                    <input type="date" max={today} className={fieldClass} value={birthDate} onChange={event => setBirthDate(event.target.value)} disabled={busy} />
                                    {birthDate && birthDate <= today && <span className="block text-slate-600">อายุ {age} ปี</span>}
                                </label>
                            </div>
                        )}
                        {step === 1 && (
                            <div className="space-y-3">
                                <input type="number" min="0" step="1" inputMode="numeric" aria-label="งบประมาณต่อทริป (บาท)" className={fieldClass} value={budget} onChange={event => setBudget(event.target.value)} />
                                <input type="range" aria-label="ปรับงบประมาณ" aria-valuetext={`${BUDGET_STEPS[sliderIndex]} บาท`} min={0} max={BUDGET_STEPS.length - 1} value={sliderIndex} onChange={event => setBudget(String(BUDGET_STEPS[Number(event.target.value)]))} className="w-full accent-black" />
                                <div className="flex justify-between text-xs text-slate-600"><span>ประหยัด (100฿)</span><span>หรูหรา (5,000฿+)</span></div>
                            </div>
                        )}
                        {step === 2 && (
                            <div className="grid gap-2">
                                {Array.from({ length: 10 }, (_, index) => index + 1).map(value => (
                                    <button key={value} type="button" aria-pressed={activityStyle === value} className={optionClass(activityStyle === value)} onClick={() => setActivityStyle(value)}>
                                        {value} สถานที่ต่อวัน
                                    </button>
                                ))}
                            </div>
                        )}
                        {step === 3 && (
                            <div className="grid gap-2">
                                {TIME_SLOTS.map(([key, label, detail]) => (
                                    <button key={key} type="button" aria-pressed={times.includes(key)} className={optionClass(times.includes(key))}
                                        onClick={() => setTimes(current => current.includes(key) ? current.filter(time => time !== key) : [...current, key])}>
                                        <span className="block font-semibold">{label}</span>
                                        <span className="mt-1 block text-sm opacity-80">{detail}</span>
                                    </button>
                                ))}
                            </div>
                        )}
                        {step === 4 && (
                            <div className="space-y-4">
                                <p className="text-sm text-slate-600">เลือกแล้ว {interests.length}/{INTEREST_LIMIT}</p>
                                {INTEREST_SECTIONS.map(({ title, options }) => (
                                    <section key={title}>
                                        <h2 className="mb-2 text-sm font-bold">{title}</h2>
                                        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                                            {options.map(([label, icon]) => {
                                                const selected = interests.includes(label);
                                                return (
                                                    <button key={label} type="button" aria-pressed={selected} disabled={busy || (!selected && interests.length >= INTEREST_LIMIT)}
                                                        className={`${optionClass(selected)} whitespace-nowrap text-sm disabled:opacity-50`}
                                                        onClick={() => setInterests(current => current.includes(label) ? current.filter(interest => interest !== label) : [...current, label])}>
                                                        <span aria-hidden="true">{icon} </span>{label}
                                                    </button>
                                                );
                                            })}
                                        </div>
                                    </section>
                                ))}
                            </div>
                        )}
                        <div className="mt-6 flex justify-between gap-3">
                            <button type="button" disabled={step === firstStep || busy} onClick={() => { setError(''); setStep(step - 1); }} className="rounded-xl border border-slate-200 px-5 py-3 text-sm font-semibold disabled:opacity-30">ย้อนกลับ</button>
                            <button type="button" disabled={!validStep || busy} onClick={next} className="rounded-xl bg-black px-5 py-3 text-sm font-semibold text-white disabled:opacity-40">
                                {busy ? 'กำลังดำเนินการ…' : lastStep ? 'เสร็จสิ้น' : 'ถัดไป'}
                            </button>
                        </div>
                    </>
                )}
            </div>
        </main>
    );
}
