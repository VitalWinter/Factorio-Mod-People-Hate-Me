-- A sketch of candidate replacements for the bug encampments, built from real base-game entities
-- and decoratives so they can be judged in-game before any of it becomes prototypes.
-- tools/screenshot.ps1 encampment-sketch runs it and collects the screenshots.

local area = {{-26, -20}, {26, 22}}
local column_x = {-18, -9, 0, 9, 18}
local done_tick = 200

local screenshots =
{
  {tick = 120, path = "overview.png", position = {0, 0}, zoom = 0.9, resolution = {1600, 1440}},
  {tick = 125, path = "settlements.png", position = {0, -12.5}, zoom = 2, resolution = {3008, 768}},
  {tick = 130, path = "settlements-night.png", position = {0, -12.5}, zoom = 2, resolution = {3008, 768}, daytime = 0.5},
  {tick = 135, path = "positions.png", position = {0, -0.5}, zoom = 2, resolution = {3008, 768}},
  {tick = 140, path = "ground.png", position = {0, 12.5}, zoom = 2, resolution = {3008, 960}},
}

local function label(surface, text, position)
  rendering.draw_text{text = text, surface = surface, target = position, color = {1, 1, 1}, scale = 1.5, alignment = "center"}
end

local function place(surface, name, position, force)
  return surface.create_entity{name = name, position = position, force = force or "neutral"}
end

local function person(surface, name, position)
  local unit = place(surface, name, position, "enemy")
  unit.commandable.set_command{type = defines.command.stop, distraction = defines.distraction.none}
  unit.disabled_by_script = true
end

local function fallen(surface, name, position)
  place(surface, name, position, "enemy").die()
end

local function hearth(surface, position)
  local furnace = place(surface, "stone-furnace", position)
  furnace.insert{name = "coal", count = 50}
  furnace.insert{name = "iron-ore", count = 50}
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

-- Spawners are about 5x5 tiles.
local settlements =
{
  {
    label = "biter spawner (now)",
    build = function(surface, x, y)
      place(surface, "biter-spawner", {x, y}, "enemy").disabled_by_script = true
    end,
  },
  {
    label = "stone huts",
    build = function(surface, x, y)
      decorate(surface, "enemy-decal", {x, y})
      hearth(surface, {x - 1, y - 1})
      hearth(surface, {x + 1, y + 1})
      place(surface, "wooden-chest", {x + 1.5, y - 1.5})
      place(surface, "wooden-chest", {x - 1.5, y + 1.5})
      scatter(surface, "muddy-stump", {x, y}, 4, 3, 5)
      person(surface, "small-biter", {x + 2.8, y - 0.5})
      person(surface, "small-spitter", {x - 2.8, y + 0.2})
    end,
  },
  {
    label = "market village",
    build = function(surface, x, y)
      decorate(surface, "enemy-decal", {x, y})
      place(surface, "market", {x - 0.5, y - 0.5})
      hearth(surface, {x + 2, y + 2})
      place(surface, "wooden-chest", {x - 1.5, y + 1.5})
      place(surface, "wooden-chest", {x - 0.5, y + 1.5})
      person(surface, "medium-biter", {x + 2.5, y - 1})
    end,
  },
  {
    label = "walled compound",
    build = function(surface, x, y)
      decorate(surface, "enemy-decal", {x, y})
      for dx = -2, 2 do
        for dy = -2, 2 do
          local edge = math.abs(dx) == 2 or math.abs(dy) == 2
          local gateway = dy == 2 and dx == 0
          if edge and not gateway then
            place(surface, "stone-wall", {x + dx + 0.5, y + dy + 0.5})
          end
        end
      end
      hearth(surface, {x, y})
      place(surface, "wooden-chest", {x + 1.5, y - 0.5})
      person(surface, "medium-spitter", {x + 0.5, y + 1.6})
    end,
  },
  {
    label = "ruins",
    build = function(surface, x, y)
      place(surface, "medium-scorchmark", {x, y})
      place(surface, "small-scorchmark", {x - 2, y + 2})
      place(surface, "stone-furnace-remnants", {x - 1, y - 1})
      place(surface, "stone-furnace-remnants", {x + 1, y + 1})
      place(surface, "wooden-chest-remnants", {x + 1.5, y - 1.5})
      fallen(surface, "small-biter", {x + 2.5, y})
      fallen(surface, "small-spitter", {x - 2.5, y - 0.5})
    end,
  },
}

-- Worms are about 2x2 (small) to 3x3 (big and behemoth) tiles.
local positions =
{
  {
    label = "big worm (now)",
    build = function(surface, x, y)
      place(surface, "big-worm-turret", {x, y}, "enemy").disabled_by_script = true
    end,
  },
  {
    label = "gun turret",
    build = function(surface, x, y)
      place(surface, "gun-turret", {x, y})
    end,
  },
  {
    label = "rifle pit",
    build = function(surface, x, y)
      decorate(surface, "dark-mud-decal", {x, y})
      for dx = -1, 1 do
        place(surface, "stone-wall", {x + dx + 0.5, y + 1.5})
      end
      person(surface, "medium-spitter", {x + 0.5, y + 0.6})
    end,
  },
  {
    label = "walled gun nest",
    build = function(surface, x, y)
      decorate(surface, "dark-mud-decal", {x, y})
      for dx = -1, 1 do
        for dy = -1, 1 do
          if dx ~= 0 or dy ~= 0 then
            place(surface, "stone-wall", {x + dx + 0.5, y + dy + 0.5})
          end
        end
      end
      person(surface, "big-spitter", {x + 0.5, y + 0.5})
    end,
  },
  {
    label = "fallen position",
    build = function(surface, x, y)
      place(surface, "small-scorchmark", {x, y + 1})
      for dx = -1, 1 do
        place(surface, "wall-remnants", {x + dx + 0.5, y + 1.5})
      end
      fallen(surface, "medium-spitter", {x + 0.5, y + 0.3})
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

local function build_row(surface, entries, y)
  for column, entry in pairs(entries) do
    local x = column_x[column]
    label(surface, entry.label, {x, y - 4.5})
    entry.build(surface, x, y)
  end
end

local function build_sketch()
  local surface = game.surfaces["nauvis"]
  prepare_ground(surface)
  game.forces["enemy"].set_cease_fire("player", true)
  game.forces["player"].set_cease_fire("enemy", true)

  build_row(surface, settlements, -12)
  build_row(surface, positions, 0)
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
