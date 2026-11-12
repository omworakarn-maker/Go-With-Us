import React, { useEffect, useRef, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { authFetch } from '../services/api';
import { AnimatePresence } from 'framer-motion';
import PromotionCard from './PromotionCard';

type Promotion = { id: string; revision: string; enabled: boolean; image: string; title: string; frequency: string; targetType: string; target: string };

export default function PromotionPopup() {
    const { user } = useAuth();
    const location = useLocation();
    const navigate = useNavigate();
    const [promotion, setPromotion] = useState<Promotion | null>(null);
    const closeButton = useRef<HTMLButtonElement>(null);
    useEffect(() => {
        setPromotion(null);
        if (!user || location.pathname !== '/') return;
        let cancelled = false;
        const timer = window.setTimeout(async () => {
            try {
                const data = await authFetch((import.meta.env.VITE_API_URL || '/api') + '/promotions');
                const candidate: Promotion | null = data.promotion;
                if (cancelled || !candidate?.enabled) return;
                const key = 'promotion.web.seen.' + user.id + '.' + candidate.revision;
                const store = candidate.frequency === 'launch' ? sessionStorage : localStorage;
                const last = store.getItem(key);
                const today = new Date().toLocaleDateString('en-CA');
                if (last && (candidate.frequency !== 'daily' || last === today)) return;
                const image = new Image();
                image.src = candidate.image;
                await image.decode();
                if (cancelled) return;
                store.setItem(key, today);
                setPromotion(candidate);
            } catch { /* A banner must never block browsing. */ }
        }, 400);
        return () => { cancelled = true; window.clearTimeout(timer); };
    }, [user?.id, location.pathname]);

    useEffect(() => {
        if (!promotion) return;
        const oldFocus = document.activeElement instanceof HTMLElement ? document.activeElement : null;
        const oldOverflow = document.body.style.overflow;
        document.body.style.overflow = 'hidden';
        closeButton.current?.focus();
        const onKey = (event: KeyboardEvent) => {
            if (event.key === 'Escape') setPromotion(null);
            if (event.key === 'Tab') {
                const modal = closeButton.current?.closest('[role="dialog"]');
                const buttons = modal?.querySelectorAll<HTMLButtonElement>('button');
                if (!buttons?.length) return;
                const first = buttons[0], last = buttons[buttons.length - 1];
                if (event.shiftKey && document.activeElement === first) { event.preventDefault(); last.focus(); }
                else if (!event.shiftKey && document.activeElement === last) { event.preventDefault(); first.focus(); }
            }
        };
        window.addEventListener('keydown', onKey);
        return () => {
            document.body.style.overflow = oldOverflow;
            window.removeEventListener('keydown', onKey);
            oldFocus?.focus();
        };
    }, [promotion]);
    return <AnimatePresence>{promotion && <PromotionCard
        key={promotion.revision} image={promotion.image} title={promotion.title}
        actionable={promotion.targetType !== 'none'} closeRef={closeButton}
        onClose={() => setPromotion(null)} onOpen={() => {
                if (promotion.targetType === 'trip') {
                    setPromotion(null); navigate('/trip/' + encodeURIComponent(promotion.target));
                } else if (promotion.targetType === 'url') {
                    try {
                        const url = new URL(promotion.target);
                        if (url.protocol === 'https:') { setPromotion(null); window.location.assign(url.href); }
                    } catch { /* Ignore invalid legacy targets. */ }
                }
            }} />}</AnimatePresence>;
}
