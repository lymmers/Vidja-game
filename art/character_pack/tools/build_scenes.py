from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
def val(v):
 if isinstance(v,list):return 'Vector2(%s, %s)'%tuple(v)
 return str(v).lower()
def build(who):
 d=json.loads((ROOT/'characters'/who/'rig.json').read_text());paths={}
 for n in d['nodes']:paths[n['name']]=(paths[n['parent']]+'/' if n['parent'] else 'Facing/')+n['name']
 parts=d['parts'];text=['[gd_scene load_steps=23 format=3]','[ext_resource type="Script" path="res://scripts/character_actor.gd" id="1"]']
 for i,p in enumerate(parts,2):text.append(f'[ext_resource type="Texture2D" path="res://{p["file"]}" id="{i}"]')
 animations=dict(d['animations']);reset=[]
 for tr in animations['idle']['tracks']:reset.append(dict(tr,keys=[[0,tr['keys'][0][1]]]))
 animations['RESET']=dict(duration=.001,loop=False,tracks=reset)
 for name,a in animations.items():
  text += [f'[sub_resource type="Animation" id="{name}"]',f'resource_name = "{name}"',f'length = {a["duration"]}',f'loop_mode = {1 if a["loop"] else 0}']
  for i,tr in enumerate(a['tracks']):
   times=', '.join(str(k[0]) for k in tr['keys']);vs=', '.join(val(k[1]) for k in tr['keys'])
   text += [f'tracks/{i}/type = "value"',f'tracks/{i}/path = NodePath("{paths[tr["node"]]}:{tr["property"]}")',f'tracks/{i}/interp = 1',f'tracks/{i}/keys = {{"times": PackedFloat32Array({times}), "transitions": PackedFloat32Array({", ".join("1" for _ in tr["keys"])}), "update": 0, "values": [{vs}]}}']
  if name=='attack':
   i=len(a['tracks']);text += [f'tracks/{i}/type = "method"',f'tracks/{i}/path = NodePath(".")',f'tracks/{i}/keys = {{"times": PackedFloat32Array({a["impact"]}), "transitions": PackedFloat32Array(1), "values": [{{"method": &"_emit_impact", "args": []}}]}}']
 text+=['[sub_resource type="AnimationLibrary" id="Library"]','_data = {'+', '.join('&"'+n+'": SubResource("'+n+'")' for n in animations)+'}']
 slots={}
 mapping={'sword':'weapon','shield':'shield','helmet':'helmet','chestplate':'chest','forearm':'gloves','boot':'boots'}
 for p in parts:
  if p['name'] in mapping and p.get('equipment_enabled',True):slots[mapping[p['name']]]=paths[p['node']]+'/Art_'+p['name']
 text += [f'[node name="{who.capitalize()}" type="Node2D"]','script = ExtResource("1")','equipment_slots = '+json.dumps(slots),'[node name="Facing" type="Node2D" parent="."]']
 for n in d['nodes']:
  parent=paths[n['parent']] if n['parent'] else 'Facing'
  text += [f'[node name="{n["name"]}" type="Node2D" parent="{parent}"]',f'position = {val(n["position"])}',f'rotation = {n["rotation"]}']
 for i,p in enumerate(parts,2):
  w,h=p['size'];px,py=p['pivot'];iw,ih=Image.open(ROOT/p['file']).size
  text += [f'[node name="Art_{p["name"]}" type="Sprite2D" parent="{paths[p["node"]]}"]',f'visible = {str(p.get("visible",True)).lower()}',f'position = Vector2({-w*px}, {-h*py})',f'scale = Vector2({w/iw}, {h/ih})',f'z_index = {p["z"]}',f'texture = ExtResource("{i}")','centered = false',f'metadata/display_size = Vector2({w}, {h})']
 text += ['[node name="AnimationPlayer" type="AnimationPlayer" parent="."]','libraries = {&"": SubResource("Library")}','callback_mode_method = 1','autoplay = "idle"']
 (ROOT/'characters'/who/(who+'.tscn')).write_text('\n\n'.join(text)+'\n')
for who in ['hero','skeleton']:build(who)
