--

data.raw["container"]["iron-chest"].max_health = 1000

--[[
local char = data.raw["character"]
local corpse = data.raw["character-corpse"]
]]

for k, unit in pairs(data.raw["unit"]) do
    if (string.find(k, "biter") or string.find(k, "spitter")) and unit.collision_box then
        if settings.startup["rampant--enableSwarm"].value then
            unit.collision_box = {
                {unit.collision_box[1][1] * 0.70, unit.collision_box[1][2] * 0.70},
                {unit.collision_box[2][1] * 0.70, unit.collision_box[2][2] * 0.70}
            }
        end

        unit.affected_by_tiles = settings.startup["rampant--unitsAffectedByTiles"].value

        unit.ai_settings = {
            destroy_when_commands_fail = false,
            allow_try_return_to_spawner = true
        }
    end
end

if settings.startup["rampant--enableShrinkNestsAndWorms"].value then
    for k, unit in pairs(data.raw["unit-spawner"]) do
        if (string.find(k, "biter") or string.find(k, "spitter") or string.find(k, "hive")) and unit.collision_box then
            unit.collision_box = {
                {unit.collision_box[1][1] * 0.75, unit.collision_box[1][2] * 0.75},
                {unit.collision_box[2][1] * 0.75, unit.collision_box[2][2] * 0.75}
            }
        end
    end

    for k, unit in pairs(data.raw["turret"]) do
        if string.find(k, "worm") and unit.collision_box then
            unit.collision_box = {
                {unit.collision_box[1][1] * 0.75, unit.collision_box[1][2] * 0.75},
                {unit.collision_box[2][1] * 0.75, unit.collision_box[2][2] * 0.75}
            }
        end
    end
end