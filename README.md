# People Hate Me

A Factorio 2.1 mod that redraws the native life of Nauvis as people instead of bugs.

Factorio asks you to exterminate "biters" without a second thought, because they look like
insects and monsters. This mod keeps the game exactly as it plays, but shows the enemies as
humans and their nests as a civilization. The point is to make the colonial logic of the game
visible: the same expansion, pollution and extermination feel different when the ones being
pushed out look like us.

The mod uses only assets that ship with the game. Enemy people are built from the engineer's
own sprites, varied by size, clothing colour and armor.

## Current state (0.2.1)

| Enemy | Looks like | Attack |
| --- | --- | --- |
| Small / medium / big / behemoth biter | Engineer body at 0.85 / 0.95 / 1.05 / 1.15 size; no armor / heavy armor / power armor / darkened power armor | Pickaxe swing, pickaxe sounds |
| Small / medium / big / behemoth spitter | Same sizes and armor, different clothing colours | Aims a gun, gunshot sound (still fires acid) |
| Biter and spitter corpses | Fallen engineer, two random poses, each with their own shade of clothing colour, red blood pools | |

Enemies bleed red, walk with footsteps, and no longer screech or call. Their icons show the
engineer with an armor badge for the tier and a gun badge for spitters. The game's names
("Small biter") are kept on purpose: the dehumanizing label next to a human body is part of
the commentary.

Settings (Settings > Mod settings > Startup): **Gore**, on by default. Turning it off stops
flesh being thrown when enemies die; the blood stays.

Design rules so far: body size stays within 20% of the engineer, and tiers are told apart
mainly by armor and clothing colour.

Still bugs: spawners, worms, and the spitters' acid. See [TODO.md](TODO.md).

## Project layout

```
People-Hate-Me/              the mod itself (this folder is what Factorio loads)
  info.json                  mod name, version, Factorio version, dependencies
  definitions.lua            size, armor and colour of every enemy type (shared by both stages)
  settings.lua               mod settings (the gore toggle)
  data.lua                   data stage entry point
  prototypes/people.lua      redraws biters and spitters as people: sprites, icons, sounds
  prototypes/gore.lua        recolours blood and gore red; removes flesh when gore is off
  control.lua                gives every corpse its own shade of clothing colour
  locale/en/                 in-game text for the settings
  scenarios/gallery/         lineup of every enemy type, used for testing
  changelog.txt              shown in-game and on the mod portal
People-Hate-Me-Sketches/     development-only companion mod, never packaged or published
  data.lua                   kitbash experiments: base-game sprites cropped, scaled, tinted, layered
  scenarios/asset-catalog/   every base-game asset that could be repurposed, labelled
  scenarios/encampment-sketch/  candidate settlements and defensive positions built from real pieces
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

- `tools\link.ps1` links the repo's mod folder into your normal Factorio mods folder and
  enables it. Edits in the repo apply the next time Factorio starts.
- `tools\test.ps1` loads the mod headless in an isolated mods folder (`.dev\mods`, only base,
  this mod and its sketches), runs the gallery scenario, and checks that every enemy type still
  attacks, leaves a corpse, and was redrawn. Takes a few seconds; exits 0 on pass.
- `tools\screenshot.ps1 [scenario]` opens a scenario with graphics (default `gallery`; also
  `asset-catalog` or `encampment-sketch`), waits for the screenshots it takes, closes the game,
  and copies the images to `.dev\screenshots\<scenario>`. Steam asks you to confirm the custom
  launch arguments each time; click Continue.
- `tools\package.ps1` builds `dist\People-Hate-Me_<version>.zip` for the mod portal.

The gallery is also playable: in Factorio, open Single player, then Scenarios, then
`People-Hate-Me/gallery`.

If Factorio is installed somewhere else, set `FACTORIO_EXE` to the full path of `factorio.exe`.

## Roadmap

Planned work and open design questions are tracked in [TODO.md](TODO.md). What's already done
is in [the changelog](People-Hate-Me/changelog.txt).
