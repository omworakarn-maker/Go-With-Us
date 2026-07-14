import React, { useState, useEffect } from 'react';
import { Trip } from '../types';
import { TripCard } from '../components/TripCard';
import { TripDetails } from '../components/TripDetails';
import { tripsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { useModal } from '../contexts/ModalContext'; // Import Modal Context
import Loader from '../components/Loader';

const MyTrips: React.FC = () => {
  const { user } = useAuth();
  const navigate = useNavigate();
  const { openCreateModal } = useModal(); // Use global modal
  const [loading, setLoading] = useState(true);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [activeTab, setActiveTab] = useState<'created' | 'joined' | 'interested'>('created');
  const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!user) {
      navigate('/login');
      return;
    }
    fetchMyTrips();
  }, [user, navigate]);

  const fetchMyTrips = async () => {
    try {
      setLoading(true);
      const response = await tripsAPI.getAll();
      setTrips(response.trips || []);
    } catch (err) {
      console.error('Failed to fetch my trips:', err);
      setError('ไม่สามารถโหลดข้อมูลทริปของคุณได้');
    } finally {
      setLoading(false);
    }
  };

  if (selectedTrip) {
    return <TripDetails trip={selectedTrip} onBack={() => setSelectedTrip(null)} />;
  }

  const filteredTrips = trips.filter(trip => {
    if (activeTab === 'created') return trip.creatorId === user?.id;
    if (activeTab === 'joined') return trip.participants?.some(p => p.userId === user?.id && p.status === 'going');
    if (activeTab === 'interested') return trip.participants?.some(p => p.userId === user?.id && p.status === 'interested');
    return false;
  });

  const getEmptyMessage = () => {
    if (activeTab === 'created') return 'คุณยังไม่มีทริปที่สร้าง';
    if (activeTab === 'joined') return 'คุณยังไม่ได้เข้าร่วมทริปใดเลย';
    return 'ยังไม่มีทริปในรายการโปรด';
  };

  return (
    <div className="min-h-screen bg-[#FFFFFF] flex flex-col text-[#121212]">


      <main className="flex-1 w-full max-w-6xl mx-auto px-6 pt-8 pb-24">
        <header className="mb-8">
          <div className="inline-block px-3 py-1 bg-black text-white text-[10px] font-bold rounded uppercase tracking-widest mb-4">My Trips</div>
          <h1 className="text-5xl font-black tracking-tight text-black mb-4">ทริปของฉัน.</h1>
          <p className="text-gray-400 text-lg font-medium max-w-xl">
            จัดการทริปและกิจกรรมของคุณ ติดตามผู้เข้าร่วม และดูทริปที่น่าสนใจ
          </p>
        </header>

        {/* Tabs */}
        <div className="flex gap-4 mb-8 overflow-x-auto pb-2 scrollbar-hide">
          <button 
            onClick={() => setActiveTab('created')}
            className={`px-6 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-all ${activeTab === 'created' ? 'bg-black text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'}`}
          >
            สร้างเอง
          </button>
          <button 
            onClick={() => setActiveTab('joined')}
            className={`px-6 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-all ${activeTab === 'joined' ? 'bg-black text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'}`}
          >
            เข้าร่วมแล้ว
          </button>
          <button 
            onClick={() => setActiveTab('interested')}
            className={`px-6 py-2 rounded-full text-sm font-bold whitespace-nowrap transition-all ${activeTab === 'interested' ? 'bg-black text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'}`}
          >
            รายการโปรด
          </button>
        </div>

        {loading ? (
          <Loader variant="dots" />
        ) : error ? (
          <div className="py-20 text-center border border-dashed border-red-200 rounded-3xl bg-red-50">
            <p className="text-red-600 font-medium mb-4">{error}</p>
            <button
              onClick={fetchMyTrips}
              className="text-xs font-bold text-black hover:underline"
            >
              ลองอีกครั้ง
            </button>
          </div>
        ) : filteredTrips.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 md:gap-12">
            {filteredTrips.map((trip) => (
              <TripCard key={trip.id} trip={trip} />
            ))}
          </div>
        ) : (
          <div className="py-32 text-center border-2 border-dashed border-gray-100 rounded-[2.5rem] bg-gray-50/50">
            <div className="w-24 h-24 bg-black rounded-full flex items-center justify-center mx-auto mb-6 shadow-xl shadow-black/10">
              <svg className="w-10 h-10 text-white" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
              </svg>
            </div>
            <h3 className="text-2xl font-bold text-black mb-3">{getEmptyMessage()}</h3>
            {activeTab === 'created' ? (
              <>
                <p className="text-gray-400 max-w-md mx-auto mb-8">
                  เริ่มสร้างทริปแรกของคุณและชวนเพื่อนใหม่ๆ มาร่วมเดินทางไปด้วยกัน
                </p>
                <button
                  onClick={openCreateModal} // Use global modal
                  className="px-8 py-3 bg-black text-white text-sm font-bold rounded-full hover:bg-gray-800 transition-all shadow-lg shadow-black/20"
                >
                  สร้างทริปเลย
                </button>
              </>
            ) : (
              <p className="text-gray-400 max-w-md mx-auto mb-8">
                ค้นหาทริปที่คุณสนใจในหน้าแรกและกดเข้าร่วมเพื่อเริ่มการเดินทาง
              </p>
            )}
          </div>
        )}
      </main>
    </div>
  );
};

export default MyTrips;
