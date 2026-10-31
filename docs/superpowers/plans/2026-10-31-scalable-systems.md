# Scalable Combat Foundation and Initiative — Implementation Plan

**Goal:** Keep the current two-encounter roguelite playable while making combatant scheduling, skill effects, RNG, validation, and UI scalable without skill-name-specific branches.

**Architecture:** Introduce an independent, side-prioritized logical action queue and stable actor IDs. Convert skills into effect lists interpreted by generic trigger handlers; separate combat/draft/cosmetic RNG. Validate definitions and render dynamic skill bars/encounter metadata.

**Tech stack:** Godot 4.7.2, GDScript, GitHub Actions.

**Scope:** Combat is one hero vs one enemy visually for now; companions and multiple enemies are supported by the headless core, not rendered as new sprites yet.

## Requirements and tests

1. Add failing `tests/test_architecture.gd` tests for side-first / enemy-first initiative override, companions, extra actions, isolated RNG, multiple stacked effects, data validation and encounter lookup errors. Confirm failure before implementation.
2. Implement `TurnScheduler` with stable ID/side/priority order, logical round queue, and an extra-action hook. A player-side member moves first by default; a numerical initiative modifier can reverse the order.
3. Implement `DataValidator` and strict catalog lookups. Unknown encounters return empty definitions and report meaningful errors if started.
4. Convert skills to `effects` arrays (multiple per trigger), add runtime effect instances keyed by stable actor IDs, and dispatch supported operation types by generic effect rules. Preserve Fireball / Iron Skin / Final Stand behavior.
5. Split random-number streams so drafting does not affect battle outcomes. Preserve legacy `rng` as combat stream to avoid invalidating tests.
6. Update battle model to ask scheduler for next actor rather than infer from turn-index parity, support party-member / enemy registration and future extra actions. Make damage hooks independent of actor names.
7. Update dynamic skill bar and enemy visual/label metadata without a fixed 3-slot assumption or named-enemy UI checks.
8. Run all existing Godot tests plus the new suite, fix regressions without changing intended balance, and keep changes on a draft feature branch.

## Boundaries

Don't invent multiplayer, real save slots, or a full status-effect scripting language. Generic *known* effects can be combined freely; introducing a novel operation is an explicit addition to a handler and validator. Effects and scheduler operate in logical turns and never read presentation seconds.