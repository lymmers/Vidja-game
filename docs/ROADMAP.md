# Roadmap

## Implemented, verified headlessly
- Extensible combat damage/effects, initiative and independent RNG streams.
- Two encounters, skill drafts, active skills and transparent combat log.
- Native hero and first-enemy skeleton rigs; unchanged procedural Bone Alchemist.
- Supplied rig tests plus full seeded encounter progression and mixed rendering tests.
- Operating rules, read-only audit, asset requirements and error-aware test runner.

## Remaining verification
Director visual playtest: scale, framing, orientation, animation feel and equipment
appearance on the target Godot installation/mobile viewport. Headless checks are
not visual approval. Playtest branch: integration/character-rigs. No PRs were merged into main.

## Proposed; approval needed before implementation
Prioritize per-actor enemy action definitions and bounded bonus-action chains from
the audit before heterogeneous parties or new synergistic effects. Full party
rendering, extra content, equipment gameplay and new animation components remain
outside the current approved integration scope.
