<div align="center">
  <img src="branding/Logo.png" alt="GoWithUs — รถกับกระต่าย" width="220" />
  <h1>GoWithUs</h1>
  <p><strong>ไปด้วยกัน มีเรื่องราวมากกว่า</strong></p>
  <p>แพลตฟอร์มหาเพื่อนเที่ยว วางแผนทริป และพูดคุยกับเพื่อนร่วมทาง<br />Native iOS · Web · Admin Console · REST API & WebSocket</p>
  <p>
    <img src="https://img.shields.io/badge/SwiftUI-iOS%2017%2B-FA7343?logo=swift&logoColor=white" alt="SwiftUI iOS 17+" />
    <img src="https://img.shields.io/badge/Liquid%20Glass-iOS%2026%2B-222222?logo=apple&logoColor=white" alt="Liquid Glass iOS 26+" />
    <img src="https://img.shields.io/badge/React-18-149ECA?logo=react&logoColor=white" alt="React 18" />
    <img src="https://img.shields.io/badge/Express-API-339933?logo=nodedotjs&logoColor=white" alt="Express API" />
    <img src="https://img.shields.io/badge/Prisma-PostgreSQL-4169E1?logo=postgresql&logoColor=white" alt="Prisma PostgreSQL" />
  </p>
  <p>
    <a href="#features">ฟีเจอร์</a> ·
    <a href="#screenshots">ภาพหน้าจอ</a> ·
    <a href="#getting-started">เริ่มต้นใช้งาน</a> ·
    <a href="#deployment">Deploy</a> ·
    <a href="#recent-updates">อัปเดตล่าสุด</a> ·
    <a href="#known-limitations">ข้อจำกัดปัจจุบัน</a>
  </p>
</div>

## เกี่ยวกับโปรเจกต์

GoWithUs เชื่อมคนที่อยากออกเดินทางด้วยกัน ผู้ใช้ค้นหาทริปตามจังหวัด วันที่
และสไตล์การเที่ยว ดูคะแนนความเข้ากันได้ สร้างหรือเข้าร่วมทริป และพูดคุยผ่าน
แชทส่วนตัวหรือแชทกลุ่มทริปได้ มีเว็บแอดมินสำหรับดูแลผู้ใช้ ทริป รายงาน
การยืนยันตัวตน การแจ้งเตือน และโปรโมชัน

README นี้อธิบายโค้ดใน repository ณ **12 พฤศจิกายน 2026**
การมีฟีเจอร์ใน branch ไม่ได้หมายความว่า production deploy เวอร์ชันนั้นแล้ว
โดยเฉพาะฟีเจอร์ที่ต้องมี database migration และการตั้งค่าบริการภายนอก

<a id="features"></a>
## ฟีเจอร์

### ทริปและการจับคู่

- ค้นหาและกรองทริปตามจังหวัด ช่วงวันเดินทาง และหมวดหมู่
- เรียงแบบแนะนำ มาใหม่ และยอดนิยม พร้อมมุมมอง List / Grid
- คำนวณความเข้ากันได้จากความสนใจ งบประมาณ รูปแบบกิจกรรม และช่วงเวลาที่ชอบ
- สร้างและแก้ไขทริปพร้อมรูปภาพ งบ จำนวนสมาชิก และกำหนดการรายวัน
- เข้าร่วม ออกจากทริป และบันทึกสถานะสนใจ
- แยก My Trips และ Favorites พร้อมอัปเดตรายการหลังสร้าง เข้าร่วม หรือลบ
- เปิดหน้าทริปที่เพิ่งสร้าง และนำทริปที่เข้าร่วมออกจาก Match ใน native app
- บังคับสิทธิ์อ่านทริป Private และกรองอีเมลที่ผู้ใช้เลือกซ่อนในข้อมูลทริป
- ตรวจวันที่และกรองช่วงวันที่ผิดปกติออกจากผล Match

### บัญชี โปรไฟล์ และแชท

