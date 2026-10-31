# Graphical playtest — integration/character-rigs

Use the same Godot import/F5 process as earlier versions. This is the complete
integration game, not the standalone art demo. No branch merge is required.

1. On https://github.com/lymmers/Vidja-game select branch
   `integration/character-rigs`, then **Code → Download ZIP**.
2. Extract into a **new folder**, keeping all subfolders together. Avoid opening
   an older main/feature copy already listed in Godot's Project Manager.
3. Open Godot **4.7.2** (the version used for validation), choose **Import**, and
   select the extracted game's **root project.godot**. Do not select
   `art/character_pack/project.godot`; that is the separate asset demo.
4. Let import finish, then press **F5** to run the main scene.
5. Choose a skill. Confirm the articulated hero faces the Skeleton, native idle,
   attack and hit animations play, and parts stay behind the draft and combat log.
6. Win the first battle, choose another skill and confirm Bone Alchemist retains
   its earlier procedural appearance and potion animation. Try replay afterward.

Combat is still automatic, with the existing stats, skills and initiative rules.
A loss is a normal outcome; restart to try a different draft. No test cheats,
guaranteed wins, new speed control or balance changes were added.

For an existing Git clone (commit/stash your own edits before switching):

```sh
git fetch origin
git switch --track origin/integration/character-rigs
```

If the local branch already exists, switch to it and update with a fast-forward
only pull. Open that checkout's root project.godot in Godot and press F5.

Prepared and tested on Godot 4.7.2 Linux: eight headless suites plus the supplied
PNG/keyframe check. This does not replace your graphical playtest or establish
Windows/mobile rendering quality. The nested art-demo import warning is expected.
The native actor and rig scenes are preserved as supplied. Walk/death/turnaround
animations are not included in the pack.

Architecture recommendations are separate: PROPOSED_COMBAT_GUARDRAILS.md. They
are proposals only, not changes in this playtest build.

Graphical feedback follow-up: see [visual evidence and remaining issues](VISUAL_INTEGRATION_REVIEW.md). This branch is still not approved to merge.
