# Tiny Legends — Battle Lab (Prototype 02)

Godot 4.7-compatible, 2D portrait, automatic turn-based roguelite prototype.

## How to run

1. Use **Code → Download ZIP** from the feature branch or check out the branch.
2. Godot → **Import** → select `project.godot`.
3. Press **F5**.
4. Pick a skill from three cards. Watch the skeleton battle.
5. Win and pick one of the two remaining skills. Fight the Bone Alchemist.
6. Replay resets the adventure.

## Skills and damage types

- **Fireball**: 50% chance after a basic attack to deal an additional 150% of the attack roll as magic damage.
- **Iron Skin**: take 20% less physical damage, after physical armor. Does not affect magic.
- **Final Stand**: once per encounter, lethal damage leaves 1 HP and prevents further hits within that action.
- **Bone Alchemist**: every third **skeleton action**, throws a fire potion replacing a regular attack, at 100% attack power, magic damage.

Skills and current hero HP carry over into encounter 2. The skill draft only displays skills not yet owned, and safely handles an empty pool.

Combat code: `scripts/combat/` · Skill definitions: `scripts/skills/` · UI: `scripts/battle_screen.gd` · Placeholder 2D art: `scripts/visuals/`.

For headless tests with Godot on PATH:

```sh
godot --headless --path . --script res://tests/test_battle_model.gd
```

Design details: `docs/FEATURE_SKILLS.md`.

## Combat log (Prototype 0.3)

While a hit is animated, its live readout shows the real damage, type, and formula. Use **COMBAT LOG** to review the complete scrollable history, including each critical bonus, armor mitigation, Iron Skin, magical resistance (where present), Fireball multiplier, and Final Stand. Damage is calculated once in the combat model and recorded with the result; the UI does not independently recalculate damage.

## Engineering foundation

The codebase keeps combat calculations independent of animations and UI. Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the exact responsibilities and examples of adding modifiers, damage types, skills, enemy attacks and eventual 2× presentation speed. Current game speed remains 1× in the UI; the engine exposes a configurable visual speed without affecting battle outcomes.

**Reactive skills are data-driven:** Final Stand is now defined using generic `on_damage` conditions and effects. See the architecture guide and `tests/test_generic_effects.gd` for adding another death-prevention skill without modifying the damage pipeline.

## Scalable foundation: initiative, effects and randomness

The [refactored architecture](docs/ARCHITECTURE.md) now includes a player-side-first action scheduler with configurable initiative, companions/pets in the headless core, multi-effect skill definitions, stable combatant/effect IDs, separated combat/draft RNG, and definition validation. New encounters provide their own labels and art keys. The active-skill bar grows with the player's build. **Companions do not have on-screen sprites yet**; this is the underlying battle simulation, not a new party interface.

To verify: Godot 4.7.2 CI runs `tests/test_architecture.gd` alongside the existing combat, skill, screen, and effect regression tests.

## Character assets and validation

The player and first enemy use PR #4's articulated native Godot cutout rigs.
The Bone Alchemist retains its procedural drawing and animations. Runtime scenes
live in `characters/`; the untouched standalone asset pack/demo remains in
`art/character_pack/` (open that folder as a separate Godot project).

Run all headless checks, including native rig and two-encounter integration:
`GODOT_BIN=/path/to/godot bash tools/test.sh`. Godot 4.7.2 is verified.
The runner imports first and rejects engine errors even if Godot exits zero.
See `docs/ARCHITECTURE_AUDIT.md` for scoped findings and `docs/ART_BIBLE.md`
for equipment and animation limits. Headless checks do not certify visual polish.

For the current character integration, follow [graphical playtest instructions](docs/PLAYTEST_CHARACTER_RIGS.md) on branch `integration/character-rigs`.
