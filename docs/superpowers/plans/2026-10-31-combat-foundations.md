# Combat Foundations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Separate damage modifiers, enemy/skill configuration, and visual timing so future features can change safely.

**Architecture:** Data definitions feed a pure damage pipeline. BattleModel orchestrates fixed logical turns; presentation clock and animations are separate.

**Tech Stack:** Godot 4.7 / GDScript

**Spec:** docs/superpowers/specs/2026-10-31-combat-foundations-design.md

## Global Constraints
- Preserve existing two-encounter gameplay, three skills, and combat log semantics.
- Maintain existing public interfaces unless explicitly documented.
- Keep `main` and prototype branch unchanged; feature branch plus PR only.

## Review Focus
- 0/partial HP remaining, overkill: damage event equals HP delta.
- Adding resistance for previously unknown damage type.
- Stacking additive, armor, percent effects with deterministic roundi.
- Final Stand immunity while hit ledger must reconcile to 0.
- Seeding and 1x/2x display speed must not alter turn results.

### Task 1 — Red regression tests
- [ ] Write `tests/test_foundations.gd` for custom effects, all damage types, overkill, ability cycles, and speed invariance.
- [ ] Add CI step and run Godot 4.7 on the feature branch. Expected: fail from missing extension points.

### Task 2 — Pure damage and data catalog
- [ ] Create `scripts/combat/damage_pipeline.gd`, `scripts/combat/encounter_catalog.gd`, `scripts/battle/presentation_clock.gd`.
- [ ] Extend `BattleUnit`, `SkillCatalog`, refactor `BattleModel` to use rules rather than explicit Iron Skin / potion / Fireball cases.
- [ ] Run Godot 4.7 headless tests. Expected: all pass.

### Task 3 — Presentation separation and idle rendering
- [ ] Scale UI visual waits and stage tween durations using presentation speed, not mechanics.
- [ ] Remove unconditional idle arena redraws, keep animations and restart safe.
- [ ] Add a small UI smoke check for 2x speed and regression run.

### Task 4 — Review and handoff
- [ ] Record extension examples and known limitations in docs.
- [ ] Run complete CI and inspect results and GitHub diff.
- [ ] Open draft PR against prototype feature branch and give exact link and status.