import React, { useEffect, useState } from 'react';
import './brand-splash.css';

const artwork = ['SplashCar', 'SplashSmoke', 'SplashEye', 'SplashLeftEye'];

export const IntroScreen: React.FC = () => {
    const [ready, setReady] = useState(false);
    const [visible, setVisible] = useState(true);
    const [mounted, setMounted] = useState(true);
    const [reducedMotion] = useState(() => window.matchMedia('(prefers-reduced-motion: reduce)').matches);

    useEffect(() => {
        let alive = true;
        const fallback = window.setTimeout(() => { if (alive) setReady(true); }, 1500);
        Promise.all(artwork.map(name => new Promise<void>(resolve => {
            const image = new Image();
            image.onload = () => resolve();
            image.onerror = () => resolve();
            image.src = `/brand/${name}.png`;
        }))).then(() => {
            window.clearTimeout(fallback);
            if (alive) setReady(true);
        });
        return () => { alive = false; window.clearTimeout(fallback); };
    }, []);

    useEffect(() => {
        if (!ready) return;
        const duration = reducedMotion ? 490 : 1300;
        const fade = window.setTimeout(() => setVisible(false), duration);
        const remove = window.setTimeout(() => setMounted(false), duration + 220);
        return () => { window.clearTimeout(fade); window.clearTimeout(remove); };
    }, [ready, reducedMotion]);

    if (!mounted) return null;
    return (
        <div aria-hidden="true" className={`brand-splash ${ready ? 'brand-splash--running' : ''} ${visible ? '' : 'brand-splash--finished'}`}>
            <div className="brand-splash__artwork">
                <img className="brand-splash__smoke" src="/brand/SplashSmoke.png" alt="" />
                <div className="brand-splash__car">
                    <img className="brand-splash__body" src="/brand/SplashCar.png" alt="" />
                    <div className="brand-splash__eye brand-splash__eye--left"><img src="/brand/SplashLeftEye.png" alt="" /></div>
                    <div className="brand-splash__eye brand-splash__eye--right"><img src="/brand/SplashEye.png" alt="" /></div>
                </div>
            </div>
        </div>
    );
};
