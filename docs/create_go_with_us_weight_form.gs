/**
 * สร้าง Google Form แบบสอบถามน้ำหนัก Smart Matching ฉบับตอบง่าย
 * วิธีใช้: เปิด https://script.google.com/create วางโค้ดนี้ แล้วกด Run > createGoWithUsWeightForm
 */
function createGoWithUsWeightForm() {
  const form = FormApp.create('แบบสอบถามปัจจัยที่มีผลต่อการเลือกทริป — GoWithUs');

  form.setDescription(
    'แบบสอบถามนี้จัดทำขึ้นเพื่อศึกษาความสำคัญของปัจจัยที่มีผลต่อการเลือกทริป ได้แก่ ความสนใจ งบประมาณ จำนวนกิจกรรมต่อวัน และช่วงเวลา ' +
    'เพื่อนำผลไปกำหนดค่าน้ำหนักในระบบ Smart Matching ของแอปพลิเคชัน GoWithUs โดยวิเคราะห์จากคะแนนเฉลี่ยของกลุ่มตัวอย่าง\n\n' +
    'ใช้เวลาประมาณ 1–2 นาที ไม่มีคำตอบถูกหรือผิด และรายงานผลโดยรวมโดยไม่ระบุตัวตน'
  );
  form.setCollectEmail(false);
  form.setProgressBar(true);
  form.setShuffleQuestions(false);
  form.setConfirmationMessage('ขอบคุณสำหรับการตอบแบบสอบถาม ข้อมูลของคุณจะถูกนำไปวิเคราะห์ในภาพรวม');

  form.addMultipleChoiceItem()
    .setTitle('คุณยินยอมเข้าร่วมตอบแบบสอบถามโดยสมัครใจหรือไม่?')
    .setChoiceValues(['ยินยอม', 'ไม่ยินยอม'])
    .setRequired(true);

  form.addMultipleChoiceItem()
    .setTitle('คุณเคยท่องเที่ยวร่วมกับผู้อื่น หรือสนใจใช้แอปหาเพื่อนร่วมทริปหรือไม่?')
    .setChoiceValues([
      'เคยท่องเที่ยวร่วมกับผู้อื่น',
      'สนใจใช้แอปหาเพื่อนร่วมทริป',
      'ทั้งเคยและสนใจ',
      'ไม่เคยและไม่สนใจ'
    ])
    .setRequired(true);

  form.addSectionHeaderItem()
    .setTitle('ให้คะแนนความสำคัญของแต่ละปัจจัย')
    .setHelpText('เลือก 1–5 โดย 1 = ไม่สำคัญเลย และ 5 = สำคัญมากที่สุด');

  const factors = [
    ['ความสนใจ', 'ประเภททริปตรงกับสิ่งที่ชอบ เช่น ทะเล ภูเขา คาเฟ่ หรือไหว้พระ'],
    ['งบประมาณ', 'ค่าใช้จ่ายเฉลี่ยต่อคนอยู่ในระดับที่สามารถจ่ายได้'],
    ['จำนวนกิจกรรมต่อวัน', 'จำนวนกิจกรรมและความแน่นของตารางตรงกับรูปแบบการเที่ยวที่ต้องการ'],
    ['ช่วงเวลา', 'ช่วงเช้า กลางวัน เย็น หรือกลางคืนตรงกับช่วงที่สะดวกหรือชอบทำกิจกรรม']
  ];

  factors.forEach(([name, explanation]) => {
    form.addScaleItem()
      .setTitle(name + ' — ' + explanation)
      .setBounds(1, 5)
      .setLabels('ไม่สำคัญเลย', 'สำคัญมากที่สุด')
      .setRequired(true);
  });

  form.addMultipleChoiceItem()
    .setTitle('ถ้าเลือกได้เพียงหนึ่งข้อ ปัจจัยใดมีผลต่อการเลือกทริปของคุณมากที่สุด?')
    .setChoiceValues(['ความสนใจ', 'งบประมาณ', 'จำนวนกิจกรรมต่อวัน', 'ช่วงเวลา'])
    .setRequired(true);

  form.addCheckboxItem()
    .setTitle('นอกจาก 4 ปัจจัยข้างต้น มีเรื่องใดที่สำคัญต่อการเลือกทริปของคุณอีกบ้าง? (เลือกได้มากกว่า 1 ข้อ)')
    .setChoiceValues(['ความปลอดภัย', 'สถานที่', 'จำนวนผู้ร่วมทริป', 'รีวิวหรือความน่าเชื่อถือ', 'ไม่มี'])
    .setRequired(false);

  form.addParagraphTextItem()
    .setTitle('ข้อเสนอแนะเพิ่มเติม (ไม่บังคับ)')
    .setRequired(false);

  const sheet = SpreadsheetApp.create('คำตอบแบบสอบถามน้ำหนัก Smart Matching — GoWithUs');
  form.setDestination(FormApp.DestinationType.SPREADSHEET, sheet.getId());

  Logger.log('ลิงก์แก้ไขแบบฟอร์ม: ' + form.getEditUrl());
  Logger.log('ลิงก์สำหรับผู้ตอบ: ' + form.getPublishedUrl());
  Logger.log('ตารางคำตอบ: ' + sheet.getUrl());
}
