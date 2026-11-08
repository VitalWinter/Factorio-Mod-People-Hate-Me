-- Spitters and the gunners in defensive positions throw bottles of burning goo instead of
-- spitting acid. Only what you see and hear changes: each throw flies the acid's arc and does
-- its damage, the goo left on the ground hurts whoever stands in it, and goo stuck on someone
-- slows them, exactly as the acid did. The goo is a caustic chemical, so it still does acid damage.

require("sound-util")
local util = require("util")
local definitions = require("definitions")

local bottles = {}

-- The goo colours being compared in the bottle sketch (tools/screenshot.ps1 bottle-sketch).
--   splash   the puddle
--   sheen    added over the puddle's highlights, if any
--   glow     whether the goo shines in the dark, like the acid did
--   sticker  goo stuck on someone it hit
--   fumes    the cloud a nest puffs out when its door is blocked, premultiplied
bottles.goos =
{
  oil = {splash = {0.13, 0.11, 0.09}, sheen = {0.45, 0.33, 0.08}, sticker = {0.16, 0.13, 0.1, 0.9}, fumes = {0.14, 0.12, 0.1, 0.55}},
  sludge = {splash = {0.78, 0.52, 0.26}, sticker = {0.62, 0.42, 0.2, 0.85}, fumes = {0.34, 0.24, 0.14, 0.55}},
  yellow = {splash = {1, 0.82, 0.12}, glow = true, sticker = {0.85, 0.7, 0.1, 0.8}, fumes = {0.55, 0.48, 0.12, 0.55}},
}
bottles.default = "oil"

local tiers = {"small", "medium", "big", "behemoth"}
local glass = {0.45, 0.8, 0.5}
local flame_light = {1, 0.62, 0.3}
local on_land = {layers = {water_tile = true}}

local function sound(path, count, volume)
  return
  {
    category = "enemy",
    variations = sound_variations(path, count, volume),
    aggregation = {max_count = 3, remove = true, count_already_playing = true},
  }
end

bottles.throw_sound = sound("__base__/sound/fight/throw-projectile", 6, 0.5)
local breaking_glass = sound("__base__/sound/car-glass-impact", 5, 0.45)
local whoosh = sound("__base__/sound/fight/fire-impact", 5, 0.4)

-- A bottle tumbling end over end with a burning rag in its neck: one of the artillery's spent
-- shell casings, tinted as green glass, with the start of a ground fire's flicker on top.
local function bottle(size, as_shadow)
  local casing =
  {
    filename = "__base__/graphics/particle/artillery-shell-particle/artillery-shells.png",
    y = 36,
    line_length = 12,
    width = 34,
    height = 36,
    frame_count = 12,
    animation_speed = 0.5,
    scale = 0.5 * size,
  }
  if as_shadow then
    casing.draw_as_shadow = true
    return casing
  end
  casing.tint = glass
  local flame_scale = 0.08 * size
  local rag =
  {
    filename = "__base__/graphics/entity/fire-flame/fire-flame-01.png",
    line_length = 10,
    width = 84,
    height = 130,
    frame_count = 12,
    animation_speed = 0.5,
    scale = flame_scale,
    -- The flame's base sits about a fifth of the way up its frame.
    shift = {0, -0.14 * size - 0.31 * 130 * flame_scale / 32},
    draw_as_glow = true,
  }
  return {layers = {casing, rag}}
end

-- The ground fire's flames; base is how far up its frame the flame starts.
local flames =
{
  {file = "fire-flame-01.png", width = 84, height = 130, base = 0.19},
  {file = "fire-flame-02.png", width = 82, height = 106, base = 0.12},
  {file = "fire-flame-03.png", width = 84, height = 124, base = 0.17},
}

-- One flame of the flare-up when a bottle breaks: the start of a ground fire's flames, burning
-- out within a second.
local function burst(name, radius)
  local scale = 0.1 + 0.2 * radius
  local animations = {}
  for i, flame in pairs(flames) do
    animations[i] =
    {
      filename = "__base__/graphics/entity/fire-flame/" .. flame.file,
      line_length = 10,
      width = flame.width,
      height = flame.height,
      frame_count = 40,
      animation_speed = 1,
      scale = scale,
      shift = {0, -(0.5 - flame.base) * flame.height * scale / 32},
      draw_as_glow = true,
    }
  end
  return
  {
    type = "explosion",
    name = name,
    flags = {"not-on-map"},
    hidden = true,
    animations = animations,
    height = 0,
    fade_in_duration = 4,
    fade_out_duration = 24,
    light = {intensity = 0.4, size = 2 + 2 * radius, color = flame_light},
  }
end

-- What happens where a bottle lands, besides the goo: it smashes and flares up.
local function breaking(burst_name, radius)
  return
  {
    {type = "play-sound", sound = breaking_glass},
    {type = "play-sound", sound = whoosh},
    {
      type = "create-explosion",
      entity_name = burst_name,
      repeat_count = 3,
      offset_deviation = {{-0.4 * radius, -0.25 * radius}, {0.4 * radius, 0.25 * radius}},
      tile_collision_mask = on_land,
    },
    {
      type = "create-particle",
      particle_name = "glass-particle-small",
      repeat_count = 12,
      offset_deviation = {{-0.25, -0.25}, {0.25, 0.25}},
      initial_height = 0.3,
      initial_height_deviation = 0.2,
      initial_vertical_speed = 0.07,
      initial_vertical_speed_deviation = 0.03,
      speed_from_center = 0.05,
      speed_from_center_deviation = 0.03,
    },
  }
