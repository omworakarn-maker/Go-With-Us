# 🤖 AI Agent Instructions (GoWithUs)

ไฟล์นี้สร้างขึ้นเพื่อให้ AI Agent (เช่น Cursor, Gemini, Copilot) เข้าใจบริบทของโปรเจค `GoWithUs` และสามารถเขียนโค้ดได้อย่างถูกต้องและเป็นไปในทิศทางเดียวกัน

## 1. 🌍 ภาพรวมโปรเจค (Project Context)
- **ชื่อแอป:** GoWithUs
- **คอนเซปต์:** แอปพลิเคชันสำหรับการท่องเที่ยว หาเพื่อนร่วมทริป (Find Buddy) และแชร์ประสบการณ์การเดินทาง
- **สไตล์การออกแบบ:** เน้นความพรีเมียม เรียบหรู (Minimalist), ใช้หลักการออกแบบ "Impeccable Design" (ขอบโค้งมน, ไม่มีเส้นขอบแข็งกระด้าง, ใช้พื้นที่ว่าง Spacing ให้ดูสะอาดตา)
- **ธีมสีหลัก:** Ocean Theme 
  - `appPrimary` (Ocean Navy / สีกรมท่าเข้ม)
  - `appSecondary` (Ocean Blue / สีฟ้าสว่าง)

## 2. 📂 โครงสร้างโปรเจค (Monorepo Workspace)
โปรเจคนี้ถูกแบ่งออกเป็น 4 โฟลเดอร์หลักอย่างชัดเจน:
- `/native-ios`: โค้ดแอปพลิเคชันสำหรับ iPhone (เขียนด้วย Swift / SwiftUI)
- `/web-frontend`: โค้ดสำหรับหน้าเว็บไซต์ (ใช้ Vite + Frontend Framework)
- `/backend-api`: โค้ดระบบหลังบ้านและฐานข้อมูล
- `/docs`: โฟลเดอร์สำหรับเก็บไฟล์เอกสาร (Markdown) ทั้งหมดของโปรเจค

*ห้ามนำโค้ดข้ามแพลตฟอร์มมาปะปนกันที่หน้าแรกสุด (Root) เด็ดขาด*

## 3. 🛠 เทคโนโลยีที่ใช้ (Tech Stack)
- **iOS:** ใช้ `SwiftUI` เป็นหลัก (หลีกเลี่ยงการใช้ UIKit ยกเว้นกรณีจำเป็นจริงๆ), รองรับการใช้ Canvas Preview
- **Web:** ใช้ `Vite` เป็นตัวจัดการโปรเจค ควบคู่กับ Capacitor สำหรับการแพ็คแอป
- **Backend:** Node.js / Go / หรืออื่นๆ 

## 4. 📝 กฎการเขียนโค้ด (Coding Conventions)
- **ภาษา:** คอมเมนต์อธิบายลอจิกที่ซับซ้อนให้เขียนเป็น "ภาษาไทย" เพื่อให้ทีมอ่านง่าย
- **การตั้งชื่อ (Naming):** ใช้ `camelCase` สำหรับตัวแปรและฟังก์ชัน, ใช้ `PascalCase` สำหรับชื่อ Class/Struct
- **UI Components (ฝั่ง iOS):** 
  - ห้ามใช้ `Color.black` ทื่อๆ ให้ใช้ `.adaptiveText` แทนเพื่อให้รองรับ Dark Mode
  - การเรียกใช้สีของแบรนด์ ให้เรียกผ่าน Extension เสมอ เช่น `Color.appPrimary`
  - หากสร้างปุ่ม หรือช่องกรอกข้อความ (TextField) ให้เช็คเรื่อง Padding และการตัดขอบ (`clipShape(Capsule())` หรือ `cornerRadius(12)`) ให้ดูพรีเมียมเสมอ
  - หากทำ UI ที่ซับซ้อน ให้แบ่งเป็น Component ย่อยๆ (Subviews) เสมอ

## 5. 🚀 วิธีการรันโปรเจค (How to Run)
- **iOS:** เปิดไฟล์โปรเจคในโฟลเดอร์ `/native-ios` ด้วย Xcode และกด `Cmd + R` หรือใช้ `Cmd + Option + Enter` เพื่อดู SwiftUI Canvas
- **Web:** เปิด Terminal เข้าไปที่ `/web-frontend` แล้วรันคำสั่ง `npm install` (ครั้งแรก) และ `npm run dev` เพื่อเริ่มต้นเซิร์ฟเวอร์
