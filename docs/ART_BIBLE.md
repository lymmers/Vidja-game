# Art and asset contract

## Approved direction
Portrait, side-view 2D chibi/cartoon fantasy. Art Department supplies assets;
Game Director approves visual changes. Preserve working articulated cutout rigs.

## Implemented
PR #4 (`b7c4a99`) supplies hero and skeleton scenes, 16 PNG parts each,
native idle (2.4s), attack (0.78s), hit (0.46s), RESET and impact at 0.29s.
Runtime files preserve res://characters and res://scripts/character_actor.gd paths.
The complete original pack is retained under art/character_pack, ignored by root
imports and usable as a separate demo project. Do not overwrite root project.godot.

The game scales actors to 0.9, anchors feet at (210,751)/(515,751), and faces
hero right/enemy left. Enemy 2 is still the original procedural Bone Alchemist.
Animation impacts are presentation cues only. Native playback, equipment hooks,
interruption and mixed encounters were checked on Godot 4.7.2 headlessly.
Rendered positioning, clipping and aesthetic approval still need visual playtesting.

## Supplied limitations
No walk, death or turnaround animations. Replacements must respect attachment
pivots and supplied display proportions; arbitrary weapons may need scene edits.
Skeleton helmet is baked into its primary head; independent helmet removal needs
new head art. Gloves/boots helper affects near limbs; far limbs remain separate
Sprite2D parts. This is attachment support, not an inventory system. Generator
scripts overwrite scenes: update rig.json or preserve manual edits before rebuilding.
