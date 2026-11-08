-- How a corpse leaves. A bug corpse rots through 24 frames, and each frame is held for 6
-- seconds (decay_frame_transition_duration on the base corpses), so the cleanup takes about
-- two and a half minutes and the body is gone at the end of it. People, ruins and wrecks have
-- no rot sprites. They fade out over that same time instead, which is the corpse prototype's
-- own fade (time_before_shading_off): it starts that long before removal and reaches nothing
-- as the corpse is removed.
--
-- Checked headless: time_before_removed is a plain tick count. Corpses set to 600 ticks lasted
-- 600 ticks at dying_speed 0.5, 1 and 2, and a real body was still there after 12000 ticks,
-- consistent with the 15 minutes the base prototypes ask for.

local corpses = {}

-- with_ground also fades the scorch or paving with the structure. A person's blood puddle is
-- left alone: it keeps the timing the bug blood had, and is gone after about a minute.
local fade_ticks = 24 * 6 * 60

function corpses.fade(corpse, with_ground)
  local fade = math.min(fade_ticks, corpse.time_before_removed - 60)
  corpse.time_before_shading_off = fade
  if with_ground then
    corpse.ground_patch_fade_out_start = corpse.time_before_removed - fade
    corpse.ground_patch_fade_out_duration = fade
  end
end

return corpses
