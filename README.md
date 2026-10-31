# Tiny Legends — Battle Lab (Prototype 02)

Godot 4.7-compatible, 2D portrait, automatic turn-based roguelite prototype.

## How to run

1. Use **Code → Download ZIP** from the feature branch or check out the branch.
2. Godot → **Import** → select `project.godot`.
3. Press **F5**.
4. Pick a skill from three cards. Watch the moss goblin battle.
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