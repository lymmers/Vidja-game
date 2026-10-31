# Character rig integration plan

Goal: integrate PR #4's supplied hero and skeleton, replacing only Enemy 1's
presentation and displayed identity, without combat or balance changes.
Approved scope: Game Director's Development Handoff, supplied 31 October 2026.
Implementation uses native Godot 4.7.2 scenes and animations.

- [x] Extend root AGENTS.md with approved operating rules, preserving existing rules.
- [x] Read latest development architecture; record prioritized read-only audit.
- [x] Fetch PR #4; verify checksum of Godot 4.7.2 and run baseline game/rig suites.
- [x] Run supplied demo through idle, attack, damage and automatic sparring.
- [x] Add failing presentation regression tests: supplied scenes, distinct first-enemy
  selector, unchanged Alchemist, facing/feet/scale, native playback/impact, reset,
  speed and full encounter progression.
- [x] Copy runtime scenes/parts and actor script with their supplied resource paths;
  retain original standalone pack. Add small presentation-only scene catalog.
- [x] Wire BattleStage to native idle/attack/hit and impact signals. Preserve
  procedural Alchemist drawing and its attack/spell tween timings.
- [x] Update Enemy 1 name/intro/visual selector and data-driven initial screen labels.
  Preserve both enemies' stats, Enemy 2's entire definition and simulation code.
- [x] Run existing and new tests, supplied demo and rig checks; inspect engine logs.
- [x] Update existing architecture and add concise design/art/decisions/roadmap docs.
  Report headless-only visual limitations and missing animations.

Review focus: mixed cutout/procedural presentation; cancellation without stale impact;
1x/2x native animation pacing; full two-encounter progression; unchanged Enemy 2.
No merge to main, gameplay expansion or major architecture changes is authorized.
