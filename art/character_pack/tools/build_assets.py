from PIL import Image
import numpy as np, scipy.ndimage as nd
from pathlib import Path
import json,math,sys
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'source_art'
SOURCES={'hero':'exec-080e43c7-cd56-4143-9a34-50c477f7611c.png','skeleton':'exec-f46d4901-6a6a-4693-9cfc-aac9433e756d.png'}
NAMES=['head','torso','pelvis','scarf','upper_arm','forearm','far_upper_arm','far_forearm','thigh','boot','far_thigh','far_boot','sword','shield','helmet','chestplate']
def extract(who):
 im=Image.open(SRC/SOURCES[who]).convert('RGBA'); a=np.array(im); lab,n=nd.label(a[:,:,3]>100)
 comps=[]
 for i,s in enumerate(nd.find_objects(lab)):
  if (lab[s]==i+1).sum()>500: comps.append((s,i+1))
 assert len(comps)==16
 comps.sort(key=lambda v:v[0][0].start)
 order=[]
 for r in range(4): order+=sorted(comps[r*4:r*4+4],key=lambda v:v[0][1].start)
 out=ROOT/'characters'/who/'parts';out.mkdir(parents=True,exist_ok=True)
 for name,(s,idx) in zip(NAMES,order):
  y0=max(0,s[0].start-3); y1=min(im.height,s[0].stop+3); x0=max(0,s[1].start-3); x1=min(im.width,s[1].stop+3)
  crop=a[y0:y1,x0:x1].copy(); mask=nd.binary_dilation(lab[y0:y1,x0:x1]==idx,iterations=2)
  crop[:,:,3]*=mask.astype('uint8'); cut=Image.fromarray(crop); pad=Image.new('RGBA',(cut.width+8,cut.height+8));pad.paste(cut,(4,4));pad.save(out/(name+'.png'))
 return out

