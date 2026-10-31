# Vidja Game — Engineering Rules

These project-wide rules apply to future contributors and AI assistants. Read [docs/ENGINEERING_STANDARDS.md](docs/ENGINEERING_STANDARDS.md) before changing gameplay systems.

## Core principles

1. **Design for likely change, not hypothetical everything.** Skills, damage types, resistances, modifiers, encounter rules, speeds and balance values should be extensible without rewriting unrelated code. Prefer one understandable extension point over duplicated special cases. Do not build a generic framework until there is a concrete need.
2. **Gameplay must be independent of rendering speed.** No combat outcome, damage tick, ability proc, cooldown, status duration, turn selection or random roll may depend on FPS, animation length or the duration of a `create_timer()` used for UI. A future 2× mode must accelerate *when* simulation actions are presented/executed, not change their logical outcomes.
3. **Single source of truth for combat.** The combat model resolves damage, effects and final HP. The UI, animations and combat log consume the model's structured events; they never calculate or guess damage modifiers independently.
4. **Explicit damage calculations.** Damage events should retain base roll, type, named and ordered modifiers, critical contribution, rounding decisions, final applied HP damage, and any special prevention (e.g. Final Stand). Adding a modifier should not require rewriting text formatting, animations, or enemy-specific branches.
5. **Data-driven definitions where useful.** Skill and enemy definitions should be separated from general battle flow. Use named constants, reusable functions and typed data structures; avoid magic numbers and stringly typed duplication where sensible.
6. **Readable GDScript.** Choose descriptive names and focused files/functions. Use comments to explain *why*, rules, invariants, and unintuitive edge cases. Avoid comments that repeat obvious lines or sprawling abstractions that obscure gameplay.
7. **Balance performance with clarity.** Prefer straightforward algorithms until measurements justify optimization. Avoid per-frame allocations, redundant redraws and repeatedly rebuilding UI where practical. Do not prematurely micro-optimize small turn-based computations.
8. **Test mechanics and regressions.** Each new gameplay behavior needs automated tests for normal paths, edge cases, stacking/order and relevant interactions. Use seeded randomness for determinism. Tests for speed-invariance are required when changing a scheduler/timing feature; damage log values must match actually applied HP differences.
9. **Keep working versions safe.** Use feature branches / pull requests for substantial changes, check Godot 4.7 compatibility, and do not claim behavior verified unless engine tests or actual playtesting demonstrate it. Never silently merge into `main`.
10. **Document trade-offs and technical debt.** A prototype shortcut is acceptable only when labeled, localized and inexpensive to replace. When adding a new system, explain how someone should extend it and what should not be coupled to it.

## Review checklist

Before treating a gameplay feature as finished, ask:
- Can a new damage type, modifier or skill be added without changing unrelated UI code?
- Will the same seeded battle actions produce the same results at 1× and 2× presentation speed?
- Does the log accurately explain exactly what the model resolved?
- Are names, comments, responsibilities and edge-case handling understandable to someone new to this code?
- Did we verify tests and disclose anything not tested?

**Present status:** Prototype code is still evolving; these are forward-looking engineering requirements, not a claim that every existing file already meets them.
