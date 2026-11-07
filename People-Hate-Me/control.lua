local definitions = require("definitions")

-- Every fallen person gets their own shade of their group's clothing colour,
-- so the dead read as individuals rather than copies.
local function individual_shade(tint)
  local brightness = 0.75 + 0.4 * math.random()
  local shade = {}
  for i = 1, 3 do
    local jitter = (math.random() - 0.5) * 0.12
    shade[i] = math.min(1, math.max(0, tint[i] * brightness + jitter))
  end
  return shade
end

-- A unit's own look, or the look of the gunner who manned a defensive position.
local function clothing(name)
  local position = definitions.positions[name]
  local person = definitions.people[position and position.gunner or name]
  return person and person.tint
end

script.on_event(defines.events.on_post_entity_died, function(event)
  local tint = clothing(event.prototype.name)
  if not tint or not event.corpses then
    return
  end
  for _, corpse in pairs(event.corpses) do
    if corpse.valid and corpse.type == "corpse" then
      corpse.color = individual_shade(tint)
    end
  end
end, {{filter = "type", type = "unit"}, {filter = "type", type = "turret"}})
