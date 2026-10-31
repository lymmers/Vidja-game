# Game design

## Approved vision
Original portrait mobile fantasy roguelite; 2D side-view, cute/chibi cartoon
characters. Automatic turn-based combat supports low-touch farming; player choices
come from drafts and builds. Inspiration: Rogue Legend, Obsidian Knight, Darkest
Dungeon's combat framing. No new monetization or progression rules are approved here.

## Implemented and headlessly verified
Two encounters: Skeleton (formerly Moss Goblin, same stats/behavior), then Bone
Alchemist (unchanged). One skill draft before the first fight and one after winning;
HP and owned skills carry into the second. Drafts tolerate fewer than three choices.
Fireball adds a 50%-chance magic hit for 150% base attack roll. Iron Skin reduces
physical damage by 20% after armor. Final Stand leaves 1 HP on lethal damage and
immunity for the remainder of that logical action, once per encounter. The latter
limit is the existing assistant-origin interpretation, not a new balance decision.
Combat log shows actual applied HP loss and ordered modifiers.

Player side has opening initiative priority by default; data modifiers can override
it. Presentation speed does not alter simulation. Underlying companion/action
support exists; a full party UI, equipment gameplay and speed-toggle control are
not claimed complete. Visual polish requires director playtesting.
