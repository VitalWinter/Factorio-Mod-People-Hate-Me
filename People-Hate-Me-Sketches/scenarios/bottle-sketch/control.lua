-- The ways a bottle can land (bottles.landings in People-Hate-Me/prototypes/bottles.lua), side by
-- side. Each row is one way: a big spitter and a small worm's pit throwing at someone.
-- tools/screenshot.ps1 bottle-sketch runs it and collects the screenshots. It also films a
-- spitter's and a gunner's throw every other tick into frames/, which aren't collected, for
-- checking the throw's timing.

local landings = {"smash", "fireball"}
local row_y = {-4, 4}
local area = {{-24, -14}, {16, 14}}
local done_tick = 260

local spitter_x, spitter_target_x = -14, -5
local pit_x, pit_target_x = 4, 11

-- The spitters' bottles leave at about ticks 30 and 130, and the pits' first at about 205.
local screenshots = {}
local function film(name, position, first, last)
  for tick = first, last, 2 do
    table.insert(screenshots, {tick = tick, path = string.format("frames/%s-%03d.png", name, tick), position = position, zoom = 3, resolution = {320, 320}})
  end
end
film("spitter", {spitter_x + 0.5, row_y[1] - 1}, 0, 180)
film("gunner", {pit_x + 0.5, row_y[1] - 1}, 170, 240)
for _, tick in pairs{56, 60, 66, 74, 84, 96, 110, 130} do
  table.insert(screenshots, {tick = tick, path = string.format("landing-%03d.png", tick), position = {spitter_target_x, 0}, zoom = 2, resolution = {512, 896}})
end

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

  for row, landing in pairs(landings) do
    local y = row_y[row]
    label(surface, landing, {spitter_x - 2.5, y - 0.6})

    local spitter = surface.create_entity{name = "phm-sketch-big-spitter-" .. landing, position = {spitter_x, y}, force = "enemy"}
    spitter.commandable.set_command{type = defines.command.attack, target = target(surface, spitter_target_x, y), distraction = defines.distraction.none}

    surface.create_entity{name = "phm-sketch-small-worm-turret-" .. landing, position = {pit_x, y}, force = "enemy"}
    target(surface, pit_target_x, y)
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
        daytime = 0,
      }
    end
  end
  if event.tick == done_tick then
    helpers.write_file("people-hate-me/bottle-sketch/done.txt", "done")
  end
end)
