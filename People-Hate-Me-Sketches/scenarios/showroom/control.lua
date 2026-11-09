-- A place to watch the mod in action instead of in screenshots: stations on an empty grass map
-- that keep running, and a panel to jump between them, slow the game down and switch to night.
-- tools/play.ps1 opens it.

local surface_name = "showroom"
-- The ways a bottle can land (bottles.landings in People-Hate-Me/prototypes/bottles.lua).
local landings = {{name = "smash", label = "smashing"}, {name = "fireball", label = "Exploding bottles setting"}}
local tiers = {"small", "medium", "big", "behemoth"}
local worms = {"small-worm-turret", "medium-worm-turret", "big-worm-turret", "behemoth-worm-turret"}
local column_x = {-8.5, -2.5, 3.5, 9.5}

local speeds =
{
  {caption = "Normal", value = 1},
  {caption = "Half", value = 0.5},
  {caption = "Quarter", value = 0.25},
  {caption = "Tenth", value = 0.1},
}

-- How often people come by the throwing positions, and the deaths and ruins replay.
local passer_by_ticks = 600
local replay_ticks = 900

local function label(surface, text, position, alignment)
  rendering.draw_text{text = text, surface = surface, target = position, color = {1, 1, 1}, scale = 1.5, alignment = alignment or "center"}
end

local function enemy(surface, name, position)
  return surface.create_entity{name = name, position = position, force = "enemy"}
end

-- Characters and walls the enemies throw at and hit; they heal back to full.
local function target(surface, name, position)
  return surface.create_entity{name = name, position = position, force = "showroom-target"}
end

-- Units are kept at it: an attacker goes back to its target, a walker paces between two points.
local function attack(unit, target_entity)
  storage.attackers[unit.unit_number] = {unit = unit, target = target_entity}
  unit.commandable.set_command{type = defines.command.attack, target = target_entity, distraction = defines.distraction.none}
end

local function walk(walker)
  walker.unit.commandable.set_command{type = defines.command.go_to_location, destination = walker.to, radius = 0.5, distraction = defines.distraction.none}
end

local function pace(unit, from, to)
  local walker = {unit = unit, from = from, to = to}
  storage.walkers[unit.unit_number] = walker
  walk(walker)
end

-- Each way of landing in a row: a big spitter and a small worm's pit throwing at someone.
local function build_bottles(surface, at)
  label(surface, "spitter throwing", at(-9.5, -12.5))
  label(surface, "position throwing", at(7.5, -12.5))
  for row, landing in pairs(landings) do
    local y = (row - 1.5) * 8
    label(surface, landing.label, at(-16.5, y - 0.6), "right")
    attack(enemy(surface, "phm-sketch-big-spitter-" .. landing.name, at(-14, y)), target(surface, "character", at(-5, y)))
    enemy(surface, "phm-sketch-small-worm-turret-" .. landing.name, at(4, y))
    target(surface, "character", at(11, y))
  end
end

local people_rows =
{
  {y = -8, label = "biters", kind = "biter", state = "standing"},
  {y = -4, label = "spitters", kind = "spitter", state = "standing"},
  {y = 0, label = "biters walking", kind = "biter", state = "walking"},
  {y = 4, label = "spitters walking", kind = "spitter", state = "walking"},
  {y = 8, label = "biters attacking", kind = "biter", state = "attacking", wall = 1.5},
  {y = 12, label = "spitters attacking", kind = "spitter", state = "attacking", wall = 2.5},
}

local function build_people(surface, at)
  surface.create_entity{name = "character", position = at(-17.5, -8), force = "player"}
  label(surface, "engineer", at(-17.5, -11.5))
  for column, tier in pairs(tiers) do
    label(surface, tier, at(column_x[column], -11.5))
  end

  for _, row in pairs(people_rows) do
    label(surface, row.label, at(-12.5, row.y - 0.5), "right")
    for column, tier in pairs(tiers) do
      local x = column_x[column]
      local unit = enemy(surface, tier .. "-" .. row.kind, at(x, row.y))
      if row.state == "standing" then
        unit.commandable.set_command{type = defines.command.stop, distraction = defines.distraction.none}
        unit.disabled_by_script = true
      elseif row.state == "walking" then
        pace(unit, at(x - 2, row.y), at(x + 2, row.y))
      else
        local wall
        for dx = -1, 1 do
          local piece = target(surface, "stone-wall", at(x + dx, row.y + row.wall))
          if dx == 0 then
            wall = piece
          end
        end
        attack(unit, wall)
      end
    end
  end
end

local settlements = {{"biter-spawner", 1}, {"spitter-spawner", 1}, {"spitter-spawner", 2}}

