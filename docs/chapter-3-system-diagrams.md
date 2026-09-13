# แผนภาพการออกแบบระบบ GoWithUs สำหรับบทที่ 3

เอกสารนี้จัดทำจากโครงสร้างที่พบในโปรเจกต์ GoWithUs โดยกำหนดขอบเขตการนำเสนอเป็นแอปพลิเคชัน iOS สำหรับผู้ใช้, Admin Backoffice, Backend API และฐานข้อมูล PostgreSQL เท่านั้น ระบบจับคู่ผู้ใช้กับผู้ใช้และเว็บสำหรับผู้ใช้ทั่วไปไม่อยู่ในขอบเขตของแผนภาพชุดนี้

## 1. System Context Diagram

```mermaid
flowchart LR
    U[ผู้ใช้แอป GoWithUs] -->|สมัครสมาชิก ค้นหาและเข้าร่วมทริป สนทนา| IOS[แอปพลิเคชัน iOS]
    A[ผู้ดูแลระบบ] -->|ตรวจสอบผู้ใช้ ทริป รายงาน และการยืนยันตัวตน| ADMIN[Admin Backoffice]
    IOS -->|HTTPS / JSON| API[GoWithUs Backend API]
    ADMIN -->|HTTPS / JSON| API
    API --> DB[(PostgreSQL Database)]
    API --> EMAIL[บริการส่งอีเมล OTP]
    API --> GEMINI[Google Gemini API]
    API --> FCM[Firebase Cloud Messaging]
    IOS --> VISION[Apple Vision Framework]
```

## 2. Use Case Diagram — ผู้ใช้

```mermaid
flowchart LR
    U((ผู้ใช้))

    subgraph IOS[แอปพลิเคชัน iOS]
        UC1([สมัครสมาชิก])
        UC2([ยืนยันอีเมลด้วย OTP])
        UC3([เข้าสู่ระบบ])
        UC4([ตอบแบบสอบถามรูปแบบการท่องเที่ยว])
        UC5([ดูและกรองรายการทริป])
        UC6([ดูทริปที่เหมาะสมกับตนเอง])
        UC7([สร้างและแก้ไขทริป])
        UC8([เข้าร่วม เปลี่ยนสถานะ หรือออกจากทริป])
        UC9([สนทนาในกลุ่มทริปและข้อความส่วนตัว])
        UC10([จัดการโปรไฟล์และรูปภาพ])
        UC11([ยืนยันตัวตนด้วยใบหน้า])
        UC12([ดูการแจ้งเตือน])
        UC13([รายงานผู้ใช้])
        UC14([ขอคำแนะนำจาก AI])
    end

    U --- UC1
    U --- UC2
    U --- UC3
    U --- UC4
    U --- UC5
    U --- UC6
    U --- UC7
    U --- UC8
    U --- UC9
    U --- UC10
    U --- UC11
    U --- UC12
    U --- UC13
    U --- UC14
    UC1 -. ต้องทำต่อ .-> UC2
    UC2 -. สำเร็จแล้ว .-> UC4
```

## 3. Use Case Diagram — ผู้ดูแลระบบ

```mermaid
flowchart LR
    A((ผู้ดูแลระบบ))

    subgraph BO[Admin Backoffice]
        AU1([เข้าสู่ระบบด้วยสิทธิ์ Admin])
        AU2([ดูข้อมูลสรุปของระบบ])
        AU3([ดูและจัดการบัญชีผู้ใช้])
        AU4([ตรวจสอบข้อมูลทริป])
        AU5([ตรวจสอบคำขอยืนยันตัวตน])
        AU6([อนุมัติหรือปฏิเสธการยืนยันตัวตน])
        AU7([ตรวจสอบรายงานผู้ใช้])
        AU8([เตือนหรือระงับบัญชี])
        AU9([ส่งประกาศและการแจ้งเตือน])
    end

    A --- AU1
    A --- AU2
    A --- AU3
    A --- AU4
    A --- AU5
    A --- AU6
    A --- AU7
    A --- AU8
    A --- AU9
    AU5 -. ใช้ข้อมูลประกอบ .-> AU6
    AU7 -. อาจนำไปสู่ .-> AU8
```

## 4. Data Flow Diagram — Context Level

```mermaid
flowchart LR
    U[ผู้ใช้] -->|ข้อมูลสมัคร โปรไฟล์ ความชอบ ทริป ข้อความ| SYS((ระบบ GoWithUs))
    SYS -->|OTP รายการทริป คะแนนความเข้ากันได้ ข้อความ การแจ้งเตือน| U
    A[ผู้ดูแลระบบ] -->|คำสั่งตรวจสอบ อนุมัติ เตือน ระงับ และประกาศ| SYS
    SYS -->|สถิติ ผู้ใช้ ทริป รายงาน และคำขอยืนยันตัวตน| A
    SYS -->|คำขอส่ง OTP| E[บริการอีเมล]
    E -->|ผลการส่งอีเมล| SYS
    SYS -->|คำถามหรือข้อมูลทริป| G[Gemini API]
    G -->|คำตอบและคำแนะนำ| SYS
    SYS -->|ข้อมูล Push Notification| F[Firebase]
```

## 5. Data Flow Diagram — Level 0

