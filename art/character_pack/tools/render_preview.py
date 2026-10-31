from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import numpy as np,json,math
ROOT=Path(__file__).resolve().parents[1]
def sample(keys,t):
 for (a,av),(b,bv) in zip(keys,keys[1:]):
  if t<=b:
   p=max(0,min(1,(t-a)/(b-a)))
   return (np.array(av)*(1-p)+np.array(bv)*p).tolist()
 return keys[-1][1]
def mats(d,anim,t):
 a=d['animations'][anim];t=t%a['duration'] if a['loop'] else min(t,a['duration'])
 nodes={n['name']:dict(n) for n in d['nodes']}
 for tr in a['tracks']:nodes[tr['node']][tr['property']]=sample(tr['keys'],t)
 out={}
 for n in nodes.values():
  x,y=n['position'];r=n['rotation'];c,s=math.cos(r),math.sin(r)
  m=np.array([[c,-s,x],[s,c,y],[0,0,1]])
  out[n['name']]=out[n['parent']]@m if n['parent'] else m
 return out
CACHE={}
def draw_actor(canvas,d,anim,t,origin,scale=1,face=1,armor=False):
 matrices=mats(d,anim,t);world=np.array([[scale*face,0,origin[0]],[0,scale,origin[1]],[0,0,1]])
 for p in sorted(d['parts'],key=lambda p:p['z']):
  vis=p.get('visible',True)
  if p['name'] in ['helmet','chestplate']:vis=armor and p.get('equipment_enabled',True)
  if not vis:continue
  f=p['file']
  if f not in CACHE:CACHE[f]=Image.open(ROOT/f)
  im=CACHE[f];w,h=p['size'];px,py=p['pivot']
  m=world@matrices[p['node']]@np.array([[w/im.width,0,-px*w],[0,h/im.height,-py*h],[0,0,1]])
  inv=np.linalg.inv(m);tr=im.transform(canvas.size,Image.Transform.AFFINE,tuple(inv[:2,:].flatten()),resample=Image.Resampling.BICUBIC)
  canvas.alpha_composite(tr)
def frame(anim='idle',t=0):
 im=Image.new('RGBA',(1000,550),'#e9e4d8');dr=ImageDraw.Draw(im)
 dr.rectangle((0,400,1000,550),fill='#d9d0bd');dr.line((0,400,1000,400),fill='#b9ad96',width=2)
 for x in [280,720]:dr.ellipse((x-65,392,x+65,411),fill='#b7ad9d')
 for who,x,f in [('hero',280,1),('skeleton',720,-1)]:
  d=json.loads((ROOT/'characters'/who/'rig.json').read_text());draw_actor(im,d,anim,t,(x,402),1.15,f)
 dr.text((30,25),'TINY LEGENDS  /  CHARACTER MOTION LAB',fill='#273846',font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',24))
 dr.text((30,65),anim.upper(),fill='#657785',font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',18))
 return im
if __name__=='__main__':
 import sys
 (ROOT/'previews').mkdir(exist_ok=True)
 if '--gif' in sys.argv:
  frames=[]
  for anim,dur in [('idle',2.4),('attack',.78),('idle',.6),('hit',.46),('idle',1.2)]:
   for i in range(round(dur*20)):frames.append(frame(anim,i/20).convert('RGB').resize((800,440)))
  frames[0].save(ROOT/'previews'/'animations.gif',save_all=True,append_images=frames[1:],duration=50,loop=0,optimize=True)
 else:
  shots=[frame('idle',0),frame('attack',.18),frame('attack',.29),frame('hit',.07)]
  out=Image.new('RGB',(2000,1100))
  for i,f in enumerate(shots):out.paste(f,((i%2)*1000,(i//2)*550))
  out.save(ROOT/'previews'/'pose_check.png')
