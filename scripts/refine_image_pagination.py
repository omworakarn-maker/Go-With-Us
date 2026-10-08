from docx import Document
path='/tmp/report_polished/รายงานฉบับเต็ม_จัดหน้าพร้อมส่ง.docx'
d=Document(path)
ps=d.paragraphs
for i,p in enumerate(ps):
    if not p._p.xpath('.//w:drawing'):continue
    nexttext=ps[i+1].text.strip() if i+1<len(ps) else ''
    iscaption=nexttext.startswith(('รูปที่','ภาพที่','คำบรรยาย:','3.4.4 แผนผัง'))
    p.paragraph_format.keep_with_next=iscaption
    if iscaption:
        ps[i+1].paragraph_format.keep_with_next=False
    if i:
        prev=ps[i-1]
        t=prev.text.strip()
        if t and len(t)<320 and not t.startswith(('รูปที่','ภาพที่','คำบรรยาย:')):
            prev.paragraph_format.keep_with_next=True
d.save(path)