- สมัครสมาชิก ยืนยันอีเมลด้วย OTP และเข้าสู่ระบบด้วย JWT
- จัดการชื่อ รูปโปรไฟล์ ความสนใจ แบบสำรวจสไตล์เที่ยว และความเป็นส่วนตัว
- จัดการ device session ได้สูงสุด 3 อุปกรณ์ พร้อมดูและออกจากระบบอุปกรณ์อื่น
- แชทส่วนตัว แชทกลุ่มทริป และแนบรูปภาพ
- แชทของทริปที่เข้าร่วมสถานะ going แสดงในหน้า Messages ของ native app
- WebSocket และ polling สำหรับอัปเดตข้อมูลขณะใช้งาน
- รายการแจ้งเตือน อ่านแล้ว ลบรายการ และล้างรายการ พร้อมสถานะในเครื่อง

### Native iOS และงานแบรนด์

| Edition | ขั้นต่ำ | รูปแบบ |
| --- | --- | --- |
| [native-ios](native-ios/) | iOS 17 | รุ่นรองรับ iOS เก่า พร้อม navigation เดิม |
| [native-ios26](native-ios26/) | iOS 26 | System TabView / Liquid Glass ของ Apple พร้อมแอนิเมชันไอคอน |

- ใช้โลโก้รถกับกระต่ายร่วมกันใน splash, header และ app icon
- Splash รอข้อมูลบัญชีและหน้าแรกก่อนเล่นรถออก มีเวลารอสูงสุด 12 วินาที
- โลโก้บน header เล่นแอนิเมชันเมื่อกด
- iOS 26 มีเอฟเฟกต์ควันบ้าน หมุน Match สัญญาณแชท และสลับไอคอนคน
- ปุ่ม + เปิดหน้าสร้างทริป พร้อมปรับ keyboard / safe area และวงจรปิดหน้า
- จำกัด image cache และยกเลิกงานโหลด/observer ตาม lifecycle
- ลดการสร้างหน้า Home ใหม่เมื่อกลับเข้าแอป และเก็บ cache ตามแท็บ/ตัวกรอง

### AI และความทนทานของ backend

- Gemini proxy สำหรับผู้ช่วยท่องเที่ยวและร่างทริป
- แยกข้อผิดพลาด AI ออกจากการใช้งานส่วนอื่น พร้อม timeout, backoff และจำกัดงานพร้อมกัน
- Embedding เป็นข้อมูลเสริม: quota หมดหรือ provider ขัดข้องไม่ควรทำให้การบันทึกทริปล้มเหลว
- `GET /healthz` ตรวจสถานะ process โดยไม่เรียก AI หรือฐานข้อมูล
- Server diagnostics ช่วยตรวจ request ช้า, event-loop lag, CPU และหน่วยความจำ
- มีสคริปต์ซ่อม mojibake ของหมวดความสนใจที่จับคู่กลับได้แน่นอน

### Admin และโปรโมชัน

| หน้าเว็บ | ใช้ทำอะไร |
| --- | --- |
| `/admin` | ภาพรวมระบบ |
| `/admin/users` | จัดการผู้ใช้ |
| `/admin/trips` | จัดการทริป |
| `/admin/reports` | ตรวจรายงานผู้ใช้ |
| `/admin/verify` | ตรวจการยืนยันตัวตน |
| `/admin/alerts` | จัดการประกาศและการแจ้งเตือน |
| `/admin/promotions` | จัดการป๊อปอัปโปรโมชัน |

หน้าเหล่านี้ต้องใช้บัญชี role `admin` และ API จัดการโปรโมชันตรวจสิทธิ์ฝั่ง server ด้วย

- อัปโหลดรูป ย่อภาพ และดูตัวอย่างป๊อปอัปก่อนบันทึก
- เก็บหลายโปรโมชัน ดูรายละเอียด แก้ไข และเปิด–ปิดแต่ละรายการ
- เปิดได้ครั้งละหนึ่งโปรโมชัน เพื่อลดป๊อปอัปซ้อน
- เลือกความถี่วันละครั้ง ทุกครั้งที่เปิด หรือครั้งเดียวต่อโปรโมชัน
- กดรูปหรือปุ่มเพื่อเปิดเว็บไซต์ HTTPS หรือทริปสาธารณะ
- เว็บและ iOS ใช้ active promotion จาก backend ชุดเดียวกัน
- ป๊อปอัปเว็บใช้การ์ดโทนอุ่น โลโก้แบรนด์ ปุ่มปิด และ transition ที่รองรับ Reduce Motion
- เว็บจำความถี่ตามบัญชีบน browser; iOS จำตามบัญชีบนแต่ละเครื่อง
- ตัวอย่างในแอดมินไม่นับเป็นการแสดงจริง

