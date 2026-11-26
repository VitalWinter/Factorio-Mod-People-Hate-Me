# To do

The goal: every enemy, everything they do, and everything they build feels human, like a
civilization. Only how the game looks and sounds changes; it plays exactly like the base game
(see the design rules in the README). This file is the working list for getting there.

- **(AI)** marks an idea, judgement or design choice that came from the AI assistant, not from
  the project owner. Before an item, the whole item is the AI's proposal. Inside an item, it
  marks the part that is (usually a suggested design). Unmarked text is the owner's own
  direction, something that follows directly from it (like a bug picture that still shows), or
  a plain fact about the game.
- (AI) Both sections are in priority order, highest first. The owner asked the AI to sort them.
- Anything that would change how the game plays goes under "Out of scope", not here.
  `tools\parity.ps1` (run by `tools\test.ps1`) fails when a change does.
- When an item is done, delete it here and record it in `People-Hate-Me/changelog.txt`.
- When an item under "Needs more thought" is decided, write the decision into the item and
  move it into "Ready to do" at the right priority.

## Ready to do

1. **Icons for nests and worms.** They still have bug icons, which show in Factoriopedia, the
   kill statistics and alerts. (AI) Layer item icons (walls, floor tiles, a gun) into a house, a
   block of flats and each position.
2. **Ground around nests and worms.** They spawn creep decals, mushrooms, lichen and muddy
   stumps around them. (AI) Swap these for trodden mud, paths and cleared ground (the
   encampment sketch has a first try).
3. **Remaining bug sounds.** The wet splatter on death. (AI) At least a body-fall thud when gore
   is off. Nests and worms are silent now; (AI) a building could crumble with a stone-collapse
   sound instead of just the debris explosion.
4. (AI) **Test coverage.** Grow the gallery scenario and its automatic checks with each feature
   as it's built, not at the end. Exploratory visual tests go where they show among the Mod
   Scenarios, like the showroom.
5. (AI) **Chimney smoke.** The houses and flats have chimneys; a thin trail of smoke from them
   would make the settlements feel lived in, alongside the lit windows and street lamps. Only
   smoke that is drawn, not pollution or anything that affects the game.
6. **Factoriopedia.** Every enemy has its own small simulation scene there. Check they look
   right, especially the nests and worms.
7. **Main menu and tips.** The main menu's background battles and one tips-and-tricks scene
   include biters. Check they look right.
8. **Leftover bug icons.** Corpse and death-effect prototypes still have bug icons, which show
   up in places like the map editor.
9. **Achievements.** Check whether their icons still show bugs. (AI) Keep the names ("Pest
   control", "It stinks and they don't like it", "Steamrolled"), consistent with keeping the
   enemy names.
10. (AI) **Saves and multiplayer.** Test adding the mod to an existing save, removing it again,
    and a multiplayer game, before anyone else plays it.
11. (AI) **Compatibility.** Make sure Space Age (including captured spawners) and other enemy
    mods (Armoured Biters, Rampant) don't break anything. Later, maybe a generic fallback that
    dresses any unknown enemy as a person of the closest tier.
12. (AI) **Mod portal release.** A 144x144 thumbnail (a crop from a gallery screenshot works), a
    description that states the intent, screenshots, a license, version 1.0.0, upload. Needs
    the framing question below answered first.
13. (AI) **Translations.** Other languages for the settings text.

## Needs more thought

To see what base-game assets are available for these, run `tools\screenshot.ps1 asset-catalog`
(everything labelled, plus kitbash examples) and `tools\screenshot.ps1 encampment-sketch`
(ideas shown among the real nests). Whatever is chosen follows the design rules in the README:
only the look and sound change, town buildings of a civilization (only the worms are military),
built from several assets so it doesn't look like an existing object, and within the footprint
of what it replaces.

1. **Gameplay differences already in the mod.** `tools\parity.ps1` found these; each is listed
   in `tools\parity-allowlist.txt` as waiting for the owner's decision. Each one either gets
   accepted there, with the reason, or put back to the base game's value.
   - Bottles leave the thrower's hand instead of where the bug's head was, so they start
     further from the target and land later: up to 5.5 ticks for spitters, up to 12 for worms
     (a big worm measured 9). Putting the base values back means the bottle appears in the air beside
     the person.
   - A throw is one bottle, where the acid was a stream of blobs. A stream always spawns at
     least two particles, and only the first carries the landing; the bottle is the second, so
     it lands 2 ticks later (measured 163 against 161). The damage, puddle and slowdown were
     measured the same.
   - People's selection boxes (what the mouse hovers, clicks and aims at) are the shape of a
     standing person instead of a low bug. From medium up they're about half the bug box's
     area, so a person is harder to click; the small spitter's is larger. The gallery's
     automatic checks currently require this.
2. (AI) **More kinds of building.** Biter nests are always the two houses, and spitter nests
   are the flats or the hall. A mirrored street of houses, a shop or a school would make towns
   less uniform. How much variety is worth it, and should the bugs' variety (biter versus
   spitter) keep mapping to building types?
3. (AI) **Graveyards.** A graveyard (headstones behind a palisade, in the encampment sketch)
   could stand near settlements. The owner said graveyards look neat. Does it appear with
   nests, or where many people have died? Either way it can only be decoration: anything that
   blocks building or walking, or is placed by a script during the game, changes how it plays.
4. (AI) **Individual looks for living people.** One prototype has one look, so individuality
   needs two or three look-alike variants of each enemy type (different shades, with or
   without a helmet), swapped in at spawn. Swapping an enemy for another prototype changes the
   kill statistics and may disturb attack groups, so it probably breaks the rule that the game
   plays the same.
5. (AI) **Does the mod ever say anything outright?** An intro message or tips entry, or let
   the visuals carry it alone. (AI) Leaning toward visuals only, to match keeping the names.
6. (AI) **Settlement place names on the map.** Naming a place makes it a place, but this pulls
   against keeping the dehumanizing labels. (AI) Leaning toward leaving it out.
7. **A bottle shadow that starts at the thrower's feet.** The stream draws the shadow on the
   bottle's ground track, so it leaves the hand with the bottle and meets it at the landing. A
   stream cannot start that shadow lower, at the feet, and close the gap over the flight. An
   artillery shell and a grenade can hold the picture above its own shadow and bring them
   together at the impact, and a grenade's shadow can tumble with the body. Either replaces the
   acid stream, so the arc, the goo, the sticker and the splash would have to be rebuilt, and
   the attack would no longer play exactly like the acid. A grenade descends from a fixed height
   and would not climb the ten tiles of a long throw. Worth leaving the stream for that shadow?

## Out of scope

Ideas that would change how the game plays. They're kept here, with the reason, so they aren't
proposed again.

- (AI) **Refugees.** When a settlement is destroyed, its surviving people walk to the nearest
  other settlement instead of fighting to the death. This changes what the enemies do.
