# People Hate Me

A Factorio 2.1 mod that redraws the native life of Nauvis as people instead of bugs.

Factorio asks you to exterminate "biters" without a second thought, because they look like
insects and monsters. This mod keeps the game exactly as it plays, but shows the enemies as
humans and their nests as a civilization. The point is to make the colonial logic of the game
visible: the same expansion, pollution and extermination feel different when the ones being
pushed out look like us.

The mod uses only assets that ship with the game. Enemy people are built from the engineer's
own sprites, varied by size, clothing colour and armor. Their buildings are kitbashed from
pieces of other base-game images: stone wall faces, floor tiles, furnace chimneys.

## Current state (0.3.0)

| Enemy | Looks like | Attack |
| --- | --- | --- |
| Small / medium / big / behemoth biter | Engineer body at 0.85 / 0.95 / 1.05 / 1.15 size; no armor / heavy armor / power armor / darkened power armor | Pickaxe swing, pickaxe sounds |
| Small / medium / big / behemoth spitter | Same sizes and armor, different clothing colours | Winds up and throws a bottle of glowing yellow goo, which smashes and leaves a puddle that hurts and slows like the acid did |
| Biter and spitter corpses | Fallen engineer, two random poses, each with their own shade of clothing colour, red blood pools | |
| Biter nest | Two houses with tiled roofs and chimneys on a paved lot | People walk out of it |
| Spitter nest | A two-storey block of flats or a hall with skylights | People walk out of it |
| Destroyed nest | Burnt-out ruin: broken walls, rubble, fallen roof, a standing chimney, scorched paving | |
| Small / medium / big / behemoth worm | A gunner dressed like the spitter of that tier, on a mechanical platform (a gun turret's base) that's on the ground / raised on a brick plinth / on a concrete bunker / on a steel-plated bunker | The gunner stands at ease, readies themselves as enemies near, and turns to throw the same bottles as the spitters |
| Destroyed worm | Wrecked position with the dead gunner, in their own shade | |

Enemies bleed red, walk with footsteps, and no longer screech or call. Their icons show the
engineer with an armor badge for the tier and a gun badge for spitters. Windows and street
lamps light up at night. The game's names ("Small biter") are kept on purpose: the
dehumanizing label next to a human body is part of the commentary.

Settings (Settings > Mod settings > Startup):

- **Gore**, on by default. Turning it off stops flesh being thrown when enemies die; the blood
  stays.
- **Exploding bottles**, off by default. Turning it on makes the thrown bottles burn in the air
  and burst into a fireball where they land. Only the look changes.

Design rules so far:

- Body size stays within 20% of the engineer, and tiers are told apart mainly by armor and
  clothing colour.
- Use the base game's own graphics wherever possible.
- Anything built from them must not look like an existing object. Combine pieces of several
  assets, or change one enough that it reads as something else. Resizing is fine, but it
  can't be what makes the difference: an enlarged stone furnace still looks like a stone
  furnace.
- The people's world is as modern as their gear, and it's a civilization, not an army:
  spawners become town buildings (houses, flats, halls), not huts or armouries. Only the
  worms are military, as defensive positions.
- A replacement keeps the footprint (collision box) of the structure it replaces.

Still bugs: the creep and mushrooms around nests, and the nests' and worms' icons. See
[TODO.md](TODO.md).

## Project layout

```
People-Hate-Me/              the mod itself (this folder is what Factorio loads)
  info.json                  mod name, version, Factorio version, dependencies
  definitions.lua            size, armor and colour of every enemy type, and who mans each worm (shared by both stages)
  settings.lua               mod settings (gore, exploding bottles)
  data.lua                   data stage entry point
  prototypes/person.lua      draws a person from the engineer's sprites in a look from definitions.lua
  prototypes/people.lua      redraws biters and spitters as people: sprites, icons, sounds
  prototypes/kitbash.lua     builds pictures from cropped, scaled, tinted pieces of base-game images
  prototypes/settlements.lua redraws spawners as town buildings, and their corpses as ruins
  prototypes/positions.lua   redraws worms as manned defensive positions, and their corpses as wrecks
  prototypes/bottles.lua     turns the spitters' and worms' acid into thrown bottles of burning goo
  prototypes/gore.lua        recolours blood and gore red; removes flesh when gore is off
  control.lua                gives every fallen person their own shade of clothing colour
  locale/en/                 in-game text for the settings
  scenarios/gallery/         lineup of every enemy type and structure, used for testing
  changelog.txt              shown in-game and on the mod portal
People-Hate-Me-Sketches/     development-only companion mod, never packaged or published
  data.lua                   kitbash experiments not in the mod yet (graveyard, palisade, campfire), and the ways a bottle can land
  scenarios/showroom/        the mod in action: stations that keep running, and a panel to jump between them
  scenarios/asset-catalog/   every base-game asset that could be repurposed, labelled
  scenarios/encampment-sketch/  a graveyard among the real nests, and proposed ground around nests
  scenarios/bottle-sketch/   the ways a thrown bottle can land, side by side, and the throws filmed frame by frame
tools/                       PowerShell helpers (see below)
TODO.md                      planned work and open design questions, in priority order
legacy/2023-attempt/         the original 2023 attempt (Factorio 1.1), kept for reference
```

## How a Factorio mod works (refresher)

- `info.json` identifies the mod. The folder in the mods directory must be named after
  `name` (or `name_version`).
- Factorio loads mods in stages. The **settings stage** (`settings.lua`) comes first and
  declares mod settings. "Startup" settings can be read in the data stage through
  `settings.startup`; changing one makes the game restart.
- In the **data stage** (`data.lua`, `data-updates.lua`,
  `data-final-fixes.lua`) mods edit `data.raw`, the table of every prototype (entity
  definitions, sprites, sounds). All visual changes in this mod happen here.
- In the **control stage** (`control.lua`) scripts react to events while a game is running.
  Prototypes can't change per entity, so anything individual (like corpse colours) happens here.
- The base game's own Lua files are the best reference. They live in
  `<Factorio>/data/base/prototypes`, and the full API docs are in `<Factorio>/doc-html`.

## Development

Run the scripts from the repo root. If PowerShell refuses to run scripts, prefix with
`powershell -ExecutionPolicy Bypass -File`.

- `tools\link.ps1` links the repo's mod and its sketches into your normal Factorio mods folder
  and enables them, so the showroom and every sketch scenario show among the mod scenarios. The
  sketches only add hidden copies of things, so the game plays the same; turn them off in the
  mod list to keep them out of a save. Edits in the repo apply the next time Factorio starts.
- `tools\test.ps1` loads the mod headless in an isolated mods folder (`.dev\mods`, only base,
  this mod and its sketches), runs the gallery scenario, and checks that every enemy type still
  attacks, leaves a corpse, and was redrawn, that every worm still fires, that every spitter's
  and worm's bottles leave goo, and that destroyed nests and worms leave ruins. Takes a few
  seconds; exits 0 on pass.
- `tools\play.ps1` opens the showroom with graphics and sound and leaves it open, to watch the
  mod in action. Its stations keep running: the thrown bottles smashing, and bursting as the
  Exploding bottles setting makes them, every person standing, walking and attacking, the
  settlements and positions (people come by so the positions wake up and throw), and deaths and
  ruins replaying every 15 seconds. A panel jumps between stations, slows the game to a half, a
  quarter or a tenth of normal speed, and switches to night. Steam asks you to confirm the custom launch arguments each time; click Continue.
- `tools\screenshot.ps1 [scenario]` opens a scenario with graphics (default `gallery`; also
  `asset-catalog`, `encampment-sketch` or `bottle-sketch`), waits for the screenshots it takes,
  closes the game, and replaces that scenario's images in `.dev\screenshots\<scenario>`.
- `tools\view-screenshots.ps1` opens a page in your browser showing every screenshot taken so
  far, grouped by scenario. Click an image to see it at full size.
- `tools\package.ps1` builds `dist\People-Hate-Me_<version>.zip` for the mod portal.

The gallery is also playable: in Factorio, open Single player, then Scenarios, then
`People-Hate-Me/gallery`.

If Factorio is installed somewhere else, set `FACTORIO_EXE` to the full path of `factorio.exe`.

## Roadmap

Planned work and open design questions are tracked in [TODO.md](TODO.md). What's already done
is in [the changelog](People-Hate-Me/changelog.txt).
