from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path('/Users/worakanp/Desktop/Go-with-us-1')
IMAGE_DIR = ROOT / 'reports' / 'backofficeรูปหลังบ้าน'
OUT = ROOT / 'reports' / 'canva_admin_backoffice_slides'
OUT.mkdir(parents=True, exist_ok=True)

SLIDES = [
    ('BackofficeDashboard.png', 'ADMIN BACKOFFICE', 'ภาพรวมระบบ',
     'สรุปจำนวนผู้ใช้ ทริป คำขอยืนยันตัวตน รายงานที่รอตรวจสอบ บัญชีที่ยืนยันแล้ว และบัญชีที่ถูกระงับ ช่วยให้ผู้ดูแลเห็นสถานะสำคัญและเข้าถึงงานที่ต้องดำเนินการได้รวดเร็ว'),
    ('BackofficeUsers.png', 'ADMIN BACKOFFICE', 'จัดการผู้ใช้',
     'แสดงรายชื่อและสถานะบัญชี พร้อมข้อมูลทริปที่สร้าง ทริปที่เข้าร่วม จำนวนรายงาน และวันที่สมัคร ผู้ดูแลสามารถค้นหา กรอง และระงับบัญชีที่ไม่เป็นไปตามข้อกำหนดได้'),
    ('BackofficeTrips.png', 'ADMIN BACKOFFICE', 'จัดการทริป',
     'รวมรายการทริปพร้อมจังหวัด ผู้สร้าง สมาชิก วันเดินทาง งบประมาณ และหมวดหมู่ ผู้ดูแลสามารถค้นหา เปิดดูรายละเอียด และลบทริปที่มีเนื้อหาไม่เหมาะสมได้'),
    ('BackofficeReport.png', 'ADMIN BACKOFFICE', 'จัดการรายงานผู้ใช้',
     'ใช้ตรวจสอบรายงานที่ผู้ใช้ส่งเข้ามา โดยแสดงผู้รายงาน ผู้ถูกรายงาน เหตุผล และสถานะ เพื่อให้ผู้ดูแลพิจารณาหลักฐาน ส่งคำเตือน ระงับบัญชี หรือปิดรายงาน'),
    ('BackofficeVerified.png', 'ADMIN BACKOFFICE', 'ตรวจสอบการยืนยันตัวตน',
     'แสดงคำขอยืนยันตัวตนที่รอการตรวจสอบ ผู้ดูแลตรวจสอบข้อมูลและภาพใบหน้าที่ส่งจากแอป ก่อนอนุมัติหรือปฏิเสธ และอัปเดตสถานะของบัญชีผู้ใช้'),
    ('BackofficeNoti.png', 'ADMIN BACKOFFICE', 'จัดการและประกาศการแจ้งเตือน',
     'สร้างประกาศโดยกำหนดหัวข้อ ข้อความ และประเภทการแจ้งเตือน เช่น ทั่วไป ทริป หรือระบบ พร้อมตรวจสอบประวัติและล้างรายการแจ้งเตือนที่ระบบเคยส่ง'),
]

FONT_REG = '/System/Library/Fonts/Thonburi.ttc'
FONT_BOLD = '/System/Library/Fonts/Thonburi.ttc'

def font(size, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT_REG, size, index=1 if bold else 0)

def rounded_crop(img, size, radius=34):
    img = img.copy()
    img.thumbnail(size, Image.Resampling.LANCZOS)
    canvas = Image.new('RGB', size, '#ffffff')
    x = (size[0] - img.width) // 2
    y = (size[1] - img.height) // 2
    canvas.paste(img, (x, y))
    mask = Image.new('L', size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0]-1, size[1]-1), radius=radius, fill=255)
    out = Image.new('RGB', size, '#ffffff')
    out.paste(canvas, mask=mask)
    return out

def wrap(draw, text, fnt, max_width):
    lines, line = [], ''
    for word in text.split():
        test = (line + ' ' + word).strip()
        if draw.textbbox((0,0), test, font=fnt)[2] <= max_width:
            line = test
        else:
            if line: lines.append(line)
            line = word
    if line: lines.append(line)
    return lines

for idx, (filename, kicker, title, body) in enumerate(SLIDES, 1):
    slide = Image.new('RGB', (1920, 1080), '#F7F5EF')
    d = ImageDraw.Draw(slide)
    d.rounded_rectangle((70, 60, 1850, 1020), radius=48, fill='#FFFFFF')
    d.rounded_rectangle((110, 100, 1240, 980), radius=34, fill='#EEF2EF')
    shot = rounded_crop(Image.open(IMAGE_DIR / filename).convert('RGB'), (1050, 760), 26)
    slide.paste(shot, (150, 160))

    d.text((1310, 145), kicker, fill='#839087', font=font(28, True))
    d.rectangle((1310, 195, 1400, 202), fill='#183C32')
    title_lines = wrap(d, title, font(52, True), 440)
    y = 245
    for line in title_lines:
        d.text((1310, y), line, fill='#183C32', font=font(52, True))
        y += 72
    y += 35
    for line in wrap(d, body, font(31), 440):
        d.text((1310, y), line, fill='#39443F', font=font(31))
        y += 50
    d.text((1310, 910), f'{idx:02d} / 06', fill='#9BA39E', font=font(24, True))
    slide.save(OUT / f'admin-backoffice-{idx:02d}.png', quality=95)

print(OUT)
