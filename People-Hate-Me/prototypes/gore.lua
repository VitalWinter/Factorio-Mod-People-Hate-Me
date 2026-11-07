-- Recolours the blood and gore that enemies spray when hit or killed, so it reads as human.
-- These particles are only used by enemies (biters, spitters, worms and their hit effects).

local gore_tints =
{
  ["blood-particle"]                   = {1, 0.12, 0.1},
  ["blood-particle-small"]             = {1, 0.12, 0.1},
  ["blood-particle-lower-layer"]       = {1, 0.12, 0.1},
  ["blood-particle-lower-layer-small"] = {1, 0.12, 0.1},
  ["blood-particle-carpet"]            = {1, 0.12, 0.1},
  ["blood-particle-carpet-small"]      = {1, 0.12, 0.1},

  ["guts-entrails-particle-small-medium"] = {0.85, 0.32, 0.3},
  ["guts-entrails-particle-big"]          = {0.85, 0.32, 0.3},

  -- Translucent splashes; the low alpha is what makes them read as liquid.
  ["acid-particle"]            = {0.25, 0.02, 0.02, 0.2},
  ["internal-fluids-particle"] = {0.3, 0.03, 0.03, 0.314},
}

local function tint_pictures(pictures, tint)
  if pictures.sheet then
    pictures.sheet.tint = tint
  elseif pictures.sheets then
    for _, sheet in pairs(pictures.sheets) do
      sheet.tint = tint
    end
  elseif pictures.filename or pictures.filenames or pictures.stripes then
    pictures.tint = tint
  else
    for _, variation in pairs(pictures) do
      tint_pictures(variation, tint)
    end
  end
end

for name, tint in pairs(gore_tints) do
  local particle = data.raw["optimized-particle"][name]
  if particle and particle.pictures then
    tint_pictures(particle.pictures, tint)
  end
end

-- With the gore setting off, deaths still bleed but no flesh is thrown.
-- These particles are only created by the enemies' death explosions.
if settings.startup["people-hate-me-gore"].value then return end

local flesh_particles =
{
  ["guts-entrails-particle-small-medium"] = true,
  ["guts-entrails-particle-big"]          = true,
  ["guts-entrails-particle-spawner"]      = true,
}

local function is_flesh(effect)
  return type(effect) == "table" and effect.type == "create-particle" and flesh_particles[effect.particle_name]
end

-- Triggers nest items, deliveries and effects, each either a single table or a list of them.
local function remove_flesh(node)
  if type(node) ~= "table" then return end
  if node[1] then
    for i = #node, 1, -1 do
      if is_flesh(node[i]) then
        table.remove(node, i)
      else
        remove_flesh(node[i])
      end
    end
  else
    for key, child in pairs(node) do
      if is_flesh(child) then
        node[key] = nil
      else
        remove_flesh(child)
      end
    end
  end
end

for _, explosion in pairs(data.raw.explosion) do
  remove_flesh(explosion.created_effect)
end
