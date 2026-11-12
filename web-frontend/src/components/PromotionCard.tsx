import React from 'react';
import { motion, useReducedMotion } from 'framer-motion';
import { BrandLogo } from './BrandLogo';

type Props = {
    image: string;
    title: string;
    actionable: boolean;
    onClose: () => void;
    onOpen?: () => void;
    closeRef?: React.Ref<HTMLButtonElement>;
};

/** Shared by the actual popup and the admin preview. */
export default function PromotionCard({ image, title, actionable, onClose, onOpen, closeRef }: Props) {
    const reducedMotion = useReducedMotion();
    return <motion.div
        role="dialog" aria-modal="true" aria-label={title || 'เรื่องดี ๆ จาก GoWithUs'}
        className="fixed inset-0 z-[150] flex items-center justify-center overflow-y-auto bg-[#252b30]/45 p-4 backdrop-blur-md sm:p-6"
        initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
        transition={{ duration: reducedMotion ? 0 : 0.2 }}
    >
        <motion.section
            initial={{ opacity: 0, y: reducedMotion ? 0 : 20, scale: reducedMotion ? 1 : 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: reducedMotion ? 0 : 12, scale: reducedMotion ? 1 : 0.98 }}
            transition={{ duration: reducedMotion ? 0 : 0.3, ease: [0.22, 1, 0.36, 1] }}
            className="relative my-auto w-full max-w-[410px] rounded-[32px] border border-white/80 bg-[#fffdf7] p-3 shadow-[0_24px_90px_-20px_rgba(16,37,45,0.4)] sm:p-4"
        >
            <header className="flex items-center gap-3 px-2 pb-3 pt-1">
                <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#fff0c7]">
                    <BrandLogo className="h-9 w-10" alt="" />
                </span>
                <div className="flex-1"><p className="text-[15px] font-bold tracking-tight text-[#263b45]">GoWithUs</p>
                    <p className="mt-0.5 text-xs text-[#7c8585]">เรื่องดี ๆ ระหว่างทาง</p></div>
                <button ref={closeRef} autoFocus type="button" onClick={onClose} aria-label="ปิดโปรโมชัน"
                    className="flex h-11 w-11 items-center justify-center rounded-full bg-[#f1efe7] text-xl text-[#687477] transition hover:bg-[#e8e4d9] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#527987]">×</button>
            </header>
            <div className="overflow-hidden rounded-[22px] bg-[#f3f0e7]">
                {actionable ? <button type="button" className="block w-full focus-visible:outline focus-visible:outline-2 focus-visible:outline-[#527987]" onClick={onOpen} aria-label={title || 'ดูรายละเอียดโปรโมชัน'}>
                    <img src={image} alt={title || 'โปรโมชัน'} className="max-h-[min(52vh,460px)] w-full object-contain" />
                </button> : <img src={image} alt={title || 'โปรโมชัน'} className="max-h-[min(52vh,460px)] w-full object-contain" />}
            </div>
            <footer className="px-2 pb-1 pt-4">
                {title && <h2 className="mb-3 break-words text-lg font-bold leading-snug text-[#263b45]">{title}</h2>}
                {actionable && <button type="button" onClick={onOpen}
                    className="flex w-full items-center justify-center gap-3 rounded-full bg-[#263f49] px-5 py-3.5 text-sm font-semibold text-[#fff9e9] transition hover:bg-[#355662] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#527987]">
                    ออกไปดูด้วยกัน <span aria-hidden="true">↗</span>
                </button>}
                <p className="py-3 text-center text-[11px] tracking-wide text-[#89918c]">ไปด้วยกัน มีเรื่องราวมากกว่า</p>
            </footer>
        </motion.section>
    </motion.div>;
}