```mermaid
flowchart TB
    U[ผู้ใช้]
    A[ผู้ดูแลระบบ]

    P1((1.0 จัดการบัญชีและ OTP))
    P2((2.0 จัดการโปรไฟล์และแบบสอบถาม))
    P3((3.0 จัดการทริปและผู้เข้าร่วม))
    P4((4.0 จับคู่ผู้ใช้กับทริป))
    P5((5.0 จัดการข้อความและการแจ้งเตือน))
    P6((6.0 ยืนยันตัวตนและจัดการรายงาน))
    P7((7.0 บริการผู้ช่วย AI))

    D1[(D1 Users)]
    D2[(D2 Pending Registrations)]
    D3[(D3 Trips)]
    D4[(D4 Participants)]
    D5[(D5 Messages)]
    D6[(D6 Notifications)]
    D7[(D7 Reports)]

    U <--> P1
    P1 <--> D1
    P1 <--> D2
    U <--> P2
    P2 <--> D1
    U <--> P3
    P3 <--> D3
    P3 <--> D4
    U <--> P4
    P4 --> D1
    P4 --> D3
    U <--> P5
    P5 <--> D5
    P5 <--> D6
    U <--> P6
    A <--> P6
    P6 <--> D1
    P6 <--> D7
    A <--> P3
    A <--> P5
    U <--> P7
```

## 6. DFD Level 1 — การจับคู่ผู้ใช้กับทริป

```mermaid
flowchart LR
    U[ผู้ใช้] --> P41((4.1 ขอรายการทริปที่เหมาะสม))
    P41 --> P42((4.2 อ่านความชอบของผู้ใช้))
    D1[(Users)] --> P42
    P41 --> P43((4.3 อ่านข้อมูลทริปที่เปิดให้เข้าร่วม))
    D3[(Trips)] --> P43
    P42 --> P44((4.4 เปรียบเทียบปัจจัย))
    P43 --> P44
    P44 -->|ความสนใจ| P45((4.5 คำนวณคะแนนรวม))
    P44 -->|งบประมาณ| P45
    P44 -->|จำนวนกิจกรรมต่อวัน| P45
    P44 -->|ช่วงเวลาที่ชอบ| P45
    P45 --> P46((4.6 เรียงลำดับทริป))
    P46 -->|รายการทริปและคะแนนความเข้ากันได้| U
```

## 7. System Architecture Diagram

```mermaid
flowchart TB
    subgraph CLIENT[Client Layer]
        IOS[iOS App<br/>SwiftUI]
        ADMIN[Admin Backoffice<br/>React]
    end

    subgraph SERVER[Application Layer]
        EXPRESS[Node.js / Express API]
        AUTH[JWT Authentication]
        WS[WebSocket Service]
        MATCH[Trip Matching Service]
        AI[AI Service]
        NOTI[Notification Service]
    end

    subgraph DATA[Data Layer]
        PRISMA[Prisma ORM]
        PG[(PostgreSQL)]
    end

    subgraph EXTERNAL[External Services]
        EMAIL[Email OTP Provider]
        GEMINI[Gemini API]
        FIREBASE[Firebase Cloud Messaging]
        VISION[Apple Vision<br/>ทำงานบนอุปกรณ์]
    end

    IOS --> EXPRESS
    ADMIN --> EXPRESS
    EXPRESS --> AUTH
    EXPRESS --> WS
    EXPRESS --> MATCH
    EXPRESS --> AI
    EXPRESS --> NOTI
    EXPRESS --> PRISMA
    PRISMA --> PG
    EXPRESS --> EMAIL
    AI --> GEMINI
    NOTI --> FIREBASE
    IOS --> VISION
```

## 8. Entity Relationship Diagram

ตาราง `UserMatch` ไม่นำมาใช้ใน ER Diagram นี้ตามขอบเขตระบบที่กำหนด

```mermaid
erDiagram
    USER ||--o{ TRIP : creates
    USER ||--o{ PARTICIPANT : joins
    TRIP ||--o{ PARTICIPANT : has
    USER ||--o{ MESSAGE : sends
    USER o|--o{ MESSAGE : receives
    TRIP o|--o{ MESSAGE : contains
    USER ||--o{ REPORT : reports
    USER ||--o{ REPORT : is_reported

    USER {
        string id PK
        string username UK
        string name
        string email UK
        string password
        string role
        boolean isBanned
        string gender
        datetime birthDate
        string profileImage
        string_array gallery
        string_array interests
        json travelStyle
        boolean isEmailVerified
        boolean isVerified
        string verificationStatus
        string faceScanImage
    }

    PENDING_REGISTRATION {
        string email PK
        string name
        string passwordHash
        string otpCode
        datetime otpExpiresAt
        datetime createdAt
    }

    TRIP {
        string id PK
        string title
        string destination
        datetime startDate
        datetime endDate
        int budget
        string budgetType
        int maxParticipants
        int activityStyle
        string_array timeOfDay
        string category
        string_array interestTags
        boolean isPublic
        string imageUrl
        string_array gallery
        json itinerary
        string creatorId FK
    }

    PARTICIPANT {
        string id PK
        string tripId FK
        string userId FK
        string name
        string_array interests
        string status
        datetime joinedAt
    }

    MESSAGE {
        string id PK
        string content
        string senderId FK
        string receiverId FK
        string tripId FK
        datetime createdAt
        boolean isRead
        string imageUrl
    }

    NOTIFICATION {
        string id PK
        string title
        string message
        string type
        string targetId
        string userId
        boolean isRead
        datetime createdAt
    }

    REPORT {
        string id PK
        string reason
        string status
        datetime createdAt
        string reporterId FK
        string reportedId FK
    }
```

