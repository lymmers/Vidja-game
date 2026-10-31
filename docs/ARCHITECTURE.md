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

## Initiative and party-side-first scheduling (scalable refactor)

`TurnScheduler` owns **logical actions** and has no reference to frames or animation duration. Each round contains one action per living registered combatant, in descending initiative order with stable registration-order ties. Default initiative side bonuses are **player = 100**, **enemy = 0**. This ensures the player's side (including pets/companions) starts by default. **The default is policy, not a rule baked into the battle loop.** A future ambush or initiative modifier can change the opening order:

```gdscript
battle.set_initiative_modifiers([{"side": "enemy", "add": 200}])
# The enemy now acts before the hero for this encounter.
```

`add_party_member("pet_ember", pet_unit)` registers a second player-side combatant. Actor IDs are stable identifiers (e.g. `hero`, `pet_ember`, `enemy`) and are used by effect counters, the scheduler, and combat events. They must be unique; never use `Object.get_instance_id()` for game-state identity. Additional enemies can be registered similarly via `add_enemy` before an encounter starts. The current prototype still draws only the primary hero and enemy; additional actors are exercised by headless combat tests rather than given new visuals prematurely.

`queue_extra_action(actor_id)` supports bonus actions and `skip_next_actions(actor_id, count)` is a hook for stuns/turn skips. The scheduler does not use `turn_index % 2` and preserves initiative order for every full round. Initiative adjustments made after actions begin take effect at the next encounter's opening, not midway through an existing round.

## Multi-effect skills and generic triggers

Skill definitions now contain a **list** of independently identified effects. Each effect declares a trigger and a reusable operation; no handler switches on a skill name:

```gdscript
"effects": [
    {"id": "example:fire", "name": "Flame", "trigger": "after_attack",
     "operation": "bonus_hit", "damage_type": "magic", "kind": "fireball",
     "chance": 0.5, "power_multiplier": 1.5},
    {"id": "example:ward", "name": "Ward", "trigger": "before_damage",
     "operation": "multiply", "damage_type": "physical", "value": 0.8},
]
```

Current hooks include `after_attack`, `after_damage`, `on_kill`, `before_damage`, `lethal`, and `always`. Supported operations cover bonus hits, post-damage healing, bonus actions, arithmetic modifiers and incoming-damage reactions. When a new *type* of effect is required, extend the generic interpreter and its validator once, not every skill or enemy. The bonus-hit chain has a 32-event safeguard per primary attack. Limit checks and temporary immunity remain in `CombatEffectState`, keyed by stable actor and effect IDs.

## Independent random streams

`BattleModel.rng` is the seeded **combat** stream (retained as a compatibility alias). `draft_rng` and `cosmetic_rng` are different streams. Drafting a skill, or adding a particle effect, must not change critical hits, attack rolls, or Fireball procs in a seeded encounter. Use `draft_rng` for `SkillCatalog.get_choices`.

## Validated definitions and fail-loud behavior

`DataValidator` checks skill names, effect IDs, triggers, operations, chance ranges, survival floors, enemy stats and special-action intervals. The game refuses an invalid equipped skill. Unknown encounter IDs return no definition instead of silently replacing the requested enemy with a goblin. Attempting to start an undefined encounter reports an explicit error and stops the encounter. Future content types should add validation with their definitions.

## UI follows game data

The active-skill bar is a horizontally scrollable list that grows with the owned skills; no fixed three-slot limit. The encounter header, art selector and introductory text read the encounter definition rather than checking names. The current two-encounter run remains deliberately finite, but new encounter definitions can be chained without rewriting combat calculations.

## Regression contract

In addition to the original Godot headless suites, `tests/test_architecture.gd` checks party-first, enemy-first modifiers, companions, bonus actions, separated RNG, multiple stacked defensive effects, and content validation. The on-screen UI smoke test also checks that the active-skill list grows dynamically.