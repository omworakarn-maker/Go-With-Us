import React, { useState, useEffect } from 'react';
import { Trip } from '../types';
import { TripCard } from '../components/TripCard';
import { TripDetails } from '../components/TripDetails';
import { tripsAPI } from '../services/api';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import Loader from '../components/Loader';

const TripHistory: React.FC = () => {
    const { user, isLoading } = useAuth();
    const navigate = useNavigate();
    const [loading, setLoading] = useState(true);
    const [trips, setTrips] = useState<Trip[]>([]);
    const [selectedTrip, setSelectedTrip] = useState<Trip | null>(null);
    const [error, setError] = useState('');

    useEffect(() => {
        if (isLoading) return; // Wait for auth check

        if (!user) {
            navigate('/login');
            return;
        }
        fetchHistoryInTrips();
    }, [user, isLoading, navigate]);

    const fetchHistoryInTrips = async () => {
        try {
            setLoading(true);
            const response = await tripsAPI.getAll();
            const allTrips = response.trips || [];

            // Filter for past trips that the user was involved in
            const historyTrips = allTrips.filter((trip: Trip) => {
                const isParticipant = trip.creatorId === user?.id || trip.participants?.some((p: any) => p.id === user?.id);

                // Check if trip is in the past
                const endDate = new Date(trip.endDate);
                const now = new Date();
                const isPast = endDate < now;

                return isParticipant && isPast;
            });

            setTrips(historyTrips);
        } catch (err) {
            console.error('Failed to fetch trip history:', err);
            setError('ไม่สามารถโหลดประวัติทริปได้');
        } finally {
            setLoading(false);
        }
    };

    if (selectedTrip) {
        return <TripDetails trip={selectedTrip} onBack={() => setSelectedTrip(null)} />;
    }

    return (
        <div className="min-h-screen bg-[#FFFFFF] flex flex-col text-[#121212]">
            <main className="flex-1 w-full max-w-6xl mx-auto px-6 pt-8 pb-24">
                <header className="mb-12">
                    <div className="flex items-center gap-4 mb-4">
                        <button
                            onClick={() => navigate('/profile')}
                            className="w-10 h-10 rounded-full border border-gray-200 flex items-center justify-center hover:bg-gray-50 transition-colors"
                        >
                            <svg className="w-5 h-5 text-gray-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                            </svg>
                        </button>
                        <div className="inline-block px-3 py-1 bg-gray-100 text-gray-600 text-[10px] font-bold rounded uppercase tracking-widest">
                            Past Journeys
                        </div>
                    </div>

                    <h1 className="text-5xl font-black tracking-tight text-black mb-4">ประวัติการเดินทาง.</h1>
                    <p className="text-gray-400 text-lg font-medium max-w-xl">
                        รวบรวมความทรงจำจากการเดินทางที่ผ่านมาทั้งหมดของคุณไว้ที่นี่
                    </p>
                </header>

                {loading ? (
                    <Loader variant="dots" />
                ) : error ? (
                    <div className="py-20 text-center border border-dashed border-red-200 rounded-3xl bg-red-50">
                        <p className="text-red-600 font-medium mb-4">{error}</p>
                        <button
                            onClick={fetchHistoryInTrips}
                            className="text-xs font-bold text-black hover:underline"
                        >
                            ลองอีกครั้ง
                        </button>
                    </div>
                ) : trips.length > 0 ? (
                    <div className="grid grid-cols-2 lg:grid-cols-3 gap-3 md:gap-12">
                        {trips.map((trip) => (
                            <TripCard key={trip.id} trip={trip} />
                        ))}
                    </div>
                ) : (
                    <div className="py-32 text-center border-2 border-dashed border-gray-100 rounded-[2.5rem] bg-gray-50/50">
                        <div className="w-24 h-24 bg-gray-100 rounded-full flex items-center justify-center mx-auto mb-6">
                            <svg className="w-10 h-10 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                        </div>
                        <h3 className="text-2xl font-bold text-black mb-3">ยังไม่มีประวัติการเดินทาง</h3>
                        <p className="text-gray-400 max-w-md mx-auto mb-8">
                            เมื่อคุณเข้าร่วมหรือสร้างทริปและทริปนั้นสิ้นสุดลง ข้อมูลจะมาปรากฏที่นี่
                        </p>
                        <button
                            onClick={() => navigate('/explore')}
                            className="px-8 py-3 bg-black text-white text-sm font-bold rounded-full hover:bg-gray-800 transition-all shadow-lg shadow-black/20"
                        >
                            ค้นหาทริปใหม่
                        </button>
                    </div>
                )}
            </main>
        </div>
    );
};

export default TripHistory;
