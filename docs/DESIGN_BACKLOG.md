# Vidja — Living Development & Design Backlog
_Last reviewed: 2026-10-31. Owner: Game Director._

> **Current focus: P0 only.** Make the existing two-enemy auto-combat prototype genuinely enjoyable before implementing large progression systems. This document preserves discussion decisions, not authorization for Codex to build parked features.
>
> **Status vocabulary:** `[x]` = reported implemented/verified (with stated limits); `[ ]` = not yet completed. **Approved direction** = design philosophy agreed with Director, **Proposed/parked** = details not yet approved, **In progress** = art/implementation underway, **Visual acceptance pending** = tests alone insufficient.
>
> Engineering status below is based on Codex's 2026-10-31 reports, not an independent code audit. Current integration branch `integration/character-rigs` had not been merged when reported. See `docs/ROADMAP.md`, `docs/ARCHITECTURE_AUDIT.md`, and `docs/DECISIONS.md` for technical details.

## P0 — Make the existing combat fun (ACTIVE)

**Milestone:** A polished two-enemy experience that the Director would replay voluntarily for enjoyment, not just testing.

- [x] Establish basic automatic turn-based combat, skill drafting and two encounters (headlessly tested).
- [x] Establish generic damage/effects, configurable initiative and separate RNG streams (headlessly tested).
- [x] Integrate native hero and Enemy 1 skeleton rigs; keep Bone Alchemist Enemy 2 unchanged (Codex reported headless verification).
- [x] Add Godot test runner that fails on engine errors and regression suites (Codex reported nine suites passing after focused layering fix).
- [ ] **Visual acceptance pending:** verify revised body-part layering in real rendered idle/attack/hit/interruption and both facings. Shield-side forearm Z=9 patch reported on `integration/character-rigs` at `c8fbbaa`; other shoulder/belt overlaps need review.
- [ ] Improve full-body attack anticipation, acceleration, follow-through, recovery and hit reactions; sword should feel like a committed strike, not pointing/handing over the weapon.
- [ ] Add combat-sensitive facial expressions (focused wind-up, exertion, hurt, neutral/blinking idle), not fixed `:) `.
- [ ] Add **restrained** basic-attack sword motion trails following the actual weapon path, with small synchronized on-hit impact effects; stronger attacks can be more spectacular later.
- [ ] Keep VFX **optional, action-driven, configurable and weapon-aware**, not permanently baked into a universal hero attack: staff spellcasting must not play sword slash trails. Animation team supplies cues/anchors; Codex owns game-side selection. Avoid building a large VFX framework prematurely.
- [ ] Improve weapon-contact spacing and character grounding in the arena.
- [ ] Finalize portrait **sunny ruined courtyard** artwork for Encounter 1; concept art department is preparing a slightly muted/less saturated version. Preserve brightness and atmosphere, avoid a uniform dark overlay. Verify exact battle viewport ratio and in-game framing; background should be encounter-configurable when integrated.
- [ ] Graphical/mobile playtest: character scale, clipping, foot placement, HUD readability, animation quality, VFX legibility, both encounters and transitions.
- [ ] Review each existing skill for meaningful, visible choices and inspect combat pacing (quick basics, stronger moments without sensory overload).
- [ ] Give Skeleton and Bone Alchemist distinct, interesting encounter behavior after reviewing actor-action architecture.
- [ ] Create a short replayable loop with choices whose consequences are visible in combat.

**Production acceptance:** Functional rigs require visual previews of idle, attack and hit in both facing directions, including layer/overlap checks, before delivery to Codex. Headless rig tests do not constitute visual approval.

## P1 — Engineering foundations (PROPOSALS; approval required for architectural changes)

