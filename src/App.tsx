import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Trip } from './types';
import { TripCard } from './components/TripCard';
import { TripDetails } from './components/TripDetails';
import Navbar from './components/Navbar';
import MobileHeader from './components/MobileHeader';
import { tripsAPI, userAPI } from './services/api';
import { useAuth } from './contexts/AuthContext';
import { InterestModal } from './components/InterestModal';
import CreateActivity from './pages/CreateActivity';
import { isNativeApp } from './utils/platform';


const PROVINCES = [
	'ทุกจังหวัด', 'กรุงเทพฯ', 'เชียงใหม่', 'ภูเก็ต', 'ชลบุรี', 'กระบี่',
	'กาญจนบุรี', 'ขอนแก่น', 'นครราชสีมา', 'ประจวบคีรีขันธ์', 'สุราษฎร์ธานี'
];

const CATEGORIES = [
	'ทุกหมวดหมู่', 'กินเที่ยว', 'กีฬา', 'ปาร์ตี้', 'ธรรมชาติ',
	'ถ่ายรูป', 'เวิร์กชอป', 'คอนเสิร์ต'
];

const App = () => {
	const { user } = useAuth();
	const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);
	const [trips, setTrips] = useState<Trip[]>([]);
	const [loading, setLoading] = useState(true);

	// Filters & Tabs
	const [activeTab, setActiveTab] = useState<'แนะนำ' | 'มาใหม่' | 'ยอดนิยม'>('แนะนำ');
	const [selectedProvince, setSelectedProvince] = useState('ทุกจังหวัด');
	const [selectedDate, setSelectedDate] = useState<string>('');
	const [selectedCategory, setSelectedCategory] = useState('ทุกหมวดหมู่');

	// UI States
	const [showProvinceDropdown, setShowProvinceDropdown] = useState(false);
	const [showCategoryDropdown, setShowCategoryDropdown] = useState(false);
	const [showInterestModal, setShowInterestModal] = useState(false);

	useEffect(() => {
		checkUserInterests();
	}, [user]);

	useEffect(() => {
		fetchTrips();
	}, [activeTab, selectedProvince, selectedCategory, selectedDate]);

	const checkUserInterests = async () => {
		if (user) {
			try {
				const profile = await userAPI.getProfile();
				// If user has no interests saved, show modal
				if (!profile.interests || profile.interests.length === 0) {
					setShowInterestModal(true);
				}
			} catch (error) {
				console.error('Error checking interests:', error);
			}
		}
	};

	const fetchTrips = async () => {
		try {
			setLoading(true);
			const filters: any = {};

			if (selectedProvince !== 'ทุกจังหวัด') filters.destination = selectedProvince;
			if (selectedCategory !== 'ทุกหมวดหมู่') filters.category = selectedCategory;
			if (selectedDate) filters.startDate = selectedDate;

			// Map tab to API type
			if (activeTab === 'ยอดนิยม') filters.type = 'popular';
			else if (activeTab === 'แนะนำ') filters.type = 'recommended';
			else filters.type = 'new'; // Default

			const data = await tripsAPI.getAll(filters);
			setTrips(data.trips);
		} catch (error) {
			console.error('Failed to fetch trips:', error);
		} finally {
			setLoading(false);
		}
	};

	const formatDateLabel = (dateStr: string) => {
		if (!dateStr) return 'เลือกวันที่';
		const date = new Date(dateStr);
		return date.toLocaleDateString('th-TH', { day: 'numeric', month: 'short', year: '2-digit' });
	};

	return (
		<div
			className="min-h-screen bg-white flex flex-col text-[#121212] md:pb-0 font-sans"
			style={{
				paddingBottom: isNativeApp() ? 'calc(60px + env(safe-area-inset-bottom, 0px))' : '0'
			}}
		>
			{/* Show Top Navbar ONLY on Desktop */}
			<div className="hidden md:block">
				<Navbar />
			</div>

			<InterestModal
				isOpen={showInterestModal}
				onClose={() => setShowInterestModal(false)}
				onSave={() => {
					setShowInterestModal(false);
					if (activeTab === 'แนะนำ') fetchTrips();
				}}
			/>

			{/* Mobile Header (New Component) */}
			<MobileHeader />

			<main className="flex-1 w-full max-w-6xl mx-auto md:px-6 md:pt-8 overflow-x-hidden">
				{!selectedTrip ? (
					<div className="animate-in fade-in slide-in-from-bottom-4 duration-500">

						{/* Desktop Hero Section */}
						<div className="hidden md:flex flex-col md:flex-row md:items-end justify-between gap-8 mb-12">
							<header className="space-y-4 pt-12">
								<div className="inline-block px-3 py-1 bg-indigo-50 text-indigo-600 text-[10px] font-bold rounded uppercase tracking-widest">
									ประสบการณ์ใหม่
								</div>
								<h1 className="text-7xl font-black text-black tracking-tighter leading-[0.85]">
									ไปกับเรา<br />สนุกกว่า.
								</h1>
							</header>
						</div>

						{/* Categories (Story Style) */}
						<div className="px-6 md:px-0 mb-8 overflow-x-auto no-scrollbar pb-2">
							<div className="flex gap-4 min-w-max">
								<div className="flex flex-col items-center gap-2 cursor-pointer group">
									<div className="w-16 h-16 rounded-full border-2 border-dashed border-gray-300 flex items-center justify-center bg-gray-50 group-hover:border-black transition-colors">
										<span className="text-xl">🔥</span>
									</div>
									<span className="text-[10px] font-bold text-gray-500">ทั้งหมด</span>
								</div>
								{CATEGORIES.slice(1).map((cat, index) => (
									<div
										key={cat}
										onClick={() => setSelectedCategory(cat)}
										className="flex flex-col items-center gap-2 cursor-pointer group"
									>
										<div className={`w-16 h-16 rounded-full p-0.5 border-2 ${selectedCategory === cat ? 'border-indigo-500' : 'border-red-500/30'} flex items-center justify-center`}>
											<div className="w-full h-full rounded-full bg-gray-100 overflow-hidden flex items-center justify-center text-xl font-bold text-gray-400 group-active:scale-95 transition-transform">
												{/* Placeholder Icons based on category */}
												{cat === 'กินเที่ยว' && '🍜'}
												{cat === 'กีฬา' && '⚽️'}
												{cat === 'ปาร์ตี้' && '🎉'}
												{cat === 'ธรรมชาติ' && '🏔️'}
												{cat === 'ถ่ายรูป' && '📸'}
												{cat === 'เวิร์กชอป' && '🎨'}
												{cat === 'คอนเสิร์ต' && '🎸'}
											</div>
										</div>
										<span className={`text-[10px] font-bold ${selectedCategory === cat ? 'text-black' : 'text-gray-500'}`}>{cat}</span>
									</div>
								))}
							</div>
						</div>

						{/* Section: Trending (Horizontal Scroll) */}
						<div className="mb-10">
							<div className="px-6 md:px-0 flex justify-between items-end mb-4">
								<h2 className="text-xl md:text-2xl font-black tracking-tight">กำลังมาแรง 🔥</h2>
								<button className="text-xs font-bold text-indigo-600 hover:text-indigo-800">ดูทั้งหมด</button>
							</div>

							{loading ? (
								<div className="flex px-6 gap-4 overflow-x-auto no-scrollbar">
									{[1, 2, 3].map(i => <div key={i} className="min-w-[280px] h-[340px] bg-gray-100 rounded-3xl animate-pulse" />)}
								</div>
							) : (
								<div className="flex px-6 md:px-0 gap-4 overflow-x-auto no-scrollbar pb-4 snap-x snap-mandatory">
									{trips.map((trip) => (
										<div key={trip.id} className="min-w-[85%] md:min-w-[320px] snap-center">
											<TripCard trip={trip} onClick={setSelectedTrip} />
										</div>
									))}
								</div>
							)}
						</div>

						{/* Section: Suggest for You */}
						<div className="mb-24 md:mb-12 px-6 md:px-0">
							<div className="flex justify-between items-end mb-4">
								<h2 className="text-xl md:text-2xl font-black tracking-tight">แนะนำสำหรับคุณ ✨</h2>
							</div>
							<div className="grid grid-cols-1 md:grid-cols-3 gap-6">
								{trips.slice(0, 3).map((trip) => (
									<TripCard key={trip.id} trip={trip} onClick={setSelectedTrip} />
								))}
							</div>
						</div>

					</div>
				) : (
					<TripDetails trip={selectedTrip} onBack={() => setSelectedTrip(null)} />
				)}
			</main>

			{/* Sidebar / Bottom Nav handled globally */}
		</div>
	);
};

export default App;
