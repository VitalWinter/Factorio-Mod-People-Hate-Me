-- Candidate replacements for the bug encampments, each beside the bug structure it replaces.
-- Both are outlined with that structure's collision box, so the footprints can be compared.
-- The candidates are kitbashed sprites from this mod's data.lua.
-- tools/screenshot.ps1 encampment-sketch runs it and collects the screenshots.

local area = {{-26, -20}, {26, 22}}
local column_x = {-20, -12, -4, 4, 12, 20}
local done_tick = 200

local screenshots =
{
  {tick = 120, path = "overview.png", position = {0, 0}, zoom = 0.9, resolution = {1600, 1440}},
  {tick = 125, path = "settlements.png", position = {0, -12.5}, zoom = 2, resolution = {3008, 832}},
  {tick = 130, path = "settlements-night.png", position = {0, -12.5}, zoom = 2, resolution = {3008, 832}, daytime = 0.5},
  {tick = 135, path = "positions.png", position = {0, -0.5}, zoom = 2, resolution = {3008, 640}},
  {tick = 140, path = "positions-night.png", position = {0, -0.5}, zoom = 2, resolution = {3008, 640}, daytime = 0.5},
  {tick = 145, path = "ground.png", position = {0, 12.5}, zoom = 2, resolution = {3008, 960}},
}

local function label(surface, text, position)
  rendering.draw_text{text = text, surface = surface, target = position, color = {1, 1, 1}, scale = 1.2, alignment = "center"}
end

local function place(surface, name, position, force)
  return surface.create_entity{name = name, position = position, force = force or "neutral"}
end

local function person(surface, name, position)
  local unit = place(surface, name, position, "enemy")
  unit.commandable.set_command{type = defines.command.stop, distraction = defines.distraction.none}
  unit.disabled_by_script = true
end

local function sprite(surface, name, position)
  rendering.draw_sprite{sprite = "phm-sketch-" .. name, surface = surface, target = position, render_layer = "object"}
end

local function glow(surface, position, scale)
  rendering.draw_light{sprite = "utility/light_medium", surface = surface, target = position, scale = scale or 1, intensity = 0.7, color = {1, 0.85, 0.6}}
end

-- The collision box of the bug structure being replaced, drawn on the ground at x, y.
local function outline(surface, structure, x, y)
  local box = prototypes.entity[structure].collision_box
  rendering.draw_rectangle
  {
    color = {0.4, 0.85, 1, 0.8},
    width = 2,
    filled = false,
    left_top = {x + box.left_top.x, y + box.left_top.y},
    right_bottom = {x + box.right_bottom.x, y + box.right_bottom.y},
    surface = surface,
    draw_on_ground = true,
  }
end

local function now(structure)
  return function(surface, x, y)
    place(surface, structure, {x, y}, "enemy").disabled_by_script = true
  end
end

local function decorate(surface, name, position)
  surface.create_decoratives
  {
    check_collision = false,
    decoratives = {{name = name, position = {math.floor(position[1]), math.floor(position[2])}, amount = 1}},
  }
end

local function scatter(surface, name, centre, count, min_radius, max_radius)
  for _ = 1, count do
    local angle = math.random() * 2 * math.pi
    local radius = min_radius + math.random() * (max_radius - min_radius)
    decorate(surface, name, {centre[1] + radius * math.cos(angle), centre[2] + radius * math.sin(angle)})
  end
end

