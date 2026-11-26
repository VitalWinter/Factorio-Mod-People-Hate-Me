"""Checks that the mod only changes how the game looks and sounds (run through tools/parity.ps1).

Usage: parity.py <allowlist> <base dump> <mod dump> [<mod dump> ...]

The dumps are data-raw-dump.json files from `factorio --dump-data`. Each prototype is reduced to
its gameplay: everything listed under PRESENTATION is removed, and so is every trigger effect
that only shows or plays something. What's left in each mod dump must match the base dump. A
difference passes only if a line in the allowlist matches it; the allowlist records each
reviewed deviation and the reason it's accepted. Entries whose reason starts with OPEN are
waiting for the owner's decision: they pass, but are listed on every run.

Prototypes the mod adds must be presentation (a corpse, a particle, an explosion that only shows
things), and it may not remove any.
"""

import fnmatch
import json
import sys

# Prototype types that only show or play something. They're not compared at all.
PRESENTATION_TYPES = {
    "corpse", "optimized-particle", "particle-source", "trivial-smoke", "animation", "sprite",
    "sound", "ambient-sound", "utility-sprites", "utility-sounds", "gui-style", "font",
    "mouse-cursor",
}
# Of those, the ones that are entities, which a trigger can create.
PRESENTATION_ENTITY_TYPES = {"corpse", "particle-source"}

# Fields removed wherever they appear: what a thing looks or sounds like, and nothing else.
# Anything not listed here counts as gameplay. Add a field only if the game never reads it for
# anything but drawing or sound.
PRESENTATION = {
    # pictures, at any depth
    "animation", "animations", "picture", "pictures", "sprite", "sprites", "sheet", "sheets",
    "layers", "filename", "filenames", "stripes", "icon", "icons", "icon_size",
    "icon_draw_specification", "icons_positioning", "graphics_set", "integration",
    "integration_patch", "integration_patch_render_layer", "water_reflection", "shadow",
    "light", "color", "tint", "render_layer", "secondary_draw_order",
    "factoriopedia_simulation", "localised_name", "localised_description",
    # sounds
    "sound", "sounds", "working_sound", "dying_sound", "walking_sound", "cyclic_sound",
    "starting_attack_sound", "preparing_sound", "prepared_sound", "prepared_alternative_sound",
    "folding_sound", "impact_category", "running_sound_animation_positions",
    # units: what plays while walking and attacking, and where hits and stickers are drawn. A
    # spitter's attack lands on the same tick whatever its attacking frame sequence (measured).
    "run_animation", "distance_per_frame", "alternative_attacking_frame_sequence",
    "hit_visualization_box", "sticker_box", "random_corpse_variation",
    # turrets: how the state animations are drawn, and how fast the endless folded one plays. A
    # worm wakes and hits on the same tick whatever its folded speed (measured, 0.001 to 0.01).
    "folded_animation", "preparing_animation", "prepared_animation",
    "prepared_alternative_animation", "starting_attack_animation", "attacking_animation",
    "ending_attack_animation", "folding_animation", "energy_glow_animation",
    "gun_animation_render_layer", "gun_animation_secondary_draw_order", "folded_speed",
    "folded_speed_secondary",
    # streams: the flying picture, its shadow, smoke and light
    "particle", "spine_animation", "oriented_particle", "shadow_scale_enabled",
    "particle_start_alpha", "particle_end_alpha", "particle_start_scale", "particle_end_scale",
    "particle_alpha_per_part", "particle_scale_per_part", "particle_fade_out_threshold",
    "particle_fade_out_duration", "particle_loop_frame_count", "particle_loop_exit_threshold",
    "smoke_sources", "progress_to_create_smoke", "stream_light", "ground_light",
    # fire (the goo puddles): their pictures
    "secondary_pictures", "smoke_source_pictures", "burnt_patch_pictures",
}

# Trigger effects that only show or play something.
PRESENTATION_EFFECTS = {
    "play-sound", "create-particle", "create-trivial-smoke", "camera-effect",
    "show-explosion-on-chart",
}
# Effects that create an entity; they're presentation when that entity is (see inert_entities).
CREATE_EFFECTS = {"create-entity", "create-explosion"}

# Fields that hold either one trigger, delivery or effect, or a list of them.
ONE_OR_MANY = {
    "action", "initial_action", "created_effect", "target_effects", "source_effects",
    "action_delivery", "damaged_trigger_effect", "dying_trigger_effect", "attack_reaction",
    "on_damage_tick_effect", "update_effects", "trigger",
}


def as_list(value):
    if isinstance(value, dict):
        return [value]
    return value


class Reducer:
    def __init__(self, dump):
        self.inert = inert_entities(dump)

    def is_presentation_effect(self, value):
        if not isinstance(value, dict):
            return False
        kind = value.get("type")
        if kind in PRESENTATION_EFFECTS:
            return True
        return kind in CREATE_EFFECTS and value.get("entity_name") in self.inert

    def explosions_are_inert(self, value):
        names = []
        for item in as_list(value) if not isinstance(value, str) else [value]:
            names.append(item if isinstance(item, str) else item.get("name"))
        return all(name in self.inert for name in names)

    def reduce(self, value, key=None):
        """The value with presentation removed; None if nothing is left."""
        if key in ONE_OR_MANY:
            value = as_list(value)
        if isinstance(value, dict):
            out = {}
            for k, v in value.items():
                if k in PRESENTATION:
                    continue
                if k == "dying_explosion" and self.explosions_are_inert(v):
                    continue
                if k in ("corpse", "folded_state_corpse"):
                    continue
                r = self.reduce(v, k)
                if r is not None:
                    out[k] = r
            return out or None
        if isinstance(value, list):
            out = []
            for item in value:
                if self.is_presentation_effect(item):
                    continue
                r = self.reduce(item)
                if r is not None:
                    out.append(r)
            return out or None
        return value


