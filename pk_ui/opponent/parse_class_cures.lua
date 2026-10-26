 local opponent = Opponent

function opponent.classCureLine(pattern, cure, who)
    addTrigger(pattern, function(_, _, w)
        local name = w[who or 1]
        if not opponent.isTracked(name) then
            return
        end
        opponent.record(name, { kind = "classcure", cure = cure })
    end, { type = "regex" })
end

local CLASS_CURE_LINES = {
    -- active
    { [[^([\w'\-]+) draws a deep, measured breath\.$]], "fitness" },
    { [[^([\w'\-]+) hunches [\w'\-]+ shoulders and lets out a soft hiss\.$]], "shrugging" },
    { [[^Magma erupts forth from beneath the plates that cover ([\w'\-]+)\.$]], "eruption" },
    { [[^The fiery outer layers of ([\w'\-]+) fall away]], "slough" },
    { [[^([\w'\-]+) lets out a mighty roar\.$]], "might" },
    { [[^Perspiration suddenly breaks out on ([\w'\-]+)'s forehead\.$]], "bloodboil" },
    { [[^([\w'\-]+) sketches out a symbol in the air with [\w'\-]+ finger in the shape of a bisected circle\.$]], "salt" },
    { [[^A look of relief comes over ([\w'\-]+) as [\w'\-]+ grows less pale\.$]], "accelerate" },
    { [[^A slight tightening of the eyes is the only sign ([\w'\-]+) makes that [\w'\-]+ has made a great effort of will\.$]], "expunge" },
    { [[^A pale mist begins to rise from the skin of ([\w'\-]+)\.$]], "purification" },
    { [[^([\w'\-]+) presses a tarot to (?:his|her|their) forehead, producing a wan smile\.$]], "fool" },
    { [[^[\w'\-]+ presses a tarot to ([\w'\-]+)'s forehead, producing a wan smile\.$]], "fool" },
    { [[^As ([\w'\-]+) massages key pressure points, a look of relief comes over [\w'\-]+ face as [\w'\-]+ ailments ease\.$]], "alleviate" },
    { [[^Throwing back [\w'\-]+ head, ([\w'\-]+) shouts out in defiance as blazing flames consume [\w'\-]+ for a single, glorious instant before dying away\.$]], "phoenix" },
    { [[^([\w'\-]+) lets out a great keening, casting the impurities from [\w'\-]+ form\.$]], "dragonheal" },
    { [[^([\w'\-]+)'s eyes flash with rage\.$]], "rage" },
    -- Unconfirmed: it's probably grove cure as other people see it.
    { [[^([\w'\-]+) stands suddenly upright, rooted to the earth\.$]], "grovecure" },
    -- passive
    { [[^A demonic crimson glow emanates from ([\w'\-]+)\.$]], "syphon" },
    { [[^A song can be heard on the edge of hearing as the air distorts about ([\w'\-]+)\.$]], "hallelujah" },
    { [[^A soft chiming emanates from ([\w'\-]+)\.$]], "harmony" },
    { [[^([\w'\-]+) is surrounded in a cool, refreshing mist\.$]], "panacea" },
    { [[^The globe of light illuminates ([\w'\-]+) with its brilliance\.$]], "sun" },
    { [[^Something pulses from within the chest of ([\w'\-]+), and [\w'\-]+ seems more vital\.$]], "leech" },
    { [[^A gentle glow surrounds ([\w'\-]+)\.$]], "healing" },
    { [[^The guardian angel of ([\w'\-]+) shimmers and [\w'\-]+ gives a sigh of relief\.$]], "angelcare" },
    { [[^A rune like a rising sun upon the ground flares, bathing ([\w'\-]+) with healing magic\.$]], "dagaz" },
    { [[^The tempestuous form of ([\w'\-]+) is cleansed by a purifying breeze\.$]], "susurration" },
    -- Missing : Waterlord Class cure lines, find Xylarys
}
for _, entry in ipairs(CLASS_CURE_LINES) do
    opponent.classCureLine(entry[1], entry[2], entry[3])
end