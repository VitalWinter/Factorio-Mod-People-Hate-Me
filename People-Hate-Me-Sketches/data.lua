-- Kitbash experiments: pieces of base-game images cropped, scaled, tinted and layered into new pictures.
-- The sketch scenarios draw these with rendering.draw_sprite; nothing here is part of the real mod.
-- Each one combines several assets, so it doesn't read as a resized copy of something in the game.

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

local field_stone = {0.72, 0.7, 0.66}
local straw = {1, 0.85, 0.5}
local old_straw = {0.72, 0.58, 0.4}
local earth = {0.8, 0.7, 0.56}

-- A stone furnace's beehive shape roofed with straw. The straw is the pale tree-09 foliage, which
-- the game itself tints for its tree colours.
local function hut(x, y, k, thatch)
  return
  {
    part("entity/stone-furnace/stone-furnace-shadow.png", 0, 0, 164, 74, 0.5 * k, {x + 0.453 * k, y + 0.406 * k}, {draw_as_shadow = true}),
    part("entity/stone-furnace/stone-furnace.png", 0, 0, 151, 146, 0.5 * k, {x - 0.008 * k, y + 0.188 * k}, {tint = field_stone}),
    part("entity/stone-furnace/stone-furnace-fire.png", 0, 0, 41, 100, 0.5 * k, {x - 0.023 * k, y + 0.172 * k}, {draw_as_glow = true}),
    part("entity/tree/09/tree-09-a-leaves.png", 20, 0, 310, 150, 0.16 * k, {x, y - 0.62 * k}, {tint = thatch}),
  }
end

-- The lower trunk of a tree-02, below its branches, as a log post standing on y.
local function post(x, y, top, scale, tint)
  local height = 312 - top
  return part("entity/tree/02/tree-02-a-trunk.png", 60, top, 44, height, scale, {x, y - height * scale / 64}, {tint = tint})
end

local post_tops = {205, 195, 210, 200, 192, 206, 198}
local post_tints = {{1, 1, 1}, {0.9, 0.88, 0.85}, {1, 1, 1}, {0.85, 0.82, 0.78}}

-- Each post also casts a stone wall's shadow, which is about the right height. Overlapping
-- shadows don't darken each other, so a row of them makes one continuous shadow.
local function post_row(x1, x2, y, step, scale)
  local layers = {}
  local k = scale / 0.4
  local i = 0
  for x = x1, x2 + 0.001, step do
    layers[#layers + 1] = part("entity/wall/wall-single-shadow.png", 0, 0, 98, 60, 0.5 * k, {x + 0.31 * k, y + 0.03 * k}, {draw_as_shadow = true})
    layers[#layers + 1] = post(x, y, post_tops[i % #post_tops + 1], scale, post_tints[i % #post_tints + 1])
    i = i + 1
  end
  return layers
end

local small_rocks =
{
  {file = "decorative/small-rock/small-rock-01.png", width = 51, height = 37},
  {file = "decorative/small-rock/small-rock-02.png", width = 52, height = 35},
}

local function small_rock(index, scale, shift)
  local rock = small_rocks[(index - 1) % #small_rocks + 1]
  return part(rock.file, 0, 0, rock.width, rock.height, scale, shift)
end

-- A ring of stones around broken crate planks, burning with the first frame of the small fire
-- that spreads on the ground.
local function campfire(x, y)
  local layers = {}
  for i = 1, 8 do
    local angle = 2 * math.pi * (i - 1) / 8
    layers[i] = small_rock(i, 0.28, {x + 0.42 * math.cos(angle), y + 0.26 * math.sin(angle)})
  end
  return add(layers,
  {
    part("entity/wooden-chest/remnants/wooden-chest-remnants.png", 4, 10, 66, 34, 0.32, {x, y + 0.02}),
    part("entity/fire-flame/fire-flame-04.png", 0, 0, 84, 94, 0.3, {x, y - 0.3}, {draw_as_glow = true, tint = {0.9, 0.9, 0.9}}),
  })
end

local function chest(x, y)
  return part("entity/wooden-chest/wooden-chest.png", 0, 0, 62, 72, 0.5, {x + 0.016, y - 0.063})
end

local compound = post_row(-2.4, 2.4, -1.6, 0.4, 0.32)
add(compound, hut(-1, -0.2, 1, straw))
add(compound, hut(1.1, -0.4, 0.9, straw))
add(compound, campfire(0.1, 1))
add(compound, {chest(-2, 1.1), chest(-1.55, 1.2)})
add(compound, post_row(-2.4, -1.2, 1.9, 0.4, 0.32))
add(compound, post_row(1.2, 2.4, 1.9, 0.4, 0.32))

data:extend
{
  {type = "sprite", name = "phm-sketch-hut", layers = hut(0, 0, 1.2, straw)},
  {type = "sprite", name = "phm-sketch-hut-old", layers = hut(0, 0, 1.2, old_straw)},
  {type = "sprite", name = "phm-sketch-campfire", layers = campfire(0, 0)},
  {
    type = "sprite",
    name = "phm-sketch-barricade",
    layers = add(post_row(-1.2, 1.2, -0.1, 0.4, 0.32),
    {
      part("entity/wall/remnants/wall-remnants.png", 0, 0, 118, 114, 0.5, {-0.75, 0.3}, {tint = earth}),
      part("entity/wooden-chest/remnants/wooden-chest-remnants.png", 0, 0, 110, 74, 0.5, {0.15, 0.3}),
      small_rock(1, 0.5, {1.15, 0.45}),
    }),
  },
  {type = "sprite", name = "phm-sketch-palisade", layers = post_row(-1.6, 1.6, 0.3, 0.4, 0.4)},
  {type = "sprite", name = "phm-sketch-compound", layers = compound},
}
