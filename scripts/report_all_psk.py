from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from lxml import etree
import unicodedata

source=Path('/Users/worakanp/Desktop/Go-with-us-1/reports/รายงานฉบับเต็ม_จัดหน้าใหม่.docx')
output=Path('/tmp/report_psk/รายงานฉบับเต็ม_สารบรรณPSK16.docx')
W='http://schemas.openxmlformats.org/wordprocessingml/2006/main'
M='http://schemas.openxmlformats.org/officeDocument/2006/math'
ns={'w':W,'m':M}
def tag(x):return '{'+W+'}'+x
def apply_props(pr):
    rf=pr.find(tag('rFonts'))
    if rf is None:rf=etree.Element(tag('rFonts'));pr.insert(0,rf)
    rf.attrib.clear()
    for a in ('ascii','hAnsi','eastAsia','cs'):rf.set(tag(a),'TH SarabunPSK')
    for size in ('sz','szCs'):
        s=pr.find(tag(size))
        if s is None:s=etree.SubElement(pr,tag(size))
        s.set(tag('val'),'32')

formulas=[
    'CategoryScore = round[100 × (Ac · Bc) ÷ (||Ac|| × ||Bc||)]',
    'TimeScore = round[100 × (At · Bt) ÷ (||At|| × ||Bt||)]',
    'BudgetScore = round(100 × UserBudget ÷ TripBudget)',
    'MatchScore = round(ผลรวมคะแนนย่อยที่มีข้อมูล ÷ n), n > 0',
]
output.parent.mkdir(parents=True,exist_ok=True)
with ZipFile(source) as zin, ZipFile(output,'w',ZIP_DEFLATED) as zout:
    for item in zin.infolist():
        data=zin.read(item.filename)
        if item.filename.startswith('word/') and item.filename.endswith('.xml'):
            root=etree.fromstring(data)
            if item.filename=='word/document.xml':
                mathparas=root.xpath('//w:p[m:oMathPara or m:oMath]',namespaces=ns)
                assert len(mathparas)==4
                for p,text in zip(mathparas,formulas):
                    for c in list(p):
                        if c.tag!=tag('pPr'):p.remove(c)
                    r=etree.SubElement(p,tag('r'))
                    pr=etree.SubElement(r,tag('rPr'));apply_props(pr)
                    etree.SubElement(r,tag('t')).text=text
            for pr in root.xpath('//w:rPr',namespaces=ns):apply_props(pr)
            for r in root.xpath('//w:r',namespaces=ns):
                pr=r.find(tag('rPr'))
                if pr is None:pr=etree.Element(tag('rPr'));r.insert(0,pr)
                apply_props(pr)
            for rf in root.xpath('//w:rFonts',namespaces=ns):
                rf.attrib.clear()
                for a in ('ascii','hAnsi','eastAsia','cs'):rf.set(tag(a),'TH SarabunPSK')
            for text in root.xpath('//w:t',namespaces=ns):
                if text.text:
                    text.text=''.join(unicodedata.normalize('NFKC',c) if 0x1D400<=ord(c)<=0x1D7FF else c for c in text.text)
                    # Use font formatting for superscripts rather than unsupported modifier-letter glyphs.
                    if 'ᶜ' in text.text or 'ᵗ' in text.text:
                        r=text.getparent();position=r.getparent().index(r)
                        value=text.text
                        for c in list(r):
                            if c.tag!=tag('rPr'):r.remove(c)
                        parts=[];acc=''
                        for c in value:
                            if c in 'ᶜᵗ':
                                if acc:parts.append((acc,False));acc=''
                                parts.append(('c' if c=='ᶜ' else 't',True))
                            else:acc+=c
                        if acc:parts.append((acc,False))
                        from copy import deepcopy
                        for offset,(part,sup) in enumerate(parts):
                            run=r if offset==0 else deepcopy(r)
                            if offset: r.getparent().insert(position+offset,run)
                            for c in list(run):
                                if c.tag!=tag('rPr'):run.remove(c)
                            pr=run.find(tag('rPr'))
                            if sup:
                                v=etree.SubElement(pr,tag('vertAlign'));v.set(tag('val'),'superscript')
                            etree.SubElement(run,tag('t')).text=part
            data=etree.tostring(root,xml_declaration=True,encoding='UTF-8',standalone=True)
        zout.writestr(item,data)

with ZipFile(output) as z:
    fonts=set()
    for name in z.namelist():
        if name.startswith('word/') and name.endswith('.xml'):
            root=etree.fromstring(z.read(name))
            for rf in root.xpath('//w:rFonts',namespaces=ns):fonts.update(rf.attrib.values())
    assert fonts=={'TH SarabunPSK'},fonts
print(output)
print('All Word text fonts verified: TH SarabunPSK 16')
