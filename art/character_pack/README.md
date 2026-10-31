# Tiny Legends — animated character pack

Two articulated 2D characters for Godot 4.4+: the neutral-presenting hero and evil skeleton. This is a first cutout animation pass based on the approved cartoon designs, with reconstructed transparent parts. It is not a 3D model or final mesh-deformed animation.

## Try it

Extract the ZIP and import `project.godot` in Godot. Run the project for the combat animation demo. Alternatively open `previews/motion_lab.html` in a browser; it is self-contained and works offline. It includes attack/hit controls, automatic sparring, speed, equipment overlays and joint visualization. `previews/animations.gif` is a quick motion reference.

## Included

- 16 transparent PNG parts per character, including spare equipment.
- Editable Node2D joint hierarchies and Sprite2D artwork in `characters/hero/hero.tscn` and `characters/skeleton/skeleton.tscn`.
- Native AnimationPlayer animations: looping idle (2.4s), attack (0.78s), damage recoil (`hit`, 0.46s), and RESET.
- Attack impact signal at 0.29s, interruption handling and automatic return to idle.
- Source atlases, JSON joint/keyframe definitions, build scripts and validation checks.

## Add to the game

Copy `characters/` and `scripts/character_actor.gd` into your project's root, preserving those paths. Instance either character scene into the battle stage. The actor root is approximately at the feet; change its position and uniform scale to fit the stage. The supplied demo is standalone and has not been merged into the separate combat project.

```gdscript
var hero = preload("res://characters/hero/hero.tscn").instantiate()
add_child(hero)
hero.position = Vector2(240, 480)
hero.set_facing(1) # 1 right, -1 left
hero.impact.connect(func(): enemy.play_action("hit"))
hero.play_action("attack")
```

Use `play_action("idle")`, `play_action("attack")`, and `play_action("hit")`. Treat `impact` as a presentation cue only (hit flash, sound or recoil). The combat model must resolve outcomes independently of animation timing; animations present already-resolved events. The demo only shows reactions; it does not implement health, targeting or combat rules. `action_finished(action)` and `action_cancelled(action)` let your controller track completion and interruptions.

## Equipment

`set_equipment_texture("weapon", texture)` replaces the sword attached to the hand. Other slots are `shield`, `chest`, `gloves`, `boots`, and hero-only `helmet`. Supply transparent textures with the same placement/proportions as the corresponding included PNG; the current helper scales replacements to the slot's existing display size. Arbitrary weapon proportions require editing the pivot/display size in the scene.

`set_armor_visible(true)` shows alternate chest armour and the hero helmet. The skeleton's primary head already includes its helmet, so the spare skeleton helmet is intentionally not an active overlay. A bare skull/new head asset is needed for independent skeleton helmet swaps. Gloves and boots slots currently affect the near limb; far limbs are separate Sprite2D parts that can be replaced in the editor. This demonstrates equipment attachment, not a complete inventory or armour-set system.

## Editing and rebuilding

Edit native Godot animation tracks directly for game integration. Generator scripts overwrite generated scenes, so preserve editor changes separately or update `rig.json` before rebuilding.

Python tooling requires Pillow, NumPy and SciPy. From this folder:

```sh
python3 tools/build_assets.py
python3 tools/build_scenes.py
python3 tools/build_html.py
python3 tests/test_assets.py
godot --headless --path . --editor --import
godot --headless --path . --script tests/test_rigs.gd
```

`build_assets.py` extracts the included source atlases and regenerates joint/keyframe JSON. `build_scenes.py` and `build_html.py` consume that JSON. The optional Python GIF renderer uses a Linux DejaVu font path; change that path on other systems.

## Scope and validation

Tested in Godot 4.4.1: both scene loads, all animation names, one impact per attack, interruption cancellation, no delayed impact after interruption, idle return, facing and equipment replacement. Transparent parts and animated keyframes have automated checks. Browser preview uses the same JSON animation data; it is a motion viewer, not an export of the actual Godot game. No walking, death, directional turnaround or final animation polish is included yet.

Browser automation could not run in this environment because the browser download was unavailable; the HTML preview has not received a browser runtime check. Godot tests and rendered pose inspections were completed.

## Repository placement

This pack is staged under `art/character_pack/` for review and integration. Open this folder's `project.godot` separately. `.gdignore` keeps its nested demo and tooling out of the root game project imports. When integrating, move the runtime scenes, parts and actor script into the game's chosen asset folders and update `res://` paths. Do not copy this project.godot over the root project.

The repository targets Godot 4.7; the pack was tested in 4.4.1 only. Godot 4.7 compatibility and integration into the current combat presentation remain unverified. No combat behavior is changed by this upload.