หมายเหตุ: ใน Prisma Schema ปัจจุบัน `Notification.userId` และ `Notification.targetId` เก็บเป็นค่าอ้างอิง แต่ไม่ได้ประกาศ relation โดยตรง ส่วน `PendingRegistration` เป็นพื้นที่พักข้อมูลก่อนสร้างบัญชีผู้ใช้จริงหลังยืนยัน OTP สำเร็จ

## 9. Activity Diagram — สมัครสมาชิกและยืนยัน OTP

```mermaid
flowchart TD
    S([เริ่มต้น]) --> F[กรอกชื่อ อีเมล และรหัสผ่าน]
    F --> V{ข้อมูลถูกต้องหรือไม่}
    V -- ไม่ถูกต้อง --> E[แสดงข้อความแจ้งข้อผิดพลาด]
    E --> F
    V -- ถูกต้อง --> P[เข้ารหัสรหัสผ่านและสร้าง OTP]
    P --> TEMP[(บันทึก PendingRegistration)]
    TEMP --> MAIL[ส่ง OTP ไปยังอีเมล]
    MAIL --> INPUT[ผู้ใช้กรอก OTP]
    INPUT --> CHECK{OTP ถูกต้องและยังไม่หมดอายุหรือไม่}
    CHECK -- ไม่ถูกต้อง --> RETRY[แจ้งเตือนหรือขอส่ง OTP ใหม่]
    RETRY --> INPUT
    CHECK -- ถูกต้อง --> CREATE[สร้างข้อมูล User]
    CREATE --> DELETE[ลบ PendingRegistration]
    DELETE --> QUIZ[เข้าสู่แบบสอบถามเริ่มต้น]
    QUIZ --> END([เสร็จสิ้น])
```

## 10. Activity Diagram — สร้างทริป

```mermaid
flowchart TD
    S([เริ่มต้น]) --> OPEN[เปิดหน้าสร้างทริป]
    OPEN --> INFO[กรอกชื่อ จุดหมาย วันเดินทาง งบประมาณ และจำนวนคน]
    INFO --> PREF[กำหนดหมวดหมู่ ระดับกิจกรรม และช่วงเวลา]
    PREF --> IMAGE[เลือกรูปหน้าปกและรูปเพิ่มเติม]
    IMAGE --> PLAN{ต้องการสร้างกำหนดการด้วย AI หรือไม่}
    PLAN -- ใช่ --> GEMINI[ส่งข้อมูลไปยัง Gemini API]
    GEMINI --> REVIEW[ตรวจสอบและแก้ไขกำหนดการ]
    PLAN -- ไม่ใช่ --> REVIEW
    REVIEW --> VALID{ข้อมูลจำเป็นครบหรือไม่}
    VALID -- ไม่ครบ --> INFO
    VALID -- ครบ --> SAVE[บันทึก Trip]
    SAVE --> OWNER[กำหนดผู้ใช้เป็นผู้สร้างทริป]
    OWNER --> END([แสดงรายละเอียดทริป])
```

## 11. Activity Diagram — เข้าร่วมและออกจากทริป

```mermaid
flowchart TD
    S([ผู้ใช้เปิดรายละเอียดทริป]) --> CHECK{เป็นผู้สร้างทริปหรือไม่}
    CHECK -- ใช่ --> MANAGE[จัดการทริปและผู้ร่วมเดินทาง]
    CHECK -- ไม่ใช่ --> MEMBER{เข้าร่วมทริปแล้วหรือไม่}
    MEMBER -- ยังไม่เข้าร่วม --> FULL{จำนวนผู้ร่วมเดินทางเต็มหรือไม่}
    FULL -- เต็ม --> DISABLE[ไม่อนุญาตให้เข้าร่วม]
    FULL -- ยังว่าง --> JOIN[เลือกสนใจหรือยืนยันเข้าร่วม]
    JOIN --> SAVE[(เพิ่มหรืออัปเดต Participant)]
    MEMBER -- เข้าร่วมแล้ว --> ACTION{ต้องการเปลี่ยนสถานะหรือออกจากทริป}
    ACTION -- เปลี่ยนสถานะ --> SAVE
    ACTION -- ออกจากทริป --> CONFIRM[ยืนยันการออกจากทริป]
    CONFIRM --> DELETE[(ลบ Participant)]
    SAVE --> RESULT[อัปเดตจำนวนที่ว่างและรายละเอียด]
    DELETE --> RESULT
    RESULT --> END([เสร็จสิ้น])
```

## 12. Sequence Diagram — การจับคู่ผู้ใช้กับทริป

