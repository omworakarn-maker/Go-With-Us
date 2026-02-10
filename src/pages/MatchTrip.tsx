import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { SparklesIcon, MapIcon, ArrowPathIcon } from '@heroicons/react/24/outline';
import { matchAPI, MatchTrip as MatchTripType } from '../services/matchService';
import { TripCard } from '../components/TripCard';

const MatchTrip: React.FC = () => {
  const [matches, setMatches] = useState<MatchTripType[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchMatches();
  }, []);

  const fetchMatches = async () => {
    try {
      setLoading(true);
      const data = await matchAPI.getTripMatches();
      setMatches(data.matches || []);
    } catch (err) {
      console.error("Failed to fetch trip matches:", err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white relative overflow-x-hidden font-sans pb-24">
      <main className="relative z-10 w-full max-w-6xl mx-auto px-6 pt-8 pb-12">
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-12">
          <div>
            <div className="inline-block px-3 py-1 bg-black text-white text-[10px] font-bold rounded uppercase tracking-widest mb-4">RECOMMENDED</div>
            <h1 className="text-6xl md:text-7xl font-black tracking-tighter leading-[0.85] text-black">
              แมตช์ทริป
            </h1>
            <p className="text-gray-400 text-lg font-medium mt-4 max-w-xl">
              ทริปที่คัดสรรมาเพื่อคุณโดยเฉพาะ จากสไตล์การท่องเที่ยวของคุณ
            </p>
          </div>

          <button
            onClick={fetchMatches}
            disabled={loading}
            className="p-3 bg-gray-50 border border-gray-100 rounded-full hover:bg-gray-100 transition-colors shadow-sm self-start md:self-auto"
          >
            <ArrowPathIcon className={`w-6 h-6 text-black ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[1, 2, 3].map(i => (
              <div key={i} className="aspect-[4/3] bg-gray-100 rounded-3xl animate-pulse"></div>
            ))}
          </div>
        ) : matches.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {matches.map((trip) => (
              <div key={trip.id} className="relative group">
                <div className="absolute -top-3 -right-3 z-20 bg-black text-white text-[10px] font-bold px-3 py-1.5 rounded-full border-4 border-white shadow-xl transform group-hover:scale-110 transition-transform">
                  {trip.matchScore}% Match
                </div>
                {/* Reusing TripCard component but mapped to MatchTrip interface */}
                <TripCard trip={trip as any} />
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-20 bg-gray-50 rounded-3xl border border-dashed border-gray-200">
            <MapIcon className="w-20 h-20 text-gray-300 mx-auto mb-4" />
            <h3 className="text-xl font-bold text-gray-900">ยังไม่พบทริปที่แมตช์กับคุณ</h3>
            <p className="text-gray-500 mt-2 mb-8">
              ลองเพิ่มความสนใจในโปรไฟล์ หรือค้นหาทริปอื่นๆ ดูสิ
            </p>
            <Link to="/" className="px-8 py-3 bg-black text-white rounded-full font-bold hover:bg-gray-800 transition-colors shadow-lg shadow-black/20">
              ค้นหาทริปทั่วไป
            </Link>
          </div>
        )}
      </main>
    </div>
  );
};

export default MatchTrip;