ดูรายละเอียดการตั้งค่าและเงื่อนไขความถี่ที่ [Promotion popup](docs/Promotion-popup.md)

<a id="screenshots"></a>
## ภาพหน้าจอ

ภาพตัวอย่างใน repo อาจเป็น UI รุ่นก่อนหน้าการปรับ iOS 26 และโปรโมชัน

| หน้าแรก | รายละเอียดทริป | สร้างทริป | โปรไฟล์ |
| :---: | :---: | :---: | :---: |
| <img src="web-frontend/assets/screenshots/1.png" width="190" alt="หน้าแรก" /> | <img src="web-frontend/assets/screenshots/2.png" width="190" alt="รายละเอียดทริป" /> | <img src="web-frontend/assets/screenshots/3.png" width="190" alt="สร้างทริป" /> | <img src="web-frontend/assets/screenshots/4.png" width="190" alt="โปรไฟล์" /> |

## โครงสร้างและเทคโนโลยี

```text
Go-With-Us/
├── backend-api/       Express API, WebSocket, Prisma และ migrations
├── web-frontend/      React, TypeScript, Vite, Framer Motion, PWA/Capacitor
├── native-ios/        SwiftUI / MVVM สำหรับ iOS 17+
├── native-ios26/      SwiftUI รุ่น iOS 26+ และ Xcode project
├── branding/          โลโก้ต้นฉบับ ไอคอน และเลเยอร์ splash
├── docs/              เอกสารระบบและคู่มือฟีเจอร์
├── scripts/           สคริปต์พัฒนาและงานเอกสาร
└── reports/           รายงานและภาพประกอบ
```

Clients เรียก Express REST API เพื่ออ่าน/เขียนข้อมูลใน PostgreSQL ผ่าน Prisma
ส่วน WebSocket ใช้กระจายเหตุการณ์แบบ realtime ระหว่าง backend กับ client
Gemini, SendGrid และ Firebase เป็นบริการภายนอกที่ต้องตั้งค่าแยก

## โลโก้และ assets

- [Logo ต้นฉบับ](branding/Logo.png): artwork โปร่งใสสำหรับ header และหน้าบัญชี
- [App icon](branding/app-icon.png): ไอคอนแอปพื้นทึบ
- [Web brand assets](web-frontend/public/brand/): โลโก้ ไอคอน PWA และ apple-touch-icon
- [Splash assets](branding/SplashAssets.xcassets/): รถ ดวงตา และควันแยกเลเยอร์
- [คู่มือ export assets](branding/README.md): ขั้นตอนสร้างไอคอนจาก artwork

แก้ master asset แล้ว export/copy ไปยังแต่ละ client ให้ครบ ไฟล์ใน `branding/`
ไม่ได้อัปเดต asset ที่แพ็กในแอปให้อัตโนมัติ

<a id="getting-started"></a>
## เริ่มต้นใช้งาน

### สิ่งที่ต้องเตรียม

- Node.js ที่รองรับ dependencies ของโปรเจกต์ และ npm
- PostgreSQL พร้อม connection URL
- macOS และ Xcode ที่มี SDK รองรับ edition ที่จะ build
- สำหรับ iOS 26 ใช้ Xcode ที่มี iOS 26 SDK
- XcodeGen สำหรับสร้าง Xcode project ของรุ่น `native-ios` จาก `project.yml`

### 1. Backend

```bash
cd backend-api
npm ci
```

สร้าง `backend-api/.env` บนเครื่องเอง ตัวอย่างโครงสร้าง:

