-- Redraws the biters and spitters of Nauvis as people, built only from the
-- engineer's own sprites (__base__/graphics/entity/character).

local util = require("util")
require("sound-util")
local definitions = require("definitions")
local person = require("prototypes.person")
local bottles = require("prototypes.bottles")
local corpses = require("prototypes.corpses")

local blood_tint = {r = 0.55, g = 0.06, b = 0.05, a = 1}

-- Spitters throw (person.throw). The bottle leaves 30 ticks into the attack, and the release
-- starts as soon as the wind-up ends, so the wind-up takes 27 ticks to have the arm forward as
-- the bottle leaves. The first throw after walking winds up with the warmup sequence, later ones
-- with warmup2. Speeds are the fraction of a sequence played per tick.
local throw = person.throw
local throwing =
{
  warmup_frame_sequence = throw.wind_up,
  warmup2_frame_sequence = throw.wind_up,
  attacking_frame_sequence = person.frames(throw.release, throw.recover),
  cooldown_frame_sequence = throw.ready,
  prepared_frame_sequence = throw.ready,
  back_to_walk_frame_sequence = {1},
  warmup_animation_speed = 1 / 27,
  attacking_animation_speed = 1 / 12,
  cooldown_animation_speed = 1 / 40,
  prepared_animation_speed = 1 / 40,
  back_to_walk_animation_speed = 1 / 4,
}

local pickaxe_hits =
{
  category = "enemy",
  variations = sound_variations("__core__/sound/axe-mining-stone", 7, 0.5),
  aggregation = {max_count = 2, remove = true, count_already_playing = true},
}

local function water_reflection(look)
  local reflection = table.deepcopy(data.raw["character"]["character"].water_reflection)
  reflection.pictures.scale = reflection.pictures.scale * look.scale
  reflection.pictures.shift = util.mul_shift(reflection.pictures.shift, look.scale)
  return reflection
end

-- The engineer's icon, badged with the tier's armor and, for gunmen, a gun.
local function icons(look)
  local layers = {{icon = "__core__/graphics/icons/entity/character.png"}}
  if look.armor_icon then
    table.insert(layers, {icon = "__base__/graphics/icons/" .. look.armor_icon .. ".png", scale = 0.25, shift = {8, 8}})
  end
  if look.role == "ranged" then
    table.insert(layers, {icon = "__base__/graphics/icons/submachine-gun.png", scale = 0.25, shift = {-8, 8}})
  end
  return layers
end

local function footsteps(look)
  return
  {
    aggregation = {max_count = 3, remove = true, count_already_playing = true},
    variations = sound_variations_with_volume_variations("__base__/sound/walking/dirt-1", 10, look.footstep_volume[1], look.footstep_volume[2]),
    priority = 192,
  }
end

local function humanize_unit(unit, look)
  local s = look.scale

  unit.icon = nil
  unit.icons = icons(look)

  unit.run_animation = person.pose(look, "running")
  unit.distance_per_frame = 0.13 * s
  unit.running_sound_animation_positions = {5, 16}
  unit.walking_sound = footsteps(look)
  unit.working_sound = nil
  unit.dying_sound = nil

  unit.attack_parameters.animation = person.pose(look, "mining_tool")
  if look.role == "ranged" then
    unit.alternative_attacking_frame_sequence = throwing
    unit.attack_parameters.projectile_creation_parameters = person.hand_offsets(s)
    unit.attack_parameters.sound = nil
    unit.attack_parameters.cyclic_sound = {begin_sound = bottles.throw_sound}
  else
    unit.alternative_attacking_frame_sequence = nil
    unit.attack_parameters.sound = pickaxe_hits
  end

  unit.selection_box = {{-0.4 * s, -1.4 * s}, {0.4 * s, 0.2 * s}}
  unit.hit_visualization_box = {{-0.2 * s, -1.1 * s}, {0.2 * s, 0.2 * s}}
  unit.sticker_box = {{-0.2 * s, -1.0 * s}, {0.2 * s, 0}}
  unit.water_reflection = water_reflection(look)
  unit.random_corpse_variation = true
end

local function humanize_corpse(corpse, look)
  corpse.animation = {}
  for _, layers in pairs(person.fallen(look)) do
    table.insert(corpse.animation, {layers = layers})
  end
  corpse.decay_animation = nil
  corpse.use_decay_layer = false
  corpse.direction_shuffle = nil
  corpse.shuffle_directions_at_frame = nil
  corpses.fade(corpse)
  if corpse.ground_patch and corpse.ground_patch.sheet then
    corpse.ground_patch.sheet.tint = blood_tint
  end
end

for name, definition in pairs(definitions.people) do
  local unit = data.raw["unit"][name]
  if unit then
    local look = person.look(definition)
    humanize_unit(unit, look)
    local corpse_names = type(unit.corpse) == "table" and unit.corpse or {unit.corpse}
    for _, corpse_name in pairs(corpse_names) do
      local corpse = data.raw["corpse"][corpse_name]
      if corpse then
        humanize_corpse(corpse, look)
      end
    end
  end
end
