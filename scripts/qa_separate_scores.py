from pathlib import Path
from PIL import Image, ImageOps, ImageDraw
import sys
root = Path(sys.argv[1] if len(sys.argv)>1 else '/tmp/separate_scores_render')
files = sorted(root.glob('page-*.png'), key=lambda p:int(p.stem.split('-')[1]))
for start in range(0,len(files),40):
    chunk=files[start:start+40]
    canvas=Image.new('RGB',(1200,((len(chunk)+7)//8)*235),'#bbb')
    draw=ImageDraw.Draw(canvas)
    for j,p in enumerate(chunk):
        im=Image.open(p).convert('RGB'); im.thumbnail((145,212))
        x=(j%8)*150;y=(j//8)*235
        canvas.paste(im,(x,y));draw.text((x,y+213),p.stem,fill='black')
    canvas.save(root/f'contact-{start//40+1}.jpg')
print(len(files))
