# To do

The goal: every enemy, everything they do, and everything they build feels human, like a
civilization. This file is the working list for getting there.

- Both sections are in priority order, highest first.
- When an item is done, delete it here and record it in `People-Hate-Me/changelog.txt`.
- When an item under "Needs more thought" is decided, write the decision into the item and
  move it into "Ready to do" at the right priority.

## Ready to do

1. **Icons for nests and worms.** They still have bug icons, which show in Factoriopedia, the
   kill statistics and alerts. Layer item icons (walls, floor tiles, a gun) into a house, a
   block of flats and each position.
2. **Ground around nests and worms.** They spawn creep decals, mushrooms, lichen and muddy
   stumps around them. Swap these for trodden mud, paths and cleared ground (the encampment
   sketch has a first try).
3. **Remaining bug sounds.** The wet splatter on death (at least a body-fall thud when gore is
   off). Nests and worms are silent now; a building could crumble with a
   stone-collapse sound instead of just the debris explosion.
4. **Test coverage.** Grow the gallery scenario and its automatic checks with each feature as
   it's built, not at the end.
5. **Chimney smoke.** The houses and flats have chimneys; a thin trail of smoke from them would
   make the settlements feel lived in, alongside the lit windows and street lamps.
6. **Refugees.** When a settlement is destroyed, its surviving people walk to the nearest other
   settlement instead of fighting to the death.
7. **Factoriopedia.** Every enemy has its own small simulation scene there. Check they look
   right, especially the nests and worms.
8. **Main menu and tips.** The main menu's background battles and one tips-and-tricks scene
    include biters. Check they look right.
9. **Leftover bug icons.** Corpse and death-effect prototypes still have bug icons, which show
    up in places like the map editor.
10. **Achievements.** Keep the names ("Pest control", "It stinks and they don't like it",
    "Steamrolled"), consistent with keeping the enemy names. Check whether their icons still
    show bugs.
11. **Saves and multiplayer.** Test adding the mod to an existing save, removing it again, and
    a multiplayer game, before anyone else plays it.
12. **Compatibility.** Make sure Space Age (including captured spawners) and other enemy mods
    (Armoured Biters, Rampant) don't break anything. Later, maybe a generic fallback that
    dresses any unknown enemy as a person of the closest tier.
13. **Mod portal release.** A 144x144 thumbnail (a crop from a gallery screenshot works), a
    description that states the intent, screenshots, a license, version 1.0.0, upload. Needs
    the framing question below answered first.
14. **Translations.** Other languages for the settings text.

## Needs more thought

To see what base-game assets are available for these, run `tools\screenshot.ps1 asset-catalog`
(everything labelled, plus kitbash examples) and `tools\screenshot.ps1 encampment-sketch`
(ideas shown among the real nests). Whatever is chosen follows the design rules in the README:
town buildings of a civilization (only the worms are military), built from several assets so
it doesn't look like an existing object, and within the footprint of what it replaces.

1. **More kinds of building.** Biter nests are always the two houses, and spitter nests are the
   flats or the hall. A mirrored street of houses, a shop or a school would make towns less
   uniform. How much variety is worth it, and should the bugs' variety (biter versus spitter)
   keep mapping to building types?
2. **Graveyards.** A graveyard (headstones behind a palisade, in the encampment sketch) could
   stand near settlements. Does it appear with nests, or where many people have died?
3. **Individual looks for living people.** One prototype has one look, so individuality needs
   two or three look-alike variants of each enemy type (different shades, with or without a
   helmet), swapped in at spawn. The cost is extra rows in the kill statistics. Worth it?
4. **Does the mod ever say anything outright?** An intro message or tips entry, or let the
   visuals carry it alone. Leaning toward visuals only, to match keeping the names.
5. **Settlement place names on the map.** Naming a place makes it a place, but this pulls
   against keeping the dehumanizing labels. Leaning toward leaving it out.
6. **A bottle shadow that starts at the thrower's feet.** The stream draws the shadow on the
   bottle's ground track, so it leaves the hand with the bottle and meets it at the landing. A
   stream cannot start that shadow lower, at the feet, and close the gap over the flight. An
   artillery shell and a grenade can hold the picture above its own shadow and bring them
   together at the impact, and a grenade's shadow can tumble with the body. Either replaces the
   acid stream, so the arc, the goo, the sticker and the splash would have to be rebuilt. A
   grenade descends from a fixed height and would not climb the ten tiles of a long throw.
   Worth leaving the stream for that shadow?