def rig(who):
 nodes=[];parts=[]
 def node(name,parent,pos=(0,0),rot=0): nodes.append(dict(name=name,parent=parent,position=list(pos),rotation=math.radians(rot)))
 def part(name,joint,size,pivot,z): parts.append(dict(name=name,node=joint,file=f'characters/{who}/parts/{name}.png',size=size,pivot=pivot,z=z))
 node('Rig','',[0,-110]);node('Body','Rig',[0,-55]);node('Head','Body',[0,-3]);node('Scarf','Body',[-5,2],5)
 node('FarArm','Body',[-24,17],18);node('FarForearm','FarArm',[0,34],-35);node('Shield','FarForearm',[0,36],15)
 node('NearArm','Body',[27,18],-35);node('NearForearm','NearArm',[0,34],-55);node('Weapon','NearForearm',[0,37],120)
 node('FarThigh','Rig',[-20,18],13);node('FarBoot','FarThigh',[0,35],-13)
 node('NearThigh','Rig',[20,18],-13);node('NearBoot','NearThigh',[0,35],13)
 part('far_thigh','FarThigh',[31,47],[.5,.13],0);part('far_boot','FarBoot',[49,57],[.35,.12],1)
 part('far_upper_arm','FarArm',[29,47],[.5,.15],2);part('far_forearm','FarForearm',[28,49],[.5,.12],3)
 part('scarf','Scarf',[105,60],[.94,.35],4)
 part('thigh','NearThigh',[32,47],[.5,.13],5);part('boot','NearBoot',[50,57],[.35,.12],6)
 part('torso','Body',[80,82],[.5,.12],7);part('pelvis','Rig',[79,45],[.5,.22],8)
 part('head','Head',[145,125] if who=='hero' else [140,145],[.5,.91],9)
 part('shield','Shield',[72,78],[.5,.5],10)
 part('upper_arm','NearArm',[30,47],[.5,.15],11);part('sword','Weapon',[49,129],[.5,.85],12);part('forearm','NearForearm',[30,49],[.5,.12],13)
 # Alternate equipment are attachable independent overlays, not baked into body parts.
 node('Helmet','Head',[0,0]);node('Chestplate','Body',[0,0])
 part('helmet','Helmet',[148,112],[.5,.95],15);part('chestplate','Chestplate',[91,84],[.5,.12],8)
 for p in parts:
  if p['name'] in ('helmet','chestplate'):p['visible']=False
  if p['name']=='shield' and who=='hero':p['visible']=False
  if p['name']=='helmet' and who=='skeleton':p['equipment_enabled']=False
 base={n['name']:n for n in nodes}
 def track(n,prop,keys):return dict(node=n,property=prop,keys=keys)
 def rot(n,times,vals):return track(n,'rotation',[[t,math.radians(v)] for t,v in zip(times,vals)])
 def xpos(n,times,vals):return track(n,'position',[[t,[x,base[n]['position'][1]]] for t,x in zip(times,vals)])
 # Each action keys all animated properties, preventing stale transforms after interruptions.
 animated=['Body','Head','Scarf','NearArm','NearForearm','Weapon','FarArm','FarForearm','NearThigh','NearBoot','FarThigh','FarBoot']
 def complete(tracks,duration):
  keyed={(t['node'],t['property']) for t in tracks}
  for n in animated:
   if (n,'rotation') not in keyed: tracks.append(track(n,'rotation',[[0,base[n]['rotation']],[duration,base[n]['rotation']]]))
  for n in ['Rig','Body']:
   if (n,'position') not in keyed:tracks.append(track(n,'position',[[0,base[n]['position']],[duration,base[n]['position']]]))
  return tracks
 idle=[track('Body','position',[[0,[0,-55]],[.6,[0,-58]],[1.2,[0,-55]],[1.8,[0,-53]],[2.4,[0,-55]]]),rot('Head',[0,1.2,2.4],[0,2,0]),rot('Scarf',[0,.6,1.2,1.8,2.4],[5,-1,7,1,5]),rot('NearArm',[0,1.2,2.4],[-35,-32,-35]),rot('FarArm',[0,1.2,2.4],[18,15,18]),rot('NearThigh',[0,1.2,2.4],[-13,-12,-13]),rot('NearBoot',[0,1.2,2.4],[13,12,13]),rot('FarThigh',[0,1.2,2.4],[13,12,13]),rot('FarBoot',[0,1.2,2.4],[-13,-12,-13])]
 ts=[0,.18,.29,.37,.55,.78]
 atk=[rot('Body',ts,[0,-10,9,12,5,0]),rot('Head',ts,[0,6,-5,-6,-2,0]),rot('NearArm',ts,[-35,65,-100,-105,-70,-35]),rot('NearForearm',ts,[-55,-100,-20,-15,-35,-55]),rot('Weapon',ts,[120,35,195,195,150,120]),rot('Scarf',ts,[5,20,-20,-25,0,5]),xpos('Rig',ts,[0,-8,27,30,12,0]),rot('FarArm',ts,[18,28,-5,0,10,18]),rot('NearThigh',ts,[-13,-6,-24,-26,-18,-13]),rot('NearBoot',ts,[13,6,24,26,18,13]),rot('FarThigh',ts,[13,22,8,6,10,13]),rot('FarBoot',ts,[-13,-22,-8,-6,-10,-13])]
 ht=[0,.07,.17,.30,.46]
 hit=[xpos('Rig',ht,[0,-17,-12,-4,0]),rot('Body',ht,[0,-17,-11,-4,0]),rot('Head',ht,[0,-12,-6,1,0]),rot('NearArm',ht,[-35,-5,-15,-29,-35]),rot('NearForearm',ht,[-55,-35,-42,-50,-55]),rot('Scarf',ht,[5,25,18,-3,5])]
 return dict(character=who,nodes=nodes,parts=parts,animations={'idle':dict(duration=2.4,loop=True,tracks=complete(idle,2.4)),'attack':dict(duration=.78,loop=False,impact=.29,tracks=complete(atk,.78)),'hit':dict(duration=.46,loop=False,tracks=complete(hit,.46))})
if __name__=='__main__':
 for who in SOURCES:
  extract(who);d=rig(who);(ROOT/'characters'/who/'rig.json').write_text(json.dumps(d,indent=2))
 print('Extracted 32 alpha parts and two animation definitions')