```mermaid
sequenceDiagram
    actor U as ผู้ใช้
    participant IOS as iOS App
    participant API as Backend API
    participant DB as PostgreSQL
    participant M as Trip Matching Service

    U->>IOS: เปิดหน้า Match Trip
    IOS->>API: GET /api/match/trips พร้อม JWT
    API->>DB: อ่าน interests และ travelStyle ของผู้ใช้
    DB-->>API: ข้อมูลความชอบผู้ใช้
    API->>DB: อ่านทริปที่เปิดให้เข้าร่วม
    DB-->>API: รายการทริป
    API->>M: ส่งข้อมูลผู้ใช้และรายการทริป
    M->>M: คำนวณความสนใจ งบประมาณ กิจกรรม และช่วงเวลา
    M->>M: รวมคะแนนและเรียงลำดับ
    M-->>API: ทริปพร้อมคะแนนความเข้ากันได้
    API-->>IOS: JSON รายการทริปที่เรียงแล้ว
    IOS-->>U: แสดงผลการจับคู่
```

## 13. Sequence Diagram — การส่งข้อความในกลุ่มทริป

```mermaid
sequenceDiagram
    actor U as ผู้ใช้
    participant IOS as iOS App
    participant API as Backend API
    participant DB as PostgreSQL
    participant WS as WebSocket
    participant FCM as Firebase

    U->>IOS: พิมพ์และส่งข้อความ
    IOS->>API: POST /api/messages/trips/:tripId
    API->>API: ตรวจสอบ JWT และสิทธิ์ในทริป
    API->>DB: บันทึก Message
    DB-->>API: ข้อความที่บันทึกแล้ว
    API->>WS: กระจายข้อความใหม่
    API->>FCM: ส่ง Push Notification ให้สมาชิก
    API-->>IOS: ผลการส่งสำเร็จ
    WS-->>IOS: อัปเดตข้อความในห้องสนทนา
```

## 14. Activity Diagram — การยืนยันตัวตนด้วยใบหน้า

```mermaid
flowchart TD
    S([เริ่มยืนยันตัวตน]) --> PERM{อนุญาตใช้กล้องหรือไม่}
    PERM -- ไม่อนุญาต --> GUIDE[แนะนำให้เปิดสิทธิ์กล้องในการตั้งค่า]
    PERM -- อนุญาต --> FRAME[จัดใบหน้าให้อยู่ในกรอบ]
    FRAME --> FACE{ตรวจพบใบหน้าหรือไม่}
    FACE -- ไม่พบ --> FRAME
    FACE -- พบ --> CHALLENGE[สุ่มคำสั่งหันซ้าย หันขวา หรือยิ้ม]
    CHALLENGE --> VISION[Apple Vision ตรวจจับการเคลื่อนไหวบนอุปกรณ์]
    VISION --> PASS{ผ่านทุกคำสั่งหรือไม่}
    PASS -- ไม่ผ่าน --> CHALLENGE
    PASS -- ผ่าน --> STRAIGHT[แจ้งให้มองหน้าตรง]
    STRAIGHT --> CAPTURE[ถ่ายภาพยืนยันขั้นสุดท้าย]
    CAPTURE --> SUBMIT[ส่งภาพและสถานะไป Backend]
    SUBMIT --> PENDING[(ตั้งสถานะ pending)]
    PENDING --> ADMIN[รอผู้ดูแลระบบตรวจสอบ]
    ADMIN --> END([แจ้งผลให้ผู้ใช้])
```

## 15. Activity Diagram — ผู้ดูแลระบบตรวจสอบรายงาน

```mermaid
flowchart TD
    S([Admin เข้าสู่ Backoffice]) --> LIST[เปิดรายการรายงาน]
    LIST --> DETAIL[ตรวจสอบเหตุผล ผู้รายงาน และผู้ถูกรายงาน]
    DETAIL --> DECIDE{ผลการตรวจสอบ}
    DECIDE -- ไม่มีการกระทำผิด --> CLOSE[เปลี่ยนสถานะรายงานเป็น reviewed หรือ resolved]
    DECIDE -- ควรตักเตือน --> WARN[ส่งคำเตือน]
    DECIDE -- ร้ายแรง --> BAN[ระงับบัญชีผู้ใช้]
    WARN --> NOTIFY[(สร้าง Notification)]
    BAN --> UPDATE[(อัปเดต User.isBanned)]
    NOTIFY --> CLOSE
    UPDATE --> CLOSE
    CLOSE --> END([เสร็จสิ้น])
```

## 16. Navigation Flow — แอปพลิเคชัน iOS

```mermaid
flowchart TD
    START([เปิดแอป]) --> AUTH{เข้าสู่ระบบแล้วหรือไม่}
    AUTH -- ไม่ --> LOGIN[เข้าสู่ระบบ]
    LOGIN --> REGISTER[สมัครสมาชิก]
    REGISTER --> OTP[ยืนยัน OTP]
    OTP --> QUIZ[แบบสอบถามเริ่มต้น]
    AUTH -- ใช่ --> HOME[หน้าหลัก]
    QUIZ --> HOME

    HOME --> DETAIL[รายละเอียดทริป]
    HOME --> FILTER[ตัวกรองทริป]
    HOME --> CREATE[สร้างทริป]
    HOME --> MATCH[Match Trip]
    HOME --> CHAT[Chat]
    HOME --> PROFILE[Profile]
    DETAIL --> JOIN[เข้าร่วมหรือออกจากทริป]
    DETAIL --> GROUPCHAT[ห้องสนทนาทริป]
    CHAT --> PRIVATE[ข้อความส่วนตัว]
    PROFILE --> EDIT[แก้ไขโปรไฟล์]
    PROFILE --> VERIFY[ยืนยันตัวตน]
    PROFILE --> MYTRIPS[ทริปของฉัน]
    HOME --> AI[AI Chat]
    HOME --> NOTI[Notifications]
```

