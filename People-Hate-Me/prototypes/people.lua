-- Redraws the biters and spitters of Nauvis as people, built only from the
-- engineer's own sprites (__base__/graphics/entity/character).

local util = require("util")

if not character_animations then
  require("__base__.prototypes.entity.character-animations")
end

local blood_tint = {r = 0.55, g = 0.06, b = 0.05, a = 1}

-- scale:  body size relative to the engineer
-- outfit: character_animations sets drawn on top of each other, the same way the
--         engineer's armor tiers are drawn
-- tint:   clothing colour, applied where the engineer shows the player colour
-- role:   "melee" people swing a pickaxe, "ranged" people aim a gun
local people =
{
  ["small-biter"]      = {scale = 0.8,  outfit = {"level1"},                tint = {0.78, 0.62, 0.42}, role = "melee"},
  ["medium-biter"]     = {scale = 0.95, outfit = {"level1", "level2addon"}, tint = {0.72, 0.26, 0.22}, role = "melee"},
  ["big-biter"]        = {scale = 1.1,  outfit = {"level1", "level3addon"}, tint = {0.26, 0.36, 0.78}, role = "melee"},
  ["behemoth-biter"]   = {scale = 1.35, outfit = {"level1", "level3addon"}, tint = {0.24, 0.52, 0.16}, role = "melee"},

  ["small-spitter"]    = {scale = 0.8,  outfit = {"level1"},                tint = {0.92, 0.56, 0.12}, role = "ranged"},
  ["medium-spitter"]   = {scale = 0.95, outfit = {"level1", "level2addon"}, tint = {0.74, 0.22, 0.48}, role = "ranged"},
  ["big-spitter"]      = {scale = 1.1,  outfit = {"level1", "level3addon"}, tint = {0.12, 0.56, 0.60}, role = "ranged"},
  ["behemoth-spitter"] = {scale = 1.35, outfit = {"level1", "level3addon"}, tint = {0.52, 0.70, 0.12}, role = "ranged"},
}

local attack_poses =
{
  melee  = {name = "mining_tool"},
  -- The aiming loop has to fit inside the spitters' 100 tick cooldown.
  ranged = {name = "idle_gun", animation_speed = 0.25},
}

local function dress(layer, person)
  local piece = table.deepcopy(layer)
  piece.scale = (piece.scale or 1) * person.scale
  piece.shift = util.mul_shift(piece.shift, person.scale)
  piece.usage = "enemy"
  if piece.apply_runtime_tint then
    piece.apply_runtime_tint = false
    piece.tint = person.tint
  end
  return piece
end

-- Builds one pose (e.g. "running") for a person, layered like the engineer:
-- every outfit piece with its colour mask first, then all of their shadows.
local function pose(person, name, animation_speed)
  local layers, shadows = {}, {}
  for _, set_name in pairs(person.outfit) do
    local set = character_animations[set_name]
    for _, suffix in pairs({"", "_mask"}) do
      if set[name .. suffix] then
        table.insert(layers, dress(set[name .. suffix], person))
      end
    end
    if set[name .. "_shadow"] then
      table.insert(shadows, dress(set[name .. "_shadow"], person))
    end
  end
  for _, shadow in pairs(shadows) do
    table.insert(layers, shadow)
  end
  if animation_speed then
    for _, layer in pairs(layers) do
      layer.animation_speed = animation_speed
    end
  end
  return {layers = layers}
end

-- The engineer's death sheet holds two different fallen poses side by side.
local function corpse_variations(person)
  local variations = {}
  for frame = 0, 1 do
    local body = pose(person, "dead")
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

local function water_reflection(person)
  local reflection = table.deepcopy(data.raw["character"]["character"].water_reflection)
  reflection.pictures.scale = reflection.pictures.scale * person.scale
  reflection.pictures.shift = util.mul_shift(reflection.pictures.shift, person.scale)
  return reflection
end

local function humanize_unit(unit, person)
  local s = person.scale
  local attack = attack_poses[person.role]

  unit.run_animation = pose(person, "running")
  unit.distance_per_frame = 0.13 * s
  unit.running_sound_animation_positions = {5, 16}

  unit.alternative_attacking_frame_sequence = nil
  unit.attack_parameters.animation = pose(person, attack.name, attack.animation_speed)
  if person.role == "ranged" then
    unit.attack_parameters.projectile_creation_parameters = muzzle_offsets(s)
  end

  unit.selection_box = {{-0.4 * s, -1.4 * s}, {0.4 * s, 0.2 * s}}
  unit.hit_visualization_box = {{-0.2 * s, -1.1 * s}, {0.2 * s, 0.2 * s}}
  unit.sticker_box = {{-0.2 * s, -1.0 * s}, {0.2 * s, 0}}
  unit.water_reflection = water_reflection(person)
  unit.random_corpse_variation = true
end

local function humanize_corpse(corpse, person)
  corpse.animation = corpse_variations(person)
  corpse.decay_animation = nil
  corpse.use_decay_layer = false
  corpse.direction_shuffle = nil
  corpse.shuffle_directions_at_frame = nil
  if corpse.ground_patch and corpse.ground_patch.sheet then
    corpse.ground_patch.sheet.tint = blood_tint
  end
end

for name, person in pairs(people) do
  local unit = data.raw["unit"][name]
  if unit then
    humanize_unit(unit, person)
    local corpse_names = type(unit.corpse) == "table" and unit.corpse or {unit.corpse}
    for _, corpse_name in pairs(corpse_names) do
      local corpse = data.raw["corpse"][corpse_name]
      if corpse then
        humanize_corpse(corpse, person)
      end
    end
  end
end
