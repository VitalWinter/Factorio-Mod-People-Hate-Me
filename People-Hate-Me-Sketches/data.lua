-- Kitbash experiments: pieces of base-game images cropped, scaled, tinted and layered into new pictures.
-- The sketch scenarios draw these with rendering.draw_sprite; nothing here is part of the real mod.
-- Each one combines several assets, so it doesn't read as a resized copy of something in the game,
-- and each replacement for a nest or worm keeps to that structure's footprint.

require("util")

-- A cropped piece of an image. Its centre sits at shift (in tiles) from the sprite's position, and
-- it covers width * scale / 32 tiles. Paths without a mod prefix are in the base game's graphics.
local function part(file, x, y, width, height, scale, shift, extra)
  local filename = file:find("^__") and file or "__base__/graphics/" .. file
  return util.merge{{filename = filename, x = x, y = y, width = width, height = height, scale = scale, shift = shift}, extra or {}}
end

local function add(layers, more)
  for _, layer in pairs(more) do
    layers[#layers + 1] = layer
  end
  return layers
end

-- A w by h tile rectangle cut from the game's 10x10 white square. Crops are whole pixels, so the
-- proportions are approximate.
local function rect(x, y, w, h, tint, extra)
  local pw, ph = 10, 10
  if w >= h then
    ph = math.max(1, math.floor(10 * h / w + 0.5))
  else
    pw = math.max(1, math.floor(10 * w / h + 0.5))
  end
  return part("__core__/graphics/white-square.png", 0, 0, pw, ph, w * 32 / pw, {x, y}, util.merge{{tint = tint}, extra or {}})
end

local roofs =
{
  stone_path = "terrain/stone-path/stone-path-4.png",
  concrete = "terrain/concrete/concrete.png",
  refined_concrete = "terrain/concrete/refined-concrete.png",
}

local terracotta = {0.95, 0.72, 0.6}
local brick = {0.8, 0.55, 0.45}
local plaster = {1, 0.95, 0.85}
local glass = {0.22, 0.26, 0.3}
local lamplight = {1, 0.8, 0.5}
local wood = {0.3, 0.2, 0.13}
local earth = {0.85, 0.8, 0.68}

-- A box building on the footprint centred at x, y: spec.columns wall segments of k tiles across,
-- spec.depth tiles deep, spec.floors storeys of k tiles high. The front wall is the stone wall's
-- face, with its cap as the cornice; the roof is a floor tile's texture, raised by the wall's
-- height; an assembler's shadow falls to the east.
local function building(x, y, spec)
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

-- Glass, plus the same pane lit from inside added to lit. Script-drawn sprites ignore
-- draw_as_light, so the lit panes are a separate sprite that the sketch shows at night.
local function pane(x, y, w, h, lit)
  lit[#lit + 1] = rect(x, y, w, h, lamplight)
  return {rect(x, y, w, h, glass)}
end

-- A window in a storey that stands on bottom.
local function window(x, bottom, lit, k)
  k = k or 1
  return pane(x, bottom - 0.55 * k, 0.26 * k, 0.34 * k, lit)
end

local function door(x, bottom, k)
  k = k or 1
  return {rect(x, bottom - 0.38 * k, 0.36 * k, 0.6 * k, wood)}
end

-- The steel furnace's stovepipe, standing on a roof at bottom.
local function chimney(x, bottom)
  return {part("entity/steel-furnace/steel-furnace.png", 113, 0, 28, 52, 0.5, {x, bottom - 0.41})}
end

local function lamp(x, y)
  return
  {
    part("entity/small-lamp/lamp-shadow.png", 0, 0, 76, 47, 0.5, {x + 0.125, y + 0.148}, {draw_as_shadow = true}),
    part("entity/small-lamp/lamp.png", 0, 0, 83, 70, 0.5, {x + 0.008, y + 0.094}),
  }
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

local function bank_rock(i, x, y)
  local rock = bank_rocks[i % #bank_rocks + 1]
  return part(rock.file, 0, 0, rock.width, rock.height, 0.26, {x, y}, {tint = earth})
end

-- A low bank of earth: desert rocks overlapping in a row.
local function earth_bank(x1, x2, y)
  local layers = {}
  local i = 0
  for x = x1, x2 + 0.001, 0.38 do
    layers[#layers + 1] = bank_rock(i, x, y + 0.04 * (i % 2))
    i = i + 1
  end
  return layers
end

-- A horseshoe of earth bank around the left, front and right, open at the back.
local function earth_ring(rx, ry)
  local layers = {}
  for i = 0, 6 do
    local angle = math.rad(190 - 200 * i / 6)
    layers[#layers + 1] = bank_rock(i, rx * math.cos(angle), ry * math.sin(angle))
  end
  table.sort(layers, function(a, b) return a.shift[2] < b.shift[2] end)
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

-- Biter nest (5x5): two houses with tiled roofs and chimneys, and a street lamp.
local houses_lit = {}
local houses = building(-1, -0.9, {columns = 2, depth = 2, floors = 1, roof = "stone_path", roof_tint = terracotta, wall_tint = plaster})
add(houses, chimney(-0.4, -2))
add(houses, window(-1.5, 0.1, houses_lit))
add(houses, window(-0.5, 0.1, houses_lit))
add(houses, door(-1, 0.1))
add(houses, building(1.1, 1, {columns = 2, depth = 1.5, floors = 1, roof = "stone_path", roof_tint = brick, wall_tint = plaster}))
add(houses, chimney(1.6, -0.4))
add(houses, window(0.6, 1.75, houses_lit))
add(houses, door(1.5, 1.75))
add(houses, lamp(-1.8, 1.6))

-- Spitter nest (5x5): a two-storey block of flats with a concrete roof and chimneys.
local flats_lit = {}
local flats = building(0, 0.2, {columns = 4, depth = 2, floors = 2, roof = "concrete"})
add(flats, chimney(-1.3, -1.3))
add(flats, chimney(1.3, -1.3))
for _, x in pairs{-1.5, -0.5, 0.5, 1.5} do
  add(flats, window(x, 0.2, flats_lit))
end
for _, x in pairs{-1.5, 0.5, 1.5} do
  add(flats, window(x, 1.2, flats_lit))
end
add(flats, door(-0.5, 1.2))
add(flats, lamp(1.9, 1.9))

-- Another nest option (5x5): a single-storey hall with skylights and double doors.
local hall_lit = {}
local hall = building(0, -0.2, {columns = 4, depth = 3, floors = 1, roof = "refined_concrete", wall_tint = plaster})
for _, y in pairs{-1.8, -1.1} do
  for _, x in pairs{-0.9, -0.3, 0.3, 0.9} do
    add(hall, pane(x, y, 0.4, 0.26, hall_lit))
  end
end
for _, x in pairs{-1.5, -0.9, 0.9, 1.5} do
  add(hall, window(x, 1.3, hall_lit))
end
add(hall, door(-0.2, 1.3))
add(hall, door(0.2, 1.3))
add(hall, lamp(-1.9, 1.9))
add(hall, lamp(1.9, 1.9))

-- A graveyard (5x5): two rows of headstones behind a palisade, with a lamp.
local graveyard = post_row(-2, 2, -1.7, 0.32)
for _, y in pairs{-0.6, 0.6} do
  for _, x in pairs{-1.2, 0, 1.2} do
    add(graveyard, headstone(x, y))
  end
end
add(graveyard, lamp(1.9, 1.5))

-- Worms become defensive positions, each within its worm's footprint.
local small_position = earth_ring(0.42, 0.35)

local medium_position = building(0, 0.1, {columns = 2, depth = 1.2, floors = 1, k = 0.8, roof = "refined_concrete"})
add(medium_position, {rect(0, 0.35, 1, 0.1, {0.05, 0.05, 0.05})})

local big_position = building(0, 0.2, {columns = 3, depth = 1.6, floors = 1, k = 0.8, roof = "concrete"})
add(big_position,
{
  rect(-0.3, 0.6, 1.2, 0.1, {0.05, 0.05, 0.05}),
  part("entity/gun-turret/gun-turret-base.png", 0, 0, 150, 118, 0.4, {0, -0.65}),
})

local function sprite(name, layers)
  return {type = "sprite", name = "phm-sketch-" .. name, layers = layers}
end

data:extend
{
  sprite("houses", houses),
  sprite("houses-lit", houses_lit),
  sprite("flats", flats),
  sprite("flats-lit", flats_lit),
  sprite("hall", hall),
  sprite("hall-lit", hall_lit),
  sprite("graveyard", graveyard),
  sprite("position-small", small_position),
  sprite("position-medium", medium_position),
  sprite("position-big", big_position),
  sprite("palisade", post_row(-1.6, 1.6, 0.3, 0.4)),
  sprite("earth-bank", earth_bank(-1.5, 1.5, 0.2)),
  sprite("campfire", campfire(0, 0)),
}
