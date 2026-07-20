
import React, { useState } from 'react';
import { TravelStyle } from '../types';
import { userAPI } from '../services/api';

interface TravelStyleQuizModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSave: (style: TravelStyle) => void;
    initialData?: TravelStyle;
}

export const TravelStyleQuizModal: React.FC<TravelStyleQuizModalProps> = ({ isOpen, onClose, onSave, initialData }) => {
    const [step, setStep] = useState(0);
    const [loading, setLoading] = useState(false);
    const [answers, setAnswers] = useState<Partial<TravelStyle>>(initialData || {});

    if (!isOpen) return null;

    const questions = [
        {
            key: 'budget',
            question: "งบประมาณต่อทริปของคุณ?",
            options: [
                { value: 'budget', label: "ประหยัด (Budget)", desc: "เน้นคุ้มค่า เก็บตังค์ไว้กินของอร่อย" },
                { value: 'moderate', label: "ปานกลาง (Standard)", desc: "จ่ายได้ถ้าคุ้มค่า ไม่ถูกไม่แพง" },
                { value: 'luxury', label: "จัดเต็ม (Luxury)", desc: "ขอสบายไว้ก่อน แพงหน่อยไม่ว่ากัน" }
            ]
        },
        {
            key: 'pace',
            question: "สไตล์การท่องเที่ยว (Pace)?",
            options: [
                { value: 'fast', label: "แน่นเอี๊ยด (Fast)", desc: "เก็บครบทุกแลนด์มาร์ค ตื่นเช้าลุยยันดึก" },
                { value: 'moderate', label: "สบายๆ (Flexible)", desc: "มีแผนบ้าง ปรับเปลี่ยนได้หน้างาน" },
                { value: 'relaxed', label: "ชิลล์ (Slow Life)", desc: "นอนตื่นสาย เน้นซึมซับบรรยากาศ" }
            ]
        },
        {
            key: 'social',
            question: "ชอบเที่ยวกับใคร?",
            options: [
                { value: 'pair', label: "คู่หู (Pair)", desc: "ไปกับเพื่อนสนิท 1 คน" },
                { value: 'small_group', label: "กลุ่มเล็ก (3-5 คน)", desc: "แก๊งเพื่อนสนิท คล่องตัว" },
                { value: 'large_group', label: "ปาร์ตี้ (6+ คน)", desc: "ยิ่งเยอะยิ่งมันส์ เฮฮาได้เต็มที่" }
            ]
        },
        {
            key: 'accommodation',
            question: "ชอบที่พักแบบไหน?",
            options: [
                { value: 'hostel', label: "โฮสเทล (Hostel)", desc: "เน้นถูก ได้เจอเพื่อนใหม่" },
                { value: 'camping', label: "กางเต็นท์ (Camping)", desc: "ใกล้ชิดธรรมชาติ นอนดูดาว" },
                { value: 'hotel', label: "โรงแรม (Hotel)", desc: "สะดวกสบาย มาตรฐานครบ" },
                { value: 'resort', label: "รีสอร์ท (Resort)", desc: "พักผ่อนเต็มที่ บรรยากาศดี" }
            ]
        },
        {
            key: 'food',
            question: "สไตล์การกิน?",
            options: [
                { value: 'street', label: "Street Food", desc: "กินง่าย อยู่ง่าย เน้นรสชาติท้องถิ่น" },
                { value: 'cafe', label: "Cafe Hopping", desc: "เน้นร้านสวย ถ่ายรูปปัง กาแฟดี" },
                { value: 'local', label: "ร้านดังเจ้าถิ่น", desc: "ร้านตำนานที่ต้องไปลอง" },
                { value: 'fine_dining', label: "Fine Dining", desc: "อาหารหรู บรรยากาศเลิศ" }
            ]
        },
        {
            key: 'nightlife',
            question: "ยามค่ำคืน?",
            options: [
                { value: 'party', label: "Party Animal", desc: "แดนซ์ยับ ผับบาร์ต้องไป" },
                { value: 'chill', label: "Nang Chill", desc: "นั่งชิลล์ ฟังเพลง จิบเครื่องดื่ม" },
                { value: 'quiet', label: "Sleep Early", desc: "นอนเร็ว เก็บแรงไว้เที่ยวพรุ่งนี้" }
            ]
        },
        {
            key: 'transport',
            question: "การเดินทาง?",
            options: [
                { value: 'public', label: "ขนส่งสาธารณะ", desc: "รถเมล์ รถไฟ ไปได้หมด ประหยัดดี" },
                { value: 'rent_car', label: "เช่ารถขับ", desc: "ขับเอง อิสระ อยากแวะไหนก็แวะ" },
                { value: 'private_driver', label: "เหมารถพร้อมคนขับ", desc: "นั่งสวยๆ สบายๆ ไม่ต้องขับเอง" }
            ]
        },
        {
            key: 'photography',
            question: "เรื่องถ่ายรูป?",
            options: [
                { value: 'pro', label: "ตากล้องมือโปร", desc: "อุปกรณ์ครบ รูปต้องสวยเป๊ะ" },
                { value: 'instagram', label: "สายคอนเทนต์", desc: "เน้นถ่ายคน มุมสวย ลงไอจี" },
                { value: 'snap', label: "Snap & Go", desc: "ถ่ายเก็บความทรงจำ ไม่เน้นสวยงาม" },
                { value: 'none', label: "ไม่เน้นถ่าย", desc: "เก็บภาพไว้ในความทรงจำก็พอ" }
            ]
        }
    ];

    const handleSelect = (key: string, value: any) => {
        const newAnswers = { ...answers, [key]: value };
        setAnswers(newAnswers);

        if (step < questions.length - 1) {
            setTimeout(() => setStep(step + 1), 300);
        } else {
            // Finished - Save directly without AI Analysis display
            handleFinalSave(newAnswers as TravelStyle);
        }
    };

    const handleFinalSave = async (finalAnswers: TravelStyle) => {
        try {
            setLoading(true);
            await userAPI.updateProfile({
                // @ts-ignore
                travelStyle: finalAnswers
            });
            onSave(finalAnswers);
            onClose();
        } catch (error) {
            console.error("Failed to save", error);
            onClose();
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            <div className="absolute inset-0 bg-white/95 backdrop-blur-md"></div>

            <div className="relative z-10 w-full max-w-2xl bg-white rounded-3xl p-8 border border-gray-100 shadow-2xl">
                {step < questions.length ? (
                    <>
                        {/* Header & Progress */}
                        <div className="mb-8">
                            <div className="flex items-center justify-between mb-4">
                                {step > 0 ? (
                                    <button
                                        onClick={() => setStep(step - 1)}
                                        className="text-gray-400 hover:text-black transition-colors flex items-center gap-1 text-sm font-bold"
                                    >
                                        <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                                        </svg>
                                        Back
                                    </button>
                                ) : (
                                    <div></div> // Spacer
                                )}
                                <div className="text-xs text-gray-400 font-mono uppercase tracking-widest">
                                    {step + 1} / {questions.length}
                                </div>
                            </div>

                            <div className="h-1 bg-gray-100 rounded-full overflow-hidden">
                                <div
                                    className="h-full bg-black transition-all duration-500"
                                    style={{ width: `${((step + 1) / questions.length) * 100}%` }}
                                ></div>
                            </div>
                        </div>

                        {/* Question */}
                        <div className="mb-8 animate-in fade-in slide-in-from-bottom-4 duration-500 key={step}">
                            <h2 className="text-3xl font-black text-black mb-2">{questions[step].question}</h2>
                            <p className="text-gray-500">เลือกคำตอบที่เป็นตัวคุณที่สุด</p>
                        </div>

                        {/* Options */}
                        <div className="grid gap-3">
                            {questions[step].options.map((option) => {
                                // Check if this option is selected
                                const isSelected = (answers as any)[questions[step].key] === option.value;

                                return (
                                    <button
                                        key={option.value}
                                        onClick={() => handleSelect(questions[step].key, option.value)}
                                        className={`group text-left p-6 rounded-2xl border-2 transition-all duration-200 
                                            ${isSelected
                                                ? 'border-black bg-black text-white shadow-lg scale-[1.02]'
                                                : 'border-gray-100 hover:border-black hover:bg-gray-50 text-black'
                                            }`}
                                    >
                                        <div className={`font-bold text-lg ${isSelected ? 'text-white' : 'group-hover:text-black'}`}>
                                            {option.label}
                                        </div>
                                        <div className={`text-sm ${isSelected ? 'text-gray-300' : 'text-gray-400 group-hover:text-gray-600'}`}>
                                            {option.desc}
                                        </div>
                                    </button>
                                );
                            })}
                        </div>
                    </>
                ) : (
                    <div className="text-center py-20">
                        <div className="w-16 h-16 border-4 border-black border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
                        <p className="font-bold">กำลังบันทึกข้อมูล...</p>
                    </div>
                )}
            </div>
        </div>
    );
};
