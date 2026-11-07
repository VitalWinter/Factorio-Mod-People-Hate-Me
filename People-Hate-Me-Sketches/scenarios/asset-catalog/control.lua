-- Every base-game asset that could be repurposed for the people's settlements, laid out with labels,
-- followed by combinations of real pieces and kitbashed sprites (cropped, scaled, tinted, layered).
-- tools/screenshot.ps1 asset-catalog runs it and collects the screenshots.

local area = {{-27, -58}, {27, 58}}
local done_tick = 240

local screenshots =
{
  {tick = 150, path = "buildings.png", position = {0, -47}, resolution = {2944, 1088}},
  {tick = 155, path = "walls-and-ruins.png", position = {0, -27}, resolution = {2944, 1408}},
  {tick = 160, path = "nature.png", position = {0, -6.5}, resolution = {2944, 1088}},
  {tick = 165, path = "ground.png", position = {0, 15.5}, resolution = {2944, 1632}},
  {tick = 170, path = "combinations.png", position = {0, 44}, resolution = {2944, 1568}},
  {tick = 175, path = "combinations-night.png", position = {0, 44}, resolution = {2944, 1568}, daytime = 0.5},
  {tick = 180, path = "buildings-night.png", position = {0, -47}, resolution = {2944, 1088}, daytime = 0.5},
  {tick = 185, path = "kitbash.png", position = {0, 49.5}, resolution = {2944, 640}},
  {tick = 190, path = "kitbash-night.png", position = {0, 49.5}, resolution = {2944, 640}, daytime = 0.5},
}

local function text(surface, value, position, options)
  options = options or {}
  rendering.draw_text
  {
    text = value,
    surface = surface,
    target = position,
    color = options.color or {1, 1, 1},
    scale = options.scale or 1,
    alignment = options.alignment or "center",
  }
end

local function heading(surface, value, y)
  text(surface, value, {-22.5, y}, {scale = 2, color = {1, 0.85, 0.4}, alignment = "left"})
end

local function place(surface, name, position, options)
  local spec = {name = name, position = position, force = "neutral"}
  for key, value in pairs(options or {}) do
    spec[key] = value
  end
  return surface.create_entity(spec)
end

local function person(surface, name, position)
  local unit = surface.create_entity{name = name, position = position, force = "enemy"}
  unit.commandable.set_command{type = defines.command.stop, distraction = defines.distraction.none}
  unit.disabled_by_script = true
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

