import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { userAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import { TRIP_CATEGORIES } from '../constants/categories';

// ---- Types ----
interface RatingQuestion {
    type: 'rating';
    key: string;
    question: string;
    desc: string;
    lowLabel: string;
    midLabel: string;
    highLabel: string;
}

interface TimeSlot {
    key: string;
    label: string;
    emoji: string;
    desc: string;
}

interface TimeQuestion {
    type: 'time';
    key: string;
    question: string;
    desc: string;
    slots: TimeSlot[];
}

type AnyQuestion = RatingQuestion | TimeQuestion;

// ---- Step definitions ----
const TIME_SLOTS: TimeSlot[] = [
    { key: 'morning',   label: 'เช้า',      emoji: '', desc: 'ตื่นแต่เช้า สูดอากาศสด กิจกรรมยามเช้าตรู่' },
    { key: 'noon',      label: 'กลางวัน',   emoji: '', desc: 'ท่องเที่ยวระหว่างวัน เดินเล่น ช็อปปิ้ง' },
    { key: 'evening',   label: 'เย็น',      emoji: '', desc: 'ชมวิว ดูพระอาทิตย์ตก ดินเนอร์ริมทะเล' },
    { key: 'night',     label: 'มืด/ราตรี', emoji: '', desc: 'แฮงเอาต์ บาร์ ไนท์มาร์เก็ต ปาร์ตี้' },
];

const QUESTIONS: AnyQuestion[] = [
    {
        type: 'rating',
        key: 'budget',
        question: 'งบประมาณในการท่องเที่ยว (Budget Level)',
        desc: 'ระดับงบประมาณเฉลี่ยที่คุณพึงพอใจในการใช้จ่ายระหว่างทริป',
        lowLabel: 'ประหยัด (Budget) - เน้นคุ้มค่า โฮสเทล สตรีทฟู้ด',
        midLabel: 'ปานกลาง (Standard) - โรงแรมทั่วไป ร้านอาหารปานกลาง สบายๆ',
        highLabel: 'หรูหรา (Luxury) - รีสอร์ทห้าดาว ดินเนอร์หรู สะดวกสบาย',
    },
    {
        type: 'rating',
        key: 'activityStyle',
        question: 'สไตล์กิจกรรมที่ชื่นชอบ (Activity Style)',
        desc: 'รูปแบบของกิจกรรมที่คุณต้องการทำระหว่างการท่องเที่ยว',
        lowLabel: 'พักผ่อนชิลล์ๆ (Relaxing) - เดินเล่น ถ่ายรูป นั่งคาเฟ่ สบายๆ',
        midLabel: 'ยืดหยุ่นปานกลาง (Standard) - เดินป่าสั้นๆ เที่ยวชมเมือง ทำกิจกรรมทั่วไป',
        highLabel: 'ลุยเต็มพิกัด (Adventure) - ปีนเขา กางเต็นท์ แอดเวนเจอร์ กีฬาเอ็กซ์ตรีม',
    },
    {
        type: 'time',
        key: 'timeOfDay',
        question: 'ช่วงเวลาที่ชอบท่องเที่ยว (Time of Day)',
        desc: 'เลือกช่วงเวลาที่คุณชอบออกไปทำกิจกรรมหรือท่องเที่ยว (เลือกได้มากกว่า 1 ช่วง)',
        slots: TIME_SLOTS,
    },
];

const INTERESTS_STEP_INDEX = QUESTIONS.length;        // index 3
const TOTAL_STEPS         = QUESTIONS.length + 1;    // 4

// ---- Animation variants ----
const slideVariants = {
    enter: (dir: 'next' | 'back') => ({ x: dir === 'next' ? 150 : -150, opacity: 0 }),
    center: {
        x: 0, opacity: 1,
        transition: { x: { type: 'spring', stiffness: 300, damping: 30 }, opacity: { duration: 0.2 } },
    },
    exit: (dir: 'next' | 'back') => ({
        x: dir === 'next' ? -150 : 150, opacity: 0,
        transition: { x: { type: 'spring', stiffness: 300, damping: 30 }, opacity: { duration: 0.2 } },
    }),
};

// ---- Component ----
const Questionnaire: React.FC = () => {
    const navigate    = useNavigate();
    const { refreshUser } = useAuth();

    const [step,              setStep]              = useState(0);
    const [ratings,           setRatings]           = useState<{ [key: string]: number }>({});
    const [selectedTimes,     setSelectedTimes]     = useState<string[]>([]);
    const [selectedInterests, setSelectedInterests] = useState<string[]>([]);
    const [loading,           setLoading]           = useState(false);
    const [error,             setError]             = useState('');
    const [direction,         setDirection]         = useState<'next' | 'back'>('next');

    // Pre-fill existing data
    useEffect(() => {
        const load = async () => {
            try {
                const profile = await userAPI.getProfile();
                if (!profile) return;

                if (profile.travelStyle) {
                    const style: any = profile.travelStyle;
                    const pre: { [key: string]: number } = {};
                    QUESTIONS.forEach(q => {
                        if (q.type === 'rating' && typeof style[q.key] === 'number') {
                            pre[q.key] = style[q.key];
                        }
                    });
                    if (Object.keys(pre).length) setRatings(pre);

                    if (Array.isArray(style['timeOfDay'])) setSelectedTimes(style['timeOfDay']);
                }
                if (Array.isArray(profile.interests)) setSelectedInterests(profile.interests);
            } catch (e) {
                console.error('Failed to pre-fill questionnaire:', e);
            }
        };
        load();
    }, []);

    const currentQ        = QUESTIONS[step];
    const isInterestsStep = step === INTERESTS_STEP_INDEX;
    const isTimeStep      = !isInterestsStep && currentQ?.type === 'time';
    const isRatingStep    = !isInterestsStep && currentQ?.type === 'rating';
    const selectedRating  = isRatingStep ? (ratings[(currentQ as RatingQuestion).key] || 0) : 0;

    const progressPercent = ((step + 1) / TOTAL_STEPS) * 100;

    // ---- Handlers ----
    const handleSelectRating = (val: number) => {
        if (isRatingStep) {
            setRatings(prev => ({ ...prev, [(currentQ as RatingQuestion).key]: val }));
        }
    };

    const toggleTime = (key: string) => {
        setSelectedTimes(prev =>
            prev.includes(key) ? prev.filter(k => k !== key) : [...prev, key]
        );
    };

    const toggleInterest = (label: string) => {
        setSelectedInterests(prev =>
            prev.includes(label) ? prev.filter(l => l !== label) : [...prev, label]
        );
    };

    const handleNext = () => {
        setError('');
        if (isRatingStep && !selectedRating) {
            setError('โปรดเลือกคะแนน 1-10 ก่อนไปข้อถัดไป');
            return;
        }
        if (isTimeStep && selectedTimes.length === 0) {
            setError('โปรดเลือกอย่างน้อย 1 ช่วงเวลา');
            return;
        }
        if (step < TOTAL_STEPS - 1) {
            setDirection('next');
            setStep(s => s + 1);
        } else {
            handleSave();
        }
    };

    const handleBack = () => {
        setError('');
        if (step > 0) {
            setDirection('back');
            setStep(s => s - 1);
        }
    };

    const handleSave = async () => {
        // Validate rating questions
        const missingRating = QUESTIONS.filter(
            q => q.type === 'rating' && !ratings[(q as RatingQuestion).key]
        );
        if (missingRating.length) {
            const idx = QUESTIONS.indexOf(missingRating[0]);
            setStep(idx);
            setError('โปรดตอบคำถามให้ครบทุกข้อ');
            return;
        }
        if (selectedTimes.length === 0) {
            setStep(2);
            setError('โปรดเลือกอย่างน้อย 1 ช่วงเวลา');
            return;
        }

        setLoading(true);
        setError('');
        try {
            await userAPI.updateProfile({
                travelStyle: { ...ratings, timeOfDay: selectedTimes },
                interests: selectedInterests,
            });
            await refreshUser();
            navigate('/');
        } catch (err: any) {
            setError(err.message || 'เกิดข้อผิดพลาดในการบันทึกแบบสอบถาม');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-slate-50 flex flex-col justify-center items-center px-4 py-8 relative overflow-hidden">
            <div className="absolute top-[-20%] left-[-20%] w-[60%] h-[60%] rounded-full bg-slate-200/50 blur-3xl" />
            <div className="absolute bottom-[-20%] right-[-20%] w-[60%] h-[60%] rounded-full bg-slate-200/50 blur-3xl" />

            <div className="w-full max-w-2xl bg-white/80 backdrop-blur-xl border border-gray-100 rounded-3xl p-6 sm:p-10 shadow-2xl shadow-slate-100 z-10">
                {/* Header */}
                <div className="flex items-center justify-between mb-6">
                    <span className="text-2xl font-black tracking-tight text-black">
                        GoWithUs<span className="text-gray-400">.</span>
                    </span>
                    <button
                        onClick={() => navigate('/')}
                        className="text-xs text-gray-400 hover:text-black font-semibold uppercase tracking-wider transition-colors"
                    >
                        ข้ามคำถาม
                    </button>
                </div>

                {/* Progress */}
                <div className="mb-10">
                    <div className="flex justify-between items-center text-xs text-gray-400 font-bold uppercase tracking-widest mb-2">
                        <span>{isInterestsStep ? 'สิ่งที่สนใจ' : 'แบบสอบถามไลฟ์สไตล์'}</span>
                        <span>{step + 1} / {TOTAL_STEPS}</span>
                    </div>
                    <div className="w-full h-1.5 bg-gray-100 rounded-full overflow-hidden">
                        <div className="h-full bg-black transition-all duration-300" style={{ width: `${progressPercent}%` }} />
                    </div>
                </div>

                {error && (
                    <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-2xl text-red-600 text-sm font-medium">
                        {error}
                    </div>
                )}

                {/* Slide area */}
                <div className="relative min-h-[320px]">
                    <AnimatePresence mode="wait" custom={direction}>
                        <motion.div
                            key={step}
                            custom={direction}
                            variants={slideVariants}
                            initial="enter"
                            animate="center"
                            exit="exit"
                            className="w-full"
                        >
                            {/* ── Interests Step ── */}
                            {isInterestsStep && (
                                <div>
                                    <h2 className="text-2xl sm:text-3xl font-black text-black leading-tight mb-3">
                                        เลือกสิ่งที่คุณสนใจ (Interests)
                                    </h2>
                                    <p className="text-gray-500 text-sm mb-6 leading-relaxed">
                                        เลือกหัวข้อหรือประเภทกิจกรรมที่คุณชื่นชอบเพื่อช่วยแนะนำทริปและเพื่อนร่วมทางที่เหมาะสมกับตัวคุณ
                                    </p>
                                    <div className="flex flex-wrap gap-2.5 max-h-[300px] overflow-y-auto p-1">
                                        {TRIP_CATEGORIES.map(cat => {
                                            const sel = selectedInterests.includes(cat.label);
                                            return (
                                                <button
                                                    key={cat.id}
                                                    type="button"
                                                    onClick={() => toggleInterest(cat.label)}
                                                    className={`px-4 py-2.5 rounded-2xl text-xs sm:text-sm font-bold border-2 transition-all flex items-center gap-2 active:scale-95
                                                        ${sel
                                                            ? 'bg-black border-black text-white shadow-lg shadow-black/10 scale-[1.02]'
                                                            : 'bg-white border-gray-100 text-gray-500 hover:border-black hover:text-black'
                                                        }`}
                                                >
                                                    <span>{cat.emoji}</span>
                                                    <span>{cat.label}</span>
                                                    {sel && (
                                                        <span className="w-3.5 h-3.5 bg-white text-black rounded-full flex items-center justify-center text-[9px] font-bold ml-1">
                                                            ✓
                                                        </span>
                                                    )}
                                                </button>
                                            );
                                        })}
                                    </div>
                                </div>
                            )}

                            {/* ── Time of Day Step ── */}
                            {isTimeStep && (() => {
                                const q = currentQ as TimeQuestion;
                                return (
                                    <div>
                                        <h2 className="text-2xl sm:text-3xl font-black text-black leading-tight mb-3">
                                            {q.question}
                                        </h2>
                                        <p className="text-gray-500 text-sm mb-8 leading-relaxed">
                                            {q.desc}
                                        </p>
                                        <div className="grid grid-cols-2 gap-4">
                                            {q.slots.map(slot => {
                                                const sel = selectedTimes.includes(slot.key);
                                                return (
                                                    <button
                                                        key={slot.key}
                                                        type="button"
                                                        onClick={() => toggleTime(slot.key)}
                                                        className={`relative flex flex-col items-start gap-1.5 p-5 rounded-2xl border-2 text-left transition-all active:scale-95
                                                            ${sel
                                                                ? 'bg-black border-black text-white shadow-lg shadow-black/10'
                                                                : 'bg-white border-gray-100 text-gray-700 hover:border-black'
                                                            }`}
                                                    >
                                                        <span className="font-black text-base">{slot.label}</span>
                                                        <span className={`text-xs leading-snug ${sel ? 'text-gray-300' : 'text-gray-400'}`}>
                                                            {slot.desc}
                                                        </span>
                                                        {sel && (
                                                            <span className="absolute top-3 right-3 w-5 h-5 bg-white text-black rounded-full flex items-center justify-center text-[10px] font-black">
                                                                ✓
                                                            </span>
                                                        )}
                                                    </button>
                                                );
                                            })}
                                        </div>
                                    </div>
                                );
                            })()}

                            {/* ── Rating Step ── */}
                            {isRatingStep && (() => {
                                const q = currentQ as RatingQuestion;
                                return (
                                    <div>
                                        <h2 className="text-2xl sm:text-3xl font-black text-black leading-tight mb-3">
                                            {q.question}
                                        </h2>
                                        <p className="text-gray-500 text-sm mb-8 leading-relaxed">
                                            {q.desc}
                                        </p>
                                        <div className="space-y-6">
                                            <div className="grid grid-cols-5 sm:grid-cols-10 gap-2.5">
                                                {Array.from({ length: 10 }, (_, i) => i + 1).map(val => {
                                                    const sel = selectedRating === val;
                                                    return (
                                                        <button
                                                            key={val}
                                                            type="button"
                                                            onClick={() => handleSelectRating(val)}
                                                            className={`aspect-square sm:h-12 w-full rounded-2xl font-black text-lg border-2 transition-all flex items-center justify-center
                                                                ${sel
                                                                    ? 'bg-black border-black text-white scale-[1.08] shadow-lg shadow-black/10'
                                                                    : 'bg-white border-gray-100 text-gray-500 hover:border-black hover:text-black hover:scale-105'
                                                                }`}
                                                        >
                                                            {val}
                                                        </button>
                                                    );
                                                })}
                                            </div>
                                            <div className="grid grid-cols-1 md:grid-cols-3 gap-3 pt-4 border-t border-gray-50 text-xs">
                                                <div className="bg-slate-50 rounded-xl p-3 flex flex-col">
                                                    <span className="text-[10px] text-slate-400 uppercase tracking-wider mb-1">คะแนน 1 - 3</span>
                                                    <span className="text-gray-700 font-bold">{q.lowLabel}</span>
                                                </div>
                                                <div className="bg-slate-50 rounded-xl p-3 flex flex-col">
                                                    <span className="text-[10px] text-slate-400 uppercase tracking-wider mb-1">คะแนน 4 - 7</span>
                                                    <span className="text-gray-700 font-bold">{q.midLabel}</span>
                                                </div>
                                                <div className="bg-slate-50 rounded-xl p-3 flex flex-col">
                                                    <span className="text-[10px] text-slate-400 uppercase tracking-wider mb-1">คะแนน 8 - 10</span>
                                                    <span className="text-gray-700 font-bold">{q.highLabel}</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                );
                            })()}
                        </motion.div>
                    </AnimatePresence>
                </div>

                {/* Footer nav */}
                <div className="flex items-center justify-between mt-10 pt-6 border-t border-gray-100">
                    <button
                        onClick={handleBack}
                        disabled={step === 0}
                        className="px-6 py-3 border border-gray-200 text-gray-500 font-bold rounded-xl text-sm transition-all hover:bg-gray-50 active:scale-95 disabled:opacity-30 disabled:pointer-events-none"
                    >
                        ย้อนกลับ
                    </button>
                    <button
                        onClick={handleNext}
                        disabled={loading}
                        className="px-8 py-3 bg-black text-white font-bold rounded-xl text-sm transition-all hover:bg-gray-800 active:scale-95 disabled:opacity-50 flex items-center gap-2 shadow-lg shadow-black/10"
                    >
                        {loading && <span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />}
                        {step === TOTAL_STEPS - 1 ? 'บันทึกคำตอบ' : 'ถัดไป'}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default Questionnaire;
