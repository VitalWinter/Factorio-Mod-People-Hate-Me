-- Draws a person from the engineer's own sprites (__base__/graphics/entity/character), dressed
-- in a look from definitions.lua. Used for the units and for the gunners of defensive positions.

local util = require("util")
local definitions = require("definitions")

if not character_animations then
  require("__base__.prototypes.entity.character-animations")
end

local person = {}

-- A person's definition with their tier's look filled in.
function person.look(definition)
  return util.merge({definitions.tiers[definition.tier], definition})
end

-- keep_runtime_tint leaves the colour mask to be tinted per entity at runtime
-- (LuaEntity.color), which is how corpses get individual shades.
local function dress(layer, look, body_tint, options)
  local piece = table.deepcopy(layer)
  piece.scale = (piece.scale or 1) * look.scale
  piece.shift = util.mul_shift(piece.shift, look.scale)
  if options.offset then
    piece.shift = util.add_shift(piece.shift, options.offset)
  end
  piece.usage = "enemy"
  if piece.apply_runtime_tint then
    if not options.keep_runtime_tint then
      piece.apply_runtime_tint = false
      piece.tint = look.tint
    end
  elseif body_tint and not piece.draw_as_shadow then
    piece.tint = body_tint
  end
  -- The engineer's sheets hold one direction per row, so a single row is one facing.
  if options.facing then
    assert(piece.filename and piece.direction_count == 8, "can only pick a facing from a one-file, 8-direction sheet")
    piece.y = (piece.y or 0) + options.facing * piece.height
    piece.direction_count = 1
  end
  return piece
end

-- Builds one pose (e.g. "running") for a person, layered like the engineer:
-- the body and any armor with their colour masks first, then all of their shadows.
-- options: keep_runtime_tint; animation_speed; offset, a shift in tiles; facing, a direction
-- 0 to 7 (clockwise from north) to keep only that one; frame_sequence, the frames to play.
function person.pose(look, name, options)
  options = options or {}
  local sets = {{name = "level1"}}
  if look.armor then
    table.insert(sets, {name = look.armor, body_tint = look.armor_tint})
  end

  local layers, shadows = {}, {}
  for _, set in pairs(sets) do
    local animations = character_animations[set.name]
    for _, suffix in pairs({"", "_mask"}) do
      local layer = animations[name .. suffix]
      if layer then
        table.insert(layers, dress(layer, look, set.body_tint, options))
      end
    end
    local shadow = animations[name .. "_shadow"]
    if shadow then
      table.insert(shadows, dress(shadow, look, nil, options))
    end
  end
  for _, shadow in pairs(shadows) do
    table.insert(layers, shadow)
  end

  for _, layer in pairs(layers) do
    layer.animation_speed = options.animation_speed or layer.animation_speed
    layer.frame_sequence = options.frame_sequence or layer.frame_sequence
  end
  return {layers = layers}
end

-- A throw, cut from the engineer's pickaxe swing ("mining_tool", 26 frames): the arm draws back
-- slowly (frames 1 to 6) and holds overhead for a moment, comes forward to let go, and
-- straightens up, leaving out the strike into the ground (frames 19 to 23). Between throws they
-- stay ready, swaying a little.
person.throw =
{
  wind_up = {1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 10, 13, 17},
  release = {18},
  recover = {24, 25, 26},
  ready = {1, 2, 3, 2},
}

-- Joins frame sequences, each repeated as often as it's given.
function person.frames(...)
  local sequence = {}
  for _, part in pairs{...} do
    for _, frame in pairs(part) do
      table.insert(sequence, frame)
    end
  end
  return sequence
end

-- Where a thrown bottle leaves the hand, raised and forward, for each facing direction.
function person.hand_offsets(scale, offset)
  offset = offset or {0, 0}
  local offsets = {}
  for i = 0, 15 do
    local orientation = i / 16
    local angle = orientation * 2 * math.pi
    offsets[i + 1] = {orientation, {offset[1] + 0.4 * scale * math.sin(angle), offset[2] - scale * (1.5 + 0.3 * math.cos(angle))}}
  end
  return offsets
end

-- The engineer's death sheet holds two different fallen poses side by side.
-- Each variation is a list of layers.
function person.fallen(look, offset)
  local variations = {}
  for frame = 0, 1 do
    local body = person.pose(look, "dead", {keep_runtime_tint = true, offset = offset})
    for _, layer in pairs(body.layers) do
      layer.frame_count = 1
      layer.x = frame * layer.width
    end
    table.insert(variations, body.layers)
  end
  return variations
end

return person
