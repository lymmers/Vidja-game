# Character integration report — 31 October 2026

## Scope and result

Implemented locally on `integration/character-rigs`, based on latest development
commit `ece2bc5`, using PR #4 asset commit `b7c4a99`. Prepared on an isolated playtest branch. No branches were merged and no
stacked PR integration policy was changed. See PLAYTEST_CHARACTER_RIGS.md for
the existing GitHub ZIP / Godot import / F5 process.

- Extended root AGENTS.md without removing existing engineering rules.
- Completed a read-only architecture audit before integration.
- Instanced original articulated player and skeleton scenes; native idle, attack,
  hit, impact, interruption, completion and equipment helpers remain intact.
- First enemy now displays SKELETON, with its previous balance and basic attack.
- Bone Alchemist definition remains exactly unchanged; its procedural drawing,
  landscape, spell animation and legacy attack tween branch are preserved.
- Combat model, pipeline, scheduler, effect state, units and skill definitions
  are unchanged from the development baseline.

## Files

Modified: AGENTS.md, README.md, docs/ARCHITECTURE.md,
scripts/battle_screen.gd, scripts/combat/encounter_catalog.gd,
scripts/visuals/battle_stage.gd, tests/test_battle_model.gd,
.github/workflows/godot-tests.yml.

Added runtime files: characters/hero and characters/skeleton (supplied scenes,
parts and rig JSON), scripts/character_actor.gd (unchanged supplied controller),
scripts/visuals/character_visuals.gd (presentation-only registry).
Original standalone PR #4 pack is retained in art/character_pack with demo,
source art, tooling, previews and tests. Generated Godot caches are ignored;
UID and texture-import sidecars are engine-generated setup outputs.

Added verification: tests/test_character_rigs.gd (supplied rig suite),
tests/test_rig_integration.gd, tools/test.sh. CI now uses this same full runner,
which rejects engine errors even when a test process returns exit zero.

Added documentation: docs/ARCHITECTURE_AUDIT.md, docs/GAME_DESIGN.md,
docs/ART_BIBLE.md, docs/DECISIONS.md, docs/ROADMAP.md, this report, and
implementation checklist docs/superpowers/plans/2026-10-31-character-rigs.md.

## Verification

Godot 4.7.2 official Linux build, verified against the release's SHA-512 manifest.
`GODOT_BIN=/workspace/tools/godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64 bash tools/test.sh`
passed all eight tests/test_*.gd scripts (six existing, two new) after import.
Covers combat, skills, modifiers/logs, initiative, generic effects, RNG isolation,
native rigs, impacts, interruption, facing, equipment and full seeded progression
through both encounters, including potion use, mixed rendering and restart.

The supplied standalone rig suite passed before integration. The standalone demo
was also instantiated and exercised through idle, attacks, damage and automatic
sparring on 4.7.2. `python3 art/character_pack/tests/test_assets.py` passed its one
unittest, checking both rigs' transparent PNG parts and animation keyframe data.
Source comparisons confirmed supplied runtime files are byte-identical to the pack,
Alchemist drawing/spell code unchanged, and combat implementation untouched.
`git diff --check` passed. GitHub CI was updated but not run remotely.

All runtime checks were **headless**. Position anchors, facing and playback are
programmatically checked; rendered appearance, clipping, polish and mobile visual
approval need a graphical playtest. Root import reports the expected warning that
the nested standalone demo project is ignored. Final test runs had no script/engine
errors or object-leak warnings.

## Audit and decisions

See ARCHITECTURE_AUDIT.md for the prioritized findings. Highest priorities are
per-actor action definitions (additional enemies currently inherit encounter
specials) and a bonus-action budget (the event cap does not bound turn queues).
Medium concerns include party presentation collapsing actor IDs to sides, missing
healing ledger events, incomplete validation and gaps in historical test coverage.
These are proposed follow-ups; no unrelated rules were changed.

Both PR #4 rigs work as supplied under Godot 4.7.2. No flattened/recreated or generic
replacement animations were used. Missing supplied components remain walk/death/
turnaround animations, independent skeleton helmet removal, and automatic far-limb
equipment replacement. No decision is blocking this scoped integration. New
mechanics, balance changes, substantial architecture fixes and additional art
components require the Director's approval before further work.

The stage uses z=-100 so native positive sprite layers remain below the z=0
HUD, skill draft and combat-log overlays. Effective-z regression tests cover all
rig Sprite2D parts; native internal layer ordering is preserved.


## Subsequent visual review
The original byte-identity/headless findings above describe the initial integration,
not a visual acceptance. Director playtesting exposed source forearm occlusion.
Runtime scene/rig JSON layer values have since been corrected; actual rendered
evidence and outstanding contact/asset issues are recorded in
VISUAL_INTEGRATION_REVIEW.md. No merge approval is implied.
