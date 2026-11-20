import { useEffect, useRef, useState } from 'react';

type GoogleIdentity = {
    initialize: (options: { client_id: string; callback: (response: { credential: string }) => void }) => void;
    renderButton: (element: HTMLElement, options: {
        theme: 'outline';
        size: 'large';
        shape: 'pill';
        text: 'continue_with';
        locale: 'th';
        width: string;
    }) => void;
};

const getIdentity = () => (window as Window & { google?: { accounts: { id: GoogleIdentity } } }).google?.accounts.id;
let identityLoader: Promise<GoogleIdentity> | undefined;

function loadGoogleIdentity() {
    if (identityLoader) return identityLoader;
    identityLoader = new Promise<GoogleIdentity>((resolve, reject) => {
        const script = document.createElement('script');
        script.src = 'https://accounts.google.com/gsi/client';
        script.async = true;
        script.onload = () => {
            const identity = getIdentity();
            if (identity) resolve(identity);
            else reject(new Error('Google Identity Services unavailable'));
        };
        script.onerror = () => reject(new Error('Google Identity Services unavailable'));
        document.head.appendChild(script);
    });
    return identityLoader;
}

export default function GoogleSignInButton({ onCredential, disabled }: {
    onCredential: (credential: string) => void;
    disabled: boolean;
}) {
    const clientId = import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID?.trim();
    const container = useRef<HTMLDivElement>(null);
    const callback = useRef(onCredential);
    const [failed, setFailed] = useState(false);

    useEffect(() => { callback.current = onCredential; }, [onCredential]);
    useEffect(() => { container.current?.toggleAttribute('inert', disabled); }, [disabled]);

    useEffect(() => {
        const element = container.current;
        if (!clientId || !element) return;
        let active = true;
        let observer: ResizeObserver | undefined;
        loadGoogleIdentity().then(identity => {
            if (!active) return;
            identity.initialize({
                client_id: clientId,
                callback: ({ credential }) => {
                    if (active && credential) callback.current(credential);
                },
            });
            let previousWidth = 0;
            const render = () => {
                const width = Math.min(element.clientWidth, 400);
                if (!width || width === previousWidth) return;
                previousWidth = width;
                element.replaceChildren();
                identity.renderButton(element, {
                    theme: 'outline',
                    size: 'large',
                    shape: 'pill',
                    text: 'continue_with',
                    locale: 'th',
                    width: String(width),
                });
            };
            render();
            observer = new ResizeObserver(render);
            observer.observe(element);
        }).catch(() => { if (active) setFailed(true); });
        return () => {
            active = false;
            observer?.disconnect();
            element.replaceChildren();
        };
    }, [clientId]);

    if (!clientId) return null;
    return (
        <div className="mt-6">
            <div aria-hidden="true" className="mb-4 flex items-center gap-3 text-xs text-gray-500">
                <span className="h-px flex-1 bg-gray-200" />
                หรือ
                <span className="h-px flex-1 bg-gray-200" />
            </div>
            {failed
                ? <p role="status" className="text-center text-sm text-slate-600">โหลดปุ่ม Google ไม่ได้ กรุณาลองรีเฟรชหน้า</p>
                : <div className={`flex min-h-10 w-full justify-center ${disabled ? 'opacity-50' : ''}`} ref={container} />}
        </div>
    );
}
