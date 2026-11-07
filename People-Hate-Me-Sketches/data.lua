-- Kitbash experiments: pieces of base-game images cropped, scaled, tinted and layered into new pictures.
-- The sketch scenarios draw these with rendering.draw_sprite; nothing here is part of the real mod.
-- Each one combines several assets, so it doesn't read as a resized copy of something in the game,
-- and each replacement for a nest or worm keeps to that structure's footprint.

require("util")

local graphics = "__base__/graphics/"

-- A cropped piece of a base-game image. Its centre sits at shift (in tiles) from the sprite's
-- position, and it covers width * scale / 32 tiles.
local function part(file, x, y, width, height, scale, shift, extra)
  return util.merge{{filename = graphics .. file, x = x, y = y, width = width, height = height, scale = scale, shift = shift}, extra or {}}
end

local function add(layers, more)
  for _, layer in pairs(more) do
    layers[#layers + 1] = layer
  end
  return layers
end

-- Base-game pictures with the shifts they have at their normal scale of 0.5.
local pictures =
{
  assembler = {file = "entity/assembling-machine-1/assembling-machine-1-base.png", width = 198, height = 184, shift = {0, 0.125}},
  assembler_shadow = {file = "entity/assembling-machine-1/assembling-machine-1-shadow.png", width = 50, height = 166, shift = {1.39, 0.016}, shadow = true},
  electric_furnace = {file = "entity/electric-furnace/electric-furnace.png", width = 239, height = 219, shift = {0.023, 0.18}},
  electric_furnace_shadow = {file = "entity/electric-furnace/electric-furnace-shadow.png", width = 227, height = 171, shift = {0.35, 0.24}, shadow = true},
  steel_furnace = {file = "entity/steel-furnace/steel-furnace.png", width = 171, height = 174, shift = {-0.039, 0.0625}},
  steel_furnace_shadow = {file = "entity/steel-furnace/steel-furnace-shadow.png", width = 277, height = 85, shift = {1.227, 0.35}, shadow = true},
  turret_mount = {file = "entity/gun-turret/gun-turret-base.png", width = 150, height = 118, shift = {0.016, -0.031}},
  cargo_pod = {file = "entity/crash-site-chests/crash-site-chest-1.png", width = 120, height = 76, shift = {0.0625, 0.25}},
  cargo_pod_2 = {file = "entity/crash-site-chests/crash-site-chest-2.png", width = 116, height = 88, shift = {0, 0.25}},
  hull_plate = {file = "entity/crash-site-spaceship/spaceship-wreck-medium-1.png", width = 228, height = 120, shift = {-0.44, -0.125}},
  -- The pole sheet holds four directions side by side; this is the first.
  mast = {file = "entity/medium-electric-pole/medium-electric-pole.png", width = 84, height = 252, shift = {0.11, -1.375}},
  lamp = {file = "entity/small-lamp/lamp.png", width = 83, height = 70, shift = {0.008, 0.094}},
  lamp_shadow = {file = "entity/small-lamp/lamp-shadow.png", width = 76, height = 47, shift = {0.125, 0.148}, shadow = true},
  steel_chest = {file = "entity/steel-chest/steel-chest.png", width = 64, height = 80, shift = {-0.008, -0.016}},
  steel_chest_shadow = {file = "entity/steel-chest/steel-chest-shadow.png", width = 110, height = 46, shift = {0.383, 0.25}, shadow = true},
  crate = {file = "entity/wooden-chest/wooden-chest.png", width = 62, height = 72, shift = {0.016, -0.063}},
  crate_shadow = {file = "entity/wooden-chest/wooden-chest-shadow.png", width = 104, height = 40, shift = {0.3125, 0.203}, shadow = true},
  -- The wall sheet holds two variations side by side; this is the first.
  headstone = {file = "entity/wall/wall-single.png", width = 64, height = 86, shift = {0, -0.156}},
  wall_shadow = {file = "entity/wall/wall-single-shadow.png", width = 98, height = 60, shift = {0.3125, 0.53}, shadow = true},
}

-- A base-game picture scaled by k (its shift too, so it keeps its footing) and moved by offset.
local function piece(name, k, offset, extra)
  local picture = pictures[name]
  local shift = {picture.shift[1] * k + offset[1], picture.shift[2] * k + offset[2]}
  return part(picture.file, 0, 0, picture.width, picture.height, 0.5 * k, shift, util.merge{{draw_as_shadow = picture.shadow}, extra or {}})
end

local drab = {0.82, 0.84, 0.74}
local olive = {0.55, 0.62, 0.38}
local dark_olive = {0.42, 0.47, 0.3}
local earth = {0.85, 0.8, 0.68}

-- Cut foliage laid over a roof as camouflage: the pale tree-09 leaves, which the game itself tints
-- for its tree colours.
local function camo(x, y, width, tint)
  return part("entity/tree/09/tree-09-a-leaves.png", 20, 0, 310, 150, width * 32 / 310, {x, y}, {tint = tint or olive})
end

-- The lower trunk of a tree-02, below its branches, as a log post standing on y.
local function post(x, y, top, scale)
  local height = 312 - top
  return part("entity/tree/02/tree-02-a-trunk.png", 60, top, 44, height, scale, {x, y - height * scale / 64})
end

local post_tops = {205, 195, 210, 200, 192, 206, 198}

-- Each post also casts a stone wall's shadow, which is about the right height. Overlapping
-- shadows don't darken each other, so a row of them makes one continuous shadow.
local function post_row(x1, x2, y, scale)
  local layers = {}
  local k = scale / 0.4
  local i = 0
  for x = x1, x2 + 0.001, 0.4 do
    layers[#layers + 1] = part("entity/wall/wall-single-shadow.png", 0, 0, 98, 60, 0.5 * k, {x + 0.31 * k, y + 0.03 * k}, {draw_as_shadow = true})
    layers[#layers + 1] = post(x, y, post_tops[i % #post_tops + 1], scale)
    i = i + 1
  end
  return layers
end

local bank_rocks =
{
  {file = "decorative/sand-rock/medium-sand-rock-01.png", width = 134, height = 82},
  {file = "decorative/sand-rock/medium-sand-rock-02.png", width = 110, height = 79},
  {file = "decorative/sand-rock/medium-sand-rock-04.png", width = 110, height = 89},
  {file = "decorative/sand-rock/medium-sand-rock-05.png", width = 106, height = 76},
}

-- A low bank of earth: desert rocks overlapping in a row.
local function earth_bank(x1, x2, y)
  local layers = {}
  local i = 0
  for x = x1, x2 + 0.001, 0.38 do
    local rock = bank_rocks[i % #bank_rocks + 1]
    layers[#layers + 1] = part(rock.file, 0, 0, rock.width, rock.height, 0.26, {x, y + 0.04 * (i % 2)}, {tint = earth})
    i = i + 1
  end
  return layers
end

local small_rocks =
{
  {file = "decorative/small-rock/small-rock-01.png", width = 51, height = 37},
  {file = "decorative/small-rock/small-rock-02.png", width = 52, height = 35},
}

-- A ring of stones around broken crate planks, burning with the first frame of the small fire
-- that spreads on the ground.
local function campfire(x, y)
  local layers = {}
  for i = 1, 8 do
    local angle = 2 * math.pi * (i - 1) / 8
    local rock = small_rocks[(i - 1) % #small_rocks + 1]
    layers[i] = part(rock.file, 0, 0, rock.width, rock.height, 0.28, {x + 0.42 * math.cos(angle), y + 0.26 * math.sin(angle)})
  end
  return add(layers,
  {
    part("entity/wooden-chest/remnants/wooden-chest-remnants.png", 4, 10, 66, 34, 0.32, {x, y + 0.02}),
    part("entity/fire-flame/fire-flame-04.png", 0, 0, 84, 94, 0.3, {x, y - 0.3}, {draw_as_glow = true, tint = {0.9, 0.9, 0.9}}),
  })
end

local function lamp(x, y)
  return {piece("lamp_shadow", 1, {x, y}), piece("lamp", 1, {x, y})}
end

local function steel_chest(x, y, k)
  return {piece("steel_chest_shadow", k or 1, {x, y}), piece("steel_chest", k or 1, {x, y})}
end

local function headstone(x, y)
  return {piece("wall_shadow", 0.5, {x, y}), piece("headstone", 0.5, {x, y}, {tint = {0.95, 0.94, 0.9}})}
end

-- Biter nest (5x5): a workshop. An assembler's housing with its machinery hidden under camouflage,
-- a radio mast, crates and a salvaged cargo pod.
local workshop =
{
  piece("mast", 0.85, {1.55, -1.3}),
  piece("assembler_shadow", 1, {0, -0.3}),
  piece("assembler", 1, {0, -0.3}, {tint = drab}),
  camo(0, -1.15, 3.3),
  piece("crate_shadow", 1, {-1.6, 1.5}),
  piece("crate", 1, {-1.75, 1.45}),
  piece("crate", 1, {-1.25, 1.65}),
  piece("cargo_pod", 0.8, {1.3, 1.55}),
}

-- Spitter nest (5x5): an armoury. An electric furnace's body as a bunker under camouflage, with
-- ammunition boxes, a lamp, and earth banks either side of the door.
local armoury =
{
  piece("electric_furnace_shadow", 0.85, {0, -0.45}),
  piece("electric_furnace", 0.85, {0, -0.45}, {tint = drab}),
  camo(0, -1.45, 3.1, dark_olive),
}
add(armoury, steel_chest(1.85, -0.2))
add(armoury, steel_chest(1.85, 0.45))
add(armoury, earth_bank(-1.6, -0.6, 1.75))
add(armoury, earth_bank(0.6, 1.6, 1.75))
add(armoury, lamp(-1.9, 0.6))

-- Another nest option (5x5): two small cabins, steel furnaces under camouflage, behind a palisade.
local cabins = post_row(-2, 2, -1.6, 0.32)
add(cabins,
{
  piece("steel_furnace_shadow", 0.75, {-1, -0.4}),
  piece("steel_furnace", 0.75, {-1, -0.4}, {tint = drab}),
  camo(-1.1, -1.05, 1.9),
  piece("steel_furnace_shadow", 0.75, {1.1, 0.3}),
  piece("steel_furnace", 0.75, {1.1, 0.3}, {tint = drab}),
  camo(1, -0.35, 1.9, dark_olive),
  piece("cargo_pod_2", 0.7, {-1.2, 1.4}),
  piece("crate", 1, {0.1, 1.6}),
})

-- A graveyard (5x5): two rows of headstones behind a palisade, with a lamp.
local graveyard = post_row(-2, 2, -1.7, 0.32)
for _, y in pairs{-0.6, 0.6} do
  for _, x in pairs{-1.2, 0, 1.2} do
    add(graveyard, headstone(x, y))
  end
end
add(graveyard, lamp(1.9, 1.5))

-- Worms become firing positions, each within its worm's footprint.
local small_position = {camo(0, -0.5, 1.5), piece("hull_plate", 0.55, {0.15, 0.4})}

local medium_position = {camo(0, -0.65, 2, dark_olive)}
add(medium_position, steel_chest(0.85, -0.15, 0.8))
add(medium_position, earth_bank(-0.5, 0, 0.55))
add(medium_position, {piece("hull_plate", 0.5, {0.75, 0.55})})

local big_position = post_row(-1.2, 1.2, -0.75, 0.26)
add(big_position, {camo(0, -1.3, 2.8, dark_olive), piece("turret_mount", 0.9, {0, 0.05}, {tint = drab})})
add(big_position, earth_bank(-0.8, 0.1, 0.8))
add(big_position, {piece("hull_plate", 0.5, {0.85, 0.85})})

local function sprite(name, layers)
  return {type = "sprite", name = "phm-sketch-" .. name, layers = layers}
end

data:extend
{
  sprite("workshop", workshop),
  sprite("armoury", armoury),
  sprite("cabins", cabins),
  sprite("graveyard", graveyard),
  sprite("position-small", small_position),
  sprite("position-medium", medium_position),
  sprite("position-big", big_position),
  sprite("palisade", post_row(-1.6, 1.6, 0.3, 0.4)),
  sprite("earth-bank", earth_bank(-1.5, 1.5, 0.2)),
  sprite("campfire", campfire(0, 0)),
}
