-- Kitbash experiments that aren't in the mod yet, built with the mod's own helpers
-- (People-Hate-Me/prototypes/kitbash.lua). The sketch scenarios draw them with
-- rendering.draw_sprite; nothing here is part of the real mod.

local kitbash = require("__People-Hate-Me__.prototypes.kitbash")

local part, add = kitbash.part, kitbash.add

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

local function headstone(x, y)
  return
  {
    part("entity/wall/wall-single-shadow.png", 0, 0, 98, 60, 0.25, {x + 0.156, y + 0.265}, {draw_as_shadow = true}),
    part("entity/wall/wall-single.png", 0, 0, 64, 86, 0.25, {x, y - 0.078}, {tint = {0.95, 0.94, 0.9}}),
  }
end

-- A graveyard (5x5): two rows of headstones behind a palisade, with a lamp.
local graveyard = post_row(-2, 2, -1.7, 0.32)
for _, y in pairs{-0.6, 0.6} do
  for _, x in pairs{-1.2, 0, 1.2} do
    add(graveyard, headstone(x, y))
  end
end
add(graveyard, kitbash.lamp(1.9, 1.5))

local function sprite(name, layers)
  return {type = "sprite", name = "phm-sketch-" .. name, layers = layers}
end

data:extend
{
  sprite("graveyard", graveyard),
  sprite("palisade", post_row(-1.6, 1.6, 0.3, 0.4)),
  sprite("earth-bank", kitbash.earth_bank(-1.5, 1.5, 0.2)),
  sprite("campfire", campfire(0, 0)),
}

-- For the bottle sketch: each goo colour's acid, and a big spitter and a small worm's pit that
-- throw it, named phm-sketch-<enemy>-<goo>.
local bottles = require("__People-Hate-Me__.prototypes.bottles")

local function thrower(type, name, goo_name, stream)
  local copy = table.deepcopy(data.raw[type][name])
  copy.name = "phm-sketch-" .. name .. "-" .. goo_name
  copy.localised_name = {"entity-name." .. name}
  copy.hidden = true
  copy.autoplace = nil
  copy.attack_parameters.ammo_type.action.action_delivery.stream = stream .. "-" .. goo_name
  return copy
end

for goo_name, goo in pairs(bottles.goos) do
  bottles.dress(goo, goo_name)
  data:extend
  {
    thrower("unit", "big-spitter", goo_name, "acid-stream-spitter-big"),
    thrower("turret", "small-worm-turret", goo_name, "acid-stream-worm-small"),
  }
end