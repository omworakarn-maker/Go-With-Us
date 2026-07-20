# วิธีแก้ AI Error (404 Model Not Found) 🤖🛠️

ปัญหานี้เกิดจาก **API Key** เก่า หรือไม่รองรับโมเดลรุ่นใหม่ (Gemini 1.5 Flash) ไม่ใช่เพราะโควต้าหมดครับ

## วิธีแก้ไข (ทำตามนี้หายแน่นอน):

1.  ไปที่เว็บ **[Google AI Studio](https://aistudio.google.com/app/apikey)** (ล็อกอินด้วย Google)
2.  คลิกปุ่มสีฟ้า **"Create API Key"**
3.  เลือก **"Create API Key in new project"** (แนะนำอันนี้เพื่อ Reset การตั้งค่า)
4.  Copy รหัส **API Key** ที่ได้มา (ขึ้นต้นด้วย `AIza...`)
5.  กลับมาที่โปรเจค เปิดไฟล์ `.env.local`
6.  เปลี่ยนค่า `VITE_GEMINI_API_KEY` เป็นรหัสใหม่
    ```env
    VITE_GEMINI_API_KEY=AIzaSyDxxxxxxxxxxxxxxxxxxxxxxxxx
    ```
7.  **สำคัญ:** ปิด Terminal ที่รัน `npm run dev` แล้วสั่งรันใหม่อีกครั้ง
    ```bash
    npm run dev
    ```

### ทำไมถึงต้องแก้?
เพราะโมเดล `gemini-1.5-flash` เป็นของใหม่ บางที API Key เก่าๆ จะมองไม่เห็นครับ เปลี่ยน Key ใหม่ก็ใช้งานได้ฟรีเหมือนเดิม (วันละ 1,500 ครั้ง)!
