import fs from 'node:fs';
import path from 'node:path';

const root = process.argv[2];
const translations = new Map([
  ['กำลังโหลดโปรไฟล์…', 'Loading profile…'], ['ผู้ใช้งานที่ยืนยันตัวตนแล้ว', 'Verified user'],
  ['ประวัติส่วนตัว', 'Bio'], ['สไตล์การเที่ยว', 'Travel styles'], ['ตกลง', 'OK'],
  ['ระบุข้อความตักเตือน...', 'Enter a warning message…'], ['ยกเลิก', 'Cancel'], ['ส่งคำเตือน', 'Send warning'],
  ['ระบุเหตุผล (เช่น สแปม, ก้าวร้าว)...', 'Enter a reason (e.g. spam or abusive behavior)…'],
  ['ส่งรายงาน', 'Submit report'], ['จัดการผู้ใช้', 'Manage user'], ['แก้ไขโปรไฟล์ (Edit Profile)', 'Edit profile'],
  ['แบนผู้ใช้ (Ban)', 'Ban user'], ['ตักเตือนผู้ใช้ (Warn)', 'Warn user'], ['รายงานผู้ใช้ (Report)', 'Report user'],
  ['แมตช์ทริป', 'Trip matches'], ['ลองใหม่', 'Try again'], ['ไม่มีทริปแมตช์ใหม่ๆ ตอนนี้', 'No new trip matches right now'],
  ['กลับมาเช็คดูใหม่ หรือเพิ่มสไตล์การเที่ยวในโปรไฟล์', 'Check again later or add travel styles to your profile'],
  ['รีเฟรช', 'Refresh'], ['กำลังโหลด…', 'Loading…'], ['ยืนยันการลบ', 'Confirm deletion'], ['ลบ', 'Delete'],
  ['คุณต้องการลบทริปนี้ใช่หรือไม่?', 'Are you sure you want to delete this trip?'], ['เตะออกจากทริป', 'Remove from trip'],
  ['เตะ ออก', 'Remove'], ['ความเข้ากันของคุณ', 'Your compatibility'], ['แมตช์', 'Match'], ['ไม่มีข้อมูล', 'No data'],
  ['ผู้จัดทริป', 'Trip organizer'], ['ดูโปรไฟล์ →', 'View profile →'], ['ส่งข้อความถึงผู้จัด', 'Message organizer'],
  ['รายละเอียด', 'Details'], ['การเดินทางแต่ละวัน', 'Daily itinerary'], ['รูปภาพ', 'Photos'], ['(คุณ)', '(You)'],
  ['ออกจากทริป', 'Leave trip'], ['จะไปด้วย', 'Join trip'], ['ทริปเต็มแล้ว', 'Trip is full'], ['สนใจทริปนี้', 'Save this trip'],
  ['คุณต้องการบันทึกทริปนี้เข้ารายการโปรดใช่หรือไม่?', 'Would you like to save this trip to Favorites?'],
  ['ไม่สามารถบันทึกได้', 'Unable to save'], ['ตรวจสอบ', 'OK'], ['จังหวัด', 'Province'], ['สไตล์ของทริป', 'Trip styles'],
  ['เพิ่มสไตล์...', 'Add style…'], ['ความต้องการพิเศษให้ AI (เช่น เน้นคาเฟ่, สายมู)...', 'Special requests for AI (e.g. cafes or temples)…'],
  ['เขียนรายละเอียดตรงนี้', 'Enter details here'], ['แท็ก / คีย์เวิร์ด', 'Tags / Keywords'],
  ['เช่น ทะเล, คาเฟ่, ธรรมชาติ', 'e.g. beach, cafe, nature'], ['สาธารณะ', 'Public'],
  ['ทุกคนสามารถเห็นทริปนี้ได้', 'Everyone can see this trip'], ['ประเภทงบ:', 'Budget type:'], ['ต่อคน', 'Per person'],
  ['ต่อทริป (รวม)', 'Per trip (total)'], ['ช่วงเวลาของทริป', 'Trip time preferences'], ['ย้อนกลับ', 'Back'],
  ['ยืนยันการลบทริป', 'Confirm trip deletion'], ['คุณแน่ใจหรือไม่ว่าต้องการลบทริปนี้? การดำเนินการนี้ไม่สามารถย้อนกลับได้', 'Are you sure you want to delete this trip? This action cannot be undone.'],
  ['ชื่อสไตล์ใหม่', 'New style name'], ['เพิ่มสไตล์', 'Add style'], ['บันทึก', 'Save'],
  ['คุณแน่ใจหรือไม่ว่าต้องการลบทริปนี้?', 'Are you sure you want to delete this trip?'],
  ['ความต้องการพิเศษให้ AI (ไม่จำเป็น)', 'Special requests for AI (optional)'], ['ประเภทงบ', 'Budget type'],
  ['เพิ่มกิจกรรมแยกตามวัน ระบบจะใช้แผนนี้คำนวณจำนวนกิจกรรมเฉลี่ยต่อวัน', 'Add activities by day. The system uses this plan to calculate average activities per day.'],
  ['วันเริ่ม', 'Start date'], ['วันสิ้นสุด', 'End date'], ['ลบออก', 'Remove'], ['วันเดียว (ไม่มีวันกลับ)', 'One day (no return date)'],
  ['เลือกวันเดินทางไป-กลับ', 'Select travel dates'], ['ปิด', 'Close'], ['แผนการเดินทางแต่ละวัน', 'Daily itinerary'],
  ['เพิ่มวันใหม่', 'Add another day'], ['เริ่มสร้างแผนท่องเที่ยว', 'Start building your itinerary'], ['เพิ่มกิจกรรม', 'Add activity'],
  ['ชื่อกิจกรรม', 'Activity name'], ['สมัครสมาชิก', 'Sign up'], ['เริ่มต้นการผจญภัยของคุณ', 'Start your adventure'],
  ['ชื่อ', 'Name'], ['ชื่อของคุณ', 'Your name'], ['อีเมล', 'Email'], ['รหัสผ่าน', 'Password'],
  ['อย่างน้อย 6 ตัวอักษร', 'At least 6 characters'], ['ยืนยันรหัสผ่าน', 'Confirm password'],
  ['พิมพ์รหัสผ่านอีกครั้ง', 'Enter your password again'], ['รายละเอียดการแจ้งเตือน', 'Notification details'],
  ['หัวข้อ', 'Title'], ['ประเภท', 'Type'], ['ทั่วไป', 'General'], ['ทริป', 'Trip'], ['ระบบ', 'System'],
  ['ทริป (ถ้ามี)', 'Trip (optional)'], ['ส่งการแจ้งเตือน', 'Send notification'], ['สร้างการแจ้งเตือน', 'Create notification'],
  ['ข้อผิดพลาด', 'Error'], ['👤 ข้อมูลส่วนตัวของคุณ', '👤 Your personal information'],
  ['ข้อมูลนี้ช่วยให้ผู้ร่วมทริปรู้จักคุณ และใช้สร้างโปรไฟล์ของคุณ', 'This information helps travel companions get to know you and builds your profile.'],
  ['จำเป็นต้องเลือกรูปโปรไฟล์ก่อนดำเนินการต่อ', 'Select a profile photo to continue'],
  ['Username นี้ใช้งานได้', 'This username is available'], ['เว้นว่างได้ ระบบจะสร้าง Username ที่ไม่ซ้ำให้อัตโนมัติ', 'Leave blank to generate a unique username automatically'],
  ['วันเกิด', 'Date of birth'], ['💰 งบประมาณเฉลี่ยต่อทริป (Budget per Trip)', '💰 Average budget per trip'],
  ['ระบุงบประมาณที่คุณสะดวกใช้จ่ายสำหรับหนึ่งทริป (บาท)', 'Enter the amount you are comfortable spending on one trip (THB)'],
  ['ประหยัด (100฿)', 'Budget (฿100)'], ['หรูหรา (5,000฿+)', 'Luxury (฿5,000+)'],
  ['🎯 จำนวนสถานที่ท่องเที่ยวต่อวัน (Places per Day)', '🎯 Places per day'],
  ['เลือกจำนวนสถานที่ที่คุณสะดวกเที่ยวในหนึ่งวัน', 'Choose how many places you prefer to visit in one day'],
  ['🕘 ช่วงเวลาที่ชอบท่องเที่ยว (Time of Day)', '🕘 Preferred travel times'],
  ['เลือกช่วงเวลาที่คุณชอบออกไปทำกิจกรรมหรือท่องเที่ยว (เลือกได้มากกว่า 1 ช่วง)', 'Choose when you prefer activities or travel (select more than one)'],
  ['✨ ความสนใจด้านการท่องเที่ยว (Travel Interests)', '✨ Travel interests'],
  ['เลือกหมวดหมู่ที่คุณสนใจได้สูงสุด 5 ข้อ เพื่อให้เราแนะนำทริปที่เหมาะกับคุณ', 'Select up to 5 interests so we can recommend suitable trips'],
  ['เลื่อนซ้าย–ขวาเพื่อดูตัวเลือก', 'Swipe left or right to view options'], ['แบบสอบถาม', 'Questionnaire'],
  ['ไม่มีการแจ้งเตือน', 'No notifications'], ['ลบทั้งหมด', 'Delete all'], ['การแจ้งเตือน', 'Notifications'],
  ['ยืนยันตัวตน', 'Identity verification'], ['การยืนยันตัวตน', 'Identity verification'],
  ['ยืนยันตัวตนเพื่อความปลอดภัย', 'Verify your identity for safety'],
  ['ทำตามคำแนะนำการขยับใบหน้า แล้วส่งคำขอให้ผู้ดูแลตรวจสอบ', 'Follow the face movement instructions, then submit your request for review.'],
  ['ก่อนเริ่ม กรุณาถอดแว่น หน้ากาก และหมวก เพื่อให้กล้องมองเห็นใบหน้าอย่างชัดเจน', 'Before starting, remove glasses, masks, and hats so your face is clearly visible.'],
  ['ตรวจการเคลื่อนไหวผ่านแล้ว', 'Liveness check passed'], ['ยังไม่ได้ตรวจการเคลื่อนไหวใบหน้า', 'Liveness check not completed'],
  ['เปิดการตั้งค่าเพื่ออนุญาตกล้อง', 'Open Settings to allow camera access'], ['จัดดวงตา จมูก และคางให้อยู่ภายในกรอบ', 'Keep your eyes, nose, and chin inside the frame'],
  ['เปิดโปรไฟล์สาธารณะ', 'Public profile'], ['แสดงเพศ', 'Show gender'], ['แสดงอายุ', 'Show age'],
  ['แสดงประวัติส่วนตัว', 'Show bio'], ['แสดงสไตล์การเที่ยว', 'Show travel styles'], ['แสดงอีเมล', 'Show email'],
  ['คัดลอกข้อความ', 'Copy message'], ['ยกเลิกข้อความ', 'Unsend message'], ['พิมพ์ข้อความ...', 'Type a message…'], ['อ่านแล้ว', 'Read'],
  ['ไปกับเรา สนุกกว่า', 'Travel is better together'], ['เข้าสู่ระบบ', 'Log in'], ['ยังไม่มีบัญชี?', "Don't have an account?"],
  ['สร้างทริปสำเร็จ! 🎉', 'Trip created! 🎉'], ['ทริปของคุณถูกสร้างแล้ว ไปดูได้ที่หน้าแรกเลย!', 'Your trip has been created. View it on the Home screen!'],
  ['ไม่พบรูปภาพ', 'Image not found'], ['ปรับแต่งรูปภาพ', 'Adjust photo'], ['เสร็จสิ้น', 'Done'],
  ['รีเซ็ตบัญชี', 'Reset account'], ['ระบบจะล้างโปรไฟล์ แบบสอบถาม ทริป การเข้าร่วม แชท และประวัติการใช้งาน แต่คุณยังเข้าสู่ระบบด้วยอีเมลเดิมได้', 'This clears your profile, questionnaire, trips, participation, chats, and activity. You can still log in with the same email.'],
  ['ลบบัญชีถาวร', 'Permanently delete account'], ['บัญชีและข้อมูลทั้งหมดจะถูกลบถาวรและไม่สามารถกู้คืนได้', 'Your account and all data will be permanently deleted and cannot be recovered.'],
  ['จัดการบัญชี', 'Manage account'], ['กำลังดำเนินการ...', 'Processing…'],
  ['พิมพ์ชื่อสถานที่ เช่น ร้านอาหาร, คาเฟ่...', 'Search for a place, restaurant, or cafe…'], ['ค้นหาสถานที่', 'Search places']
]);

const callNames = '(?:Text|Button|TextField|SecureField|Label|Toggle|navigationTitle|alert|accessibilityLabel)';
function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full);
    else if (entry.name.endsWith('.swift')) localize(full);
  }
}
function esc(value) { return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); }
function swift(value) { return value.replace(/\\/g, '\\\\').replace(/"/g, '\\"'); }
function localize(file) {
  let source = fs.readFileSync(file, 'utf8');
  for (const [thai, english] of translations) {
    const re = new RegExp(`(${callNames})\\("${esc(thai)}"`, 'g');
    source = source.replace(re, `$1(tr("${swift(thai)}", "${swift(english)}")`);
    const stateAssignment = new RegExp(`((?:errorMessage|actionMessage|message|instruction)\\s*=\\s*)"${esc(thai)}"`, 'g');
    source = source.replace(stateAssignment, `$1tr("${swift(thai)}", "${swift(english)}")`);
    const statusCall = new RegExp(`((?:reportError|publishStatus)\\()"${esc(thai)}"`, 'g');
    source = source.replace(statusCall, `$1tr("${swift(thai)}", "${swift(english)}")`);
  }
  fs.writeFileSync(file, source);
}
walk(root);
