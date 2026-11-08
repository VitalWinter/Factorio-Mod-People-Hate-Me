-- Worms become defensive positions, kitbashed from base-game images (prototypes/kitbash.lua)
-- within each worm's collision box, and manned by a gunner drawn like the people
-- (prototypes/person.lua). Every position is the same mechanical platform with the gunner on it,
-- on ground works that are built up tier by tier: on the ground, a brick plinth, a concrete
-- bunker and a steel-plated one. The gunner stands at ease while the worm would be folded
-- underground, and readies themselves to throw bottles (prototypes/bottles.lua). Destroyed
-- positions leave their dead gunner.

local hit_effects = require("__base__.prototypes.entity.hit-effects")
local definitions = require("definitions")
local kitbash = require("prototypes.kitbash")
local person = require("prototypes.person")
local bottles = require("prototypes.bottles")
local corpses = require("prototypes.corpses")

local add, building, rect, part, tints = kitbash.add, kitbash.building, kitbash.rect, kitbash.part, kitbash.tints

-- Each design returns:
--   back    layers drawn behind the gunner
--   front   layers drawn over the gunner, if any
--   gunner  where the gunner stands
--   ruin    what's left of the position
--   fallen  where the dead gunner lies
--   width   of the burnt ground
--   hit     the hit effect
local designs = {}

-- The platform every gunner stands on: the gun turret's mechanical base, centred at y. The
-- gunner's feet are a little in front of its centre.
local function platform(y, scale, tint)
  return part("entity/gun-turret/gun-turret-base.png", 0, 0, 150, 118, scale, {0, y}, {tint = tint})
end

local function on_platform(y, scale)
  return {0, y + 0.25 * scale}
end

-- A scorched platform among the ruins, under the rubble.
local function scorched_platform(y, scale)
  return platform(y, scale, tints.soot)
end

-- The platform on its own, so the mechanical base is what you see.
function designs.pit()
  local scale, y = 0.3, -0.05
  return {back = {platform(y, scale)}, gunner = on_platform(y, scale), ruin = {scorched_platform(y, scale)},
    fallen = {0.1, -0.05}, width = 2, hit = hit_effects.entity}
end

-- The platform on the roof of a block centred at y. slits are {x, width} along the front wall.
local function raised(y, block, scale, slits, fallen, width)
  local back = building(0, y, block)
  local front = y + block.depth / 2
  for _, slit in pairs(slits) do
    add(back, {rect(slit[1], front - 0.5 * block.k, slit[2], 0.1, tints.slit)})
  end
  local roof = front - block.floors * block.k - block.depth / 2
  add(back, {platform(roof, scale)})
  local ruin = add({scorched_platform(roof + 0.3, scale * 0.9)}, kitbash.ruin(0, y, block))
  return {back = back, gunner = on_platform(roof, scale), ruin = ruin, fallen = fallen, width = width, hit = hit_effects.wall}
end

-- A low brick plinth.
function designs.plinth()
  return raised(0.15, {columns = 3, depth = 1.3, floors = 1, k = 0.6, roof = "stone_path", wall_tint = tints.brick}, 0.34, {},
    {0.35, 0.55}, 2.2)
end

-- A concrete bunker with a firing slit.
function designs.bunker()
  return raised(0.2, {columns = 3, depth = 1.6, floors = 1, k = 0.8, roof = "concrete"}, 0.4, {{-0.3, 1.2}}, {0.5, 0.85}, 2.8)
end

-- The behemoth's bunker is the same size, but plated in dark steel like the behemoths' armor,
-- with two slits.
function designs.heavy_bunker()
  local steel = {0.62, 0.62, 0.68}
  return raised(0.2, {columns = 3, depth = 1.6, floors = 1, k = 0.8, roof = "refined_concrete", roof_tint = steel, wall_tint = steel, seed = 3},
    0.4, {{-0.65, 0.7}, {0.65, 0.7}}, {0.5, 0.85}, 2.8)
end

local design_of =
{
  ["small-worm-turret"] = designs.pit,
  ["medium-worm-turret"] = designs.plinth,
  ["big-worm-turret"] = designs.bunker,
  ["behemoth-worm-turret"] = designs.heavy_bunker,
}

-- The engineer's idle loop: 22 frames at 0.15 frames per tick. Turret speeds are the fraction of
-- the whole animation played each tick.
local idle_speed = 0.15 / 22

local function man(worm, design, look)
  local offset = design.gunner
  -- The throw (person.throw) keeps the worm's timing. The start of the attack winds up, and the
  -- bottle leaves as it ends, when the arm comes forward. The end of the attack is long (about a
  -- second), so the gunner lets go and straightens up over its first third, then holds ready.
  local function throwing(...)
    return person.pose(look, "mining_tool", {offset = offset, frame_sequence = person.frames(...)})
  end
  local throw = person.throw
  local ready = throw.ready
  local held = {}
  for i = 1, 8 do
    held[i] = ready[1]
  end
  worm.folded_animation = person.pose(look, "idle", {offset = offset, facing = 4})
  worm.preparing_animation = throwing(ready)
  worm.prepared_animation = throwing(ready)
  worm.starting_attack_animation = throwing(throw.wind_up)
  worm.attacking_animation = throwing(throw.release)
  worm.ending_attack_animation = throwing(throw.release, throw.recover, held)
  worm.folding_animation = throwing(ready)
  worm.folded_speed = idle_speed
  worm.folded_speed_secondary = idle_speed * 0.9
  worm.attack_parameters.projectile_creation_parameters = person.hand_offsets(look.scale, offset)
end

local function wreck(corpse, design, look)
  corpse.animation = {}
  for _, fallen in pairs(person.fallen(look, design.fallen)) do
    table.insert(corpse.animation, {layers = add(table.deepcopy(design.ruin), fallen)})
  end
  corpse.decay_animation = nil
  corpse.decay_frame_transition_duration = nil
  corpse.ground_patch = {kitbash.scorch(design.width)}
  corpse.ground_patch_decay = nil
  corpses.fade(corpse, true)
end

for name, position in pairs(definitions.positions) do
  local worm = data.raw["turret"][name]
  if worm then
    local gunner = definitions.people[position.gunner]
    local look = person.look(gunner)
    local design = design_of[name]()

    local visualisations = {{render_layer = "object", secondary_draw_order = -1, animation = {layers = design.back}}}
    if design.front then
      table.insert(visualisations, {render_layer = "object", secondary_draw_order = 1, animation = {layers = design.front}})
    end
    worm.graphics_set = {base_visualisation = visualisations}
    worm.gun_animation_render_layer = "object"
    worm.gun_animation_secondary_draw_order = 0
    worm.integration = nil
    man(worm, design, look)

    worm.prepared_alternative_chance = 0
    worm.prepared_alternative_animation = nil
    for _, sound in pairs{"preparing_sound", "prepared_sound", "prepared_alternative_sound", "folding_sound", "dying_sound"} do
      worm[sound] = nil
    end
    worm.starting_attack_sound = bottles.throw_sound
    worm.damaged_trigger_effect = design.hit()
    worm.impact_category = "stone"
    worm.dying_explosion = {{name = position.gunner .. "-die"}, {name = "wall-explosion"}}

    for _, corpse_name in pairs{worm.corpse, worm.folded_state_corpse} do
      local corpse = data.raw["corpse"][corpse_name]
      if corpse then
        wreck(corpse, design, look)
      end
    end
  end
end
