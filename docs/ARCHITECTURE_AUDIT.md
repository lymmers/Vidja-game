# Architecture audit — 31 October 2026

Read-only baseline: `ece2bc5` (`refactor/initiative-and-scalable-systems`).
PR #4 asset baseline: `b7c4a99`. Recommendations below are **Proposed**, not
permission to expand this integration. No blocker to the approved visual swap.

## Verified strengths

Simulation is independent of Godot scene timing. DamagePipeline consumes ordered
modifiers and generic survival operations, producing an applied-HP ledger.
CombatEffectState tracks actor/effect charges and logical-action immunity. Skills
supply effect arrays; TurnScheduler supports stable initiative, party priority and
bonus actions. Combat, draft and cosmetic RNG streams are separate. EncounterCatalog
supplies stats and action intervals. Tests cover these seams and both skill drafts.
All six baseline game suites and supplied rig tests pass on Godot 4.7.2 after import.

## Prioritized findings

| Severity | Evidence / impact | Recommended follow-up |
| --- | --- | --- |
| High | BattleModel.take_next_turn uses EncounterCatalog.get_action(encounter, count) for **every** enemy-side actor. Additional enemies inherit the primary encounter's special action rather than their own definition. | Add per-actor action definitions before shipping heterogeneous enemy rosters. |
| High | _process_trigger caps damage-event count, but extra_action queues actions without adding damage events to that counter. An always-triggering extra-action effect can perpetually starve the opponent across turns. | Specify a logical action-chain budget and test bounded bonus turns before exposing such skills. |
| Medium | BattleScreen and BattleStage collapse actor IDs into hero/enemy sides. Companion attacks would animate the hero; only primary HP bars are displayed. | Add actor-ID-to-presenter mapping when party rendering is approved. Current one-on-one encounters are supported. |
| Medium | heal changes HP without emitting a structured healing event; after_damage/on_kill consumers can repeat across bonus-hit chains. | Define event provenance/trigger semantics and ledger healing before new synergistic content. |
| Medium | Validation accepts negative power/ratio/usage fields and does not enforce effect-ID uniqueness across equipped skills and external effects. Charge keys could collide. | Validate domain ranges and complete actor loadouts; add malformed-content tests. |
| Medium | Existing tests may print PASS and exit zero after a GDScript runtime error aborts a test function (observed with stale class cache before import). Some UI smoke paths jump directly between encounters. | Import before tests, reject engine/script errors in the runner, add full progression and animation interruption coverage. |
| Low | Hero stats remain constants in BattleModel; basic physical/magic semantics are explicit. UI layout uses fixed portrait coordinates; presentation branches on fireball/potion. | Extract only when real new content requires these seams; retain typed event contracts. |
| Low | Architecture/engineering docs mix historical descriptions with current implementation. | Label verified, approved and proposed state and keep architecture guidance current. |

## Rendering and assets before integration

BattleStage draws the landscape and both actors procedurally; enemy visual selector
`skeleton` means the **Bone Alchemist**, not PR #4's skeleton warrior. Do not reuse
that selector for the new first enemy. Native rig scenes provide idle/attack/hit,
impact and completion/cancellation signals, and replaceable equipment attachments.
Their root is near the feet. Supplied demo has its own project.godot and absolute
res://characters and res://scripts paths; preserve those runtime paths in the game.
Keep the standalone pack ignored by root imports. No walking/death animation is supplied.

## Coverage and audit limits

Reviewed simulation, pipeline, effect state, scheduler, validator, skill/encounter
catalogs, screen, stage, actor script, demo, tests, workflow and architecture docs.
Baseline tests exercise damage, skills, initiative, RNG, drafts and transitions;
they do not prove a full party UI or rendered animation quality. Audit findings
are inspection findings unless a reproduction is explicitly stated. No unrelated
mechanics or architecture fixes are included in this integration.
