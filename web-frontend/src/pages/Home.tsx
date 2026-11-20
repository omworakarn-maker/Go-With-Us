import { AdjustmentsHorizontalIcon, MagnifyingGlassIcon, QueueListIcon, Squares2X2Icon, XMarkIcon } from '@heroicons/react/24/outline';
import React, { useState, useEffect } from 'react';
import FilterBar from '../components/FilterBar';
import { Trip } from '../types';
import { TripCard } from '../components/TripCard';
import { tripsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import { TRIP_CATEGORIES } from '../constants/categories';
import Loader from '../components/Loader';

const PROVINCES = [
  'ทุกจังหวัด', 'กรุงเทพฯ', 'กระบี่', 'กาญจนบุรี', 'กาฬสินธุ์', 'กำแพงเพชร', 'ขอนแก่น', 'จันทบุรี', 'ฉะเชิงเทรา', 'ชลบุรี', 'ชัยนาท', 'ชัยภูมิ', 'ชุมพร', 'เชียงราย', 'เชียงใหม่', 'ตรัง', 'ตราด', 'ตาก', 'นครนายก', 'นครปฐม', 'นครพนม', 'นครราชสีมา', 'นครศรีธรรมราช', 'นครสวรรค์', 'นนทบุรี', 'นราธิวาส', 'น่าน', 'บึงกาฬ', 'บุรีรัมย์', 'ปทุมธานี', 'ประจวบคีรีขันธ์', 'ปราจีนบุรี', 'ปัตตานี', 'พระนครศรีอยุธยา', 'พะเยา', 'พังงา', 'พัทลุง', 'พิจิตร', 'พิษณุโลก', 'เพชรบุรี', 'เพชรบูรณ์', 'แพร่', 'ภูเก็ต', 'มหาสารคาม', 'มุกดาหาร', 'แม่ฮ่องสอน', 'ยโสธร', 'ยะลา', 'ร้อยเอ็ด', 'ระนอง', 'ระยอง', 'ราชบุรี', 'ลพบุรี', 'ลำปาง', 'ลำพูน', 'เลย', 'ศรีสะเกษ', 'สกลนคร', 'สงขลา', 'สตูล', 'สมุทรปราการ', 'สมุทรสงคราม', 'สมุทรสาคร', 'สระแก้ว', 'สระบุรี', 'สิงห์บุรี', 'สุโขทัย', 'สุพรรณบุรี', 'สุราษฎร์ธานี', 'สุรินทร์', 'หนองคาย', 'หนองบัวลำภู', 'อ่างทอง', 'อำนาจเจริญ', 'อุดรธานี', 'อุตรดิตถ์', 'อุทัยธานี', 'อุบลราชธานี'
];

const CATEGORIES_FILTER = ['ทุกหมวดหมู่', ...TRIP_CATEGORIES.map(c => c.label)];

const Home: React.FC = () => {
  const { user } = useAuth();
  const [trips, setTrips] = useState<Trip[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('แนะนำ');
  const [gridLayout, setGridLayout] = useState(false);

  // Filters
  const [searchText, setSearchText] = useState('');
  const [selectedProvince, setSelectedProvince] = useState('ทุกจังหวัด');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('ทุกหมวดหมู่');

  useEffect(() => {
    fetchTrips();
  }, []);

  const fetchTrips = async () => {
    try {
      setLoading(true);
      const response = await tripsAPI.getAll();
      setTrips(response.trips || []);
      setError('');
    } catch (err: any) {
      console.error('Failed to fetch trips:', err);
      setError('ไม่สามารถโหลดทริปได้');
      setTrips([]);
    } finally {
      setLoading(false);
    }
  };

  const query = searchText.trim().toLocaleLowerCase();
  const hasFilters = Boolean(query || startDate || endDate ||
    selectedProvince !== PROVINCES[0] || selectedCategory !== CATEGORIES_FILTER[0]);

  const clearFilters = () => {
    setSearchText('');
    setSelectedProvince(PROVINCES[0]);
    setSelectedCategory(CATEGORIES_FILTER[0]);
    setStartDate('');
    setEndDate('');
  };

  const filteredTrips = trips.filter(trip => {
    const searchMatch = !query || [trip.title, trip.destination, trip.description]
      .some(value => value?.toLocaleLowerCase().includes(query));
    const provinceMatch = selectedProvince === PROVINCES[0] || trip.destination.includes(selectedProvince);
    const tripStart = trip.startDate.split('T')[0];
    const dateMatch = (!startDate || tripStart >= startDate) && (!endDate || tripStart <= endDate);
    const categoryMatch = selectedCategory === 'ทุกหมวดหมู่' || trip.category === selectedCategory;

    return searchMatch && provinceMatch && dateMatch && categoryMatch;
  }).sort((a, b) => {
    if (activeTab === 'ยอดนิยม') {
      const countA = a.participants?.length || 0;
      const countB = b.participants?.length || 0;
      if (countA !== countB) return countB - countA;
      // Secondary sort for popular is newness
      const dateA = new Date(a.createdAt || 0).getTime();
      const dateB = new Date(b.createdAt || 0).getTime();
      return dateB - dateA;
    }

    if (activeTab === 'มาใหม่') {
      const dateA = new Date(a.createdAt || 0).getTime();
      const dateB = new Date(b.createdAt || 0).getTime();
      return dateB - dateA;
    }

    if (activeTab === 'แนะนำ') {
      const userInterests = user?.interests || [];
      // Check if trip category is in user interests
      const aMatch = userInterests.includes(a.category || '') ? 1 : 0;
      const bMatch = userInterests.includes(b.category || '') ? 1 : 0;

      // Prioritize matched interests
      if (aMatch !== bMatch) {
        return bMatch - aMatch;
      }

      // Secondary sort for recommended: Recency
      const dateA = new Date(a.createdAt || 0).getTime();
      const dateB = new Date(b.createdAt || 0).getTime();
      return dateB - dateA;
    }

    return 0;
  });

  const LayoutIcon = gridLayout ? QueueListIcon : Squares2X2Icon;

  return (
    <main className="min-h-screen bg-slate-50 px-4 pb-10 pt-5 text-slate-900 sm:px-6">
      <div className="mx-auto w-full max-w-6xl">
        <div className="mb-5 space-y-3 rounded-2xl border border-slate-200 bg-white p-3 sm:p-4">
          <div className="flex gap-2">
            <div className="relative flex min-w-0 flex-1 items-center rounded-full border border-slate-200 bg-white focus-within:border-blue-500">
              <MagnifyingGlassIcon aria-hidden="true" className="pointer-events-none absolute left-4 h-5 w-5 text-slate-500" />
              <input
                type="search"
                aria-label="ค้นหาทริป"
                placeholder="ค้นหาทริปหรือจุดหมาย"
                value={searchText}
                onChange={(event) => setSearchText(event.target.value)}
                className="min-h-11 w-full rounded-full bg-transparent py-2 pl-11 pr-4 text-base outline-none"
              />
            </div>
            <button
              type="button"
              aria-label={gridLayout ? 'แสดงทริปแบบรายการ' : 'แสดงทริปแบบตาราง'}
              title={gridLayout ? 'แสดงแบบรายการ' : 'แสดงแบบตาราง'}
              onClick={() => setGridLayout(!gridLayout)}
              className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-slate-200 bg-white text-blue-600 hover:bg-blue-50"
            >
              <LayoutIcon aria-hidden="true" className="h-5 w-5" />
            </button>
          </div>

          <details>
            <summary className="flex w-fit cursor-pointer list-none items-center gap-2 rounded-full bg-slate-100 px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-200 [&::-webkit-details-marker]:hidden">
              <AdjustmentsHorizontalIcon aria-hidden="true" className="h-4 w-4" />
              {selectedProvince !== PROVINCES[0] || selectedCategory !== CATEGORIES_FILTER[0] || startDate || endDate ? 'ตัวกรองที่ใช้อยู่' : 'ตัวกรอง'}
            </summary>
            <div className="space-y-3 pt-3">
              <FilterBar
                provinces={PROVINCES}
                categories={CATEGORIES_FILTER}
                selectedProvince={selectedProvince}
                setSelectedProvince={setSelectedProvince}
                selectedCategory={selectedCategory}
                setSelectedCategory={setSelectedCategory}
                startDate={startDate}
                setStartDate={setStartDate}
                endDate={endDate}
                setEndDate={setEndDate}
              />
              {hasFilters && (
                <button type="button" onClick={clearFilters} className="inline-flex items-center gap-1 px-2 text-sm font-semibold text-blue-700 hover:underline">
                  <XMarkIcon aria-hidden="true" className="h-4 w-4" />
                  ล้างตัวกรอง
                </button>
              )}
            </div>
          </details>

          <div role="group" aria-label="เรียงทริป" className="grid grid-cols-3 gap-1 rounded-full bg-slate-100 p-1 sm:max-w-sm">
            {['แนะนำ', 'มาใหม่', 'ยอดนิยม'].map((tab) => (
              <button
                key={tab}
                type="button"
                aria-pressed={activeTab === tab}
                onClick={() => setActiveTab(tab)}
                className={`min-h-10 rounded-full px-2 text-sm font-semibold transition-colors ${activeTab === tab ? 'bg-white text-blue-700 shadow-sm' : 'text-slate-600 hover:text-slate-900'}`}
              >
                {tab}
              </button>
            ))}
          </div>
        </div>

        {loading ? (
          <div role="status" aria-label="กำลังโหลดทริป"><Loader /></div>
        ) : error ? (
          <div role="alert" className="rounded-3xl border border-slate-200 bg-white px-4 py-12 text-center">
            <p className="font-medium text-slate-700">{error}</p>
            <button type="button" onClick={fetchTrips} className="mt-4 rounded-full bg-blue-600 px-5 py-2 text-sm font-semibold text-white hover:bg-blue-700">
              ลองอีกครั้ง
            </button>
          </div>
        ) : filteredTrips.length > 0 ? (
          <div className={`grid gap-4 ${gridLayout ? 'grid-cols-2 md:grid-cols-3' : 'grid-cols-1 lg:grid-cols-2'}`}>
            {filteredTrips.map((trip) => (
              <TripCard key={trip.id} trip={trip} layout={gridLayout ? 'feed' : 'list'} />
            ))}
          </div>
        ) : (
          <p role="status" className="rounded-3xl border border-slate-200 bg-white px-4 py-12 text-center font-medium text-slate-600">
            {hasFilters ? 'ไม่พบทริปที่ตรงกับการค้นหา' : 'ยังไม่มีทริปให้แสดง'}
          </p>
        )}
      </div>
    </main>
  );
};

export default Home;