def trigger_effects(value):
    """Every trigger effect inside value."""
    found = []
    if isinstance(value, dict):
        for k, v in value.items():
            if k in ("target_effects", "source_effects"):
                found.extend(as_list(v))
            found.extend(trigger_effects(v))
    elif isinstance(value, list):
        for v in value:
            found.extend(trigger_effects(v))
    return found


def inert_entities(dump):
    """Names of entities that only show something: every corpse and particle source, and every
    explosion whose effects, followed through the explosions they create, are all presentation."""
    inert = set()
    for kind in PRESENTATION_ENTITY_TYPES:
        inert.update(dump.get(kind, {}))
    explosions = dump.get("explosion", {})
    changed = True
    while changed:
        changed = False
        for name, explosion in explosions.items():
            if name in inert:
                continue
            if all(effect.get("type") in PRESENTATION_EFFECTS
                   or (effect.get("type") in CREATE_EFFECTS and effect.get("entity_name") in inert)
                   for effect in trigger_effects(explosion)):
                inert.add(name)
                changed = True
    return inert


def differences(base, mod, path):
    """(path, base value, mod value) for each difference. Lists of tables (triggers, effects)
    are compared item by item; other lists, like positions, as a whole."""
    if isinstance(base, dict) and isinstance(mod, dict):
        for k in sorted(set(base) | set(mod)):
            yield from differences(base.get(k), mod.get(k), path + "." + k if path else k)
    elif (isinstance(base, list) and isinstance(mod, list) and len(base) == len(mod)
          and all(isinstance(item, dict) for item in base + mod)):
        for i, (b, m) in enumerate(zip(base, mod)):
            yield from differences(b, m, "%s[%d]" % (path, i))
    elif base != mod:
        yield path, base, mod


def load_allowlist(path):
    entries = []
    with open(path, encoding="utf-8") as f:
        for number, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            pattern, _, reason = line.partition("|")
            if not reason.strip():
                sys.exit("%s:%d: every entry needs a reason after a |" % (path, number))
            entries.append({"pattern": pattern.strip(), "reason": reason.strip(), "used": False})
    return entries


def allowed(entries, where):
    for entry in entries:
        if fnmatch.fnmatchcase(where, entry["pattern"]):
            entry["used"] = True
            return True
    return False


def short(value, limit=110):
    text = "(absent)" if value is None else json.dumps(value, sort_keys=True)
    return text if len(text) <= limit else text[:limit] + "..."


def compare(base_dump, mod_dump, entries):
    base_reducer, mod_reducer = Reducer(base_dump), Reducer(mod_dump)
    found = []
    for kind in sorted(set(base_dump) | set(mod_dump)):
        if kind in PRESENTATION_TYPES:
            continue
        base_protos, mod_protos = base_dump.get(kind, {}), mod_dump.get(kind, {})
        for name in sorted(set(base_protos) | set(mod_protos)):
            where = "%s/%s" % (kind, name)
            if name not in mod_protos:
                found.append((where, "removed by the mod", None, None))
                continue
            if name not in base_protos:
                if not (kind == "explosion" and name in mod_reducer.inert):
                    found.append((where, "added by the mod, and not presentation", None, None))
                continue
            base_r = base_reducer.reduce(base_protos[name])
            mod_r = mod_reducer.reduce(mod_protos[name])
            for path, b, m in differences(base_r, mod_r, ""):
                found.append((where + ":" + path, None, b, m))
    unexplained = [f for f in found if not allowed(entries, f[0])]
    return found, unexplained


def main(argv):
    if len(argv) < 4:
        sys.exit(__doc__)
    entries = load_allowlist(argv[1])
    with open(argv[2], encoding="utf-8") as f:
        base_dump = json.load(f)
    failed = False
    for mod_path in argv[3:]:
        with open(mod_path, encoding="utf-8") as f:
            mod_dump = json.load(f)
        found, unexplained = compare(base_dump, mod_dump, entries)
        print("%s: %d gameplay differences from the base game, %d of them not in the allowlist"
              % (mod_path, len(found), len(unexplained)))
        for where, note, b, m in unexplained:
            failed = True
            if note:
                print("  %s  %s" % (where, note))
            else:
                print("  %s\n      base: %s\n      mod:  %s" % (where, short(b), short(m)))
    open_entries = [e for e in entries if e["used"] and e["reason"].startswith("OPEN")]
    if open_entries:
        print("Deviations still waiting for the owner's decision:")
        for entry in open_entries:
            print("  %s\n      %s" % (entry["pattern"], entry["reason"]))
    for entry in entries:
        if not entry["used"]:
            print("Allowlist entry matched nothing, remove it if it's no longer needed: %s"
                  % entry["pattern"])
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