local function tiles(surface, name, left_top, width, height)
  local list = {}
  for dx = 0, width - 1 do
    for dy = 0, height - 1 do
      list[#list + 1] = {name = name, position = {math.floor(left_top[1]) + dx, math.floor(left_top[2]) + dy}}
    end
  end
  surface.set_tiles(list)
end

-- Each entry: label, the bug structure whose footprint it must fit, and how to build it.
local settlements =
{
  {label = "biter nest (now)", structure = "biter-spawner", build = now("biter-spawner")},
  {
    label = "workshop",
    structure = "biter-spawner",
    build = function(surface, x, y)
      sprite(surface, "workshop", {x, y})
      person(surface, "small-biter", {x + 0.2, y + 1.5})
    end,
  },
  {label = "spitter nest (now)", structure = "spitter-spawner", build = now("spitter-spawner")},
  {
    label = "armoury",
    structure = "spitter-spawner",
    build = function(surface, x, y)
      sprite(surface, "armoury", {x, y})
      glow(surface, {x - 1.9, y + 0.5}, 0.8)
      person(surface, "small-spitter", {x, y + 1.3})
    end,
  },
  {
    label = "cabins (another nest option)",
    structure = "biter-spawner",
    build = function(surface, x, y)
      sprite(surface, "cabins", {x, y})
      person(surface, "medium-biter", {x - 0.2, y + 0.7})
    end,
  },
  {
    label = "graveyard",
    structure = "biter-spawner",
    build = function(surface, x, y)
      for _, row in pairs{-0.6, 0.6} do
        tiles(surface, "dirt-4", {x - 2, y + row}, 4, 1)
      end
      sprite(surface, "graveyard", {x, y})
      glow(surface, {x + 1.9, y + 1.4}, 0.8)
      person(surface, "medium-spitter", {x + 0.3, y + 1.6})
    end,
  },
}

local positions =
{
  {label = "small worm (now)", structure = "small-worm-turret", build = now("small-worm-turret")},
  {
    label = "small position",
    structure = "small-worm-turret",
    build = function(surface, x, y)
      person(surface, "small-spitter", {x, y - 0.1})
      sprite(surface, "position-small", {x, y})
    end,
  },
  {label = "medium worm (now)", structure = "medium-worm-turret", build = now("medium-worm-turret")},
  {
    label = "medium position",
    structure = "medium-worm-turret",
    build = function(surface, x, y)
      person(surface, "medium-spitter", {x - 0.3, y})
      sprite(surface, "position-medium", {x, y})
    end,
  },
  {label = "big worm (now)", structure = "big-worm-turret", build = now("big-worm-turret")},
  {
    label = "big position",
    structure = "big-worm-turret",
    build = function(surface, x, y)
      sprite(surface, "position-big", {x, y})
      person(surface, "big-spitter", {x, y + 0.1})
    end,
  },
}

-- Each entry is {decorative, count, min radius, max radius}, like the spawners' spawn_decoration.
local ground =
{
  {
    label = "nest ground (now)",
    x = -11,
    decoratives =
    {
      {"enemy-decal", 1, 0, 0}, {"enemy-decal-transparent", 8, 2, 7}, {"worms-decal", 3, 1, 5},
      {"shroom-decal", 3, 1, 5}, {"lichen-decal", 2, 2, 6}, {"muddy-stump", 4, 3, 6},
      {"red-croton", 5, 3, 6}, {"red-pita", 3, 3, 6},
    },
  },
  {
    label = "proposed",
    x = 11,
    decoratives =
    {
      {"enemy-decal", 1, 0, 0}, {"enemy-decal-transparent", 8, 2, 7}, {"cracked-mud-decal", 3, 1, 5},
      {"tiny-rock", 6, 1, 5}, {"small-rock", 3, 2, 6}, {"muddy-stump", 4, 3, 6},
      {"green-croton", 5, 3, 6}, {"green-pita", 3, 3, 6},
    },
  },
}

local function prepare_ground(surface)
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()

  for _, entity in pairs(surface.find_entities_filtered{area = area}) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy()
    end
  end
  surface.destroy_decoratives{area = area}
  tiles(surface, "grass-1", area[1], area[2][1] - area[1][1], area[2][2] - area[1][2])

  surface.always_day = true
  game.map_settings.pollution.enabled = false
  game.map_settings.enemy_expansion.enabled = false
end

local function build_row(surface, entries, y, label_offset)
  for column, entry in pairs(entries) do
    local x = column_x[column]
    label(surface, entry.label, {x, y - label_offset})
    outline(surface, entry.structure, x, y)
    entry.build(surface, x, y)
  end
end

local function build_sketch()
  local surface = game.surfaces["nauvis"]
  prepare_ground(surface)
  game.forces["enemy"].set_cease_fire("player", true)
  game.forces["player"].set_cease_fire("enemy", true)

  build_row(surface, settlements, -12, 5.6)
  build_row(surface, positions, 0, 3.8)
  for _, patch in pairs(ground) do
    label(surface, patch.label, {patch.x, 5})
    for _, entry in pairs(patch.decoratives) do
      scatter(surface, entry[1], {patch.x, 13}, entry[2], entry[3], entry[4])
    end
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

script.on_event(defines.events.on_tick, function(event)
  for _, shot in pairs(screenshots) do
    if event.tick == shot.tick then
      game.take_screenshot
      {
        surface = "nauvis",
        position = shot.position,
        zoom = shot.zoom,
        resolution = shot.resolution,
        path = "people-hate-me/encampment-sketch/" .. shot.path,
        hide_health_bars = true,
        force_render = true,
        daytime = shot.daytime or 0,
      }
    end
  end
  if event.tick == done_tick then
    helpers.write_file("people-hate-me/encampment-sketch/done.txt", "done")
  end
end)
