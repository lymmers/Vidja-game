# Vidja Game — Combat Foundation (Prototype 0.3 refactor)

The goal is to make **common future changes local, safe and easy to read**.
Avoid adding an abstract system unless a real new game mechanic requires it.

## Where the rules live

| Module | Responsibility |
| --- | --- |
| `scripts/combat/battle_model.gd` | Turn order, seeded RNG, the player's selected skills, encounter state and Final Stand's per-action state. **No timers or visuals.** |
| `scripts/combat/damage_pipeline.gd` | Ordered bonus/defense modifiers, rounding, minimum damage, Final Stand's HP cap, overkill, HP application and truthful damage ledger. |
| `scripts/combat/battle_unit.gd` | Current HP and stats, including a dictionary of named resistance types. |
| `scripts/combat/encounter_catalog.gd` | Enemy stats and their special-action interval/type; the turn loop doesn't know the skeleton by name. |
| `scripts/skills/skill_catalog.gd` | Skill descriptions and data-defined attack/defense effects. |
| `scripts/battle/presentation_clock.gd` | Presentation speed conversion only; never used by the battle model. |
| `scripts/visuals/battle_stage.gd` | Placeholder art and tweening. Redraws only while an animation is active. |
| `scripts/battle_screen.gd` | The scene, input, animation ordering, skill draft, HP bars and combat-log UI. |

## Adding a resistance or damage type

1. Assign a string damage type to an action (e.g. `"arcane"`).
2. Add `unit.resistances["arcane"] = 0.25` for a 25% reduction, when applicable.
3. All matching hits automatically apply the reduction **after armor and equipped defensive effects**, rounding to nearest integer, and emit a named ledger entry.
4. Test in `tests/test_foundations.gd` and `tests/test_combat_log.gd`.

The existing `magic_resistance` property remains for compatibility; new types should use the `resistances` dictionary. An ordinary mitigated hit has a floor of 1 damage. **Final Stand and immunity may make that 0.** All damage shown in the log is *actual HP lost*, including overkill clamping.

## Adding a damage modifier

Supply an ordered dictionary with `name`, `operation` (`add`, `subtract`, or `multiply`) and `value` (integer delta or multiplier). Optional `damage_type` filters a defensive modifier. The damage pipeline performs the maths and records the true numerical change after rounding/clamping; the formatter only displays it. For percent reduction, `value = 0.75` means 25% reduction. Effects are applied in this order: outgoing bonuses, armor, equipped defenses, resistance, additional custom defenses, Final Stand, remaining HP cap.

## Adding a skill

`SkillCatalog.DEFINITIONS` supports `on_attack` (chance, kind, damage type, base-attack multiplier, modifier name) and `on_defend` (one modifier). The current three examples map directly to these definitions. An entirely new effect **category** (such as an ongoing poison or shield) will need a new explicit handler; don't stretch a simple damage modifier into an inscrutable generic trigger engine. Keep unique stateful effects (e.g. Final Stand) in a focused state handler.

## Adding an enemy

Add data to `EncounterCatalog.ENCOUNTERS` for enemy stats and optional `special_action` with `every`, `kind`, `damage_type`, and `can_crit`. Attack scheduling continues to use logical enemy turn counts and will be identical at 1× and 2×. New animation kinds may require a visual presentation handler, but **combat** remains data-driven.

## Presentation speed and pause

The scene uses `PresentationClock.wait_seconds()` for delays and `BattleStage.animation_speed` for tween durations. `BattleModel` knows nothing about seconds, FPS, or tweens. To add 2× speed later, expose `BattleScreen._set_game_speed(2.0)` from a button or an unlock; no damage formulas should change. Skill selection already pauses battle progression. A future scheduler should retain this boundary, and version/restart callbacks should remain guarded by `run_id`.

## Performance and limits

The stage skips per-frame redraw while idle. History is bounded to 250 entries so long runs don't grow memory indefinitely. Heavy optimization beyond this should be justified by real mobile profiling, not speculation.

## Verification

CI uses Godot 4.7.2 to import the project and run `test_battle_model.gd`, `test_battle_screen.gd`, `test_combat_log.gd`, and `test_foundations.gd`. Seeded battle outcomes must remain identical for the same user choices regardless of display speed.