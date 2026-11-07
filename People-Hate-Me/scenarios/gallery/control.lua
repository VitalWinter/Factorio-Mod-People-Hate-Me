-- A lineup of every enemy type next to the engineer, and of the settlements and defensive
-- positions they build, for checking how the mod looks.
-- tools/test.ps1 runs it headless and reads the pass/fail result from script.finish_test.
-- tools/screenshot.ps1 runs it with graphics and collects the screenshots it takes.

local tiers = {"small", "medium", "big", "behemoth"}
local kinds = {"biter", "spitter"}
local column_x = {-9, -3, 3, 9}
local engineer_position = {-16.5, -5}
local gallery_area = {{-26, -14}, {18, 72}}

-- Spawner graphics variations: the biter nest's houses, the spitter nest's flats and hall.
local settlements = {{"biter-spawner", 1}, {"spitter-spawner", 1}, {"spitter-spawner", 2}}
local worms = {"small-worm-turret", "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret"}
local settlement_y = 22
local position_y = 30
local ruin_y = 38
-- Far enough from the walls in the fighting rows that even the behemoth position can't reach them.
local firing_y = 62
local target_distance = 6

local rows =
{
  {y = -5, label = "biters", state = "standing", kind = "biter"},
  {y = -1, label = "spitters", state = "standing", kind = "spitter"},
  {y = 3, label = "biters attacking", state = "fighting", kind = "biter", wall_offset = 1.5},
  {y = 7, label = "spitters attacking", state = "fighting", kind = "spitter", wall_offset = 2.5},
  {y = 12, label = "fallen", state = "fallen"},
}

-- The fallen row dies a little after the others start fighting, so the screenshot right
-- after catches the blood in the air and the aftermath shot catches the blood pools.
local death_tick = 120
local check_tick = 600
local done_tick = 930

local screenshots =
{
  {tick = 150, path = "fallen.png", position = {0, 11.5}, zoom = 3, resolution = {2560, 600}},
  {tick = 180, path = "overview.png", position = {-4, 2}, zoom = 1.75, resolution = {2048, 1536}},
  {tick = 190, path = "standing.png", position = {-4, -3}, zoom = 3, resolution = {2880, 1080}},
  {tick = 200, path = "fighting.png", position = {0, 5}, zoom = 3, resolution = {2560, 1080}},
  {tick = 210, path = "settlements.png", position = {-9.5, 21}, zoom = 2, resolution = {1792, 640}},
  {tick = 215, path = "settlements-night.png", position = {-9.5, 21}, zoom = 2, resolution = {1792, 640}, daytime = 0.5},
  {tick = 220, path = "positions.png", position = {-9.5, 29.5}, zoom = 3, resolution = {2560, 576}},
  {tick = 240, path = "positions-firing.png", position = {-9.5, 64}, zoom = 2, resolution = {1792, 832}},
  {tick = 450, path = "ruins.png", position = {-5, 38}, zoom = 2, resolution = {2048, 512}},
  {tick = 900, path = "aftermath.png", position = {0, 11.5}, zoom = 3, resolution = {2560, 600}},
}

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
      rendering.draw_sprite{sprite = "entity/" .. unit.name, surface = surface, target = {x - 1.6, row.y - 0.6}}

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
    end
  end
end

-- Settlements and positions, inactive so nests don't spawn and positions stay at ease.
local function place_structure(surface, name, position, variation)
  local structure = spawn(surface, name, position)
  structure.disabled_by_script = true
  if variation then
    structure.graphics_variation = variation
  end
  return structure
end

local function build_structures(surface)
  label(surface, "settlements", {-17.5, settlement_y - 0.5}, "right")
  for i, settlement in pairs(settlements) do
    place_structure(surface, settlement[1], {-14 + (i - 1) * 7, settlement_y}, settlement[2])
  end

  label(surface, "positions", {-17.5, position_y - 0.5}, "right")
  label(surface, "ruins", {-17.5, ruin_y - 0.5}, "right")
  label(surface, "positions firing", {-17.5, firing_y - 0.5}, "right")
  for i, worm in pairs(worms) do
    local x = -14 + (i - 1) * 4.5
    place_structure(surface, worm, {x, position_y})
    spawn(surface, worm, {x, firing_y})
    surface.create_entity{name = "character", position = {x, firing_y + target_distance}, force = "gallery-target"}
  end
end

local function kill_fallen_row(surface)
  local row = rows[#rows]
  for column, tier in pairs(tiers) do
    local x = column_x[column] + 0.5
    spawn(surface, tier .. "-biter", {x - 1, row.y}).die()
    spawn(surface, tier .. "-spitter", {x + 1.5, row.y}).die()
  end

  place_structure(surface, "biter-spawner", {-14, ruin_y}).die()
  place_structure(surface, "spitter-spawner", {-7, ruin_y}).die()
  for i, worm in pairs(worms) do
    place_structure(surface, worm, {-1.5 + (i - 1) * 3.5, ruin_y}).die()
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
  build_structures(surface)

  storage.hits = {}
end

local function run_checks()
  local surface = game.surfaces["nauvis"]
  local failures = {}

  local corpses = {}
  for _, corpse in pairs(surface.find_entities_filtered{area = gallery_area, type = "corpse"}) do
    corpses[corpse.name] = true
    -- Fallen people, including the gunners left in destroyed positions.
    local is_person = corpse.name:find("^%a+%-biter%-corpse$") or corpse.name:find("^%a+%-spitter%-corpse$")
      or corpse.name:find("-worm-corpse", 1, true)
    if is_person and not corpse.color then
      table.insert(failures, corpse.name .. " has no individual colour")
    end
  end

  for _, spawner in pairs{"biter-spawner", "spitter-spawner"} do
    if not corpses[spawner .. "-corpse"] then
      table.insert(failures, spawner .. " left no ruins")
    end
  end
  for _, worm in pairs(worms) do
    if not storage.hits[worm] then
      table.insert(failures, worm .. " never hit its target")
    end
    -- The ruins row's positions were at ease when destroyed, so they leave the folded-state corpse.
    if not corpses[worm:gsub("%-turret$", "") .. "-corpse-burrowed"] then
      table.insert(failures, worm .. " left no wreck")
    end
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
end, {{filter = "name", name = "stone-wall"}, {filter = "name", name = "character"}})

script.on_event(defines.events.on_tick, function(event)
  for _, shot in pairs(screenshots) do
    if event.tick == shot.tick then
      game.take_screenshot
      {
        surface = "nauvis",
        position = shot.position,
        zoom = shot.zoom,
        resolution = shot.resolution,
        path = "people-hate-me/gallery/" .. shot.path,
        hide_health_bars = true,
        force_render = true,
        daytime = shot.daytime or 0,
      }
    end
  end
  if event.tick == death_tick then
    kill_fallen_row(game.surfaces["nauvis"])
  end
  if event.tick == check_tick then
    run_checks()
  end
  if event.tick == done_tick then
    helpers.write_file("people-hate-me/gallery/done.txt", "done")
  end
end)