end

local function list(value)
  return value.type and {value} or value
end

-- Calls visit(effect, delivery) for each target effect of a trigger.
local function each_effect(trigger, visit)
  for _, item in pairs(list(trigger)) do
    for _, delivery in pairs(list(item.action_delivery)) do
      for _, effect in pairs(list(delivery.target_effects)) do
        visit(effect, delivery)
      end
    end
  end
end

local function spit_radius(stream)
  for _, item in pairs(list(stream.initial_action)) do
    if item.type == "area" then
      return item.radius
    end
  end
  return 1
end

local function dress_stream(stream, size, burst_name, splash_name, sticker_name)
  stream.particle = bottle(size)
  stream.shadow = bottle(size, true)
  stream.spine_animation = nil
  stream.oriented_particle = false
  -- A stream always spawns a few particles. The first one carries the hit, so it's the bottle,
  -- and the ones trailing it are drawn at nothing.
  stream.particle_spawn_timeout = 1
  stream.particle_start_alpha = 1
  stream.particle_end_alpha = 1
  stream.particle_alpha_per_part = 0
  stream.particle_scale_per_part = 0.01
  stream.particle_loop_frame_count = 12
  stream.working_sound = nil
  stream.smoke_sources = {{name = "soft-fire-smoke", frequency = 0.3, position = {0, 0}, starting_frame_deviation = 60}}
  stream.progress_to_create_smoke = 0
  stream.stream_light = {intensity = 0.25, size = 2, color = flame_light}

  each_effect(stream.initial_action, function(effect, delivery)
    if effect.type == "create-fire" then
      effect.entity_name = splash_name
      local landing = {effect}
      for _, other in pairs(list(delivery.target_effects)) do
        if other.type == "create-entity" and other.entity_name == "water-splash" then
          table.insert(landing, other)
        end
      end
      for _, extra in pairs(breaking(burst_name, spit_radius(stream))) do
        table.insert(landing, extra)
      end
      delivery.target_effects = landing
    elseif effect.type == "create-sticker" then
      effect.sticker = sticker_name
    end
  end)
end

local function dress_goo_layers(variations, tint, goo)
  for _, variation in pairs(variations) do
    local layers = {}
    for _, layer in pairs(variation.layers) do
      if not layer.draw_as_shadow and layer.blend_mode ~= "additive" then
        layer.tint = tint(goo.splash)
        layer.draw_as_glow = goo.glow
        table.insert(layers, layer)
        if goo.sheen then
          table.insert(layers, util.merge{layer, {tint = tint(goo.sheen), blend_mode = "additive", draw_as_glow = false}})
        end
      elseif layer.draw_as_shadow then
        table.insert(layers, layer)
      end
    end
    variation.layers = layers
  end
end

-- The ground patch under the splash is drawn at the acid's patch opacity.
local function patch(color)
  return util.multiply_color({color[1], color[2], color[3], 1}, 0.7)
end

local function dress_splash(splash, goo, sticker_name)
  dress_goo_layers(splash.pictures, function(color) return color end, goo)
  dress_goo_layers(splash.secondary_pictures, patch, goo)
  each_effect(splash.on_damage_tick_effect, function(effect)
    if effect.type == "create-sticker" then
      effect.sticker = sticker_name
    end
  end)
end

local function dress_sticker(sticker, goo)
  sticker.animation.tint = goo.sticker
  sticker.animation.draw_as_glow = goo.glow
end

-- The prototype to dress: the original, or with a suffix, a copy named <name>-<suffix>.
local function prototype(type, name, suffix)
  local original = data.raw[type][name]
  if not suffix then
    return original
  end
  local copy = table.deepcopy(original)
  copy.name = name .. "-" .. suffix
  data:extend{copy}
  return copy
end

-- Dresses every spitter's and worm's acid in a goo from bottles.goos. With a suffix, dresses
-- copies named <name>-<suffix> instead and leaves the originals alone, so the sketches can show
-- several goos side by side.
function bottles.dress(goo, suffix)
  for _, tier in pairs(tiers) do
    local size = definitions.tiers[tier].scale
    local sticker = prototype("sticker", "acid-sticker-" .. tier, suffix)
    dress_sticker(sticker, goo)
    for _, kind in pairs{"spitter", "worm"} do
      local name = "acid-stream-" .. kind .. "-" .. tier
      local burst_name = name .. "-burst"
      local stream = prototype("stream", name, suffix)
      if not data.raw["explosion"][burst_name] then
        data:extend{burst(burst_name, spit_radius(stream))}
      end
      local splash = prototype("fire", "acid-splash-fire-" .. kind .. "-" .. tier, suffix)
      dress_splash(splash, goo, sticker.name)
      dress_stream(stream, size, burst_name, splash.name, sticker.name)
    end
  end

  local visual = prototype("smoke-with-trigger", "acid-cloud-visual-dummy", suffix)
  visual.color = goo.fumes
  local cloud = prototype("smoke-with-trigger", "acid-cloud", suffix)
  cloud.color = goo.fumes
  each_effect(cloud.created_effect, function(effect)
    if effect.type == "create-smoke" then
      effect.entity_name = visual.name
    end
  end)
end

return bottles
