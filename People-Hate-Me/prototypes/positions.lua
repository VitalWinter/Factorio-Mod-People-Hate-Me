-- Worms become defensive positions, kitbashed from base-game images (prototypes/kitbash.lua)
-- within each worm's collision box, and manned by a gunner drawn like the people
-- (prototypes/person.lua). The gunner stands at ease while the worm would be folded underground,
-- and readies themselves to throw bottles (prototypes/bottles.lua). Destroyed positions leave
-- their dead gunner.

local hit_effects = require("__base__.prototypes.entity.hit-effects")
local definitions = require("definitions")
local kitbash = require("prototypes.kitbash")
local person = require("prototypes.person")
local bottles = require("prototypes.bottles")

local add, building, rect, part, tints = kitbash.add, kitbash.building, kitbash.rect, kitbash.part, kitbash.tints

-- Each design returns:
--   back    layers drawn behind the gunner
--   front   layers drawn over the gunner, if any
--   gunner  where the gunner stands, or nil when they're out of sight inside
--   muzzle  where fire leaves the position when the gunner is out of sight
--   ruin    what's left of the position
--   fallen  where the dead gunner lies
--   width   of the burnt ground
--   hit     the hit effect
local designs = {}

-- A horseshoe pit of earth bank, open at the back.
function designs.pit()
  local back, front = {}, {}
  for _, rock in pairs(kitbash.earth_ring(0.42, 0.35)) do
    table.insert(rock.shift[2] < 0 and back or front, rock)
  end
  local ruin = {}
  for i, spot in pairs{{-0.6, -0.15}, {-0.25, 0.3}, {0.45, 0.25}, {0.6, -0.2}} do
    ruin[i] = kitbash.bank_rock(i, spot[1], spot[2], tints.soot)
  end
  return {back = back, front = front, gunner = {0, -0.08}, ruin = ruin, fallen = {0.1, -0.05}, width = 1.8, hit = hit_effects.rock}
end

-- A concrete pillbox with a firing slit; its gunner is inside.
function designs.pillbox()
  local block = {columns = 2, depth = 1.2, floors = 1, k = 0.8, roof = "refined_concrete"}
  local back = building(0, 0.1, block)
  add(back, {rect(0, 0.35, 1, 0.1, tints.slit)})
  return {back = back, muzzle = {0, 0.35}, ruin = kitbash.ruin(0, 0.1, block), fallen = {0.35, 0.6}, width = 2.2, hit = hit_effects.wall}
end

-- A concrete bunker with a gun turret's mount on the roof, where the gunner stands.
local function bunker(block, slits)
  local back = building(0, 0.2, block)
  for _, slit in pairs(slits) do
    add(back, {rect(slit[1], 0.6, slit[2], 0.1, tints.slit)})
  end
  add(back, {part("entity/gun-turret/gun-turret-base.png", 0, 0, 150, 118, 0.4, {0, -0.65}, {tint = block.roof_tint})})
  return {back = back, gunner = {0, -0.55}, ruin = kitbash.ruin(0, 0.2, block), fallen = {0.5, 0.85}, width = 2.8, hit = hit_effects.wall}
end

function designs.bunker()
  return bunker({columns = 3, depth = 1.6, floors = 1, k = 0.8, roof = "concrete"}, {{-0.3, 1.2}})
end

-- The behemoth's bunker is the same size, but plated in dark steel like the behemoths' armor.
function designs.heavy_bunker()
  local steel = {0.62, 0.62, 0.68}
  return bunker({columns = 3, depth = 1.6, floors = 1, k = 0.8, roof = "refined_concrete", roof_tint = steel, wall_tint = steel, seed = 3},
    {{-0.65, 0.7}, {0.65, 0.7}})
end

local design_of =
{
  ["small-worm-turret"] = designs.pit,
  ["medium-worm-turret"] = designs.pillbox,
  ["big-worm-turret"] = designs.bunker,
  ["behemoth-worm-turret"] = designs.heavy_bunker,
}

-- The engineer's idle loop: 22 frames at 0.15 frames per tick. Turret speeds are the fraction of
-- the whole animation played each tick.
local idle_speed = 0.15 / 22
local ready_speed = 1 / 40

local empty = {filename = "__core__/graphics/empty.png", size = 1}

local function man(worm, design, look)
  local offset = design.gunner
  if not offset then
    for _, state in pairs{"folded", "preparing", "prepared", "starting_attack", "ending_attack", "folding"} do
      worm[state .. "_animation"] = empty
    end
    local muzzle = {}
    for i = 0, 15 do
      muzzle[i + 1] = {i / 16, design.muzzle}
    end
    worm.attack_parameters.projectile_creation_parameters = muzzle
    return
  end

  -- The throw (person.throw) keeps the worm's timing. The start of the attack winds up, and the
  -- bottle leaves as it ends, when the arm comes forward. The end of the attack is long (about a
  -- second), so the gunner lets go and straightens up in its first few ticks, then sways ready.
  local function throwing(...)
    return person.pose(look, "mining_tool", {offset = offset, frame_sequence = person.frames(...)})
  end
  local throw = person.throw
  local ready = throw.ready
  worm.folded_animation = person.pose(look, "idle", {offset = offset, facing = 4})
  worm.preparing_animation = throwing(ready)
  worm.prepared_animation = throwing(ready)
  worm.starting_attack_animation = throwing(throw.wind_up)
  worm.attacking_animation = throwing(throw.release)
  worm.ending_attack_animation = throwing(throw.release, throw.recover, ready, ready, ready, ready, ready, ready)
  worm.folding_animation = throwing({ready[1]})
  worm.folded_speed = idle_speed
  worm.folded_speed_secondary = idle_speed * 0.9
  worm.prepared_speed = ready_speed
  worm.prepared_speed_secondary = ready_speed * 0.9
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