## 17. Navigation Flow — Admin Backoffice

```mermaid
flowchart TD
    LOGIN[Admin Login] --> ROLE{มีสิทธิ์ Admin หรือไม่}
    ROLE -- ไม่มี --> DENY[ปฏิเสธการเข้าถึง]
    ROLE -- มี --> DASH[Dashboard]
    DASH --> USERS[Users Management]
    DASH --> TRIPS[Trips Management]
    DASH --> VERIFY[Verification Requests]
    DASH --> REPORTS[Reports Management]
    DASH --> ALERTS[Alerts and Notifications]
    USERS --> USERACTION[ดูรายละเอียด แก้ไข เตือน หรือระงับบัญชี]
    VERIFY --> VERIFYACTION[อนุมัติหรือปฏิเสธ]
    REPORTS --> REPORTACTION[ตรวจสอบและปิดรายงาน]
    ALERTS --> SEND[ส่งประกาศถึงผู้ใช้]
```

## 18. Deployment Diagram

```mermaid
flowchart LR
    subgraph DEVICE[iPhone ของผู้ใช้]
        APP[GoWithUs iOS App]
        AV[Apple Vision Framework]
        APP --> AV
    end

    subgraph ADMINDEVICE[อุปกรณ์ของผู้ดูแลระบบ]
        BROWSER[Web Browser]
        BO[Admin Backoffice]
        BROWSER --> BO
    end

    subgraph CLOUD[Cloud Environment]
        API[Node.js / Express Backend]
        DB[(PostgreSQL Database)]
        API --> DB
    end

    APP -->|HTTPS / WebSocket| API
    BO -->|HTTPS| API
    API --> EMAIL[Email OTP Service]
    API --> GEMINI[Gemini API]
    API --> FIREBASE[Firebase Cloud Messaging]
```

## 19. การออกแบบตารางฐานข้อมูล (Database Design)

ฐานข้อมูลของระบบใช้ PostgreSQL และจัดการโครงสร้างข้อมูลผ่าน Prisma ORM ตารางที่อยู่ในขอบเขตของระบบมีทั้งหมด 7 ตาราง โดยไม่นับตาราง `user_matches`

### 19.1 ตาราง users

ใช้เก็บบัญชีผู้ใช้ ข้อมูลโปรไฟล์ ความชอบ การตั้งค่าความเป็นส่วนตัว และสถานะการยืนยันตัวตน

| ชื่อฟิลด์ | ชนิดข้อมูล | คีย์/ข้อกำหนด | รายละเอียด |
|---|---|---|---|
| id | String (UUID) | PK | รหัสผู้ใช้ |
| username | String | Unique, Nullable | ชื่อผู้ใช้ที่ขึ้นต้นด้วย @ ในแอป |
| usernameUpdatedAt | DateTime | Nullable | วันที่เปลี่ยน username ล่าสุด |
| name | String | Required | ชื่อที่ใช้แสดง |
| email | String | Unique | อีเมลสำหรับเข้าสู่ระบบและรับ OTP |
| password | String | Required | รหัสผ่านที่ผ่านการแฮช |
| role | String | Default: user | สิทธิ์ `user` หรือ `admin` |
| isBanned | Boolean | Default: false | สถานะระงับบัญชี |
| gender | String | Nullable | เพศของผู้ใช้ |
| age | Integer | Nullable | อายุ |
| bio | Text | Nullable | คำแนะนำตัว |
| birthDate | DateTime | Nullable | วันเกิด |
| profileImage | Text | Nullable | URL หรือ Base64 ของรูปหลัก |
| gallery | String[] | Default: [] | รูปภาพเพิ่มเติมของโปรไฟล์ |
| isProfilePublic | Boolean | Default: true | อนุญาตให้ดูโปรไฟล์สาธารณะ |
| showGender | Boolean | Default: true | แสดงเพศในโปรไฟล์หรือไม่ |
| showAge | Boolean | Default: true | แสดงอายุในโปรไฟล์หรือไม่ |
| showBio | Boolean | Default: true | แสดงคำแนะนำตัวหรือไม่ |
| showInterests | Boolean | Default: true | แสดงความสนใจหรือไม่ |
| showEmail | Boolean | Default: false | แสดงอีเมลหรือไม่ |
| interests | String[] | Default: [] | หมวดหมู่ความสนใจของผู้ใช้ |
| travelStyle | JSON | Nullable | คำตอบรูปแบบการท่องเที่ยว |
| embedding | JSON | Nullable | ข้อมูลเวกเตอร์สำหรับระบบแนะนำ |
| fcmToken | String | Nullable | Token สำหรับ Push Notification |
| isEmailVerified | Boolean | Default: false | สถานะยืนยันอีเมล |
| otpCode | String | Nullable | รหัส OTP กรณีที่เกี่ยวข้องกับบัญชี |
| otpExpiresAt | DateTime | Nullable | เวลาหมดอายุของ OTP |
| isVerified | Boolean | Default: false | สถานะยืนยันตัวตน |
| verificationStatus | String | Default: unverified | `unverified`, `pending`, `verified` หรือ `rejected` |
| idCardImage | Text | Nullable | ฟิลด์รูปเอกสารยืนยันตัวตนเดิม |
| faceScanImage | Text | Nullable | รูปใบหน้าที่ส่งตรวจสอบ |
| createdAt | DateTime | Default: now | วันที่สร้างบัญชี |
| updatedAt | DateTime | Auto update | วันที่แก้ไขข้อมูลล่าสุด |

