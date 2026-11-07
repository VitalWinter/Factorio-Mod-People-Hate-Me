-- Kitbashing: pieces of base-game images cropped, scaled, tinted and layered into new pictures.
-- Every position is in tiles from the entity's position. A piece's centre sits at its shift, and
-- it covers width * scale / 32 tiles.

local util = require("util")

local kitbash = {}

kitbash.tints =
{
  terracotta = {0.95, 0.72, 0.6},
  brick = {0.8, 0.55, 0.45},
  plaster = {1, 0.95, 0.85},
  -- Pale enough that the warm light behind it shows at night.
  glass = {0.66, 0.62, 0.55},
  lamplight = {1, 0.68, 0.32},
  wood = {0.3, 0.2, 0.13},
  earth = {0.85, 0.8, 0.68},
  soot = {0.5, 0.46, 0.42},
  ash = {0.78, 0.74, 0.7},
  slit = {0.05, 0.05, 0.05},
}
local tints = kitbash.tints

-- A cropped piece of an image. Paths without a mod prefix are in the base game's graphics.
function kitbash.part(file, x, y, width, height, scale, shift, extra)
  local filename = file:find("^__") and file or "__base__/graphics/" .. file
  return util.merge{{filename = filename, x = x, y = y, width = width, height = height, scale = scale, shift = shift}, extra or {}}
end
local part = kitbash.part

