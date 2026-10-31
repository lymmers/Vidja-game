# Vidja Game — Combat Foundation (Prototype 0.3 refactor)

The goal is to make **common future changes local, safe and easy to read**.
Avoid adding an abstract system unless a real new game mechanic requires it.

## Where the rules live

| Module | Responsibility |
| --- | --- |
| `scripts/combat/battle_model.gd` | Turn order, seeded RNG, selected skills, and encounter state; gathers effect definitions from skills. **No timers or visuals.** |
| `scripts/combat/damage_pipeline.gd` | Ordered damage modifiers, generic pre-hit and lethal-hit operations, overkill, HP application, and a truthful damage ledger. |
| `scripts/combat/combat_effect_state.gd` | Per-combatant usage limits, per-action temporary immunity and reset rules; no skill-name branches. |
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

The existing `magic_resistance` property remains for compatibility; new types should use the `resistances` dictionary. An ordinary mitigated hit has a floor of 1 damage. **Reactive survival effects and immunity may make that 0.** All damage shown in the log is *actual HP lost*, including overkill clamping.

## Adding a damage modifier

Supply an ordered dictionary with `name`, `operation` (`add`, `subtract`, or `multiply`) and `value` (integer delta or multiplier). Optional `damage_type` filters a defensive modifier. The damage pipeline performs the maths and records the true numerical change after rounding/clamping; the formatter only displays it. For percent reduction, `value = 0.75` means 25% reduction. Effects are applied in this order: outgoing bonuses, armor, equipped defenses, resistance, additional custom defenses, reactive survival effects, remaining HP cap.

## Adding a skill

`SkillCatalog.DEFINITIONS` supports `on_attack`, `on_defend`, and `on_damage` (reactive). Each equipped `on_damage` effect is passed to the generic pipeline with its skill ID as the effect ID; the pipeline **never switches on a skill ID**. For example, the entire Final Stand reaction is defined in skill data:

```gdscript
"on_damage": {
    "name": "Final Stand", "trigger": "lethal", "operation": "leave_hp",
    "hp_floor": 1, "uses_per_encounter": 1, "grants_immunity": "action",
}
```

Currently supported reactive operations are `leave_hp` on a `lethal` hit (after mitigation), and `negate_damage` with trigger `always` (before mitigation). Optional `damage_type` filters any reaction. `CombatEffectState` enforces per-encounter usage counts and expires action immunity **when the next logical action begins**, independently of game speed. The pipeline returns `triggered_effects` with the actual effect definition; the formatter uses that data, never a Final-Stand-specific boolean.

To add another *survival skill*, define another `on_damage` effect and add tests — no edits to the battle model, pipeline, or UI. New *categories of behavior* (such as poison ticks or shields with their own resource) will still require a small, explicit generic handler and tests; **not** a skill-specific branch. Reactions are resolved in supplied order; the first applicable lethal reaction wins. Effect IDs must be unique per combatant for correct charge tracking.

For testing effects from systems other than equipped skills, `BattleModel.resolve_hit(..., extra_reactions)` accepts the same dictionaries. A reusable effect can leave 2 or 3 HP just by changing `hp_floor`.

## Adding an enemy

Add data to `EncounterCatalog.ENCOUNTERS` for enemy stats and optional `special_action` with `every`, `kind`, `damage_type`, and `can_crit`. Attack scheduling continues to use logical enemy turn counts and will be identical at 1× and 2×. New animation kinds may require a visual presentation handler, but **combat** remains data-driven.

## Presentation speed and pause

The scene uses `PresentationClock.wait_seconds()` for delays and `BattleStage.animation_speed` for tween durations. `BattleModel` knows nothing about seconds, FPS, or tweens. To add 2× speed later, expose `BattleScreen._set_game_speed(2.0)` from a button or an unlock; no damage formulas should change. Skill selection already pauses battle progression. A future scheduler should retain this boundary, and version/restart callbacks should remain guarded by `run_id`.

## Performance and limits

The stage skips per-frame redraw while idle. History is bounded to 250 entries so long runs don't grow memory indefinitely. Heavy optimization beyond this should be justified by real mobile profiling, not speculation.

## Verification

CI uses Godot 4.7.2 to import the project and run `test_battle_model.gd`, `test_battle_screen.gd`, `test_combat_log.gd`, and `test_foundations.gd`, and `test_generic_effects.gd`. Seeded battle outcomes must remain identical for the same user choices regardless of display speed.