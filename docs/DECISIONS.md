# Decisions

- **Approved:** Game Director owns gameplay, architecture, visuals and scope.
  Codex may execute approved work and routine technical choices; consequential
  design changes require approval. See root AGENTS.md.
- **Approved and implemented:** replace player and Enemy 1 visuals with PR #4's
  supplied rigs. First enemy displays Skeleton but retains prior stats and behavior.
  Enemy 2 remains Bone Alchemist with its existing art, animation and gameplay.
- **Implementation choice within approved scope:** use PR #4's documented runtime
  resource paths and a small presentation-only scene registry. Distinct visual keys
  avoid confusing the skeleton warrior with the procedural alchemist.
- **Approved and verified:** simulation owns damage and action order; native impact
  cues only drive visual reactions. Playback speed never calculates combat outcomes.
- **Proposed only:** audit recommendations in ARCHITECTURE_AUDIT.md. None authorize
  new mechanics, balance changes, a party UI or a general architecture rewrite.
