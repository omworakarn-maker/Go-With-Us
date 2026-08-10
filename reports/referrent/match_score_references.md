# แหล่งอ้างอิงและทฤษฎีการคำนวณ Match Score (Go With Us)

เอกสารนี้รวบรวมทฤษฎีและแหล่งอ้างอิงทางวิชาการที่ใช้เป็นเกณฑ์ในการคำนวณคะแนนความเข้ากันได้ (Match Score) ของผู้ใช้และทริปในแอปพลิเคชัน Go With Us

## 1. อัลกอริทึมคณิตศาสตร์สำหรับระบบแนะนำ (Recommendation Systems)

ระบบจับคู่ของเราประยุกต์ใช้อัลกอริทึมมาตรฐานในกลุ่ม Content-based Filtering และ Set Similarity ดังนี้:

### Cosine Similarity
*   **ใช้สำหรับ:** คำนวณความเข้ากันได้ของ "งบประมาณ (Budget)" และ "สไตล์การทำกิจกรรม (Activity Style)"
*   **ทฤษฎี:** Cosine Similarity วัดมุมระหว่างเวกเตอร์สองเส้นในพิกัดหลายมิติ ทำให้สามารถเปรียบเทียบสไตล์ของผู้ใช้ได้โดยไม่ถูกจำกัดด้วยสเกลที่แตกต่างกัน (Scale Invariant)
*   **แหล่งอ้างอิง:**
    *   IBM Technology: [What is Cosine Similarity?](https://www.ibm.com/topics/cosine-similarity)
    *   Towards Data Science: [Understanding Cosine Similarity and its application](https://towardsdatascience.com/understanding-cosine-similarity-and-its-application-fd42f585296a)

### Dice Coefficient (Sørensen–Dice) และ Jaccard Index
*   **ใช้สำหรับ:** คำนวณความเข้ากันได้ของ "ความสนใจ (Interests)" และ "ช่วงเวลาที่ชอบ (Time of Day)"
*   **ทฤษฎี:** เป็นสมการทางสถิติที่ใช้วัดความคล้ายคลึงของกลุ่มข้อมูล (Set Similarity) โดยคำนวณจากสัดส่วนของข้อมูลที่เหมือนกันเทียบกับข้อมูลทั้งหมด เหมาะสำหรับข้อมูลประเภท Multiple Choices
*   **แหล่งอ้างอิง:**
    *   Wikipedia: [Sørensen–Dice coefficient](https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient)
    *   Wikipedia: [Jaccard Index](https://en.wikipedia.org/wiki/Jaccard_index)

## 2. ทฤษฎีจิตวิทยาและพฤติกรรมนักท่องเที่ยว (Traveler Psychographics)

การเลือก 4 ปัจจัยหลัก (งบประมาณ, สไตล์กิจกรรม, เวลา, ความสนใจ) อ้างอิงจากงานวิจัยด้านการท่องเที่ยว:

### Plog’s Model of Tourist Behavior
*   **ทฤษฎี:** Stanley Plog (1974) ได้แบ่งนักท่องเที่ยวออกเป็นกลุ่มตามสไตล์และจิตวิทยา เช่น **Allocentric** (สายลุย ชอบความท้าทาย ตารางแน่น) และ **Psychocentric** (สายชิล ชอบพักผ่อนที่เดิมๆ คาดเดาได้) ซึ่งทฤษฎีนี้ถูกนำมาใช้เป็นแกนของคำถาม **"สไตล์การทำกิจกรรม (Activity Style)"** ในแอป
*   **แหล่งอ้างอิง:**
    *   Tourism Teacher: [Plog’s Model of Tourist Behaviour Explained](https://tourismteacher.com/plogs-model-of-tourist-behaviour/)
    *   StudySmarter: [Plog's Model: Explanation & Examples](https://www.studysmarter.co.uk/explanations/business-studies/business-case-studies/plogs-model/)

### Tourism Market Segmentation (การแบ่งส่วนตลาดการท่องเที่ยว)
*   **ทฤษฎี:** การวิเคราะห์ทางวิชาการ (เช่น จาก UNWTO) มักแบ่งกลุ่มนักท่องเที่ยวด้วยปัจจัย Psychographic ซึ่งพบว่าอำนาจการซื้อ (Budget) ความสนใจหลัก (Interests) และนาฬิกาชีวิต (Time of Day) เป็นปัจจัยที่ทำให้คนมีพฤติกรรมต่างกันและส่งผลต่อความขัดแย้งในการเดินทางร่วมกัน เราจึงนำตัวแปรเหล่านี้มาถ่วงน้ำหนัก (Weighted Sum Model) เพื่อคัดกรองเพื่อนร่วมทริปที่ดีที่สุด
*   **แหล่งอ้างอิง:**
    *   ScienceDirect: [Market Segmentation in Tourism](https://www.sciencedirect.com/topics/social-sciences/tourism-market-segmentation)
