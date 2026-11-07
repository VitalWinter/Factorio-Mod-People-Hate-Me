-- Redraws the biters and spitters of Nauvis as people, built only from the
-- engineer's own sprites (__base__/graphics/entity/character).

local util = require("util")
require("sound-util")
local definitions = require("definitions")

if not character_animations then
  require("__base__.prototypes.entity.character-animations")
end

local blood_tint = {r = 0.55, g = 0.06, b = 0.05, a = 1}

local attack_poses =
{
  melee  = {name = "mining_tool"},
  -- The aiming loop has to fit inside the spitters' 100 tick cooldown.
  ranged = {name = "idle_gun", animation_speed = 0.25},
}

local pickaxe_hits =
{
  category = "enemy",
  variations = sound_variations("__core__/sound/axe-mining-stone", 7, 0.5),
  aggregation = {max_count = 2, remove = true, count_already_playing = true},
}

local gunshots =
{
  category = "enemy",
  variations = sound_variations("__base__/sound/fight/light-gunshot", 7, 0.3),
  aggregation = {max_count = 2, remove = true, count_already_playing = true},
}

-- keep_runtime_tint leaves the colour mask to be tinted per entity at runtime
-- (LuaEntity.color), which is how corpses get individual shades.
local function dress(layer, look, body_tint, keep_runtime_tint)
  local piece = table.deepcopy(layer)
  piece.scale = (piece.scale or 1) * look.scale
  piece.shift = util.mul_shift(piece.shift, look.scale)
  piece.usage = "enemy"
  if piece.apply_runtime_tint then
    if not keep_runtime_tint then
      piece.apply_runtime_tint = false
      piece.tint = look.tint
    end
  elseif body_tint and not piece.draw_as_shadow then
    piece.tint = body_tint
  end
  return piece
end

-- Builds one pose (e.g. "running") for a person, layered like the engineer:
-- the body and any armor with their colour masks first, then all of their shadows.
local function pose(look, name, options)
  options = options or {}
  local sets = {{name = "level1"}}
  if look.armor then
    table.insert(sets, {name = look.armor, body_tint = look.armor_tint})
  end

  local layers, shadows = {}, {}
  for _, set in pairs(sets) do
    local animations = character_animations[set.name]
    for _, suffix in pairs({"", "_mask"}) do
      local layer = animations[name .. suffix]
      if layer then
        table.insert(layers, dress(layer, look, set.body_tint, options.keep_runtime_tint))
      end
    end
    local shadow = animations[name .. "_shadow"]
    if shadow then
      table.insert(shadows, dress(shadow, look))
    end
  end
  for _, shadow in pairs(shadows) do
    table.insert(layers, shadow)
  end

  if options.animation_speed then
    for _, layer in pairs(layers) do
      layer.animation_speed = options.animation_speed
    end
  end
  return {layers = layers}
end

-- The engineer's death sheet holds two different fallen poses side by side.
local function corpse_variations(look)
  local variations = {}
  for frame = 0, 1 do
    local body = pose(look, "dead", {keep_runtime_tint = true})
    for _, layer in pairs(body.layers) do
      layer.frame_count = 1
      layer.x = frame * layer.width
    end
    table.insert(variations, body)
  end
  return variations
end

-- Where the acid stream leaves the gun barrel, for each facing direction.
local function muzzle_offsets(scale)
  local offsets = {}
  for i = 0, 15 do
    local orientation = i / 16
    local angle = orientation * 2 * math.pi
    offsets[i + 1] = {orientation, {0.8 * scale * math.sin(angle), -scale * (1.0 + 0.35 * math.cos(angle))}}
  end
  return offsets
end

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
  local attack = attack_poses[look.role]

  unit.icon = nil
  unit.icons = icons(look)

  unit.run_animation = pose(look, "running")
  unit.distance_per_frame = 0.13 * s
  unit.running_sound_animation_positions = {5, 16}
  unit.walking_sound = footsteps(look)
  unit.working_sound = nil
  unit.dying_sound = nil

  unit.alternative_attacking_frame_sequence = nil
  unit.attack_parameters.animation = pose(look, attack.name, {animation_speed = attack.animation_speed})
  if look.role == "ranged" then
    unit.attack_parameters.projectile_creation_parameters = muzzle_offsets(s)
    unit.attack_parameters.sound = nil
    unit.attack_parameters.cyclic_sound = {begin_sound = gunshots}
  else
    unit.attack_parameters.sound = pickaxe_hits
  end

  unit.selection_box = {{-0.4 * s, -1.4 * s}, {0.4 * s, 0.2 * s}}
  unit.hit_visualization_box = {{-0.2 * s, -1.1 * s}, {0.2 * s, 0.2 * s}}
  unit.sticker_box = {{-0.2 * s, -1.0 * s}, {0.2 * s, 0}}
  unit.water_reflection = water_reflection(look)
  unit.random_corpse_variation = true
end

local function humanize_corpse(corpse, look)
  corpse.animation = corpse_variations(look)
  corpse.decay_animation = nil
  corpse.use_decay_layer = false
  corpse.direction_shuffle = nil
  corpse.shuffle_directions_at_frame = nil
  if corpse.ground_patch and corpse.ground_patch.sheet then
    corpse.ground_patch.sheet.tint = blood_tint
  end
end

for name, person in pairs(definitions.people) do
  local unit = data.raw["unit"][name]
  if unit then
    local look = util.merge({definitions.tiers[person.tier], person})
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
