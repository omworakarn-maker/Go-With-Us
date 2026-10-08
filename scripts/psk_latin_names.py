from docx import Document
path='/tmp/report_psk/รายงานฉบับเต็ม_สารบรรณPSK16.docx'
d=Document(path)
for p in d.paragraphs:
    for r in p.runs:
        for a,b in [('Sutavičiūtė','Sutaviciute'),('Paulavičius','Paulavicius'),('Kočegarov','Kocegarov')]:
            if a in r.text:r.text=r.text.replace(a,b)
d.save(path)