-- The nests are inactive so they don't fill the station with people. The throwing positions
-- wake up when someone comes by and settle down again when they leave.
local function build_settlements(surface, at)
  label(surface, "settlements", at(-17.5, -8.5), "right")
  for i, settlement in pairs(settlements) do
    local nest = enemy(surface, settlement[1], at(-14 + (i - 1) * 7, -8))
    nest.disabled_by_script = true
    nest.graphics_variation = settlement[2]
  end

  label(surface, "positions at ease", at(-17.5, -0.5), "right")
  label(surface, "positions throwing", at(-17.5, 7.5), "right")
  label(surface, "someone comes by every " .. passer_by_ticks / 60 .. " seconds", at(-7.5, 15.5))
  for i, worm in pairs(worms) do
    local x = -14 + (i - 1) * 4.5
    enemy(surface, worm, at(x, 0)).disabled_by_script = true
    enemy(surface, worm, at(x, 8))
    table.insert(storage.passer_by_spots, at(x, 14))
  end
end

-- The steel-plated bunker is the behemoth worm, and its reach is 48 tiles. Someone stands just
-- inside that, so the gunner stays ready and keeps throwing the long shot. A bottle thrown this
-- far arcs about ten tiles up; the station frame leaves that sky empty. The other stations only
-- show throws of a few tiles.
local bunker_reach = 48
local long_shot = 46

local function build_long_range(surface, at)
  label(surface, "steel-plated bunker", at(0, 4))
  enemy(surface, "behemoth-worm-turret", at(0, 0))

  local tiles = {}
  for x = 3, long_shot do
    table.insert(tiles, {name = "stone-path", position = at(x, 0)})
  end
  surface.set_tiles(tiles)

  for distance = 10, 40, 10 do
    label(surface, tostring(distance), at(distance, 2.2))
  end
  label(surface, long_shot .. " tiles", at(long_shot, 4))
  label(surface, "reach is " .. bunker_reach, at(long_shot, 5.8))
  target(surface, "character", at(long_shot, 0))
end

-- People fall and settlements and positions are destroyed, over and over.
local function build_deaths(surface, at)
  label(surface, "people falling", at(-12.5, -0.5), "right")
  label(surface, "ruins", at(-17.5, 7.5), "right")
  for column, tier in pairs(tiers) do
    label(surface, tier, at(column_x[column], -3.5))
    table.insert(storage.deaths.spots, {name = tier .. "-biter", position = at(column_x[column] - 1, 0)})
    table.insert(storage.deaths.spots, {name = tier .. "-spitter", position = at(column_x[column] + 1.5, 0)})
  end
  table.insert(storage.deaths.spots, {name = "biter-spawner", position = at(-14, 8)})
  table.insert(storage.deaths.spots, {name = "spitter-spawner", position = at(-7, 8)})
  for i, worm in pairs(worms) do
    table.insert(storage.deaths.spots, {name = worm, position = at(-1.5 + (i - 1) * 3.5, 8)})
  end
  storage.deaths.area = {at(-17, -2), at(14, 12)}
end

local stations =
{
  {caption = "Bottles", origin = {0, 0}, area = {{-24, -14}, {15, 11}}, build = build_bottles},
  {caption = "People", origin = {150, 0}, area = {{-26, -13}, {14, 16}}, build = build_people},
  {caption = "Settlements", origin = {300, 0}, area = {{-30, -12}, {8, 17}}, build = build_settlements},
  {caption = "Deaths", origin = {450, 0}, area = {{-26, -6}, {14, 12}}, build = build_deaths},
  {caption = "Long range", origin = {600, 0}, area = {{-10, -16}, {54, 8}}, build = build_long_range},
}
local deaths_station = 4

local function create_surface()
  local surface = game.create_surface(surface_name,
  {
    default_enable_all_autoplace_controls = false,
    autoplace_settings =
    {
      entity = {treat_missing_as_default = false, settings = {}},
      decorative = {treat_missing_as_default = false, settings = {}},
      tile = {treat_missing_as_default = false, settings = {["grass-1"] = {}}},
    },
  })
  surface.always_day = true
  for _, station in pairs(stations) do
    surface.request_to_generate_chunks(station.origin, 2)
  end
  surface.force_generate_chunk_requests()
  return surface
end

local function showroom()
  return game.surfaces[surface_name]
end

local function toggle_passers_by()
  if storage.passers_by then
    for _, passer_by in pairs(storage.passers_by) do
      if passer_by.valid then
        passer_by.destroy()
      end
    end
    storage.passers_by = nil
  else
    storage.passers_by = {}
    for _, spot in pairs(storage.passer_by_spots) do
      table.insert(storage.passers_by, target(showroom(), "character", spot))
    end
  end
end

local function replay_deaths()
  local area = storage.deaths.area
  for _, entity in pairs(showroom().find_entities_filtered{area = area, type = {"corpse", "unit", "unit-spawner", "turret"}}) do
    entity.destroy()
  end
  showroom().destroy_decoratives{area = area}
  for _, spot in pairs(storage.deaths.spots) do
    local entity = enemy(showroom(), spot.name, spot.position)
    -- Positions destroyed while at ease leave the wreck of a folded position.
    entity.disabled_by_script = true
    entity.die()
  end
