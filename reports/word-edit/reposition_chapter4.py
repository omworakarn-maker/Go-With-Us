from docx import Document

SOURCE = "reports/word-edit/เว็บแอพแก้ล่าสุด_ฉบับแก้ไข.docx"

document = Document(SOURCE)
paragraphs = document.paragraphs

anchor_index = next(i for i, p in enumerate(paragraphs) if p.text.startswith("4.1.2 ผลการพัฒนาระบบ Backoffice"))
start_index = next(i for i, p in enumerate(paragraphs) if p.text == "4.1.3 ผลการพัฒนา Backend และฐานข้อมูล")
end_index = next(i for i, p in enumerate(paragraphs) if p.text == "4.7 สรุปผลการดำเนินงาน") + 1

# Move the new block immediately after 4.1.2.  The original document has a
# long run of blank paragraphs before References; leaving the new content
# after them strands its first heading at the bottom of an otherwise blank page.
anchor = paragraphs[anchor_index]._p
block = [paragraphs[i]._p for i in range(start_index, end_index)]
for element in reversed(block):
    anchor.addnext(element)

document.save(SOURCE)
