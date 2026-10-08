from copy import deepcopy
from docx import Document
from docx.text.paragraph import Paragraph
from docx.shared import Pt
source=Document('/Users/worakanp/Downloads/รายงานฉบับเต็ม_แยกคะแนนหมวดหมู่และช่วงเวลา.docx')
path='/tmp/report_polished/รายงานฉบับเต็ม_จัดหน้าพร้อมส่ง.docx'
d=Document(path)
ps=source.paragraphs
for i,p in enumerate(ps):
    if not p._p.xpath('.//m:oMath'):continue
    anchor=next(ps[j].text for j in range(i-1,-1,-1) if ps[j].text.strip())
    target=next(x for x in d.paragraphs if x.text==anchor)
    el=deepcopy(p._p);target._p.addnext(el)
    restored=Paragraph(el,target._parent)
    restored.paragraph_format.space_before=Pt(4)
    restored.paragraph_format.space_after=Pt(6)
    restored.paragraph_format.keep_together=True
    restored.paragraph_format.keep_with_next=True
d.save(path)
assert len(Document(path).element.xpath('.//m:oMath'))==len(source.element.xpath('.//m:oMath'))
print('All 4 native Word equations preserved')
