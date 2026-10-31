# Tiny Legends — Battle Lab (Prototype 01)

Our first playable Godot proof of concept for an original side-view, chibi-style mobile roguelite, inspired by the *feel* of Rogue Legend, Obsidian Knight and classic fantasy RPGs.

**How to play on Windows**

1. Download this repository: **Code → Download ZIP**, then extract it.
2. In Godot 4.4 or newer, select **Import** and select `project.godot`.
3. Open the project and press **F5**.
4. Watch the hero and goblin fight automatically. When it finishes, click **FIGHT AGAIN**.

No third-party plugins or art assets are required. Characters and scenery are drawn in code.

**Implemented:** one hero versus one goblin, automatic alternating turns, random attack rolls and critical hits, armor, health, win/loss screen, replay.

**Not yet implemented:** randomized skill drafts, additional enemies, stages, inventory, unlockable automation, multiplayer or saves.

**Foundation:** combat rules live in `scripts/combat/`, independent of the UI in `scripts/battle_screen.gd` and placeholder art in `scripts/visuals/`. This separation lets us expand or replace the artwork later.

**Headless test** (if the Godot executable is on your PATH):
```sh
godot --headless --path . --script res://tests/test_battle_model.gd
```

The project has not yet been run inside the user's Godot installation; please report any import/parse errors so we can fix them.

Next planned milestone: three randomized skill cards that pause play until the player picks one.