### 19.2 ตาราง pending_registrations

ใช้พักข้อมูลการสมัครก่อนยืนยัน OTP สำเร็จ เพื่อไม่สร้างบัญชีผู้ใช้จริงก่อนยืนยันอีเมล

| ชื่อฟิลด์ | ชนิดข้อมูล | คีย์/ข้อกำหนด | รายละเอียด |
|---|---|---|---|
| email | String | PK | อีเมลที่กำลังรอยืนยัน |
| name | String | Required | ชื่อที่กรอกตอนสมัคร |
| password_hash | String | Required | รหัสผ่านที่ผ่านการแฮช |
| otp_code | String | Required | รหัส OTP ที่ระบบสร้าง |
| otp_expires_at | DateTime | Required | เวลาหมดอายุของ OTP |
| created_at | DateTime | Default: now | วันที่เริ่มสมัคร |
| updated_at | DateTime | Auto update | วันที่แก้ไขข้อมูลล่าสุด |

เมื่อยืนยัน OTP สำเร็จ ระบบจะสร้างข้อมูลใน `users` และลบข้อมูลชั่วคราวรายการนี้

### 19.3 ตาราง trips

ใช้เก็บรายละเอียดทริป เงื่อนไขการเข้าร่วม ข้อมูลสำหรับ Matching รูปภาพ และกำหนดการ

| ชื่อฟิลด์ | ชนิดข้อมูล | คีย์/ข้อกำหนด | รายละเอียด |
|---|---|---|---|
| id | String (UUID) | PK | รหัสทริป |
| title | String | Required | ชื่อทริป |
| destination | String | Required, Index | จังหวัดหรือจุดหมาย |
| description | String | Nullable | รายละเอียดทริป |
| start_date | DateTime | Required | วันเริ่มเดินทาง |
| end_date | DateTime | Nullable | วันสิ้นสุดการเดินทาง |
| budget | Integer | Default: 1000 | งบประมาณหน่วยบาท |
| budget_type | String | Default: per_person | งบต่อคนหรือต่อทริป |
| max_participants | Integer | Default: 10 | จำนวนผู้ร่วมเดินทางสูงสุด |
| activity_style | Integer | Nullable, Default: 5 | ระดับจำนวนกิจกรรมต่อวัน |
| time_of_day | String[] | Default: [] | ช่วงเวลาที่มีกิจกรรม |
| budget_rating | Integer | Nullable, Default: 5 | ระดับงบประมาณสำหรับ Matching |
| category | String | Nullable, Index | หมวดหมู่หลักของทริป |
| interest_tags | String[] | Default: [] | หมวดหมู่เสริมสำหรับ Matching |
| is_public | Boolean | Default: true | สถานะเปิดเผยทริป |
| imageUrl | Text | Nullable | รูปหน้าปกทริป |
| gallery | String[] | Default: [] | รูปภาพเพิ่มเติมของทริป |
| itinerary | JSON | Nullable | กำหนดการเดินทาง |
| embedding | JSON | Nullable | เวกเตอร์สำหรับระบบแนะนำ |
| creator_id | String | FK → users.id, Index | ผู้สร้างทริป |
| summary | Text | Nullable | สรุปข้อมูลทริป |
| groupAnalysis | Text | Nullable | ผลวิเคราะห์กลุ่ม |
| created_at | DateTime | Default: now | วันที่สร้างทริป |
| updated_at | DateTime | Auto update | วันที่แก้ไขล่าสุด |

### 19.4 ตาราง participants

เป็นตารางกลางแสดงความสัมพันธ์แบบหลายต่อหลายระหว่างผู้ใช้กับทริป

| ชื่อฟิลด์ | ชนิดข้อมูล | คีย์/ข้อกำหนด | รายละเอียด |
|---|---|---|---|
| id | String (UUID) | PK | รหัสรายการเข้าร่วม |
| trip_id | String | FK → trips.id, Index | ทริปที่เข้าร่วม |
| user_id | String | FK → users.id | ผู้เข้าร่วม |
| name | String | Required | ชื่อผู้เข้าร่วม ณ เวลาบันทึก |
| interests | String[] | Required | ความสนใจของผู้เข้าร่วม |
| status | String | Default: going | `going` หรือ `interested` |
| joined_at | DateTime | Default: now | วันที่เข้าร่วม |

ข้อกำหนดสำคัญ: คู่ค่า `trip_id` และ `user_id` ต้องไม่ซ้ำ เพื่อป้องกันผู้ใช้เข้าร่วมทริปเดิมหลายครั้ง

### 19.5 ตาราง messages

ใช้ตารางเดียวรองรับทั้งข้อความในกลุ่มทริปและข้อความส่วนตัว

