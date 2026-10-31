# Combat Foundations — Refactor Design

## Intent
Implement the project owner's maintainability rules **now** while prototype 0.3 is small. Preserve playable behaviour and deterministic seeded battles.

## Approach
Use **small, explicit game systems**, not an elaborate ECS, node hierarchy or general-purpose scripting engine.

- BattleModel handles turn order, RNG, skill ownership, encounter state and Final Stand usage. It delegates damage maths to DamagePipeline.
- DamagePipeline applies an **ordered, named modifier list**, returns the exact steps actually used and the final HP damage. Support add, multiply, subtract; min-one for ordinary mitigation, Final Stand immunity and lethal prevention, and transparent overkill clamping.
- SkillCatalog owns the effect data for Iron Skin and Fireball, including percentages/chances. EncounterCatalog owns enemy base stats and special-action schedule. Adding a skill or enemy should not require copy-pasted cases in the battle loop.
- A small PresentationClock scales visual wait time; neither BattleModel nor DamagePipeline knows about real-world seconds or FPS. BattleStage redraws during animations, not continuously when idle.
- Visuals and combat logs consume structured events from BattleModel. Existing UI and skill selection stay intact.

## Accepted specifics
- Iron Skin still mitigates 20% physical after armor, rounded using Godot roundi.
- Fireball remains a separate 50% extra magic attack at 150% of basic roll (no critical multiplier).
- The Bone Alchemist replaces every third enemy action with a magic potion, 100% attack, no crit.
- Final Stand still triggers once per encounter and blocks later hits within the same action.
- No changes to balance except making displayed overkill damage equal real HP removed.
- No game-speed purchase or progression feature is introduced; simple 1x/2x presentation readiness is enough.

## Rejected alternatives
- Full entity/component engine: too much complexity and indirection for this codebase.
- Just changing comments or constants: leaves hard-coded damage and timing couplings in place.

## Tests and safety
Create regression tests first for custom modifiers and damage types, overkill, seed stability, speed invariance, enemy schedules and preserved skills. Keep changes on `refactor/combat-foundation` derived from the current prototype feature branch; no automatic merge.