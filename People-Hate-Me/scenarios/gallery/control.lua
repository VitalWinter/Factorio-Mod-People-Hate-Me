-- A lineup of every enemy type next to the engineer, for checking how the mod looks.
-- tools/test.ps1 runs it headless and reads the pass/fail result from script.finish_test.
-- tools/screenshot.ps1 runs it with graphics and collects the screenshots it takes.

local tiers = {"small", "medium", "big", "behemoth"}
local kinds = {"biter", "spitter"}
local column_x = {-9, -3, 3, 9}
local engineer_position = {-16.5, -5}
local gallery_area = {{-26, -14}, {18, 18}}

local rows =
{
  {y = -5, label = "biters", state = "standing", kind = "biter"},
  {y = -1, label = "spitters", state = "standing", kind = "spitter"},
  {y = 3, label = "biters attacking", state = "fighting", kind = "biter", wall_offset = 1.5},
  {y = 7, label = "spitters attacking", state = "fighting", kind = "spitter", wall_offset = 2.5},
  {y = 12, label = "fallen", state = "fallen"},
}

local screenshots =
{
  {tick = 180, path = "overview.png", position = {-4, 2}, zoom = 1.75, resolution = {2048, 1536}},
  {tick = 190, path = "standing.png", position = {-4, -3}, zoom = 3, resolution = {2880, 1080}},
  {tick = 200, path = "fighting.png", position = {0, 5}, zoom = 3, resolution = {2560, 1080}},
  {tick = 210, path = "fallen.png", position = {0, 11.5}, zoom = 3, resolution = {2560, 600}},
}

local check_tick = 600

local function label(surface, text, position, alignment)
  rendering.draw_text
  {
    text = text,
    surface = surface,
    target = position,
    color = {1, 1, 1},
    scale = 1.5,
    alignment = alignment or "center",
  }
end

local function prepare_ground(surface)
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()

  for _, entity in pairs(surface.find_entities_filtered{area = gallery_area}) do
    if entity.valid and entity.type ~= "character" then
      entity.destroy()
    end
  end
  surface.destroy_decoratives{area = gallery_area}

  local tiles = {}
  for x = gallery_area[1][1], gallery_area[2][1] - 1 do
    for y = gallery_area[1][2], gallery_area[2][2] - 1 do
      tiles[#tiles + 1] = {name = "grass-1", position = {x, y}}
    end
  end
  surface.set_tiles(tiles)

  surface.always_day = true
  game.map_settings.pollution.enabled = false
  game.map_settings.enemy_expansion.enabled = false
end

local function spawn(surface, name, position)
  return surface.create_entity{name = name, position = position, force = "enemy"}
end

local function build_row(surface, row)
  label(surface, row.label, {-12.5, row.y - 0.5}, "right")

  for column, tier in pairs(tiers) do
    local x = column_x[column] + 0.5

    if row.state == "standing" then
      local unit = spawn(surface, tier .. "-" .. row.kind, {x, row.y})
      unit.commandable.set_command{type = defines.command.stop, distraction = defines.distraction.none}
      unit.disabled_by_script = true

    elseif row.state == "fighting" then
      local unit = spawn(surface, tier .. "-" .. row.kind, {x, row.y})
      local target
      for dx = -1, 1 do
        local wall = surface.create_entity{name = "stone-wall", position = {x + dx, row.y + row.wall_offset}, force = "gallery-target"}
        if dx == 0 then
          target = wall
        end
      end
      unit.commandable.set_command{type = defines.command.attack, target = target, distraction = defines.distraction.none}

    elseif row.state == "fallen" then
      spawn(surface, tier .. "-biter", {x - 1, row.y}).die()
      spawn(surface, tier .. "-spitter", {x + 1.5, row.y}).die()
    end
  end
end

local function build_gallery()
  local surface = game.surfaces["nauvis"]
  prepare_ground(surface)

  game.create_force("gallery-target")
  game.forces["enemy"].set_cease_fire("player", true)
  game.forces["player"].set_cease_fire("enemy", true)

  surface.create_entity{name = "character", position = engineer_position, force = "player"}
  label(surface, "engineer", {engineer_position[1], -8})
  for column, tier in pairs(tiers) do
    label(surface, tier, {column_x[column] + 0.5, -8})
  end

  for _, row in pairs(rows) do
    build_row(surface, row)
  end

  storage.hits = {}
end

local function run_checks()
  local surface = game.surfaces["nauvis"]
  local failures = {}

  local corpses = {}
  for _, corpse in pairs(surface.find_entities_filtered{area = gallery_area, type = "corpse"}) do
    corpses[corpse.name] = true
  end

  for _, tier in pairs(tiers) do
    for _, kind in pairs(kinds) do
      local name = tier .. "-" .. kind
      if not storage.hits[name] then
        table.insert(failures, name .. " never landed an attack")
      end
      if not corpses[name .. "-corpse"] then
        table.insert(failures, name .. " left no corpse")
      end
      -- People are taller than bugs, so a redrawn unit's selection box reaches well above its feet.
      if prototypes.entity[name].selection_box.left_top.y > -1 then
        table.insert(failures, name .. " still has its bug-shaped selection box")
      end
    end
  end

  local passed = #failures == 0
  local summary = passed and "People Hate Me gallery: all checks passed"
    or ("People Hate Me gallery: " .. #failures .. " check(s) failed:\n  " .. table.concat(failures, "\n  "))
  log(summary)
  game.print(summary)
  script.finish_test(passed)
end

script.on_init(build_gallery)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if player.character then
    player.character.destroy()
  end
  player.set_controller{type = defines.controllers.spectator}
  player.teleport({-4, 2})
end)

script.on_event(defines.events.on_entity_damaged, function(event)
  local cause = event.cause
  if cause and cause.valid then
    storage.hits[cause.name] = (storage.hits[cause.name] or 0) + 1
  end
  event.entity.health = event.entity.max_health
end, {{filter = "name", name = "stone-wall"}})

script.on_event(defines.events.on_tick, function(event)
  for _, shot in pairs(screenshots) do
    if event.tick == shot.tick then
      game.take_screenshot
      {
        surface = "nauvis",
        position = shot.position,
        zoom = shot.zoom,
        resolution = shot.resolution,
        path = "people-hate-me/" .. shot.path,
        hide_health_bars = true,
        force_render = true,
        daytime = 0,
      }
    end
  end
  if event.tick == check_tick then
    run_checks()
  end
end)
