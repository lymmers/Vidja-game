# Engineering Standards — Design for Change Without Overengineering

**Project:** Vidja Game / Tiny Legends (Godot 4.7, GDScript)

**Intent:** Build a fantasy roguelite that is easy to modify and understand as skills, status effects, damage types, enemy AI and optional 2× game speed are introduced. This document records the owner's requested engineering constraints. It defines expectations for future work; it is **not** a claim that today's prototype has already been fully refactored to meet them.

## 1. Separate simulation, presentation, and data

- **Simulation:** deterministic, testable outcomes: turn order, attack rolls, damage, status effects, death checks, skill triggers, encounter progression.
- **Data:** definitions of skills, enemies, base stats, coefficients, durations, and effect tags. Balance changes belong in one sensible place rather than duplicated conditionals.
- **Presentation:** buttons, skill cards, HP bars, animation, sounds and combat-log display. Presentation responds to simulation results; it does not decide mechanics.
- **Scheduler:** decides when the next logical action is processed. It can pause for player skill selection and later change speed without altering combat formulas.

Avoid circular dependencies. A combat model should run in headless tests without loading a battle scene. UI displays result events without recomputing HP loss.

## 2. A scalable modifier and damage pipeline

When the prototype grows, evolve `resolve_hit` toward a clear **damage context -> ordered effects -> damage result** flow. No premature general-purpose plugin framework is required: a small set of plain typed records/dictionaries and focused functions is enough initially.

Each damage event should retain:
- source/target, attack or skill identifier and damage type;
- base attack roll and additive/multiplicative bonus details (including a crit multiplier);
- named mitigation steps (e.g. Armor, Iron Skin, future Magic Resistance);
- pre-mitigation and post-mitigation values where relevant;
- rounding rule and how any minimum-damage rule applies;
- special prevention (e.g. Final Stand or invulnerability), final HP damage applied, and remaining HP.

**Example** (illustrative values, not a live battle event): `20 base + 10 Critical - 2 Armor - 6 Iron Skin = 22 Physical damage`. The log should be generated from the same ordered steps that affected HP, rather than re-deriving math from stat names. Note that 20% mitigation must be computed against the specified intermediate amount, with a documented rounding rule; do not simply subtract a percentage of the initial base if the chosen ordering differs.

The owner should be able to add a new damage resistance or modifier by extending appropriate data/rules, without editing every enemy's attack code or the combat log UI. Explicitly decide stacking order, minimum damage and rounding when introducing new effect types, then cover that decision with tests.

**Do not hide exceptions.** A hit that dealt 0 due to immunity, was prevented by Final Stand, or was overkill must display a truthful reason and final applied HP change.

## 3. Game speed must never be a hidden gameplay stat

For our current **turn-based** game:
- The logical sequence is a list of actions/turns; battle calculations occur once per resolved action.
- **1× vs 2×** should change scheduling delays, tween/visual durations and perhaps effect timing *in real-world seconds*, not how much damage a hit deals or how often a per-turn effect triggers.
- Do not use `_process(delta)`, FPS, animation-finished signals or visual `SceneTreeTimer` intervals to determine critical hits, potion frequency, status expiration or skill chances.
- For any future continuous-time mechanic, pick **simulation time** or a fixed logical tick; advance that clock consistently. Clearly distinguish simulation duration, turn duration and real-world animation duration.
- Pausing for skill selection must pause simulation progress. Restarts must invalidate pending animation/callback work from older runs.
- Keep seeded RNG within the combat system; the number/order of rolls should not change merely because effects animate faster.

**Acceptance check:** With the same battle seed, starting state and decisions, the turn-by-turn outcomes are identical at 1× and 2×, even though the wall-clock play duration changes.

## 4. Maintainable, human-readable GDScript

- Use descriptive function and variable names (e.g. `damage_after_armor`, `enemy_actions_taken`).
- Prefer short methods with one clear responsibility; move cohesive rules into appropriately named files.
- Use type annotations for public methods, state and event structures when feasible; define a clear event contract.
- Write comments for reasons, assumptions, formula order, non-obvious guard conditions and pitfalls. Do not comment trivial syntax.
- Keep numeric balancing parameters named and centralized. Avoid copying identical checks or literals into multiple files.
- Avoid brittle dependencies on node paths, UI text, specific enemy names or animation durations.
- Keep new features as small as possible. Extract reusable systems when a second real use case demands it; **change-friendly** must not mean **overengineered**.
- Where persistence is added later, version save data and define backward-compatible upgrades.

## 5. Performance and correctness

- Prefer a small, clean game loop over speculative performance tricks; profile on mobile hardware before optimizing.
- Avoid allocating large collections every rendered frame, unbounded combat history in memory, unnecessary `queue_redraw()` calls, or rebuilding large UI trees every hit.
- Keep combat results pure enough to test without running animations.
- Test individual formula stages and interactions: normal/critical, physical/magic, with/without armor, Iron Skin, Final Stand, Fireball, stack ordering and clamping/rounding.
- Test empty and partial skill pools, pause/restart, encounter transitions, and action ordering.
- On every relevant change, run headless Godot 4.7 import + existing tests + new regression tests, then visually playtest where possible.
- Distinguish verified engine behavior from assumptions in change summaries.

## 6. Scope and adoption

The current prototype already separates some battle rules from UI, but its combat model still has prototype-specific branching and its animations use timed delays. We should **incrementally** improve those seams when implementing subsequent features, rather than refactor everything at once without tests.

New code must follow these rules immediately; existing code should be updated when the touched component or a new requirement makes that necessary.

**Guiding question:** Would adding one more skill, modifier, enemy or speed mode require editing just its definition and the relevant rule extension—or would we have to search through the entire game? Aim for the former while preserving clarity.
