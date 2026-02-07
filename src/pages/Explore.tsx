import React, { useState, useEffect, useRef } from 'react';
import { Trip } from '../types';
import { tripsAPI } from '../services/api';
import { exploreTrips } from '../services/geminiService';
import Loader from '../components/Loader';
import { TripCard } from '../components/TripCard'; // Keep if used or remove if unused, but based on code below it seems used or similar
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

interface ProposedTrip {
  title: string;
  destination: string;
  description: string;
  startDate: string;
  endDate: string;
  budget: string;
  category: string;
}

interface Message {
  id: string;
  sender: 'user' | 'ai';
  text: string;
  relatedTrips?: Trip[];
  proposedTrip?: ProposedTrip;
}

const SUGGESTIONS = [
  "ทริปทะเลงบประหยัด",
  "ที่เที่ยวใกล้กรุงเทพฯ",
  "หาเพื่อนปีนเขา",
  "คาเฟ่ถ่ายรูปสวยๆ",
  "ทริปสายบุญไหว้พระ",
];

const Explore: React.FC = () => {
  const { user } = useAuth();
  const [messages, setMessages] = useState<Message[]>([
    {
      id: '1',
      sender: 'ai',
      text: user
        ? `สวัสดีครับคุณ ${user.name}! 👋 ผมคือ AI Explorer \nอ้างอิงจากความสนใจของคุณ ผมพอจะช่วยแนะนำทริปได้นะครับ หรืออยากไปไหนบอกผมได้เลย!`
        : 'สวัสดีครับ! ผมคือ AI Explorer 🤖\nอยากให้ช่วยแนะนำที่เที่ยว หรือค้นหาทริปแบบไหน บอกได้เลยครับ!',
    },
  ]);
  const [inputText, setInputText] = useState('');
  const [loading, setLoading] = useState(false);
  const [allTrips, setAllTrips] = useState<Trip[]>([]);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();

  useEffect(() => {
    // Fetch trips once for context
    const fetchTrips = async () => {
      try {
        const data = await tripsAPI.getAll({});
        setAllTrips(data.trips);
      } catch (error) {
        console.error("Failed to fetch trips for AI context", error);
      }
    };
    fetchTrips();
  }, []);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Create Trip Function
  const handleCreateTrip = async (tripData: ProposedTrip) => {
    if (!user) {
      alert("กรุณาเข้าสู่ระบบก่อนสร้างทริป");
      navigate('/login');
      return;
    }

    if (window.confirm(`ยืนยันสร้างทริป "${tripData.title}" ใช่หรือไม่?`)) {
      try {
        setLoading(true);
        const res = await tripsAPI.create({
          title: tripData.title,
          destination: tripData.destination,
          description: tripData.description,
          startDate: tripData.startDate,
          endDate: tripData.endDate,
          budget: tripData.budget,
          category: tripData.category,
          maxParticipants: 10, // Default
          imageUrl: "" // Default empty
        });

        // Navigate to new trip
        navigate(`/trip/${res.trip.id}`);
      } catch (error) {
        console.error("Failed to create trip:", error);
        alert("ไม่สามารถสร้างทริปได้ กรุณาลองใหม่");
      } finally {
        setLoading(false);
      }
    }
  };

  const handleSendMessage = async (text: string) => {
    if (!text.trim()) return;

    // Add User Message
    const userMsg: Message = { id: Date.now().toString(), sender: 'user', text };
    setMessages(prev => [...prev, userMsg]);
    setInputText('');
    setLoading(true);

    try {
      // Call AI with User Profile
      const userProfile = user ? { name: user.name, interests: user.interests || [] } : undefined;
      const result = await exploreTrips(text, allTrips, userProfile);

      // Find related trips objects
      const relatedTrips = allTrips.filter(t => result.suggestedTripIds?.includes(t.id));

      const aiMsg: Message = {
        id: (Date.now() + 1).toString(),
        sender: 'ai',
        text: result.answer,
        relatedTrips: relatedTrips.length > 0 ? relatedTrips : undefined,
        proposedTrip: result.proposedTrip || undefined
      };

      setMessages(prev => [...prev, aiMsg]);
    } catch (error) {
      setMessages(prev => [...prev, {
        id: Date.now().toString(),
        sender: 'ai',
        text: 'ขออภัยครับ เกิดข้อผิดพลาดในการเชื่อมต่อกับ AI ลองใหม่อีกครั้งนะครับ 😅 ' + (error as any).message
      }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-white flex flex-col text-[#121212]">


      <div className="flex-1 flex flex-col max-w-4xl mx-auto w-full pt-8 pb-6 px-4">
        {/* Header */}
        <div className="text-center mb-8 animate-in slide-in-from-top-4">
          <div className="w-16 h-16 bg-black rounded-2xl mx-auto mb-4 flex items-center justify-center shadow-lg">
            <div className="w-3 h-3 bg-white rounded-full"></div>
          </div>
          <h1 className="text-3xl font-black tracking-tight mb-2">Ai assistant</h1>
          <p className="text-gray-500 text-sm">พร้อมช่วยแล้วครับ...</p>
        </div>

        {/* Chat Area */}
        <div className="flex-1 overflow-y-auto no-scrollbar mb-6 space-y-6 px-2">
          {messages.map((msg) => (
            <div
              key={msg.id}
              className={`flex flex-col ${msg.sender === 'user' ? 'items-end' : 'items-start'}`}
            >
              <div
                className={`max-w-[85%] md:max-w-[70%] px-6 py-4 rounded-2xl text-sm leading-relaxed whitespace-pre-line shadow-sm ${msg.sender === 'user'
                  ? 'bg-black text-white rounded-br-none'
                  : 'bg-gray-100 text-gray-800 rounded-bl-none border border-gray-200'
                  }`}
              >
                {msg.text}
              </div>

              {/* Trip Suggestions Cards */}
              {msg.relatedTrips && (
                <div className="mt-4 w-full max-w-[90%] grid grid-cols-1 sm:grid-cols-2 gap-4 animate-in fade-in slide-in-from-bottom-2">
                  {msg.relatedTrips.map(trip => (
                    <div key={trip.id} className="transform scale-95 origin-top-left">
                      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden shadow-sm hover:shadow-md transition-all cursor-pointer" onClick={() => navigate(`/trip/${trip.id}`)}>
                        <div className="h-32 bg-gray-200 relative">
                          {trip.imageUrl ? (
                            <img src={trip.imageUrl} alt={trip.title} className="w-full h-full object-cover" />
                          ) : (
                            <div className="w-full h-full flex items-center justify-center text-2xl bg-indigo-50">✈️</div>
                          )}
                          <span className="absolute top-2 right-2 bg-white/90 px-2 py-1 text-[10px] font-bold rounded-lg backdrop-blur-sm">
                            {trip.category || 'Travel'}
                          </span>
                        </div>
                        <div className="p-3">
                          <h3 className="font-bold text-sm truncate">{trip.title}</h3>
                          <p className="text-xs text-gray-500 mt-1">📍 {trip.destination}</p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Proposed Trip Draft Card */}
              {msg.proposedTrip && (
                <div className="mt-4 w-full max-w-md animate-in fade-in slide-in-from-bottom-2">
                  <div className="bg-white rounded-3xl border border-gray-200 overflow-hidden shadow-lg">
                    <div className="bg-gradient-to-r from-indigo-600 to-purple-600 p-6 text-white">
                      <h3 className="text-lg font-bold mb-1">📝 แบบร่างทริปใหม่</h3>
                      <p className="text-xs opacity-80">AI สร้างให้คุณพิจารณา</p>
                    </div>
                    <div className="p-6 space-y-4">
                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-gray-400 font-bold">ชื่อทริป</label>
                        <p className="font-bold text-gray-900">{msg.proposedTrip.title}</p>
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-gray-400 font-bold">สถานที่</label>
                          <p className="text-sm">{msg.proposedTrip.destination}</p>
                        </div>
                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-gray-400 font-bold">ประเภท</label>
                          <p className="text-sm">{msg.proposedTrip.category}</p>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-gray-400 font-bold">วันที่</label>
                          <p className="text-sm">{msg.proposedTrip.startDate} - {msg.proposedTrip.endDate}</p>
                        </div>
                        <div>
                          <label className="text-[10px] uppercase tracking-wider text-gray-400 font-bold">งบประมาณ</label>
                          <p className="text-sm">{msg.proposedTrip.budget}</p>
                        </div>
                      </div>
                      <div>
                        <label className="text-[10px] uppercase tracking-wider text-gray-400 font-bold">รายละเอียด</label>
                        <p className="text-sm text-gray-600 mt-1">{msg.proposedTrip.description}</p>
                      </div>

                      <button
                        onClick={() => handleCreateTrip(msg.proposedTrip!)}
                        className="w-full py-3 bg-black text-white rounded-xl font-bold text-sm hover:bg-gray-800 transition-all flex items-center justify-center gap-2 mt-4"
                      >
                        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4v16m8-8H4" /></svg>
                        ยืนยันสร้างทริปนี้
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          ))}
          {loading && (
            <div className="flex items-center gap-2 text-gray-400 text-sm pl-4 animate-pulse">
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-75"></div>
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce delay-150"></div>
              <span>กำลังคิด...</span>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Suggestion Chips */}
        {messages.length === 1 && (
          <div className="flex flex-wrap justify-center gap-2 mb-6 animate-in fade-in slide-in-from-bottom-4">
            {SUGGESTIONS.map(s => (
              <button
                key={s}
                onClick={() => handleSendMessage(s)}
                className="px-4 py-2 bg-white border border-gray-200 rounded-full text-xs font-bold text-gray-600 hover:border-black hover:text-black hover:bg-gray-50 transition-all shadow-sm"
              >
                ✨ {s}
              </button>
            ))}
          </div>
        )}

        {/* Input Area */}
        <div className="relative">
          <form
            onSubmit={(e) => {
              e.preventDefault();
              handleSendMessage(inputText);
            }}
            className="relative"
          >
            <input
              type="text"
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="พิมพ์คำถามของคุณที่นี่..."
              className="w-full pl-6 pr-14 py-4 bg-gray-50 border border-gray-200 rounded-full focus:outline-none focus:bg-white focus:border-black focus:ring-1 focus:ring-black transition-all shadow-sm font-medium"
              disabled={loading}
            />
            <button
              type="submit"
              disabled={!inputText.trim() || loading}
              className="absolute right-2 top-2 p-2 w-10 h-10 bg-black text-white rounded-full flex items-center justify-center hover:bg-gray-800 disabled:opacity-50 disabled:bg-gray-300 transition-all"
            >
              <svg className="w-4 h-4 transform rotate-90" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M12 19V5M5 12l7-7 7 7" /></svg>
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Explore;
