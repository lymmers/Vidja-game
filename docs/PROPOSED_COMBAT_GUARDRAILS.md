# Combat recommendations — proposed, not implemented

These proposals are separate from the character-rig graphical playtest. No
mechanics, validation rules or action scheduling are changed by this document.

## 1. Per-actor action definitions

Problem: every enemy currently calls EncounterCatalog.get_action(encounter, count),
so a second, different enemy would inherit the primary encounter's potion cycle.

Minimal proposed fix: store an immutable action profile on each registered actor,
separate from mutable actions_taken[actor_id]. It contains a basic attack and an
optional periodic special action. A small pure resolver selects an action from
that actor's profile and its own action count, without checking enemy names/IDs.
The primary enemy receives its profile from the existing encounter definition;
add_enemy accepts an optional profile and otherwise defaults to basic attack.
The hero and companions retain today's basic-attack default. No enemy catalog
split or scheduler rewrite is necessary for this fix.

Compatibility: retain existing encounter fields and add_enemy arguments; append
an optional argument. Preserve the Alchemist's every-third-action rule, counting
bonus actions just as today. Test two enemies with distinct profiles/counters,
encounter resets and identical seeded outcomes for today's two encounters.
**Approval requested for design only; no implementation yet.**

## 2. Negative parameters and duplicate effect IDs

Validate finite numeric values before coercion; reject NaN/infinity and wrong
numeric types. Require chance in [0,1], power_multiplier and heal ratio >=0,
armor >=0, hp_floor integer >=1, special interval integer >=1, and usage/count
limits integer >=0. Preserve uses_per_encounter=0 as unlimited. Do not impose an
arbitrary upper bound of 1 on healing ratios or damage multipliers. Zero power
currently still resolves through the minimum-one-damage floor; validation must
not silently change that combat rule.

Arithmetic is operation-specific: allow signed add values for buffs/debuffs;
require subtract magnitudes and multiply factors >=0. This preserves debuffs
without permitting accidental double negatives or negative damage scaling.

Require nonempty string effect IDs unique within an actor's complete equipped
set (skills plus external effects). The same definition ID on different actors
is valid because charge state is actor-scoped. Reject collisions atomically,
with both sources named; do not silently overwrite or rename IDs. Distinct effects
must use distinct IDs. If identical equipment copies should stack independently,
introduce explicit per-instance IDs only after stacking semantics are approved.
Intentional shared charge pools would likewise need explicit grouping.

Compatibility: shipped skills satisfy these proposed constraints. Stricter rules
would reject formerly accepted negative/coerced values and cross-source collisions;
existing content must be audited first. If saved effects later exist, retain or
explicitly migrate stable IDs rather than silently resetting usage state. No
save format currently requires migration. **Rules remain unchanged.**

## 3. Bonus-action chain safeguards

The current 32-damage-event limit does not bound queued actions across turns.
A chain must mean one normally scheduled action plus all bonus actions descended
from it, including bonuses passed between actors. Resetting a budget on every
bonus action would not terminate a loop.

| Option | Legitimate-build consequence |
| --- | --- |
| Bonus actions cannot generate more bonus actions | Simple termination; prevents extra-turn combos even when finite and intentional. |
| Each effect can grant a bonus once per originating chain | Supports combinations of distinct effects; repeated use of the same effect/actor is blocked. A per-chain total is still advisable for large branching rosters. |
| Configurable total bonus-action budget per originating chain | Allows repeated and cross-actor combos up to a chosen limit; very long legitimate bursts are truncated. Must decide which pending bonuses are dropped or deferred. |
| Resource/charge costs that bonus actions cannot replenish within a chain | Allows long builds with an explicit finite resource; changes balance and needs a rule preventing circular resource regeneration. |
| Scheduler fairness: defer bonuses after a burst | Gives other actors turns but does not itself terminate infinite generation or bound queue growth. Changes priority/timing, so is not sufficient alone. |

Recommendation: discuss a per-origin-chain total budget, optionally combined with
explicit per-effect repeat policy. Decide the limit, scope across actors, and
whether exhaustion drops bonuses or reports a content error before implementing.
No silent per-encounter cutoff: that would penalize long fights unrelated to loops.
A developer diagnostic can expose runaway content, but must not secretly become
a production gameplay cap. **No safeguard is implemented or approved here.**
