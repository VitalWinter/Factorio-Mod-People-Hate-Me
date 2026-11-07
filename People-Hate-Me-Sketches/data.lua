-- Kitbash experiments: base-game sprites cropped, scaled, tinted and layered into new pictures.
-- The sketch scenarios draw these with rendering.draw_sprite; nothing here is part of the real mod.
-- Shifts and scales start from the base game's own definitions, so a piece scaled by k keeps its
-- footing when its shift is multiplied by k too.

require("util")

local function piece(base, k, extra)
  local layer = util.merge{base, extra or {}}
  layer.scale = (base.scale or 1) * k
  layer.shift = util.mul_shift(base.shift or {0, 0}, k)
  if extra and extra.offset then
    layer.shift = {layer.shift[1] + extra.offset[1], layer.shift[2] + extra.offset[2]}
    layer.offset = nil
  end
  return layer
end

local furnace =
{
  filename = "__base__/graphics/entity/stone-furnace/stone-furnace.png",
  width = 151, height = 146, shift = util.by_pixel(-0.25, 6), scale = 0.5,
}
local furnace_shadow =
{
  filename = "__base__/graphics/entity/stone-furnace/stone-furnace-shadow.png",
  width = 164, height = 74, shift = util.by_pixel(14.5, 13), scale = 0.5, draw_as_shadow = true,
}
-- The first frame of the furnace's fire animation.
local furnace_fire =
{
  filename = "__base__/graphics/entity/stone-furnace/stone-furnace-fire.png",
  x = 0, y = 0, width = 41, height = 100, shift = util.by_pixel(-0.75, 5.5), scale = 0.5, draw_as_glow = true,
}
-- The wall sheet holds two variations side by side; this crops the first.
local wall_single =
{
  filename = "__base__/graphics/entity/wall/wall-single.png",
  x = 0, y = 0, width = 64, height = 86, shift = util.by_pixel(0, -5), scale = 0.5,
}
local wall_single_shadow =
{
  filename = "__base__/graphics/entity/wall/wall-single-shadow.png",
  width = 98, height = 60, shift = util.by_pixel(10, 17), scale = 0.5, draw_as_shadow = true,
}
local chest =
{
  filename = "__base__/graphics/entity/wooden-chest/wooden-chest.png",
  width = 62, height = 72, shift = util.by_pixel(0.5, -2), scale = 0.5,
}
local chest_shadow =
{
  filename = "__base__/graphics/entity/wooden-chest/wooden-chest-shadow.png",
  width = 104, height = 40, shift = util.by_pixel(10, 6.5), scale = 0.5, draw_as_shadow = true,
}
-- The pole sheet holds four directions side by side; this crops the first.
local pole =
{
  filename = "__base__/graphics/entity/small-electric-pole/small-electric-pole.png",
  x = 0, y = 0, width = 72, height = 220, shift = util.by_pixel(1.5, -42.5), scale = 0.5,
}
local market =
{
  filename = "__base__/graphics/entity/market/market.png",
  width = 156, height = 127, shift = {0.95, 0.2},
}

local warm_stone = {0.8, 0.72, 0.62}

data:extend
{
  {
    type = "sprite",
    name = "phm-sketch-hut",
    layers =
    {
      piece(furnace_shadow, 1.5),
      piece(furnace, 1.5, {tint = warm_stone}),
      piece(furnace_fire, 1.5),
    },
  },
  {
    type = "sprite",
    name = "phm-sketch-gravestone",
    layers =
    {
      piece(wall_single_shadow, 0.4),
      piece(wall_single, 0.4, {tint = {0.75, 0.74, 0.7}}),
    },
  },
  {
    type = "sprite",
    name = "phm-sketch-market-wood",
    layers = {piece(market, 1, {tint = {0.75, 0.58, 0.4}})},
  },
  {
    type = "sprite",
    name = "phm-sketch-crate-stack",
    layers =
    {
      piece(chest_shadow, 1.6),
      piece(chest, 1, {offset = {-0.45, 0.25}}),
      piece(chest, 1, {offset = {0.45, 0.25}}),
      piece(chest, 1, {offset = {0, -0.35}}),
    },
  },
  {
    type = "sprite",
    name = "phm-sketch-stake",
    layers = {piece(pole, 0.6, {tint = {0.85, 0.78, 0.7}})},
  },
}