| ชื่อฟิลด์ | ชนิดข้อมูล | คีย์/ข้อกำหนด | รายละเอียด |
|---|---|---|---|
| id | String (UUID) | PK | รหัสข้อความ |
| content | Text | Required | เนื้อหาข้อความ |
| sender_id | String | FK → users.id, Index | ผู้ส่งข้อความ |
| receiver_id | String | FK → users.id, Nullable, Index | ผู้รับข้อความส่วนตัว |
| trip_id | String | FK → trips.id, Nullable, Index | ทริปของข้อความกลุ่ม |
| created_at | DateTime | Default: now | วันและเวลาที่ส่ง |
| is_read | Boolean | Default: false | สถานะอ่านข้อความ |
| imageUrl | Text | Nullable | รูปภาพที่แนบมากับข้อความ |

- ข้อความกลุ่มทริปใช้ `trip_id` และปล่อย `receiver_id` เป็นค่าว่าง
- ข้อความส่วนตัวใช้ `receiver_id` และปล่อย `trip_id` เป็นค่าว่าง

### 19.6 ตาราง notifications

ใช้เก็บการแจ้งเตือนเฉพาะผู้ใช้ การแจ้งเตือนเกี่ยวกับทริป และประกาศถึงผู้ใช้ทั้งหมด

| ชื่อฟิลด์ | ชนิดข้อมูล | คีย์/ข้อกำหนด | รายละเอียด |
|---|---|---|---|
| id | String (UUID) | PK | รหัสการแจ้งเตือน |
| title | String | Required | หัวข้อการแจ้งเตือน |
| message | Text | Nullable | รายละเอียดการแจ้งเตือน |
| type | String | Default: alert | `alert`, `trip` หรือ `system` |
| target_id | String | Nullable, Index | รหัสเป้าหมาย เช่น รหัสทริป |
| user_id | String | Nullable, Index | ผู้รับ; ค่าว่างหมายถึงส่งถึงผู้ใช้ทั้งหมด |
| is_read | Boolean | Default: false | สถานะอ่านแล้ว |
| created_at | DateTime | Default: now, Index | วันที่สร้างการแจ้งเตือน |

หมายเหตุ: `user_id` และ `target_id` เป็นค่าอ้างอิงเชิงตรรกะใน Schema ปัจจุบัน แต่ไม่ได้ประกาศ Foreign Key relation ผ่าน Prisma

### 19.7 ตาราง user_reports

ใช้เก็บรายงานที่ผู้ใช้ส่งให้ผู้ดูแลระบบตรวจสอบ

| ชื่อฟิลด์ | ชนิดข้อมูล | คีย์/ข้อกำหนด | รายละเอียด |
|---|---|---|---|
| id | String (UUID) | PK | รหัสรายงาน |
| reason | Text | Required | เหตุผลและรายละเอียดการรายงาน |
| status | String | Default: pending | `pending`, `reviewed` หรือ `resolved` |
| reporterId | String | FK → users.id | ผู้ส่งรายงาน |
| reportedId | String | FK → users.id | ผู้ใช้ที่ถูกรายงาน |
| createdAt | DateTime | Default: now | วันที่ส่งรายงาน |

### 19.8 สรุปความสัมพันธ์ระหว่างตาราง

| ตารางต้นทาง | ความสัมพันธ์ | ตารางปลายทาง | คีย์ที่ใช้ |
|---|---:|---|---|
| users | 1:N | trips | trips.creator_id |
| users | 1:N | participants | participants.user_id |
| trips | 1:N | participants | participants.trip_id |
| users | 1:N | messages (ผู้ส่ง) | messages.sender_id |
| users | 1:N | messages (ผู้รับ) | messages.receiver_id |
| trips | 1:N | messages | messages.trip_id |
| users | 1:N | user_reports (ผู้รายงาน) | user_reports.reporterId |
| users | 1:N | user_reports (ผู้ถูกรายงาน) | user_reports.reportedId |

ดังนั้นความสัมพันธ์ระหว่าง `users` และ `trips` ในด้านการเข้าร่วมเป็นแบบ M:N ซึ่งแยกจัดเก็บผ่านตาราง `participants` ส่วนผู้สร้างทริปเป็นความสัมพันธ์ 1:N ผ่าน `trips.creator_id`

## 20. แผนภาพการเก็บข้อมูลแบบสอบถามสำหรับ Smart Matching

คำตอบแบบสอบถามหลักไม่ได้แยกเก็บเป็นตารางแบบสอบถาม แต่บันทึกอยู่ในตาราง `users` โดยแบ่งเป็น 2 ฟิลด์ ได้แก่ `interests` และ `travelStyle` จากนั้นจึงนำไปเปรียบเทียบกับข้อมูลในตาราง `trips`

