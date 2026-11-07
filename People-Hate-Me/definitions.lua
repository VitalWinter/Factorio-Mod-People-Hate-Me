-- How each enemy is drawn as a person. Read by both the data stage and control.lua.

local definitions = {}

-- scale:           body size relative to the engineer, kept within +/-20%
-- armor:           character_animations set drawn over the base body, like the engineer's armor
-- armor_tint:      darkens the armor plating itself
-- armor_icon:      item icon used as the tier badge on the enemy's icon
-- footstep_volume: min and max volume of each footstep
definitions.tiers =
{
  small    = {scale = 0.85, footstep_volume = {0.2, 0.35}},
  medium   = {scale = 0.95, armor = "level2addon", armor_icon = "heavy-armor", footstep_volume = {0.25, 0.4}},
  big      = {scale = 1.05, armor = "level3addon", armor_icon = "power-armor", footstep_volume = {0.35, 0.5}},
  behemoth = {scale = 1.15, armor = "level3addon", armor_icon = "power-armor-mk2", armor_tint = {0.42, 0.42, 0.48}, footstep_volume = {0.45, 0.6}},
}

-- role: "melee" people swing a pickaxe, "ranged" people aim a gun
-- tint: clothing colour, applied where the engineer shows the player colour
definitions.people =
{
  ["small-biter"]      = {tier = "small",    role = "melee",  tint = {0.78, 0.62, 0.42}},
  ["medium-biter"]     = {tier = "medium",   role = "melee",  tint = {0.72, 0.26, 0.22}},
  ["big-biter"]        = {tier = "big",      role = "melee",  tint = {0.26, 0.36, 0.78}},
  ["behemoth-biter"]   = {tier = "behemoth", role = "melee",  tint = {0.24, 0.52, 0.16}},

  ["small-spitter"]    = {tier = "small",    role = "ranged", tint = {0.92, 0.56, 0.12}},
  ["medium-spitter"]   = {tier = "medium",   role = "ranged", tint = {0.74, 0.22, 0.48}},
  ["big-spitter"]      = {tier = "big",      role = "ranged", tint = {0.12, 0.56, 0.60}},
  ["behemoth-spitter"] = {tier = "behemoth", role = "ranged", tint = {0.52, 0.70, 0.12}},
}

return definitions
