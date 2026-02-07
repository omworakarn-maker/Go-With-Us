# วิธีเอาเว็บขึ้น Vercel (ฟรี) 🚀🌐

โปรเจคนี้พร้อม Deploy ขึ้น Vercel แบบ Full-stack (Frontend + API Backend) แล้วครับ!

## ขั้นตอนการ Deploy:

1.  **ติดตั้ง Vercel CLI** (ใน Terminal):
    ```bash
    npm i -g vercel
    ```

2.  **Login Vercel**:
    ```bash
    vercel login
    ```
    (เลือก Login with Google หรือ Github)

3.  **สั่ง Deploy**:
    ```bash
    vercel
    ```

4.  **ตั้งค่าตอน Vercel ถาม**:
    - **Set up and deploy?** -> `y`
    - **Which scope?** -> (กด Enter)
    - **Link to existing project?** -> `n`
    - **Project Name?** -> (ตั้งชื่อตามใจชอบ หรือกด Enter)
    - **In which directory?** -> `./` (กด Enter แช่ไว้ที่ root นี้)
    - **Auto-detected Project Settings?** -> `y` (หรือกด Enter)
    - **Wait...** รอจนมันขึ้น `Production: https://...` 

5.  **ตั้งค่า Environment Variables (สำคัญมาก!)**:
    - เมื่อ Deploy เสร็จแล้ว ให้เข้าไปที่ Dashboard ของโปรเจคในเว็บ Vercel
    - ไปที่ **Settings > Environment Variables**
    - เพิ่มค่าเหล่านี้ (ก๊อปจาก `.env.local` ได้เลย):
        1.  `DATABASE_URL` (ต้องเป็น URL ของ PostgreSQL จริง บน Cloud เช่น Supabase หรือ Neon)
        2.  `JWT_SECRET`
        3.  `VITE_GEMINI_API_KEY`
    - **Redeploy** โปรเจคอีกครั้ง (ในหน้า Deployments) เพื่อให้ค่าใหม่ทำงาน

---

### หมายเหตุเรื่อง Database 🗄️:
Database ที่ท่านใช้ในเครื่อง (`localhost`) จะไ**ม่สามารถใช้บน Vercel ได้**
ท่านต้องสมัคร **Neon (ฟรี)** หรือ **Supabase (ฟรี)** เพื่อเอา `DATABASE_URL` ของจริงมาใส่ใน Vercel ครับ

ถ้าไม่มี Cloud Database เว็บจะเปิดติด **แต่ Login/Load ทริปไม่ได้** ครับ!