```mermaid
flowchart LR
    subgraph Q[แบบสอบถามในแอป iOS]
        Q1[งบประมาณเฉลี่ยต่อทริป]
        Q2[จำนวนสถานที่หรือกิจกรรมต่อวัน]
        Q3[ช่วงเวลาที่ชอบทำกิจกรรม]
        Q4[หมวดหมู่ความสนใจ]
    end

    Q1 --> TS[สร้างข้อมูล travelStyle แบบ JSON]
    Q2 --> TS
    Q3 --> TS
    Q4 --> IN[สร้างข้อมูล interests แบบ String Array]

    TS --> API[PUT /api/users/profile]
    IN --> API

    API --> U[(users)]
    U --> U1[travelStyle.budget]
    U --> U2[travelStyle.activityStyle]
    U --> U3[travelStyle.timeOfDay]
    U --> U4[interests]

    U1 --> MATCH[ระบบ Smart Matching]
    U2 --> MATCH
    U3 --> MATCH
    U4 --> MATCH

    T[(trips)] --> T1[budget]
    T --> T2[activityStyle]
    T --> T3[timeOfDay]
    T --> T4[category และ interestTags]

    T1 --> MATCH
    T2 --> MATCH
    T3 --> MATCH
    T4 --> MATCH

    MATCH --> SCORE[คะแนนงบประมาณ 30%]
    MATCH --> SCORE2[คะแนนกิจกรรมต่อวัน 20%]
    MATCH --> SCORE3[คะแนนช่วงเวลา 15%]
    MATCH --> SCORE4[คะแนนความสนใจ 35%]
    SCORE --> TOTAL[รวมคะแนนและเรียงลำดับทริป]
    SCORE2 --> TOTAL
    SCORE3 --> TOTAL
    SCORE4 --> TOTAL
```

### 20.1 การเชื่อมคำถามกับฟิลด์ฐานข้อมูล

| คำถามในแบบสอบถาม | ค่าที่แอปบันทึก | ฟิลด์ใน users | ฟิลด์ของทริปที่นำมาเปรียบเทียบ |
|---|---|---|---|
| งบประมาณเฉลี่ยต่อทริป | จำนวนเงิน เช่น `1500` บาท | `travelStyle.budget` | `trips.budget` |
| จำนวนสถานที่หรือกิจกรรมต่อวัน | `2`, `5` หรือ `8` | `travelStyle.activityStyle` | `trips.activityStyle` |
| ช่วงเวลาที่ชอบทำกิจกรรม | Array เช่น `morning`, `afternoon` | `travelStyle.timeOfDay` | `trips.timeOfDay` |
| หมวดหมู่ที่สนใจ สูงสุด 5 รายการ | String Array | `users.interests` | `trips.category` และ `trips.interestTags` |

### 20.2 โครงสร้างข้อมูลที่บันทึกใน users

ตัวอย่างต่อไปนี้แสดงรูปแบบข้อมูลตาม Model ของแอป ไม่ใช่ตารางฐานข้อมูลเพิ่มเติม

```json
{
  "interests": ["ทะเล", "อาหาร", "คาเฟ่"],
  "travelStyle": {
    "budget": 1500,
    "activityStyle": 5,
    "timeOfDay": ["morning", "afternoon"]
  }
}
```

### 20.3 ลำดับการบันทึกคำตอบ

```mermaid
sequenceDiagram
    actor U as ผู้ใช้
    participant Q as QuestionnaireView
    participant VM as AuthViewModel
    participant API as Backend API
    participant DB as PostgreSQL

    U->>Q: ตอบคำถามทั้ง 4 ด้าน
    Q->>Q: สร้าง interests และ travelStyle
    Q->>VM: ส่งข้อมูลโปรไฟล์ที่แก้ไข
    VM->>API: PUT /api/users/profile
    API->>API: ตรวจสอบ JWT และข้อมูลที่รับมา
    API->>DB: UPDATE users SET interests, travelStyle
    DB-->>API: ข้อมูลผู้ใช้ที่บันทึกแล้ว
    API-->>VM: ส่งโปรไฟล์ล่าสุดกลับมา
    VM-->>Q: แสดงผลบันทึกสำเร็จ
```

### 20.4 ข้อมูลสำคัญที่ใช้คำนวณ Matching

```mermaid
flowchart TB
    USER[(users)] --> A[interests]
    USER --> B[travelStyle.budget]
    USER --> C[travelStyle.activityStyle]
    USER --> D[travelStyle.timeOfDay]

    TRIP[(trips)] --> E[category และ interestTags]
    TRIP --> F[budget]
    TRIP --> G[activityStyle]
    TRIP --> H[timeOfDay]

    A --> I[ความสนใจ 35%]
    E --> I
    B --> J[งบประมาณ 30%]
    F --> J
    C --> K[กิจกรรมต่อวัน 20%]
    G --> K
    D --> L[ช่วงเวลา 15%]
    H --> L

    I --> TOTAL[คะแนนความเข้ากันได้ของผู้ใช้กับทริป]
    J --> TOTAL
    K --> TOTAL
    L --> TOTAL
```

## ขอบเขตที่ไม่นำเสนอ

- การค้นหาเพื่อนแบบปัดหรือ Find Buddy
- การกดถูกใจและการจับคู่ระหว่างผู้ใช้สองคน
- ตาราง `UserMatch` และ API กลุ่ม `/match/buddy`
- เว็บแอปพลิเคชันสำหรับผู้ใช้ทั่วไป

โฟลเดอร์ `web-frontend` ในซอร์สโค้ดมีไฟล์เดิมของเว็บผู้ใช้อยู่ด้วย แต่แผนภาพบทที่ 3 ชุดนี้ใช้อธิบายเฉพาะหน้า Admin Backoffice ได้แก่ Dashboard, Users, Trips, Verification, Reports และ Alerts ตามขอบเขตที่กำหนด
