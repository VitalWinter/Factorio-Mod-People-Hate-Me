# To do

The goal: every enemy, everything they do, and everything they build feels human, like a
civilization. This file is the working list for getting there.

- Both sections are in priority order, highest first.
- When an item is done, delete it here and record it in `People-Hate-Me/changelog.txt`.
- When an item under "Needs more thought" is decided, write the decision into the item and
  move it into "Ready to do" at the right priority.

## Ready to do

1. **Check how corpses disappear.** The bug corpses' decay animation was removed, so bodies may
   now vanish abruptly when the game cleans them up. If so, add a fade-out.
2. **Spitter and worm acid becomes gunfire.** Replace the acid streams with bullet fire, the
   acid puddles on the ground with small scorch marks or nothing, the slowdown sticker from
   being hit, and the acid cloud a nest puffs out when its spawn point is blocked. Worms fire
   the same kind of acid streams, so this comes before the worms. Depends on the damage type
   question below, but the visuals can start without it.
3. **Ground around nests.** Nests spawn creep decals, mushrooms, lichen and muddy stumps around
   them. Swap these for trodden mud, paths and cleared ground.
4. **Remaining bug sounds.** Spawner pulsing, worm screeches, acid impacts, and the wet splatter
   on death (at least a body-fall thud when gore is off). Most of these get replaced as part of
   gunfire, worms and settlements; this item covers whatever is left.
5. **Test coverage.** Grow the gallery scenario and its automatic checks to cover gunfire,
   worms and settlements as each is built, not at the end.
6. **Signs of life in settlements.** Lights at night and chimney smoke. Best done once
   settlements have their look.
7. **Refugees.** When a settlement is destroyed, its surviving people walk to the nearest other
   settlement instead of fighting to the death.
8. **Factoriopedia.** Every enemy has its own small simulation scene there. Check they look
   right, especially worms and spawners once they're changed.
9. **Main menu and tips.** The main menu's background battles and one tips-and-tricks scene
   include biters. Check they look right.
10. **Leftover bug icons.** Corpse and death-effect prototypes still have bug icons, which show
    up in places like the map editor.
11. **Achievements.** Keep the names ("Pest control", "It stinks and they don't like it",
    "Steamrolled"), consistent with keeping the enemy names. Check whether their icons still
    show bugs.
12. **Saves and multiplayer.** Test adding the mod to an existing save, removing it again, and
    a multiplayer game, before anyone else plays it.
13. **Compatibility.** Make sure Space Age and other enemy mods (Armoured Biters, Rampant)
    don't break anything. Later, maybe a generic fallback that dresses any unknown enemy as a
    person of the closest tier.
14. **Mod portal release.** A 144x144 thumbnail (a crop from a gallery screenshot works), a
    description that states the intent, screenshots, a license, version 1.0.0, upload. Needs
    the framing question below answered first.
15. **Translations.** Other languages for the settings text.

## Needs more thought

To see what base-game assets are available for these, run `tools\screenshot.ps1 asset-catalog`
(everything labelled, plus kitbash examples) and `tools\screenshot.ps1 encampment-sketch`
(candidate settlements and defensive positions next to the bug versions).

1. **Acid damage type.** Keep acid, so game balance is untouched, or switch to physical once
   it looks like gunfire, which changes how armor and resistances work against it?
2. **Worms become defensive positions.** The gun turret moves through the same states a worm
   does (hidden, rising, aiming, firing, lowering), and dead worms could leave gun-turret
   wreckage. Open questions: turret graphics, or a person dug in behind a ring of wall pieces?
   Does the 20% size rule apply to structures, given that worms vary in size much more than
   biters?
3. **Spawners become settlements.** Composite buildings from base assets (market, stone
   furnaces, wooden chests, wooden poles, lamps), people walking out of them, and razed
   remnants with scorch marks when destroyed. Open questions: what a settlement looks like,
   and how biter settlements differ from spitter ones (for example a workshop and an armoury).
4. **Individual looks for living people.** One prototype has one look, so individuality needs
   two or three look-alike variants of each enemy type (different shades, with or without a
   helmet), swapped in at spawn. The cost is extra rows in the kill statistics. Worth it?
5. **Does the mod ever say anything outright?** An intro message or tips entry, or let the
   visuals carry it alone. Leaning toward visuals only, to match keeping the names.
6. **Settlement place names on the map.** Naming a place makes it a place, but this pulls
   against keeping the dehumanizing labels. Leaning toward leaving it out.