- [x] Record controlled autonomy in root `AGENTS.md`: Codex can make routine technical changes, but gameplay, major architecture and scope require Director approval.
- [x] Create core technical documentation and perform read-only architecture audit.
- [x] Improve engine-error-aware test execution.
- [ ] **High:** Per-actor enemy action definitions: currently every enemy-side actor can inherit the encounter primary actor's special action. Design and approve minimal per-actor solution before mixed enemy groups.
- [ ] **High:** Bounded extra/bonus-action chains: current damage-event cap does not bound indefinitely queued actions. Agree on gameplay semantics before implementing safeguards.
- [ ] **Medium:** Actor-ID-to-presentation mapping before multi-actor party battles.
- [ ] **Medium:** Healing ledger and trigger/event provenance before complex multi-hit, after-damage/on-kill synergies.
- [ ] **Medium:** Validate negative values, invalid ratios/usage and duplicate effect IDs across full loadouts.
- [ ] Expand visual tests, interruption tests and full progression coverage when relevant; preserve separation between simulation and rendering.
- [ ] Address portrait UI layout limitations as target devices require.

## P2 — Skill favoritism and build discovery (APPROVED DIRECTION; formulas not finalized)

- [ ] Build a small, satisfying initial skill pool with visibly interacting effects before expanding content.
- [ ] Introduce **data-driven multi-affinity favoritism**: one skill may contribute different amounts toward Fire, Ice, Lightning, Defense, Magic, Physical, etc.
- [ ] Favoritism values reflect a skill's **commitment to a build**, not only its rarity. A generic basic Fire skill should influence Fire less than a specialized Fire combo skill; an Epic general-purpose skill need not have high weighting.
- [ ] Hybrid skills can grant several affinities: e.g. Fire Shield promotes Fire and Defense; a three-element mastery can promote Fire, Ice and Lightning.
- [ ] Distinguish what a skill **does** (tags/effects) from what its selection **encourages in later drafts** (independent affinity metadata).
- [ ] Favoritism biases draft odds without guaranteeing optimal outcomes; prevent early accidental off-element choices from irrevocably steering a run.
- [ ] Explore permanent starting affinity from progression investments; avoid an explicit pre-run preference picker that feels like a promise of a guaranteed result.
- [ ] Possible progression unlock: `Lightning Damage+` followed by **toggleable Lightning Affinity** (researched once, independently enabled/disabled with a clear explanatory tooltip). Multiple toggles may coexist for hybrid builds; actual rules remain undecided.
- [ ] Playtest whether optional bias and natural run affinity adequately reduce repeated unwanted starts **before** introducing bad-luck protection/pity.
- [ ] Optional advanced view of actual draft odds and affinity contributions for players who like theorycrafting.

## P3 — Heroes, rarity, and progressive complexity (APPROVED DIRECTION; details parked)

- [ ] Different playable heroes have different base stats and innate skills, with **soft specialization**, not weapon/class locks.
- [ ] All playable heroes can use broad weapon archetypes, including unusual choices such as a Knight with a staff.
- [ ] Design discoverable cross-archetype hooks: e.g. a mostly physical/tank Knight with shield power that scales with Magic, inviting a viable battlemage build.
- [ ] Different starting hero rarities; players can **ascend lower-rarity favorites** through achievable effort.
- [ ] At equal current rarity and comparable total investment, a former Common hero can reach the **same overall statistical potential** as a natural Legendary hero; distinctive distributions and innate abilities remain meaningful.
- [ ] Introduce systems gradually: first minutes simple, midgame experimentation, optional late-game mastery. Avoid three interlocking trees and Path-of-Exile-level decision overload at onboarding.
- [ ] Each new progression system must justify what it adds that hero, gear and in-run skills do not already provide.
- [ ] Potential hero loadouts/configuration management; implementation deferred.

## P4 — Equipment and reversible specialization (APPROVED DIRECTION; economy not finalized)