end

local function set_night(night)
  storage.night = night
  showroom().always_day = not night
  if night then
    showroom().freeze_daytime = true
    showroom().daytime = 0.5
  end
end

-- Wide enough for the station buttons, including "Long range".
local panel_width = 580

-- Centres the station in the part of the screen the panel doesn't cover, zoomed to fit.
local function visit(player, index)
  local station = stations[index]
  local area, origin = station.area, station.origin
  local width, height = area[2][1] - area[1][1], area[2][2] - area[1][2]
  local resolution = player.display_resolution
  local reserved = panel_width * player.display_scale
  local zoom = 0.95 * math.min((resolution.width - reserved) / (32 * width), resolution.height / (32 * height))
  local x = origin[1] + (area[1][1] + area[2][1]) / 2 - reserved / (2 * 32 * zoom)
  local y = origin[2] + (area[1][2] + area[2][2]) / 2
  player.teleport({x, y}, surface_name)
  player.zoom = zoom
end

local function refresh_panel(player)
  local panel = player.gui.left["phm-showroom"]
  if not panel then
    return
  end
  for _, flow in pairs(panel.children) do
    for _, element in pairs(flow.children) do
      local tags = element.tags
      if tags.action == "speed" then
        element.toggled = tags.speed == storage.speed
      elseif tags.action == "light" then
        element.toggled = tags.night == storage.night
      end
    end
  end
end

local function build_panel(player)
  local panel = player.gui.left.add{type = "frame", name = "phm-showroom", direction = "vertical", caption = "People Hate Me showroom"}
  panel.add{type = "label", caption = "Fly around with WASD and zoom with the mouse wheel."}
  local function row(title)
    panel.add{type = "label", caption = "[font=default-bold]" .. title .. "[/font]"}
    return panel.add{type = "flow", direction = "horizontal"}
  end

  local go = row("Go to")
  for i, station in pairs(stations) do
    go.add{type = "button", caption = station.caption, tags = {action = "visit", station = i}}
  end
  local speed = row("Speed")
  for _, choice in pairs(speeds) do
    speed.add{type = "button", caption = choice.caption, tags = {action = "speed", speed = choice.value}}
  end
  local light = row("Light")
  light.add{type = "button", caption = "Day", tags = {action = "light", night = false}}
  light.add{type = "button", caption = "Night", tags = {action = "light", night = true}}
  local deaths = panel.add{type = "flow", direction = "horizontal"}
  deaths.add{type = "button", caption = "Replay the deaths now", tags = {action = "replay"}}
  refresh_panel(player)
end

script.on_init(function()
  storage.attackers, storage.walkers, storage.passer_by_spots = {}, {}, {}
  storage.deaths = {spots = {}}
  storage.speed, storage.night = 1, false

  game.map_settings.pollution.enabled = false
  game.map_settings.enemy_expansion.enabled = false
  game.create_force("showroom-target")
  game.forces["enemy"].set_cease_fire("player", true)
  game.forces["player"].set_cease_fire("enemy", true)

  local surface = create_surface()
  for _, station in pairs(stations) do
    local origin = station.origin
    station.build(surface, function(x, y) return {origin[1] + x, origin[2] + y} end)
  end
  toggle_passers_by()
  replay_deaths()
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if player.character then
    player.character.destroy()
  end
  player.set_controller{type = defines.controllers.spectator}
  build_panel(player)
  visit(player, 1)
end)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.get_player(event.player_index)
  local tags = event.element.tags
  if tags.action == "visit" then
    visit(player, tags.station)
  elseif tags.action == "speed" then
    storage.speed = tags.speed
    game.speed = tags.speed
  elseif tags.action == "light" then
    set_night(tags.night)
  elseif tags.action == "replay" then
    visit(player, deaths_station)
    replay_deaths()
  end
  refresh_panel(player)
end)

script.on_event(defines.events.on_ai_command_completed, function(event)
  local walker = storage.walkers[event.unit_number]
  if walker and walker.unit.valid then
    walker.from, walker.to = walker.to, walker.from
    walk(walker)
    return
  end
  local attacker = storage.attackers[event.unit_number]
  if attacker and attacker.unit.valid and attacker.target.valid then
    attack(attacker.unit, attacker.target)
  end
end)

script.on_event(defines.events.on_entity_damaged, function(event)
  event.entity.health = event.entity.max_health
end, {{filter = "name", name = "character"}, {filter = "name", name = "stone-wall"}})

script.on_nth_tick(passer_by_ticks, toggle_passers_by)
script.on_nth_tick(replay_ticks, replay_deaths)
