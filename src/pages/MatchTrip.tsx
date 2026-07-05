import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { SparklesIcon, MapIcon, ArrowPathIcon } from '@heroicons/react/24/outline';
import { matchAPI, MatchTrip as MatchTripType } from '../services/matchService';
import { TripCard } from '../components/TripCard';

const MatchTripPage: React.FC = () => {
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
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 md:gap-8">
            {[1, 2, 3].map(i => (
              <div key={i} className="aspect-[4/3] bg-gray-100 rounded-3xl animate-pulse"></div>
            ))}
          </div>
        ) : matches.length > 0 ? (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3 md:gap-8">
            {matches.map((trip) => {
              const score = trip.matchScore;

              // 4-tier match system
              const tier =
                score >= 76 ? {
                  color: '#16a34a',
                  bg: 'bg-green-50 border-green-200',
                  text: 'text-green-700',
                  label: 'ดีเยี่ยม',
                  sublabel: 'เนื้อคู่ร่วมทริป',
                  desc: 'มีความชอบตรงกันเกือบทุกด้าน ทั้งงบประมาณและกิจกรรม เหมาะกับการเดินทางระยะยาว',
                } : score >= 51 ? {
                  color: '#2563eb',
                  bg: 'bg-blue-50 border-blue-200',
                  text: 'text-blue-700',
                  label: 'ปานกลาง',
                  sublabel: 'พอไปกันได้',
                  desc: 'มีจุดร่วมหลักที่ตรงกัน แต่อาจมีไลฟ์สไตล์ปลีกย่อยที่ต่างกันบ้าง',
                } : score >= 26 ? {
                  color: '#d97706',
                  bg: 'bg-amber-50 border-amber-200',
                  text: 'text-amber-700',
                  label: 'ค่อนข้างต่ำ',
                  sublabel: 'ต้องปรับตัวสูง',
                  desc: 'มีจุดที่สนใจตรงกันเพียง 1-2 อย่าง หากร่วมทริปต้องมีการประนีประนอมอย่างมาก',
                } : {
                  color: '#dc2626',
                  bg: 'bg-red-50 border-red-200',
                  text: 'text-red-700',
                  label: 'ไม่แนะนำ',
                  sublabel: 'ไลฟ์สไตล์ต่างกันสิ้นเชิง',
                  desc: 'แทบไม่มีจุดร่วมในความสนใจเลย ไม่แนะนำให้ร่วมทริปกัน',
                };

              const circumference = 2 * Math.PI * 20;
              const dashOffset = circumference - (score / 100) * circumference;

              return (
                <div key={trip.id} className="flex flex-col gap-3">
                  {/* Match Score Card */}
                  <div className={`flex items-center gap-4 px-4 py-3 rounded-2xl border-2 ${tier.bg}`}>
                    {/* Circular ring */}
                    <div className="relative w-14 h-14 flex-shrink-0">
                      <svg className="w-14 h-14 -rotate-90" viewBox="0 0 48 48">
                        <circle cx="24" cy="24" r="20" fill="none" stroke="#e5e7eb" strokeWidth="4" />
                        <circle
                          cx="24" cy="24" r="20" fill="none"
                          stroke={tier.color} strokeWidth="4"
                          strokeDasharray={circumference}
                          strokeDashoffset={dashOffset}
                          strokeLinecap="round"
                          style={{ transition: 'stroke-dashoffset 0.6s ease' }}
                        />
                      </svg>
                      <span className={`absolute inset-0 flex items-center justify-center text-sm font-black ${tier.text}`}>
                        {score}%
                      </span>
                    </div>

                    {/* Text info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <p className={`text-base font-black ${tier.text} leading-tight`}>{tier.label}</p>
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full bg-white/70 ${tier.text} border border-current/20`}>
                          {tier.sublabel}
                        </span>
                      </div>
                      <p className={`text-[11px] leading-snug ${tier.text} opacity-80`}>{tier.desc}</p>
                      {/* Progress bar */}
                      <div className="mt-2 w-full h-1.5 bg-white/70 rounded-full overflow-hidden">
                        <div
                          className="h-full rounded-full transition-all duration-500"
                          style={{ width: `${score}%`, backgroundColor: tier.color }}
                        />
                      </div>
                    </div>
                  </div>

                  {/* Trip Card */}
                  <TripCard trip={trip as any} />
                </div>
              );
            })}
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

export default MatchTripPage;