```dotenv
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DATABASE
DIRECT_DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DATABASE
JWT_SECRET=REPLACE_WITH_A_LONG_RANDOM_SECRET
PORT=3000
GEMINI_API_KEY=YOUR_SERVER_SIDE_KEY
GEMINI_MODEL=gemini-flash-latest
SENDGRID_API_KEY=YOUR_SENDGRID_KEY
SENDGRID_FROM_EMAIL=YOUR_VERIFIED_SENDER
```

`DATABASE_URL`, `DIRECT_DATABASE_URL` และ JWT secret ต้องตั้งให้ตรงกับ environment
ส่วน Gemini ใช้กับ AI; SendGrid ใช้กับอีเมล OTP; `FIREBASE_SERVICE_ACCOUNT`
ใช้กับ Firebase Admin เมื่อเปิดใช้งาน push
อย่า commit ไฟล์ .env, service-account JSON, APNs key หรือ token จริง

```bash
npm run db:deploy
npm run dev
```

`db:deploy` ทำ Prisma generate, ตรวจ recovery ของ registration migration,
apply migrations และซ่อม label ภาษาไทยที่รู้จักแบบรันซ้ำได้
กรณีฐานข้อมูลเดิมไม่มี migration history ที่สอดคล้องกัน ต้องตรวจ baseline ก่อน
อย่าใช้ `prisma db push` หรือ reset เพื่อข้ามปัญหาบน production

### 2. เว็บและ Admin Console

```bash
cd web-frontend
npm ci
npm run dev
```

Vite เปิดที่ `http://localhost:5173` และ proxy `/api` ไป
`http://localhost:3000` โดยค่าเริ่มต้น
สำหรับแยก frontend/backend คนละ host ให้ตั้ง `VITE_API_URL`
เป็น base URL ที่รวม `/api` เช่น `https://YOUR_API_HOST/api` ตอน build
ตรวจ proxy target ใน `vite.config.ts` ให้ตรงกับการตั้งค่า development ด้วย

ล็อกอินบัญชีแอดมินแล้วเข้า `/admin`
การสร้างหรือยกระดับบัญชีแอดมินต้องทำผ่านขั้นตอนฝั่ง server ที่ผู้ดูแลอนุญาต

```bash
npm run build
npm run preview
```

### 3. Native iOS

**iOS 26+**

เปิด [native-ios26/gowithus1.xcodeproj](native-ios26/gowithus1.xcodeproj)
เลือก Signing Team, Bundle Identifier และ iPhone/Simulator แล้วกด Run

**iOS 17+**

```bash
cd native-ios
xcodegen generate
open GoWithUs.xcodeproj
```

แต่ละ edition มี source แยกกัน การแก้รุ่นหนึ่งไม่ได้เปลี่ยนอีกรุ่นโดยอัตโนมัติ
ตรวจ API base URL ใน `GoWithUs/Services/APIService.swift` ของ edition นั้นก่อน build
ถ้าทดสอบด้วย iPhone จริง ให้ใช้ HTTPS endpoint หรือที่อยู่เครื่องที่ iPhone เข้าถึงได้
`localhost` บน iPhone หมายถึงตัว iPhone เอง

<a id="deployment"></a>
## Deploy และ database migrations

### Backend บน Render

- Root Directory: `backend-api`
- Build Command: `npm ci && npm run db:deploy`
- Start Command: `npm start`
- ตั้ง environment variables ใน Render ให้ครบ และใช้ port ที่ platform กำหนด
- ตรวจ `/healthz` หลัง deploy; endpoint นี้ไม่ยืนยันว่า DB หรือ Gemini พร้อมใช้งาน

ฟีเจอร์ใหม่ต้อง deploy migration ก่อนใช้งาน เช่น device sessions และ promotion tables
อย่าแก้ migration ที่ถูก apply ไปแล้ว ให้เพิ่ม migration ใหม่แทน
การเปลี่ยนโปรโมชันใหม่ต้องมีทั้ง
`20261111193000_add_app_promotion` และ `20261112110000_promotion_history`

### เว็บ

