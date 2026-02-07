# แผนการยกระดับระบบ AI (AI Upgrade Roadmap)

เอกสารนี้รวบรวมแนวทางการพัฒนาฟีเจอร์ AI ขั้นสูง 4 ด้านตามความต้องการใหม่ของโปรเจกต์ Go With Us

## 1. Predictive Matching (ระบบพยากรณ์ความสำเร็จของทริป)
**แนวคิด:** เปลี่ยนจาก Matching Score ธรรมดา เป็น Predictive Model พยากรณ์ Success Rate
- **Model:** Random Forest หรือ Neural Networks
- **Input Features:**
  - อายุ, เพศ, ความสนใจ (Interests)
  - ประวัติการเที่ยว (Travel History)
  - สไตล์การใช้เงิน (Budgeting Style)
- **Output:** ความน่าจะเป็นที่ทริปจะสำเร็จ (0-100%)
- **Implementation:**
  - สร้าง Python Microservice (ใช้ FastAPI + Scikit-learn)
  - Endpoint: `POST /predict-match` ส่ง JSON โปรไฟล์สมาชิกไปให้โมเดลประมวลผล

## 2. Sentiment Analysis (การวิเคราะห์ Sentiment จากรีวิว)
**แนวคิด:** วิเคราะห์ข้อความรีวิวเพื่อหา Hidden Traits
- **Model:** Gemini 1.5 Pro/Flash (หรือ BERT หากต้องการ On-premise)
- **Process:**
  - เมื่อจบทริป ดึงรีวิวที่เป็น Text ทั้งหมด
  - ส่งให้ AI สกัด Keywords (เช่น "ตื่นสาย", "ผู้นำ", "สายเปย์")
  - อัปเดต "User DNA" ใน Database
- **Implementation:**
  - ใช้ `geminiService.ts` สร้างฟังก์ชัน `analyzeReviewSentiment`
  - ทำงานแบบ Background Job หลัง User submit รีวิว

## 3. Advanced User Clustering (ระบบจัดกลุ่มอัจฉริยะ)
**แนวคิด:** Micro-segmentation โดยใช้พฤติกรรมจริง
- **Model:** K-Means Clustering (Unsupervised Learning)
- **Features:**
  - Clickstream data (กดดูทริปแบบไหนบ่อยสุด)
  - Time spent on pages
  - Search keywords
- **Implementation:**
  - **Batch Processing:** รัน Script ทุกคืน (Nightly Job) เพื่อวิเคราะห์ Log
  - อัปเดต Tag ให้ User เช่น `Segment: "Budget Adventurer"`

## 4. Risk Assessment (Consultative AI)
**แนวคิด:** ที่ปรึกษาความเสี่ยงส่วนตัว
- **Model:** Gemini 1.5 Flash (Implemented)
- **Implementation:**
  - เพิ่มฟังก์ชัน `analyzeTripRisk` ใน `geminiService.ts` (เรียบร้อยแล้ว)
  - เรียกใช้ฟังก์ชันนี้เมื่อ User กด "ตรวจสอบแผน" หรือก่อนกดสร้างทริป
  - แสดงผลแจ้งเตือนความเสี่ยง 3 ระดับ (Low, Medium, High) พร้อมคำแนะนำ

---
**สถานะปัจจุบัน:**
- [x] อัปเดต Prompt ใน `ML_PRESENTATION.md`
- [x] เพิ่มฟังก์ชัน `analyzeTripRisk` ใน Code (`src/services/geminiService.ts`)
- [ ] ต้องพัฒนา Python Service สำหรับ Predictive Matching & Clustering (Next Phase)
