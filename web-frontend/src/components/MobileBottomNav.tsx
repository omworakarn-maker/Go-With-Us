import { ArrowPathIcon, ChatBubbleOvalLeftIcon, HomeIcon, PlusIcon, UserIcon } from '@heroicons/react/24/outline';
import { NavLink, useNavigate } from 'react-router-dom';
import { useModal } from '../contexts/ModalContext';
import { useAuth } from '../contexts/AuthContext';

const tabs = [
    { label: 'หน้าหลัก', path: '/', Icon: HomeIcon },
    { label: 'แมตช์ทริป', path: '/activities', Icon: ArrowPathIcon },
    { label: 'แชท', path: '/chat', Icon: ChatBubbleOvalLeftIcon },
    { label: 'โปรไฟล์', path: '/profile', Icon: UserIcon },
];

const surface = 'border border-white/70 bg-white/85 shadow-lg shadow-slate-900/15 backdrop-blur-xl';

const MobileBottomNav = () => {
    const navigate = useNavigate();
    const { openCreateModal } = useModal();
    const { isAuthenticated } = useAuth();

    return (
        <nav
            aria-label="เมนูหลัก"
            className="fixed inset-x-0 bottom-0 z-[1000] mx-auto flex max-w-md items-center gap-2 px-3 md:hidden"
            style={{ paddingBottom: 'calc(0.75rem + env(safe-area-inset-bottom, 0px))' }}
        >
            <div className={`grid min-w-0 flex-1 grid-cols-4 rounded-full p-1 ${surface}`}>
                {tabs.map(({ label, path, Icon }) => (
                    <NavLink
                        key={path}
                        to={path}
                        end
                        className={({ isActive }) =>
                            `flex min-h-12 flex-col items-center justify-center gap-0.5 rounded-full text-center text-[10px] font-semibold transition-colors ${isActive ? 'bg-blue-50 text-blue-600' : 'text-slate-700 hover:bg-slate-100'}`
                        }
                    >
                        <Icon className="h-5 w-5" aria-hidden="true" />
                        <span>{label}</span>
                    </NavLink>
                ))}
            </div>
            <button
                type="button"
                aria-label="สร้างทริป"
                onClick={() => {
                    if (isAuthenticated) openCreateModal();
                    else navigate('/login');
                }}
                className={`flex h-14 w-14 shrink-0 items-center justify-center rounded-full text-blue-600 transition-colors hover:bg-blue-50 ${surface}`}
            >
                <PlusIcon className="h-6 w-6" aria-hidden="true" />
            </button>
        </nav>
    );
};

export default MobileBottomNav;