- Root Directory: `web-frontend`
- Build Command: `npm ci && npm run build`
- Output Directory: `dist`
- ตั้ง `VITE_API_URL` ให้ชี้ backend ที่ deploy แล้ว
- Static host ต้อง fallback เส้นทาง client เช่น `/admin/promotions` ไป `index.html`
- ตรวจ rewrite ของ hosting ก่อนใช้ `/api` แบบ relative เพราะค่า Vercel เดิมอ้างโครงสร้าง backend รุ่นเก่า

การ push branch อย่างเดียวไม่ได้ยืนยันว่า frontend/backend production ถูก deploy แล้ว
Native iOS ต้อง build และแจกเวอร์ชันใหม่แยกจากการ deploy server

## API หลัก

| Prefix | หน้าที่ |
| --- | --- |
| `/api/auth` | สมัคร ยืนยัน OTP ล็อกอิน และ session |
| `/api/users` | โปรไฟล์ การตั้งค่า และงานแอดมินผู้ใช้ |
| `/api/trips` | ค้นหา สร้าง แก้ไข เข้าร่วม และลบทริป |
| `/api/match` | จับคู่ทริปและเพื่อน |
| `/api/messages` | ข้อความส่วนตัวและข้อความกลุ่ม |
| `/api/notifications` | รายการแจ้งเตือนและสถานะ |
| `/api/ai` | Gemini proxy |
| `/api/promotions` | active promotion และการจัดการสำหรับแอดมิน |
| `/healthz` | ตรวจสถานะ process |

## การตรวจสอบ

ชุดทดสอบ backend ที่มีใน repo:

```bash
cd backend-api
npm run test:sessions
node tests/migrationRecovery.test.cjs
node tests/interestEncoding.test.cjs
node tests/aiTimeout.test.cjs
node tests/serverDiagnostics.test.cjs
```

ชุดทดสอบและ build เว็บ:

```bash
cd web-frontend
npm run test:sessions
npm run build
```

Native ตรวจด้วย Xcode Build และทดสอบบน iPhone จริง โดยเฉพาะ animation,
keyboard, camera/face verification, image picker, lifecycle และ notification
ผล syntax/typecheck อย่างเดียวไม่ยืนยันพฤติกรรม runtime

<a id="recent-updates"></a>
## อัปเดตช่วง 8–12 พฤศจิกายน 2026

1. **iOS 26 edition:** แยกรุ่นออกจาก iOS 17 และใช้ native Liquid Glass tab/navigation
2. **Tab interactions:** เพิ่มเอฟเฟกต์ไอคอน ปรับจังหวะสลับคน และแก้ crash
   `CAAnimationImmutable` โดยตั้งค่า animation ก่อนใส่เข้า layer
3. **Brand refresh:** ใช้โลโก้รถกับกระต่าย พร้อม app/PWA icons, splash
   และ header logo ที่เล่นเมื่อกด
4. **Startup:** splash รอข้อมูลเริ่มต้นก่อนรถแล่นออก พร้อม timeout กันรอไม่จบ
5. **Layout & input:** ปรับ search/filter row, ขอบ safe area,
   หน้าสร้างทริป และการซ่อนแป้นพิมพ์
6. **Trip state:** ซิงก์รายการหลังสร้าง/เข้าร่วม/ลบ เปิดทริปใหม่ทันที
   และเพิ่ม joined trip chats ใน Messages ของ native
7. **Caching & lifecycle:** ลด Home กระพริบ จำกัด cache และยกเลิกงานที่ไม่จำเป็น
8. **Device sessions:** จำกัด 3 เครื่อง จัดการอุปกรณ์ที่ล็อกอิน และออกจากเครื่องอื่น
9. **Notifications:** คืน swipe ลบของระบบ ปรับถังขยะสีแดง
   เก็บสถานะอ่าน/ซ่อนในเครื่อง และล้างรายการทันที
10. **QA fixes:** ปรับสิทธิ์ทริป Private, การซ่อนอีเมล,
    แนบรูปแชท, สถานที่ซ้ำ, วันที่ผิดปกติ, sort List/Grid,
    accessibility label และสคริปต์ซ่อมความสนใจภาษาไทย
