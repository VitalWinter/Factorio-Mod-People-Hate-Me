-- Spawners become town buildings on paved lots, kitbashed from base-game images
-- (prototypes/kitbash.lua) within the nests' 4.4 by 4.4 collision box. When one is destroyed it
-- leaves a burnt-out ruin.

local hit_effects = require("__base__.prototypes.entity.hit-effects")
local kitbash = require("prototypes.kitbash")
local corpses = require("prototypes.corpses")

local add, building, ruin = kitbash.add, kitbash.building, kitbash.ruin
local window, door, chimney, lamp, pane = kitbash.window, kitbash.door, kitbash.chimney, kitbash.lamp, kitbash.pane
local tints = kitbash.tints

-- Two houses with tiled roofs and chimneys, and a street lamp.
local front_house = {columns = 2, depth = 2, floors = 1, roof = "stone_path", roof_tint = tints.terracotta, wall_tint = tints.plaster}
local back_house = {columns = 2, depth = 1.5, floors = 1, roof = "stone_path", roof_tint = tints.brick, wall_tint = tints.plaster, seed = 2}

local function houses()
  local layers = building(-1, -0.9, front_house)
  add(layers, chimney(-0.4, -2))
  add(layers, window(-1.5, 0.1))
  add(layers, window(-0.5, 0.1))
  add(layers, door(-1, 0.1))
  add(layers, building(1.1, 1, back_house))
  add(layers, chimney(1.6, -0.4))
  add(layers, window(0.6, 1.75))
  add(layers, door(1.5, 1.75))
  return add(layers, lamp(-1.8, 1.6))
end

local function houses_ruin()
  local layers = chimney(-0.4, -1.3, tints.soot)
  add(layers, ruin(-1, -0.9, front_house))
  return add(layers, ruin(1.1, 1, back_house))
end

-- A two-storey block of flats with a concrete roof and chimneys.
local flats_block = {columns = 4, depth = 2, floors = 2, roof = "concrete", seed = 1}

local function flats()
  local layers = building(0, 0.2, flats_block)
  add(layers, chimney(-1.3, -1.3))
  add(layers, chimney(1.3, -1.3))
  for _, x in pairs{-1.5, -0.5, 0.5, 1.5} do
    add(layers, window(x, 0.2))
  end
  for _, x in pairs{-1.5, 0.5, 1.5} do
    add(layers, window(x, 1.2))
  end
  add(layers, door(-0.5, 1.2))
  return add(layers, lamp(1.9, 1.9))
end

-- A single-storey hall with skylights and double doors.
local function hall()
  local layers = building(0, -0.2, {columns = 4, depth = 3, floors = 1, roof = "refined_concrete", wall_tint = tints.plaster})
  for _, y in pairs{-1.8, -1.1} do
    for _, x in pairs{-0.9, -0.3, 0.3, 0.9} do
      add(layers, pane(x, y, 0.4, 0.26))
    end
  end
  for _, x in pairs{-1.5, -0.9, 0.9, 1.5} do
    add(layers, window(x, 1.3))
  end
  add(layers, door(-0.2, 1.3))
  add(layers, door(0.2, 1.3))
  add(layers, lamp(-1.9, 1.9))
  return add(layers, lamp(1.9, 1.9))
end

-- The flats and the hall burn down to much the same shell.
local function block_ruin()
  local layers = chimney(-1.3, -0.5, tints.soot)
  return add(layers, ruin(0, 0.2, flats_block))
end

local function paving(tint)
  return kitbash.part("terrain/stone-path/stone-path-4.png", 0, 0, 256, 256, 0.5, {0, 0}, {tint = tint})
end

-- Stone thrown from the walls as the building comes down, and a fire.
local collapse =
{
  {name = "wall-explosion", offset = {-1.2, -0.8}},
  {name = "wall-explosion", offset = {1.2, -0.6}},
  {name = "wall-explosion", offset = {-1, 1}},
  {name = "wall-explosion", offset = {1.1, 1.1}},
  {name = "medium-explosion"},
}

local settlements =
{
  ["biter-spawner"] = {buildings = {houses}, ruin = houses_ruin},
  ["spitter-spawner"] = {buildings = {flats, hall}, ruin = block_ruin},
}

for name, settlement in pairs(settlements) do
  local spawner = data.raw["unit-spawner"][name]
  if spawner then
    local animations = {}
    for _, design in pairs(settlement.buildings) do
      table.insert(animations, {layers = design()})
    end
    spawner.graphics_set = {animations = animations, integration = paving()}
    spawner.working_sound = nil
    spawner.dying_sound = nil
    spawner.damaged_trigger_effect = hit_effects.wall()
    spawner.impact_category = "stone"
    spawner.dying_explosion = collapse

    local corpse = data.raw["corpse"][spawner.corpse]
    if corpse then
      corpse.animation = {{layers = settlement.ruin()}}
      corpse.decay_animation = nil
      corpse.decay_frame_transition_duration = nil
      corpse.ground_patch = {{layers = {paving({0.82, 0.8, 0.76}), kitbash.scorch(4.8)}}}
      corpse.ground_patch_decay = nil
      corpses.fade(corpse, true)
    end
  end
end