function kitbash.add(layers, more)
  for _, layer in pairs(more) do
    layers[#layers + 1] = layer
  end
  return layers
end
local add = kitbash.add

-- A w by h tile rectangle cut from the game's 10x10 white square. Crops are whole pixels, so the
-- proportions are approximate.
function kitbash.rect(x, y, w, h, tint, extra)
  local pw, ph = 10, 10
  if w >= h then
    ph = math.max(1, math.floor(10 * h / w + 0.5))
  else
    pw = math.max(1, math.floor(10 * w / h + 0.5))
  end
  return part("__core__/graphics/white-square.png", 0, 0, pw, ph, w * 32 / pw, {x, y}, util.merge{{tint = tint}, extra or {}})
end
local rect = kitbash.rect

local roofs =
{
  stone_path = "terrain/stone-path/stone-path-4.png",
  concrete = "terrain/concrete/concrete.png",
  refined_concrete = "terrain/concrete/refined-concrete.png",
}

-- A box building on the footprint centred at x, y: spec.columns wall segments of k tiles across,
-- spec.depth tiles deep, spec.floors storeys of k tiles high. The front wall is the stone wall's
-- face, with its cap as the cornice; the roof is a floor tile's texture, raised by the wall's
-- height; an assembler's shadow falls to the east.
function kitbash.building(x, y, spec)
  local k = spec.k or 1
  local width = spec.columns * k
  local front = y + spec.depth / 2
  local height = spec.floors * k
  local shadow_scale = (spec.depth + height + 0.25 * k) * 32 / 166
  local layers =
  {
    part("entity/assembling-machine-1/assembling-machine-1-shadow.png", 0, 0, 50, 166, shadow_scale,
      {x + width / 2 + 50 * shadow_scale / 64 - 0.05, front - (spec.depth + height) / 2}, {draw_as_shadow = true}),
    part(roofs[spec.roof], 0, 0, math.floor(width * 64 + 0.5), math.floor(spec.depth * 64 + 0.5), 0.5,
      {x, front - height - spec.depth / 2}, {tint = spec.roof_tint}),
  }
  for floor = 0, spec.floors - 1 do
    -- The top storey keeps the wall's cap; the wall sheet has six variations side by side.
    local top = floor == spec.floors - 1 and 0 or 16
    local h = 80 - top
    for i = 0, spec.columns - 1 do
      local variation = (i + floor * 2) % 6
      layers[#layers + 1] = part("entity/wall/wall-horizontal.png", variation * 64, top, 64, h, 0.5 * k,
        {x - width / 2 + k / 2 + i * k, front - floor * k - h * k / 128}, {tint = spec.wall_tint})
    end
  end
  return layers
end

-- Glass with a warm light behind it, which only shows at night.
function kitbash.pane(x, y, w, h)
  return {rect(x, y, w, h, tints.glass), rect(x, y, w, h, tints.lamplight, {draw_as_light = true})}
end

-- A window in a storey that stands on bottom.
function kitbash.window(x, bottom, k)
  k = k or 1
  return kitbash.pane(x, bottom - 0.55 * k, 0.26 * k, 0.34 * k)
end

function kitbash.door(x, bottom, k)
  k = k or 1
  return {rect(x, bottom - 0.38 * k, 0.36 * k, 0.6 * k, tints.wood)}
end

-- The steel furnace's stovepipe, standing on bottom.
function kitbash.chimney(x, bottom, tint)
  return {part("entity/steel-furnace/steel-furnace.png", 113, 0, 28, 52, 0.5, {x, bottom - 0.41}, {tint = tint})}
end

-- A small lamp on a post, with its bulb and a pool of light at night.
function kitbash.lamp(x, y)
  return
  {
    part("entity/small-lamp/lamp-shadow.png", 0, 0, 76, 47, 0.5, {x + 0.125, y + 0.148}, {draw_as_shadow = true}),
    part("entity/small-lamp/lamp.png", 0, 0, 83, 70, 0.5, {x + 0.008, y + 0.094}),
    part("entity/small-lamp/lamp-light.png", 0, 0, 90, 78, 0.5, {x, y - 0.22}, {draw_as_light = true, tint = tints.lamplight}),
    part("__core__/graphics/light-medium.png", 0, 0, 300, 300, 0.4, {x, y}, {draw_as_light = true, tint = {0.5, 0.42, 0.3, 0.5}}),
  }
end

local bank_rocks =
{
  {file = "decorative/sand-rock/medium-sand-rock-01.png", width = 134, height = 82},
  {file = "decorative/sand-rock/medium-sand-rock-02.png", width = 110, height = 79},
  {file = "decorative/sand-rock/medium-sand-rock-04.png", width = 110, height = 89},
  {file = "decorative/sand-rock/medium-sand-rock-05.png", width = 106, height = 76},
}

-- One of the desert rocks, tinted as a heap of earth.
function kitbash.bank_rock(i, x, y, tint)
  local rock = bank_rocks[i % #bank_rocks + 1]
  return part(rock.file, 0, 0, rock.width, rock.height, 0.26, {x, y}, {tint = tint or tints.earth})
end

-- A low bank of earth: desert rocks overlapping in a row.
function kitbash.earth_bank(x1, x2, y)
  local layers = {}
  local i = 0
  for x = x1, x2 + 0.001, 0.38 do
    layers[#layers + 1] = kitbash.bank_rock(i, x, y + 0.04 * (i % 2))
    i = i + 1
  end
  return layers
end

-- A horseshoe of earth bank around the left, front and right, open at the back, drawn back to front.
function kitbash.earth_ring(rx, ry)
  local layers = {}
  for i = 0, 6 do
    local angle = math.rad(190 - 200 * i / 6)
    layers[#layers + 1] = kitbash.bank_rock(i, rx * math.cos(angle), ry * math.sin(angle))
  end
  table.sort(layers, function(a, b) return a.shift[2] < b.shift[2] end)
  return layers
end

-- One of the wall's eight heaps of broken stone and rebar.
function kitbash.rubble(i, x, y, scale)
  scale = scale or 0.45
  return part("entity/wall/remnants/wall-remnants.png", 0, (i % 8) * 114, 118, 114, scale,
    {x + 3 * scale / 32, y + 7.5 * scale / 32}, {tint = tints.ash})
end

local function darken(tint, by)
  tint = tint or {1, 1, 1}
  return {tint[1] * by, tint[2] * by, tint[3] * by}
end

-- Pixels of wall face left standing in each column of a ruin.
local stub_heights = {30, 16, 40, 12, 24, 36}

-- What's left of a building after it burns: the bottoms of its front walls, broken off at
-- different heights, with rubble and pieces of the fallen roof where the rest of it was.
function kitbash.ruin(x, y, spec)
  local k = spec.k or 1
  local seed = spec.seed or 0
  local width = spec.columns * k
  local front = y + spec.depth / 2
  local layers = {}
  for i = 0, spec.columns - 1 do
    local cx = x - width / 2 + k / 2 + i * k
    layers[#layers + 1] = part(roofs[spec.roof], (i * 300 + seed * 130) % 3800, 0, 44, 30, 0.5 * k,
      {cx - 0.2 * k, y - 0.3 * spec.depth + 0.12 * (i % 2)}, {tint = darken(spec.roof_tint, 0.7)})
    layers[#layers + 1] = kitbash.rubble(i * 3 + seed, cx + 0.1 * (i % 2), y - 0.05 * spec.depth, 0.45 * k)
  end
  for i = 0, spec.columns - 1 do
    local cx = x - width / 2 + k / 2 + i * k
    local variation = (i + 3) % 6 * 64
    local h = stub_heights[(i + seed) % #stub_heights + 1]
    layers[#layers + 1] = part("entity/wall/wall-horizontal.png", variation, 80 - h, 64, h, 0.5 * k,
      {cx, front - h * k / 128}, {tint = tints.ash})
    layers[#layers + 1] = part("entity/wall/wall-horizontal.png", variation, 0, 64, 16, 0.5 * k,
      {cx, front - h * k / 64 - k / 8}, {tint = tints.ash})
  end
  return layers
end

-- Burnt ground: the base game's scorch mark, squashed to fit within a footprint w tiles wide.
function kitbash.scorch(w, variation)
  local scale = w * 32 / 510
  return part("entity/scorchmark/medium-scorchmark.png", ((variation or 0) % 2) * 510, 0, 510, 352, scale, {0, 0})
end

return kitbash