11. **Backend resilience:** แยก AI timeout/quota, เพิ่ม health probe
    และ diagnostics สำหรับตรวจอาการ server ช้า
12. **Promotions:** เพิ่มการตั้งค่าใน iOS และเว็บแอดมิน
    เก็บหลายโปรโมชัน เปิด–ปิดแยก เชื่อม popup เว็บหน้าแรก
    และปรับดีไซน์เว็บให้เข้ากับแบรนด์

รายการนี้สรุปงานใน source; ตรวจ deployment, migrations และผลทดสอบจริง
ก่อนถือว่าปัญหา QA แต่ละข้อปิดสมบูรณ์

Commit อ้างอิงของงานล่าสุด:

| Commit | งาน |
| --- | --- |
| `e586385` | ซิงก์สถานะทริปและรายการแชทใน native clients |
| `e3adb5a` | แก้ findings ด้าน privacy, data และ interaction จาก QA |
| `7f17124` | แก้ crash ของ Core Animation ตอนสลับไอคอนโปรไฟล์ |
| `b7617f1` | เพิ่ม promotion backend/native และรอ Home readiness ตอนเปิดแอป |
| `c3897bc` | เพิ่มเว็บแอดมินโปรโมชันและ preview |
| `a8582ca` | เพิ่ม popup เว็บและรายการโปรโมชันที่เก็บไว้ |
| `a22f25f` | ปรับ popup เว็บเป็นการ์ดโทนอุ่นและ transition ตามแบรนด์ |

<a id="known-limitations"></a>
## ข้อจำกัดและงานที่ยังต้องทำ

- **Push ตอนปิดแอปยังไม่พร้อมครบทั้งระบบ:** iOS ลงทะเบียน APNs token
  แต่เส้นทางส่งปัจจุบันใช้ Firebase/FCM ต้องเชื่อม token และ APNs credentials
  ให้ถูกต้อง รวมถึงจัดเก็บ token แยกอุปกรณ์ก่อนยืนยันการรับนอกแอปได้
- **AI ขึ้นกับ quota/provider:** โค้ดจัดการความล้มเหลวไม่ได้เพิ่ม quota
  หรือรับประกันว่าผู้ช่วย AI จะตอบได้ทุกครั้ง
- **ประวัติอ่าน/ซ่อนแจ้งเตือนบางส่วนอยู่ในเครื่อง:** ไม่เท่ากับการ sync
  read/dismiss state ข้ามอุปกรณ์ครบถ้วน โดยเฉพาะประกาศส่วนกลาง
- **โปรโมชันใช้ความถี่ในเครื่อง/browser:** ล้างข้อมูลหรือเปลี่ยนเครื่องอาจเห็นอีกครั้ง
  และการเปิด–ปิดมีผลเมื่อ client เรียกตรวจ active promotion รอบถัดไป
- **ประวัติโปรโมชันเป็นรายการที่เก็บไว้:** ยังไม่ใช่ audit log ทุกเวอร์ชัน
  และยังไม่มีรายงานยอด impression/click
- **Production validation ยังจำเป็น:** หน้าเว็บโปรโมชันล่าสุดยังไม่ได้ยืนยัน
  production build/runtime ใน environment ที่ไม่มี Node/npm
- **เนื้อหาเอกสารเก่าบางส่วน:** README ย่อยและ deployment config เดิม
  อาจอ้างขั้นตอนรุ่นก่อน ให้เทียบกับโครงสร้างและ scripts ปัจจุบันก่อนใช้

## เอกสารเพิ่มเติม

- [Promotion popup และ release checks](docs/Promotion-popup.md)
- [iOS 26 edition](native-ios26/README.md)
- [iOS compatible edition](native-ios/README.md)
- [Brand assets](branding/README.md)
- [Admin backoffice](docs/Admin_README.md)

---

<div align="center">
  <img src="branding/Logo.png" alt="" width="72" />
  <p><strong>GoWithUs</strong> · ออกเดินทางไปด้วยกัน</p>
  <p>Developed by Worakan P.</p>
</div>
