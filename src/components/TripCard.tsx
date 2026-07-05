
import React from 'react';
import { Link } from 'react-router-dom';
import { Trip } from '../types';
import { TRIP_CATEGORIES } from '../constants/categories';
import defaultTripImage from '../assets/Sosuke.jpg';

interface TripCardProps {
  trip: Trip;
  onClick?: (trip: Trip) => void;
}

// Helper function to format date in Thai
const formatDateThai = (dateString: string): string => {
  const date = new Date(dateString);
  const thaiMonths = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];
  const thaiDays = ['อาทิตย์', 'จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์', 'เสาร์'];

  const dayName = thaiDays[date.getDay()];
  const day = date.getDate();
  const month = thaiMonths[date.getMonth()];

  return `${dayName}, ${day} ${month}`;
};

export const TripCard: React.FC<TripCardProps> = ({ trip, onClick }) => {
  const participantCount = trip.participants?.length || 0;
  const displayParticipants = participantCount > 0 ? trip.participants.slice(0, 3) : [];

  // Find category with emoji
  const categoryData = TRIP_CATEGORIES.find(c => c.label === trip.category);

  // Status Logic
  const now = new Date();

  // Start Date (00:00:00)
  const start = new Date(trip.startDate);
  start.setHours(0, 0, 0, 0);

  // End Date Logic
  const end = trip.endDate ? new Date(trip.endDate) : new Date(trip.startDate);
  end.setHours(23, 59, 59, 999);

  const isEnded = now > end;

  // Calculate Diff in days (integer)
  const oneDay = 1000 * 60 * 60 * 24;
  const diffTime = start.getTime() - now.getTime();
  const daysLeft = Math.ceil(diffTime / oneDay);

  // Check if it's "Today" (ongoing)
  const isToday = now >= start && now <= end;

  const handleClick = () => {
    if (onClick) onClick(trip);
  };

  return (
    <Link
      to={`/trip/${trip.id}`}
      onClick={handleClick}
      className="group bg-white border border-gray-100 md:border-gray-200 rounded-2xl md:rounded-3xl transition-all duration-500 cursor-pointer flex flex-col items-stretch hover:border-black hover:shadow-xl shadow-sm relative overflow-hidden h-full aspect-square"
    >
      <div className="w-full h-1/2 overflow-hidden bg-gray-50 shrink-0 relative">
        <img
          src={trip.imageUrl || defaultTripImage}
          className={`w-full h-full object-cover transition-all duration-700 group-hover:scale-110 ${isEnded ? 'grayscale opacity-70' : ''}`}
          alt={trip.title}
        />

        {/* Match Score Badge */}
        {(() => {
          const score = trip.matchScore !== undefined 
            ? trip.matchScore 
            : 40 + (Math.abs(trip.id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0)) % 61);

          const tier =
            score >= 76 ? { bg: 'bg-green-50', text: 'text-green-700' } :
            score >= 51 ? { bg: 'bg-blue-50', text: 'text-blue-700' } :
            score >= 26 ? { bg: 'bg-amber-50', text: 'text-amber-700' } :
                          { bg: 'bg-red-50', text: 'text-red-700' };

          return (
            <div className={`absolute top-1.5 left-1.5 md:top-2 md:left-2 ${tier.bg} ${tier.text} px-1.5 py-0.5 md:px-2 md:py-1 rounded-md md:rounded-lg text-[11px] md:text-xs font-black shadow-sm border border-white/50 flex items-center z-10 backdrop-blur-sm bg-opacity-90`}>
              <span>{score}% Match</span>
            </div>
          );
        })()}

        {/* Category Badge */}
        {trip.category && (
          <div className="absolute top-1.5 right-1.5 md:top-2 md:right-2 bg-white/90 backdrop-blur-sm px-1.5 py-0.5 md:px-2 md:py-1 rounded-md md:rounded-lg text-[11px] md:text-xs font-bold shadow-sm border border-white/50 flex items-center gap-1 z-10 text-black">
            <span>{categoryData?.emoji || '✨'}</span>
            <span className="hidden md:inline">{trip.category}</span>
          </div>
        )}
      </div>

      <div className="flex flex-col flex-1 p-2.5 md:p-4 h-1/2">
        <div className="flex items-center justify-between mb-1 md:mb-2">
          <span className={`text-[11px] md:text-xs font-bold tracking-wide ${isEnded ? 'text-gray-400' : 'text-indigo-500'}`}>
            {formatDateThai(trip.startDate)}
          </span>

          {!isEnded ? (
            isToday ? (
              <span className="text-[11px] md:text-xs font-bold text-indigo-600">วันนี้!</span>
            ) : daysLeft > 0 && daysLeft <= 30 ? (
              <span className="text-[11px] md:text-xs font-bold text-gray-400">{daysLeft} วัน</span>
            ) : null
          ) : (
            <span className="text-[11px] md:text-xs font-bold text-gray-300">สิ้นสุด</span>
          )}
        </div>

        <h3 className={`text-base md:text-xl font-black leading-tight tracking-tight mb-1 ${isEnded ? 'text-gray-400 line-through decoration-2' : 'text-black'} line-clamp-2`}>
          {trip.title}
        </h3>

        <p className="text-gray-400 font-bold text-xs md:text-sm tracking-wide mb-2 line-clamp-1">
          {trip.destination}
        </p>

        <div className="mt-auto flex items-center justify-between pt-2 border-t border-gray-50 w-full">
          <div className="flex items-center gap-1.5 md:gap-3">
            {participantCount > 0 ? (
              <>
                <div className="flex -space-x-2 md:-space-x-3">
                  {displayParticipants.slice(0, 2).map((participant) => (
                    <div key={participant.id} className="w-5 h-5 md:w-8 md:h-8 rounded-full border border-white md:border-2 bg-gray-100 overflow-hidden">
                      <img
                        src={participant.user?.profileImage || `https://api.dicebear.com/7.x/avataaars/svg?seed=${participant.id}`}
                        alt={participant.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                  ))}
                </div>
                <span className="text-xs md:text-sm font-bold text-black whitespace-nowrap">
                  {participantCount} คน
                </span>
              </>
            ) : (
              <span className="text-xs md:text-sm font-medium text-gray-400 whitespace-nowrap">
                0 คน
              </span>
            )}
          </div>
        </div>
      </div>
    </Link>
  );
};
