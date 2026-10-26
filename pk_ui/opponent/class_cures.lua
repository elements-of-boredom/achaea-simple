-- Class cures: skills that cure afflictions, which the game's AFFLICTION SHOW data doesn't cover.
-- Globbed together from multiple sources. 
--
-- classes     lowercase, no spaces
-- cures       how many random afflictions it removes, or "all"
-- only        cures exactly these instead of random ones
-- first       cured before anything random, if present
-- pool        the cures.lua set random picks come from ("eat:bellwort", "focus"); default is any affliction
-- blockers    a list of groups; any one group stops the cure, and every aff in a group must be present
--             { { "weariness" } }                          weariness alone blocks it
--             { { "haemophilia" }, { "brokenleftarm", "brokenrightarm" } }   either one blocks it
--             { { "weariness", "recklessness" } }          only both together block it
return {
  active = {
    fitness = {
      classes = { "infernal", "paladin", "runewarden", "unnamable", "monk", "blademaster", "druid", "sentinel" },
      only = { "asthma" },
      blockers = { { "weariness" } },
    },
    shrugging = {
      classes = { "serpent" },
      cures = 1,
      blockers = { { "weariness" } },
    },
    purify = {
      classes = { "waterlord" },
      cures = 1,
      blockers = { { "weariness" } },
    },
    eruption = {
      classes = { "earthlord" },
      cures = 1,
      blockers = { { "weariness" } },
    },
    slough = {
      classes = { "firelord" },
      cures = 1,
      blockers = { { "prone" } },
    },
    might = {
      classes = { "druid", "sentinel" },
      cures = 1,
      blockers = { { "prone" } },
    },
    bloodboil = {
      classes = { "magi" },
      cures = 1,
      blockers = { { "haemophilia" }, { "brokenleftarm", "brokenrightarm" } },
    },
    salt = {
      classes = { "alchemist" },
      cures = 1,
      blockers = { { "stupidity" } },
    },
    -- Cures 2 when boosted (they visibly age); prone blocks only the boost.
    accelerate = {
      classes = { "depthswalker" },
      cures = 1,
      boostedCures = 2,
      blockers = { { "recklessness" } },
    },
    expunge = {
      classes = { "psion" },
      cures = 1,
      first = { "impatience" },
      pool = "focus",
      blockers = { { "confusion" } },
    },
    purification = {
      classes = { "shaman" },
      cures = 1,
      blockers = { { "selarnia" } },
    },
    -- Can also be used on someone else, so the line has to name our target.
    fool = {
      classes = { "jester", "occultist" },
      cures = 3,
      blockers = { { "paralysis" }, { "prone" } },
    },
    alleviate = {
      classes = { "blademaster" },
      cures = 1,
      blockers = { { "paralysis" } },
    },
    phoenix = {
      classes = { "blademaster" },
      cures = "all",
      blockers = { { "prone" } },
    },
    -- Cures 1 instead of 3 while prone.
    dragonheal = {
      classes = { "dragon" },
      cures = 3,
      proneCures = 1,
      blockers = { { "weariness", "recklessness" } },
    },
    -- No blocker: can always break a lock
    grovecure = {
      classes = { "druid", "sylvan" },
      cures = 1,
      blockers = {},
    },
    rage = {
      classes = { "infernal", "paladin", "runewarden", "unnamable" },
      cures = 1,
      pool = "eat:bellwort",
      blockers = {},
    },
  },

  -- Fire on their own about every 10 seconds, curing voyria first.
  passive = {
    syphon = { classes = { "apostate" }, first = { "voyria" }, cures = 1, interval = 10 },
    hallelujah = { classes = { "bard" }, first = { "voyria" }, cures = 1, interval = 10 },
    harmony = { classes = { "magi" }, first = { "voyria" }, cures = 1, interval = 10 },
    panacea = { classes = { "druid", "sylvan" }, first = { "voyria" }, cures = 1, interval = 10 },
    sun = { classes = { "jester", "occultist" }, first = { "voyria" }, cures = 1, interval = 10 },
    leech = { classes = { "pariah" }, first = { "voyria" }, cures = 1, interval = 10 },
    healing = { classes = { "priest", "paladin" }, first = { "voyria" }, cures = 1, interval = 10 },
    angelcare = { classes = { "priest" }, first = { "voyria" }, cures = 1, interval = 10 },
    dagaz = { classes = { "runewarden" }, first = { "voyria" }, cures = 1, interval = 10 },
    susurration = { classes = { "airlord" }, first = { "voyria" }, cures = 1, interval = 10 },
  },
}