- [ ] Start with an approachable weapon pool of fixed, easily understood identities: Fire Sword (burns), Frost Staff (chills), Bleed Dagger (bleeds), etc.
- [ ] Weapons should help **shape** build paths through their behavior and later unique abilities, while remaining usable by any hero.
- [ ] Prefer predictable weapon identities and upgrades over complex randomized secondary affixes; optional detail for theorycrafters.
- [ ] Individual weapon **enhancement levels** consume a reusable allocation of upgrade tokens; freely recover and automatically transfer eligible enhancement investment when swapping equipment, as in the admired Rogue Legend mechanic.
- [ ] Weapon **rarity ascension** uses permanent item-specific resources; Epic→Legendary stays Legendary, and rarity may unlock meaningful weapon-specific mechanics rather than just stats.
- [ ] **Talent-point reallocation** should be free/easy: earned points remain earned, current specialization is reversible.
- [ ] Consider saved Fire, Ice and experimental loadouts (talents, equipment, affinity toggles), with switching outside active runs.
- [ ] Preserve meaningful permanent item investments without trapping players in one build. A lucky Ice staff should invite experimentation even if the current build is Fire.
- [ ] Decide enhancement caps, material costs, rarity economy and exact transfer behavior only when needed.

## P5 — Curated weapon forging (PARKED; NOT implementation-approved)

- [ ] Investigate later-stage modification/ascension of simple weapons into deliberate hybrids (e.g. Frostfire Staff, bleed blade that cauterizes).
- [ ] Curated pre-approved modifiers/parts, **not** unconstrained 'combine anything with anything' crafting.
- [ ] Explore elemental, trigger and behavior modifiers only after the basic equipment game is fun.
- [ ] Decide permanence versus swappable modifications much later; no forging slot counts, recipes or numerical balance approved.

## P6 — Fair economy and transparency (GUIDING PRINCIPLES; implementation parked)

- [ ] Avoid obligatory months/years of F2P grinding to achieve meaningful rarity progression; long-term goals can still exist without punitive bottlenecks.
- [ ] Make effort produce visible progress; balance random excitement with deterministic opportunities.
- [ ] Avoid excessive currencies, predatory spending pressure and excessive respec costs.
- [ ] Players can inspect precise damage formulas, proc conditions, stacking, odds and drop rates if they want to; casual descriptions remain simple.
- [ ] Aim to make datamining unnecessary for understanding game mechanics.
- [ ] Prioritize fun and fair monetization over maximal extraction.

## P7 — Content expansion (PARKED)

- [ ] Additional enemies with distinctive actions, environments and bosses.
- [ ] More heroes, weapons, skill families, companions/pets and eventual game modes.
- [ ] Add complex synergies only when per-actor actions, trigger provenance and action-chain safety are reliable.

## P7a — Combat archetypes and supporting styles (PARKED; not implementation-approved)

**Early brainstorming only.** These are candidate build specializations, not fixed hero classes or confirmed launch content. Heroes may naturally favor certain builds, but should not be locked into them.

- **Power / damage archetypes:** Fire, Ice, Lightning, Bleed, Poison, Void, Light. Exact identities, mechanics and balance are undecided.
- **Supporting combat styles:** Combo, Defense, Critical Hits, Counterattacks, etc. These describe *how* a build fights and may enhance any power archetype.
- **Combo is a supporting style, not an eighth standalone power archetype.** Examples to explore later: Fire+Combo builds heat through consecutive hits; Ice+Combo accelerates freeze buildup; Poison+Combo applies repeated stacks; physical Combo builds are also viable.
- Cross-archetype combinations should be discoverable and expressive without forcing classes or restricting unconventional hero builds.
- **No implementation now.** Revisit after the two-enemy prototype has satisfying combat and a small proven skill pool.

## Decision / development workflow

1. Director proposes/approves direction; Design Chat explores tradeoffs and records decisions.
2. Concept Art Chat develops and refines approved visual concepts/backgrounds.
3. Animation Work delivers self-contained Godot rigs with visual proof of body-part order and required actions.
4. Codex integrates approved assets/features, tests and reports, without unapproved gameplay/architecture/scope changes.
5. Director visually playtests and approves before merge. **Do not merge unapproved art or integration branches.**
6. Update this backlog when priorities change; preserve the distinction between *implemented*, *approved direction*, and *proposed*.

**North star:** Players should see their decisions come together and defeat enemies; build complexity should be optional, discoverable and gradually introduced. Changing a playstyle should rarely erase earned progress.
