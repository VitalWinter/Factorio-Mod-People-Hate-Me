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