local function tiles(surface, name, left_top, width, height)
  local list = {}
  for dx = 0, width - 1 do
    for dy = 0, height - 1 do
      list[#list + 1] = {name = name, position = {math.floor(left_top[1]) + dx, math.floor(left_top[2]) + dy}}
    end
  end
  surface.set_tiles(list)
end

local function ore(surface, name, x, y)
  for dx = -1, 0 do
    for dy = -1, 0 do
      place(surface, name, {x + dx + 0.5, y + dy + 0.5}, {amount = 5000})
    end
  end
end

local function sprite(surface, name, position)
  rendering.draw_sprite{sprite = name, surface = surface, target = position, render_layer = "object"}
end

local function glow(surface, position, scale)
  rendering.draw_light{sprite = "utility/light_medium", surface = surface, target = position, scale = scale, intensity = 0.6, color = {1, 0.7, 0.4}}
end

-- Shorthands for catalogue entries.
local function entity(name, label, options)
  return {label = label or name, build = function(surface, x, y) place(surface, name, {x, y}, options) end}
end

local function remnants(name)
  return entity(name .. "-remnants", name)
end

local function decorative(name, cluster)
  return
  {
    label = name,
    build = function(surface, x, y)
      decorate(surface, name, {x, y})
      if cluster then
        decorate(surface, name, {x - 1, y})
        decorate(surface, name, {x + 1, y + 1})
        decorate(surface, name, {x, y - 1})
      end
    end,
  }
end

local function tile_patch(name)
  return {label = name, build = function(surface, x, y) tiles(surface, name, {x - 1, y - 1}, 3, 3) end}
end

local function line(name, from, to, y_offset, options)
  return function(surface, x, y)
    for dx = from, to do
      place(surface, name, {x + dx + 0.5, y + (y_offset or 0.5)}, options)
    end
  end
end

local groups =
{
  {
    heading = "Buildings and objects",
    y = -55,
    rows =
    {
      {
        y = -50, slot = 5.5, label_offset = 2.6,
        entries =
        {
          entity("stone-furnace", "stone-furnace (cold)"),
          {label = "stone-furnace (lit)", build = function(surface, x, y) hearth(surface, {x, y}) end},
          entity("wooden-chest"),
          entity("iron-chest"),
          entity("market"),
          entity("burner-mining-drill"),
          entity("boiler"),
        },
      },
      {
        y = -43, slot = 5.5, label_offset = 2.6,
        entries =
        {
          entity("small-electric-pole", "small-electric-pole (wooden)"),
          entity("small-lamp"),
          entity("storage-tank"),
          entity("car"),
          entity("crash-site-chest-1"),
          entity("crash-site-spaceship-wreck-medium-1", "crash-site wreck (medium)"),
          entity("crash-site-spaceship-wreck-big-1", "crash-site wreck (big)"),
        },
      },
    },
  },
  {
    heading = "Walls, fences, rails and pipes",
    y = -38,
    rows =
    {
      {
        y = -34, slot = 7.5, label_offset = 2,
        entries =
        {
          {label = "stone-wall", build = line("stone-wall", -2, 2)},
          {
            label = "wall corner",
            build = function(surface, x, y)
              line("stone-wall", -2, 0, -0.5)(surface, x, y)
              place(surface, "stone-wall", {x + 0.5, y + 0.5})
              place(surface, "stone-wall", {x + 0.5, y + 1.5})
            end,
          },
          {
            label = "gate",
            build = function(surface, x, y)
              line("stone-wall", -3, -2)(surface, x, y)
              line("gate", -1, 0, 0.5, {direction = defines.direction.east})(surface, x, y)
              line("stone-wall", 1, 2)(surface, x, y)
            end,
          },
          {label = "pipe", build = line("pipe", -2, 2)},
          {
            label = "straight-rail",
            build = function(surface, x, y)
              for dx = -2, 2, 2 do
                place(surface, "straight-rail", {x + dx, y}, {direction = defines.direction.east})
              end
            end,
          },
          {
            label = "wooden poles in a row",
            build = function(surface, x, y)
              for dx = -3, 3, 2 do
                place(surface, "small-electric-pole", {x + dx + 0.5, y + 0.5})
              end
            end,
          },
        },
      },
    },
  },
  {
    heading = "Ruins (each building's remnants, and scorch marks)",
    y = -29,
    rows =
    {
      {
        y = -25, slot = 4.4, label_offset = 1.8,
        entries =
        {
          remnants("stone-furnace"), remnants("wooden-chest"), remnants("iron-chest"),
          remnants("wall"), remnants("gate"), remnants("small-electric-pole"),
          remnants("lamp"), remnants("burner-mining-drill"), remnants("boiler"),
        },
      },
      {
        y = -19, slot = 4.6, label_offset = 2.2,
        entries =
        {
          remnants("gun-turret"), remnants("car"), remnants("storage-tank"),
          remnants("big"), remnants("medium"), remnants("small"),
          entity("small-scorchmark"), entity("medium-scorchmark"), entity("big-scorchmark"),
        },
      },
    },
  },
  {
    heading = "Trees, rocks, ore and water",
    y = -14,
    rows =
    {
      {
        y = -8, slot = 4.4, label_offset = 1.4,
        entries =
        {
          entity("tree-01"), entity("tree-02"), entity("tree-03"), entity("tree-05"), entity("tree-06-brown"),
          entity("tree-08-red"), entity("dry-tree"), entity("dead-tree-desert"), entity("dead-grey-trunk"),
        },
      },
      {
        y = -1, slot = 4.8, label_offset = 2,
        entries =
        {
          entity("huge-rock"), entity("big-rock"), entity("big-sand-rock"),
          {label = "stone (ore)", build = function(surface, x, y) ore(surface, "stone", x, y) end},
          {label = "coal (ore)", build = function(surface, x, y) ore(surface, "coal", x, y) end},
          {label = "iron-ore", build = function(surface, x, y) ore(surface, "iron-ore", x, y) end},
          {label = "copper-ore", build = function(surface, x, y) ore(surface, "copper-ore", x, y) end},
          {
            label = "water and fish",
            build = function(surface, x, y)
              tiles(surface, "water", {x - 1, y - 1}, 3, 3)
              place(surface, "fish", {x + 0.5, y + 0.5})
            end,
          },
        },
      },
    },
  },
  {
    heading = "Ground decorations and tiles",
    y = 4,
    rows =
    {
      {
        y = 8, slot = 5.2, label_offset = 2,
        entries =
        {
          decorative("dark-mud-decal"), decorative("light-mud-decal"), decorative("cracked-mud-decal"),
          decorative("sand-decal"), decorative("brown-carpet-grass", true), decorative("brown-fluff", true),
          decorative("garballo", true), decorative("muddy-stump", true),
        },
      },
      {
        y = 13, slot = 5.2, label_offset = 1.8,
        entries =
        {
          decorative("tiny-rock", true), decorative("small-rock", true), decorative("medium-rock"),
          decorative("green-pita", true), decorative("green-pita-mini", true), decorative("green-croton", true),
          decorative("green-bush-mini", true), decorative("red-croton", true),
        },
      },
      {
        y = 18, slot = 4.6, label_offset = 2.2,
        entries =
        {
          tile_patch("stone-path"), tile_patch("concrete"), tile_patch("landfill"), tile_patch("dirt-1"),
          tile_patch("dirt-4"), tile_patch("dirt-6"), tile_patch("dry-dirt"), tile_patch("sand-1"), tile_patch("red-desert-1"),
        },
      },
      {
        y = 24, slot = 4.6, label_offset = 2.2,
        entries =
        {
          tile_patch("grass-2"), tile_patch("grass-4"), tile_patch("sand-3"), tile_patch("red-desert-3"),
          tile_patch("nuclear-ground"), tile_patch("water-mud"), tile_patch("water-shallow"),
        },
      },
    },
  },
  {
    heading = "Combinations of real pieces",
    y = 31,
    rows =
    {
      {
        y = 37, slot = 11, label_offset = 4,
        entries =
        {
          {
            label = "campfire",
            build = function(surface, x, y)
              place(surface, "crash-site-fire-flame", {x, y})
              for dx = -1, 1 do
                for dy = -1, 1 do
                  if dx ~= 0 or dy ~= 0 then
                    decorate(surface, "tiny-rock", {x + dx, y + dy})
                  end
                end
              end
              person(surface, "small-biter", {x - 1.8, y + 0.3})
              person(surface, "small-spitter", {x + 1.8, y - 0.2})
            end,
          },
          {
            label = "crop field",
            build = function(surface, x, y)
              tiles(surface, "dirt-6", {x - 3, y - 2}, 7, 5)
              for dx = -3, 3 do
                decorate(surface, "green-pita-mini", {x + dx, y - 2})
                decorate(surface, "green-pita-mini", {x + dx, y})
                decorate(surface, "green-pita-mini", {x + dx, y + 2})
              end
              person(surface, "small-biter", {x + 3.5, y - 0.5})
            end,
          },
          {
            label = "stockpile",
            build = function(surface, x, y)
              ore(surface, "stone", x - 1.5, y)
              place(surface, "coal", {x + 0.5, y + 0.5}, {amount = 5000})
              place(surface, "wooden-chest", {x + 1.5, y - 1.5})
              place(surface, "wooden-chest", {x + 2.5, y - 1.5})
              place(surface, "wooden-chest", {x + 1.5, y + 1.5})
              decorate(surface, "muddy-stump", {x + 3, y + 1})
              decorate(surface, "muddy-stump", {x - 3, y - 2})
              person(surface, "medium-biter", {x - 0.5, y - 2})
            end,
          },
          {
            label = "village square",
            build = function(surface, x, y)
              tiles(surface, "stone-path", {x - 4, y - 3}, 8, 7)
              place(surface, "market", {x - 1.5, y - 0.5})
              hearth(surface, {x + 2, y - 1})
              place(surface, "wooden-chest", {x + 1.5, y + 1.5})
              place(surface, "wooden-chest", {x + 2.5, y + 1.5})
              person(surface, "small-spitter", {x + 0.5, y + 2.5})
              person(surface, "medium-biter", {x - 3, y + 2.2})
            end,
          },
        },
      },
    },
  },
  {
    heading = "Kitbashed building blocks (full designs are in the encampment sketch)",
    y = 43,
    rows =
    {
      {
        y = 49, slot = 8, label_offset = 3.2,
        entries =
        {
          {
            label = "palisade: cut tree trunks",
            build = function(surface, x, y) sprite(surface, "phm-sketch-palisade", {x, y}) end,
          },
          {
            label = "earth bank: desert rocks",
            build = function(surface, x, y) sprite(surface, "phm-sketch-earth-bank", {x, y}) end,
          },
          {
            label = "campfire: stones, planks, flame",
            build = function(surface, x, y)
              sprite(surface, "phm-sketch-campfire", {x, y})
              glow(surface, {x, y}, 1)
              person(surface, "small-spitter", {x - 1.3, y + 0.3})
              person(surface, "small-biter", {x + 1.3, y - 0.2})
            end,
          },
        },
      },
    },
  },
}

local function prepare_ground(surface)
  surface.request_to_generate_chunks({0, 0}, 3)
  surface.force_generate_chunk_requests()

  for _, existing in pairs(surface.find_entities_filtered{area = area}) do
    if existing.valid and existing.type ~= "character" then
      existing.destroy()
    end
  end
  surface.destroy_decoratives{area = area}
  tiles(surface, "grass-1", area[1], area[2][1] - area[1][1], area[2][2] - area[1][2])

  surface.always_day = true
  game.map_settings.pollution.enabled = false
  game.map_settings.enemy_expansion.enabled = false
end

local function build_catalog()
  local surface = game.surfaces["nauvis"]
  prepare_ground(surface)
  game.forces["enemy"].set_cease_fire("player", true)
  game.forces["player"].set_cease_fire("enemy", true)

  for _, group in pairs(groups) do
    heading(surface, group.heading, group.y)
    for _, row in pairs(group.rows) do
      local first_x = -(#row.entries - 1) * row.slot / 2
      for index, entry in pairs(row.entries) do
        local x = math.floor(first_x + (index - 1) * row.slot)
        entry.build(surface, x, row.y)
        text(surface, entry.label, {x, row.y + row.label_offset})
      end
    end
  end
end

script.on_init(build_catalog)

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
        zoom = 2,
        resolution = shot.resolution,
        path = "people-hate-me/asset-catalog/" .. shot.path,
        hide_health_bars = true,
        force_render = true,
        daytime = shot.daytime or 0,
      }
    end
  end
  if event.tick == done_tick then
    helpers.write_file("people-hate-me/asset-catalog/done.txt", "done")
  end
end)
