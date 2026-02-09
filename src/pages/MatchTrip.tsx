import React from 'react';
import { motion } from 'framer-motion';
import { Link } from 'react-router-dom';
import { SparklesIcon, UserGroupIcon, MapIcon } from '@heroicons/react/24/outline';

const Activities: React.FC = () => {
  return (
    <div className="min-h-screen bg-white relative overflow-x-hidden font-sans">
      {/* Background Gradients (Monochrome) */}
      <div className="fixed top-0 left-0 w-full h-full overflow-hidden z-0">
        <div className="absolute top-[-10%] right-[-5%] w-[500px] h-[500px] bg-gray-100 rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob"></div>
        <div className="absolute top-[20%] left-[-10%] w-[400px] h-[400px] bg-gray-200 rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob animation-delay-2000"></div>
        <div className="absolute bottom-[-10%] right-[10%] w-[600px] h-[600px] bg-gray-50 rounded-full mix-blend-multiply filter blur-3xl opacity-50 animate-blob animation-delay-4000"></div>
      </div>

      <main className="relative z-10 container mx-auto px-6 min-h-screen flex flex-col items-center justify-center text-center py-20 pb-32">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="max-w-3xl"
        >
          <div className="inline-block mb-6 px-4 py-1.5 rounded-full bg-black text-white border border-black/10 backdrop-blur-sm">
            <span className="text-xs font-bold tracking-widest uppercase">เร็วๆ นี้</span>
          </div>

          <h1 className="text-5xl md:text-7xl font-black tracking-tighter mb-6 text-black">
            แมตช์ทริป
          </h1>

          <p className="text-lg md:text-xl text-gray-600 mb-10 max-w-2xl mx-auto leading-relaxed">
            เรากำลังพัฒนาระบบที่จะช่วยให้คุณค้นหาเพื่อนร่วมทางและประสบการณ์การท่องเที่ยวที่ใช่ที่สุดสำหรับคุณ เตรียมพบกับการจับคู่ที่ลงตัวกับสไตล์ของคุณ
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Link
              to="/"
              className="px-8 py-4 bg-black text-white rounded-full font-bold text-sm tracking-wide hover:bg-gray-800 transition-colors shadow-lg hover:shadow-xl"
            >
              ดูฟีเจอร์อื่นๆ
            </Link>
            <button disabled className="px-8 py-4 bg-white text-gray-400 border border-gray-200 rounded-full font-bold text-sm tracking-wide cursor-not-allowed">
              แจ้งเตือนเมื่อพร้อม
            </button>
          </div>
        </motion.div>

        {/* Feature Teaser Cards */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.2, ease: "easeOut" }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-20 max-w-5xl w-full"
        >
          {[
            { title: "วิเคราะห์ด้วย AI", icon: <SparklesIcon className="w-8 h-8 text-black" />, desc: "เข้าใจสไตล์การท่องเที่ยวของคุณอย่างลึกซึ้ง" },
            { title: "คู่หูที่ใช่", icon: <UserGroupIcon className="w-8 h-8 text-black" />, desc: "เชื่อมต่อกับเพื่อนร่วมทางที่มีรสนิยมเดียวกัน" },
            { title: "ทริปที่คัดสรร", icon: <MapIcon className="w-8 h-8 text-black" />, desc: "แผนการเดินทางที่ออกแบบมาเพื่อคุณโดยเฉพาะ" }
          ].map((item, index) => (
            <div key={index} className="p-6 bg-white/60 backdrop-blur-md border border-gray-100 rounded-3xl shadow-sm hover:shadow-md transition-all hover:bg-white text-left group">
              <div className="mb-4 p-3 bg-gray-50 rounded-2xl w-fit group-hover:bg-black group-hover:text-white transition-colors duration-300">
                {React.cloneElement(item.icon as React.ReactElement, { className: "w-6 h-6 group-hover:text-white transition-colors duration-300" })}
              </div>
              <h3 className="font-bold text-lg mb-2 text-black">{item.title}</h3>
              <p className="text-sm text-gray-500">{item.desc}</p>
            </div>
          ))}
        </motion.div>
      </main>
    </div>
  );
};

export default Activities;
