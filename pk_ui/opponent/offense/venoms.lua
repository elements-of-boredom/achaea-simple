-- What each venom gives, whatever delivers it (thornrend, bite, doublestrike...).
--
-- gives    the affliction it lands
-- strips   a defence it removes instead, when the target has it (then gives nothing)
-- senses   defences it grants rather than afflicts (blind/deaf flags)
return {
    xentio      = { gives = "clumsiness" },
    eurypteria  = { gives = "recklessness" },
    kalmia      = { gives = "asthma" },
    digitalis   = { gives = "shyness" },
    darkshade   = { gives = "darkshade" },
    curare      = { gives = "paralysis" },
    monkshood   = { gives = "disloyalty" },
    euphorbia   = { gives = "nausea" },
    vernalius   = { gives = "weariness" },
    larkspur    = { gives = "dizziness" },
    slike       = { gives = "anorexia" },
    notechis    = { gives = "haemophilia" },
    vardrax     = { gives = "addiction" },
    aconite     = { gives = "stupidity" },
    selarnia    = { gives = "selarnia" },
    gecko       = { gives = "slickness" },
    scytherus   = { gives = "scytherus" },
    voyria      = { gives = "voyria" },
    prefarar    = { gives = "sensitivity", strips = "deaf" },
    delphinium  = { gives = "sleeping", strips = "insomnia", shown = true },
    colocasia   = { senses = { "blind", "deaf" } },
    epteth      = { breaks = "arm" },
    epseth      = { breaks = "leg" },
}