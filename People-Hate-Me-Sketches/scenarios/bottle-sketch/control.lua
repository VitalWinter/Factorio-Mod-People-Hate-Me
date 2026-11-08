-- The goo colours for the spitters' and worms' thrown bottles, side by side (the data is in
-- People-Hate-Me/prototypes/bottles.lua and this mod's data.lua). Each row is one goo: a big
-- spitter throwing at someone, a small worm's pit firing at someone, a puddle on its own, and the
-- fumes a nest puffs out when its door is blocked.
-- tools/screenshot.ps1 bottle-sketch runs it and collects the screenshots.

local goos = {"oil", "sludge", "yellow"}
local row_y = {-8, 0, 8}
local area = {{-28, -14}, {28, 14}}
local done_tick = 400

local thrower_x, thrower_target_x = -18, -9
local pit_x, pit_target_x = 0, 7
local puddle_x, fumes_x = 13, 20

-- The spitters throw at tick 32 and their bottles land at 55; the pits first fire at 217.
local screenshots =
{
  {tick = 44, path = "throwing-1-in-flight.png", position = {-8, 0}, zoom = 2, resolution = {2304, 1344}},
  {tick = 58, path = "throwing-2-breaking.png", position = {-8, 0}, zoom = 2, resolution = {2304, 1344}},
  {tick = 70, path = "throwing-3-flare-up.png", position = {-8, 0}, zoom = 2, resolution = {2304, 1344}},
  {tick = 140, path = "puddles.png", position = {4, 0}, zoom = 2, resolution = {3072, 1344}},
  {tick = 145, path = "puddles-night.png", position = {4, 0}, zoom = 2, resolution = {3072, 1344}, daytime = 0.5},
  {tick = 150, path = "close-up-puddle-and-fumes.png", position = {16.5, 0}, zoom = 3, resolution = {1728, 1824}},
  {tick = 152, path = "close-up-hit.png", position = {-9, 0}, zoom = 3, resolution = {960, 1824}},
  {tick = 226, path = "positions-1-in-flight.png", position = {-8, 0}, zoom = 2, resolution = {2304, 1344}},
  {tick = 240, path = "positions-2-breaking.png", position = {-8, 0}, zoom = 2, resolution = {2304, 1344}},
}

local function label(surface, text, position)
  rendering.draw_text{text = text, surface = surface, target = position, color = {1, 1, 1}, scale = 1.5, alignment = "right"}
end

local function prepare_ground(surface)
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()

  for _, entity in pairs(surface.find_entities_filtered{area = area}) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy()
    end
  end
  surface.destroy_decoratives{area = area}

  local tiles = {}
  for x = area[1][1], area[2][1] - 1 do
    for y = area[1][2], area[2][2] - 1 do
      tiles[#tiles + 1] = {name = "grass-1", position = {x, y}}
    end
  end
  surface.set_tiles(tiles)

  surface.always_day = true
  game.map_settings.pollution.enabled = false
  game.map_settings.enemy_expansion.enabled = false
end

local function target(surface, x, y)
  return surface.create_entity{name = "character", position = {x, y}, force = "sketch-target"}
end

local function build_sketch()
  local surface = game.surfaces["nauvis"]
  prepare_ground(surface)
  game.create_force("sketch-target")

  for row, goo in pairs(goos) do
    local y = row_y[row]
    label(surface, goo, {thrower_x - 2.5, y - 0.6})

    local spitter = surface.create_entity{name = "phm-sketch-big-spitter-" .. goo, position = {thrower_x, y}, force = "enemy"}
    spitter.commandable.set_command{type = defines.command.attack, target = target(surface, thrower_target_x, y), distraction = defines.distraction.none}

    surface.create_entity{name = "phm-sketch-small-worm-turret-" .. goo, position = {pit_x, y}, force = "enemy"}
    target(surface, pit_target_x, y)

    surface.create_entity{name = "acid-splash-fire-spitter-big-" .. goo, position = {puddle_x, y}}
    surface.create_entity{name = "acid-cloud-" .. goo, position = {fumes_x, y}, force = "enemy"}
  end
end

script.on_init(build_sketch)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if player.character then
    player.character.destroy()
  end
  player.set_controller{type = defines.controllers.spectator}
  player.teleport({0, 0})
end)

script.on_event(defines.events.on_entity_damaged, function(event)
  event.entity.health = event.entity.max_health
end, {{filter = "name", name = "character"}})

script.on_event(defines.events.on_tick, function(event)
  for _, shot in pairs(screenshots) do
    if event.tick == shot.tick then
      game.take_screenshot
      {
        surface = "nauvis",
        position = shot.position,
        zoom = shot.zoom,
        resolution = shot.resolution,
        path = "people-hate-me/bottle-sketch/" .. shot.path,
        hide_health_bars = true,
        force_render = true,
        daytime = shot.daytime or 0,
      }
    end
  end
  if event.tick == done_tick then
    helpers.write_file("people-hate-me/bottle-sketch/done.txt", "done")
  end
end)
