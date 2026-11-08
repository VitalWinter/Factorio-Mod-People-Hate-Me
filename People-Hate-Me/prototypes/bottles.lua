-- Spitters and the gunners in defensive positions throw bottles of glowing yellow goo instead of
-- spitting acid. Only what you see and hear changes: each throw flies the acid's arc and does
-- its damage, the goo left on the ground hurts whoever stands in it, and goo stuck on someone
-- slows them, exactly as the acid did. The goo is a caustic chemical, so it still does acid damage.

require("sound-util")
local util = require("util")
local definitions = require("definitions")

local bottles = {}

-- splash   the puddle, which shines in the dark like the acid did
-- sticker  goo stuck on someone it hit
-- fumes    the cloud a nest puffs out when its door is blocked, premultiplied
local goo = {splash = {1, 0.82, 0.12}, sticker = {0.85, 0.7, 0.1, 0.8}, fumes = {0.55, 0.48, 0.12, 0.55}}

-- How a bottle lands, being compared side by side in the showroom:
--   flames    a burning bottle that flares up in flames
--   smash     a plain bottle of goo that just smashes
--   fireball  a burning bottle that bursts into a fireball
bottles.landings =
{
  flames = {burning = true},
  smash = {burning = false},
  fireball = {burning = true},
}
bottles.default_landing = "flames"

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

-- A bottle tumbling end over end: one of the artillery's spent shell casings, tinted as green
-- glass. A burning one has a rag in its neck, the start of a ground fire's flicker.
local function bottle(size, burning, as_shadow)
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
  if not burning then
    return casing
  end
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

-- One flame of the flare-up when a burning bottle breaks: it catches small, grows, burns for
-- over a second, then dies down into smoke.
local function flare_up(name, radius)
  local scale = 0.1 + 0.2 * radius
  local animations = {}
  for i, flame in pairs(flames) do
    animations[i] =
    {
      filename = "__base__/graphics/entity/fire-flame/" .. flame.file,
      line_length = 10,
      width = flame.width,
      height = flame.height,
      frame_count = 60,
      animation_speed = 0.75,
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
    scale_initial = 0.25,
    scale_initial_deviation = 0.1,
    scale_in_duration = 16,
    scale_out_duration = 40,
    scale_end = 0.3,
    scale_deviation = 0.15,
    fade_in_duration = 8,
    fade_out_duration = 36,
    smoke = "soft-fire-smoke",
    smoke_count = 1,
    smoke_slow_down_factor = 1,
    light = {intensity = 0.4, size = 2 + 2 * radius, color = flame_light},
  }
end

-- A grenade's fireball, sized to the splash.
local function fireball(name, radius)
  local explosion = table.deepcopy(data.raw["explosion"]["grenade-explosion"])
  explosion.name = name
  explosion.scale = 0.45 + 0.25 * radius
  return explosion
end

local function explosion(name, make, radius)
  if not data.raw["explosion"][name] then
    data:extend{make(name, radius)}
  end
  return name
end

-- What happens where a bottle lands, besides the goo: it smashes, and a burning one goes up.
-- name is the original stream's, so copies of a stream share its explosions.
local function landing(style, name, radius)
  local effects =
  {
    {type = "play-sound", sound = breaking_glass},
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
  if style == "flames" then
    table.insert(effects, {type = "play-sound", sound = whoosh})
    table.insert(effects,
    {
      type = "create-explosion",
      entity_name = explosion(name .. "-flare-up", flare_up, radius),
      repeat_count = 3,
      offset_deviation = {{-0.4 * radius, -0.25 * radius}, {0.4 * radius, 0.25 * radius}},
      tile_collision_mask = on_land,
    })
  elseif style == "fireball" then
    table.insert(effects,
    {
      type = "create-explosion",
      entity_name = explosion(name .. "-fireball-burst", fireball, radius),
      tile_collision_mask = on_land,
    })
  end
  return effects
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

local function dress_stream(stream, size, style, name)
  local burning = bottles.landings[style].burning
  stream.particle = bottle(size, burning)
  stream.shadow = bottle(size, burning, true)
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
  if burning then
    stream.smoke_sources = {{name = "soft-fire-smoke", frequency = 0.3, position = {0, 0}, starting_frame_deviation = 60}}
    stream.progress_to_create_smoke = 0
    stream.stream_light = {intensity = 0.25, size = 2, color = flame_light}
  else
    stream.smoke_sources = nil
    stream.stream_light = nil
  end

  each_effect(stream.initial_action, function(effect, delivery)
    if effect.type == "create-fire" then
      local effects = {effect}
      for _, other in pairs(list(delivery.target_effects)) do
        if other.type == "create-entity" and other.entity_name == "water-splash" then
          table.insert(effects, other)
        end
      end
      for _, extra in pairs(landing(style, name, spit_radius(stream))) do
        table.insert(effects, extra)
      end
      delivery.target_effects = effects
    end
  end)
end

local function dress_splash_layers(variations, tint)
  for _, variation in pairs(variations) do
    for _, layer in pairs(variation.layers) do
      if not layer.draw_as_shadow then
        layer.tint = tint
        layer.draw_as_glow = true
      end
    end
  end
end

-- Recolours the acid left on the ground, stuck on people, and puffed out by nests as the goo.
function bottles.dress_goo()
  for _, tier in pairs(tiers) do
    local sticker = data.raw["sticker"]["acid-sticker-" .. tier]
    sticker.animation.tint = goo.sticker
    sticker.animation.draw_as_glow = true
    for _, kind in pairs{"spitter", "worm"} do
      local splash = data.raw["fire"]["acid-splash-fire-" .. kind .. "-" .. tier]
      dress_splash_layers(splash.pictures, goo.splash)
      -- The ground patch under the splash is drawn at the acid's patch opacity.
      dress_splash_layers(splash.secondary_pictures, util.multiply_color({goo.splash[1], goo.splash[2], goo.splash[3], 1}, 0.7))
    end
  end
  data.raw["smoke-with-trigger"]["acid-cloud"].color = goo.fumes
  data.raw["smoke-with-trigger"]["acid-cloud-visual-dummy"].color = goo.fumes
end

-- Turns every spitter's and worm's acid stream into a thrown bottle that lands in one of
-- bottles.landings. With a suffix, dresses copies named <name>-<suffix> instead and leaves the
-- originals alone, so the showroom can show the landings side by side.
function bottles.dress_streams(style, suffix)
  for _, tier in pairs(tiers) do
    local size = definitions.tiers[tier].scale
    for _, kind in pairs{"spitter", "worm"} do
      local name = "acid-stream-" .. kind .. "-" .. tier
      local stream = data.raw["stream"][name]
      if suffix then
        stream = table.deepcopy(stream)
        stream.name = name .. "-" .. suffix
        data:extend{stream}
      end
      dress_stream(stream, size, style, name)
    end
  end
end

return bottles
