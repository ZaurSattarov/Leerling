"""Bouwt alle app-iconen voor Klantio Leerling (concept 'Behaald')."""
import json, os, math
from PIL import Image, ImageDraw

BG=(0x1C,0x26,0x36); W=(255,255,255); R=(0xD7,0x2F,0x62)
SS=4  # supersampling

# Geometrie in 256-eenheden
L=36; c=(208-L)-48; cut=c-16*math.sqrt(2); X1=48+cut; Y2=208-cut
WHITES=[((48,48),{'tl':56,'tr':10,'br':10,'bl':10}),
        ((136,136),{'tl':10,'tr':10,'br':56,'bl':10}),
        ((48,136),{'tl':10,'tr':10,'br':10,'bl':56})]

def round_corners(m, d, box, rad, k):
    x0,y0,x1,y1=box
    for name,r in rad.items():
        if not r: continue
        r*=k
        if name=='tl': sq=(x0,y0,x0+r,y0+r); bb=(x0,y0,x0+2*r,y0+2*r); a=(180,270)
        if name=='tr': sq=(x1-r,y0,x1,y0+r); bb=(x1-2*r,y0,x1,y0+2*r); a=(270,360)
        if name=='br': sq=(x1-r,y1-r,x1,y1); bb=(x1-2*r,y1-2*r,x1,y1); a=(0,90)
        if name=='bl': sq=(x0,y1-r,x0+r,y1); bb=(x0,y1-2*r,x0+2*r,y1); a=(90,180)
        d.rectangle(sq, fill=0); d.pieslice(bb, a[0], a[1], fill=255)

def shape_masks(size, scale, off):
    """Geeft (wit-masker, rood-masker) voor het logo; scale = px per eenheid."""
    k=scale; T=lambda x,y:(off[0]+x*k, off[1]+y*k)
    wm=Image.new('L',(size,size),0); rm=Image.new('L',(size,size),0)
    for (x,y),rad in WHITES:
        m=Image.new('L',(size,size),0); d=ImageDraw.Draw(m)
        box=(*T(x,y),*T(x+72,y+72)); d.rectangle(box,fill=255)
        round_corners(m,d,box,rad,k); wm=_max(wm,m)
    # driehoek
    d=ImageDraw.Draw(wm); d.polygon([T(208-L,48),T(208,48),T(208,48+L)],fill=255)
    # rood blok met afgesneden hoek
    d=ImageDraw.Draw(rm); d.polygon([T(136,48),T(X1,48),T(208,Y2),T(208,120),T(136,120)],fill=255)
    round_corners(rm,d,(*T(136,48),*T(208,120)),{'tl':10,'br':10,'bl':10},k)
    return wm,rm

def _max(a,b):
    from PIL import ImageChops; return ImageChops.lighter(a,b)

def render(px, logo_frac, bg=BG, shape=None, mono=False):
    """px: uitvoermaat. logo_frac: breedte van het logo (160 eenheden) t.o.v. canvas.
    bg=None -> transparant. shape: None (vierkant), 'circle', of ('round', fractie)."""
    S=px*SS; k=S*logo_frac/160; off=(S/2-128*k, S/2-128*k)
    wm,rm=shape_masks(S,k,off)
    img=Image.new('RGBA',(S,S),(0,0,0,0))
    if bg:
        bgm=Image.new('L',(S,S),255 if shape is None else 0); d=ImageDraw.Draw(bgm)
        if shape=='circle': d.ellipse((0,0,S-1,S-1),fill=255)
        elif shape: d.rounded_rectangle((0,0,S-1,S-1),radius=int(S*shape[1]),fill=255)
        img.paste(bg+(255,),(0,0),bgm)
    img.paste((255,255,255,255) if mono else R+(255,),(0,0),rm)
    img.paste(W+(255,),(0,0),wm)
    return img.resize((px,px),Image.LANCZOS)

def save(img, path, opaque=False):
    os.makedirs(os.path.dirname(path),exist_ok=True)
    (img.convert('RGB') if opaque else img).save(path, optimize=True)

ICON_FRAC=0.625          # zelfde verhouding als het goedgekeurde ontwerp
FG_FRAC=0.43             # Android adaptive: logo binnen de veilige cirkel van 66dp

# ---------- iOS ----------
ios='ios/AppIcon.appiconset'
spec=[('iphone','20',2),('iphone','20',3),('iphone','29',2),('iphone','29',3),('iphone','40',2),('iphone','40',3),
      ('iphone','60',2),('iphone','60',3),('ipad','20',1),('ipad','20',2),('ipad','29',1),('ipad','29',2),
      ('ipad','40',1),('ipad','40',2),('ipad','76',1),('ipad','76',2),('ipad','83.5',2),('ios-marketing','1024',1)]
images=[]; cache={}
for idiom,pt,sc in spec:
    px=round(float(pt)*sc); fn=f'Icon-{pt}@{sc}x.png' if idiom!='ios-marketing' else 'Icon-1024.png'
    if fn not in cache:
        save(render(px,ICON_FRAC),f'{ios}/{fn}',opaque=True); cache[fn]=1
    images.append({'idiom':idiom,'size':f'{pt}x{pt}','scale':f'{sc}x','filename':fn})
json.dump({'images':images,'info':{'version':1,'author':'xcode'}},open(f'{ios}/Contents.json','w'),indent=2)

# ---------- Android ----------
res='android/res'
dens={'mdpi':1,'hdpi':1.5,'xhdpi':2,'xxhdpi':3,'xxxhdpi':4}
for d,f in dens.items():
    save(render(int(48*f),ICON_FRAC*1.0,shape=('round',0.18)),f'{res}/mipmap-{d}/ic_launcher.png')
    save(render(int(48*f),0.56,shape='circle'),f'{res}/mipmap-{d}/ic_launcher_round.png')
    save(render(int(108*f),FG_FRAC,bg=None),f'{res}/mipmap-{d}/ic_launcher_foreground.png')
    save(render(int(108*f),FG_FRAC,bg=None,mono=True),f'{res}/mipmap-{d}/ic_launcher_monochrome.png')
adaptive='''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>
</adaptive-icon>
'''
os.makedirs(f'{res}/mipmap-anydpi-v26',exist_ok=True)
for n in ('ic_launcher','ic_launcher_round'): open(f'{res}/mipmap-anydpi-v26/{n}.xml','w').write(adaptive)
os.makedirs(f'{res}/values',exist_ok=True)
open(f'{res}/values/ic_launcher_background.xml','w').write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#1C2636</color>\n</resources>\n')
save(render(512,ICON_FRAC),'android/play-store-icon-512.png',opaque=True)

# ---------- Masters ----------
save(render(1024,ICON_FRAC),'master/app-icon-1024.png',opaque=True)
save(render(1024,0.9,bg=None),'master/logo-transparant-1024.png')
save(render(1024,0.9,bg=None,mono=True),'master/logo-wit-1024.png')
print('klaar')
