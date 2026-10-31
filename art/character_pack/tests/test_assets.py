from pathlib import Path
import unittest,json
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
class Assets(unittest.TestCase):
 def test_both_rigs_have_transparent_parts_and_real_motion(self):
  for who in ['hero','skeleton']:
   p=ROOT/'characters'/who/'rig.json'
   self.assertTrue(p.exists(),f'Missing {who} rig')
   d=json.loads(p.read_text())
   for part in d['parts']:
    im=Image.open(ROOT/part['file']); self.assertEqual(im.mode,'RGBA')
    self.assertEqual(im.getextrema()[3][0],0)
   self.assertEqual(set(d['animations']),{'idle','attack','hit'})
   for name,a in d['animations'].items():
    self.assertGreater(a['duration'],0)
    self.assertTrue(any(len(set(str(k[1]) for k in t['keys']))>1 for t in a['tracks']),name)
   self.assertTrue(d['animations']['idle']['loop'])
   self.assertFalse(d['animations']['attack']['loop'])
   self.assertTrue(0<d['animations']['attack']['impact']<d['animations']['attack']['duration'])
if __name__=='__main__': unittest.main()
