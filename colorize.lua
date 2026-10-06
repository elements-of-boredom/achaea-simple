PkCore.colorize = PkCore.colorize or { enabled = true }

function PkCore.colorize.setEnabled(on)
  PkCore.colorize.enabled = on and true or false
  PkCore.note("colorize " .. (PkCore.colorize.enabled and "ON" or "OFF"))
end

-- ── Gradient palettes ──────────────────────────────────────────────────────

local DRAGON_ATTACK = {
  { 255, 200, 230 },  -- pale pink
  { 200,  30, 120 },  -- hot pink
  { 240, 160,  30 },  -- gold
  { 200,  30, 120 },  -- hot pink
  { 255, 200, 230 },  -- pale pink
}

local SERPENT_ATTACK = {
  { 164, 255, 146 },  -- pale venom green
  {  82, 232, 102 },  -- vivid scale green
  { 222, 255,  84 },  -- toxic yellow
  {  34, 190,  82 },  -- bright emerald
  { 130, 255, 188 },  -- mint fang sheen
}

local FIRELORD_ORANGE = { 255, 132, 42 }
local FIRELORD_ATTACK = {
  { 255, 214,  82 },  -- flame-yellow
  { 255, 132,  42 },  -- bright orange
  { 214,  42,  32 },  -- core red
  { 156,  30,  24 },  -- deep ember
  { 255, 176,  62 },  -- hot flare
}

local EARTHLORD_ATTACK = {
  { 236, 214, 172 },  -- warm sand
  { 190, 146,  92 },  -- ochre clay
  { 132,  92,  54 },  -- rich earth brown
  { 214, 174, 116 },  -- dry sandstone
  { 104,  72,  44 },  -- deep soil
}

local WATERLORD_ATTACK = {
  {  82, 190, 214 },  -- strong seafoam
  {  46, 150, 205 },  -- river blue
  {  64, 184, 178 },  -- deeper aqua current
  {  42, 132, 196 },  -- deep water blue
  { 168, 238, 230 },  -- pale wavecrest
}

local AIRLORD_ATTACK = {
  { 176, 156, 238 },  -- highstorm violet
  {  92, 150, 226 },  -- clear wind blue
  { 232, 204,  82 },  -- bright air gold
  { 126, 104, 210 },  -- pressure purple
  { 156, 190, 238 },  -- pale sky blue
}

local DEPTHSWALKER_ATTACK = {
  { 178, 142, 255 },  -- pale void violet
  { 136,  96, 222 },  -- bright abyss purple
  { 214, 190, 255 },  -- ghostlit lavender
  { 152, 102, 232 },  -- radiant shadow purple
  { 196, 164, 255 },  -- soft violet afterimage
}

local BLADEMASTER_ATTACK = {
  { 126, 158, 174 },  -- cool tempered steel
  { 166, 190, 196 },  -- muted blade flash
  { 118, 132, 144 },  -- honed grey edge
  { 190,  54,  60 },  -- clean bloodline
  { 104, 122, 136 },  -- rain-dark steel
}

local DRUID_ATTACK = {
  { 164, 222, 132 },  -- fresh leaf green
  { 104, 176,  92 },  -- wildwood green
  { 214, 186, 112 },  -- sunlit bark
  { 136, 104,  72 },  -- warm earth brown
  { 190, 224, 174 },  -- pale moonleaf
}

local MAGI_ATTACK = {
  { 255, 104,  72 },  -- fire ember
  { 102, 190, 255 },  -- water blue
  { 236, 220, 140 },  -- air gold
  { 142, 104,  72 },  -- earth brown
  { 190, 150, 255 },  -- arcane violet
}

local PRIEST_ATTACK = {
  { 226, 176,  82 },  -- warm temple gold
  { 204,  92,  72 },  -- muted sacred red
  { 238, 202, 122 },  -- candle gold
  { 178, 112,  76 },  -- soft clay tan
  { 214, 142,  74 },  -- burnished amber
}

local MONK_ATTACK = {
  { 224, 168,  92 },  -- bright sandalwood
  { 132, 210, 112 },  -- bright lotus green
  { 236, 242, 224 },  -- white lotus center
  { 112, 230,  96 },  -- vibrant lotus green
  { 224, 168,  92 },  -- bright sandalwood
}

local SYLVAN_ATTACK = {
  { 154, 238,  62 },  -- vivid yellow-green
  {  18, 132,  58 },  -- darker viridian
  {  42, 178, 214 },  -- elemental blue
  { 238, 212,  66 },  -- bright yellow magic
  {  12,  96,  48 },  -- deep dark green
}

local ICE_DRAGON_ATTACK = {
  { 202, 246, 255 },  -- frost white-blue
  { 128, 218, 255 },  -- icy sky blue
  {  64, 166, 232 },  -- glacier blue
  { 116, 236, 232 },  -- frozen aqua
  { 176, 232, 255 },  -- pale ice sheen
}

-- ── Rules: { pattern, color } ───────────────────────────────────────────────
-- color is solid {r,g,b} or a gradient {{r,g,b}, ...} (2+ stops).
local RULES = {
  -- DRAGON_ATTACK
  { "^You rip into .+ with your massive, deadly claws", DRAGON_ATTACK },
  { "^You charge quickly at .+, throwing your mighty form", DRAGON_ATTACK },
  { "^You level your draconic gaze at", DRAGON_ATTACK },
  { "^You summon a psychic storm around", DRAGON_ATTACK },
  { "^You psychically slam your mind into", DRAGON_ATTACK },
  { "^You blast .+ with psychic energy, demolishing", DRAGON_ATTACK },
  { "^You summon sparkles of psi energy around", DRAGON_ATTACK },
  { "^With a roar of triumph, you unleash a cataclysm of crushing psi energy", DRAGON_ATTACK },
  { "^You flick your tail at .+, dismissively brushing aside .+ paltry shield protecting h\\w+\\.$", DRAGON_ATTACK },
  { "^Drawing from the well of your puissance, you invoke", DRAGON_ATTACK },
  { "^Your nostrils flare with a rush of air as your sinuous body contracts", DRAGON_ATTACK },

  -- ICE_DRAGON_ATTACK
  { "^You form small chunks of ice in your enormous maw, then spit them", ICE_DRAGON_ATTACK },
  { "^You breathe a column of icy air at", ICE_DRAGON_ATTACK },
  { "^You barrel into", ICE_DRAGON_ATTACK },
  { "^You breathe a wave of icy air at", ICE_DRAGON_ATTACK },
  { "^You let loose a steady stream of cold air around", ICE_DRAGON_ATTACK },
  { "^.+'s translucent shield cracks and fades away as you breathe an icy blast at it\\.", ICE_DRAGON_ATTACK },
  { "^Opening your massive maw, you throw your head forward and blast wave after wave", ICE_DRAGON_ATTACK },

  -- SERPENT_ATTACK
  { "^You slip behind ", SERPENT_ATTACK },
  { "^You sink your fangs into", SERPENT_ATTACK },
  { "^You crack an iron-tipped whip over your head before repeatedly lashing", SERPENT_ATTACK },
  { "^You crack an iron-tipped whip lightly against ", SERPENT_ATTACK },
  { "^You leap upon ", SERPENT_ATTACK },
  { "^You lash out at .+ with your whip, stripping .+ translucent shield\\.$", SERPENT_ATTACK },
  { "^.* screams out in agony, struck by the effects of", SERPENT_ATTACK },
  { "^You crack .* over your head before repeatedly lashing", SERPENT_ATTACK },

  -- BLADEMASTER_ATTACK
  { "^With expert precision, you draw ", BLADEMASTER_ATTACK },

  -- DEPTHSWALKER_ATTACK
  { "^You lay into .+ with a vicious blow from a scythe of shadows", DEPTHSWALKER_ATTACK },
  { "^Directing your power against the magical shield surrounding", DEPTHSWALKER_ATTACK },
  { "^Bending your considerable will upon the temporal flow, you distort", DEPTHSWALKER_ATTACK },
  { "^You unleash a vicious reaping blow at", DEPTHSWALKER_ATTACK },

  -- DRUID_ATTACK
  { "^You sink your teeth deep into", DRUID_ATTACK },
  { "^Gesturing at .*, you whisper a prayer to Gaia", DRUID_ATTACK },
  { "^You strike brutally at", DRUID_ATTACK },
  { "^At your command, undergrowth rises from the ground", DRUID_ATTACK },

  -- MAGI_ATTACK
  { "^You form a lash of fire, and send it to scorch the", MAGI_ATTACK },
  { "^You draw upon the power of air to summon sharp gusts of wind which", MAGI_ATTACK },
  { "^You summon a polar vortex in a tight field around", MAGI_ATTACK },
  { "^You summon a whirlwind of flame around", MAGI_ATTACK },
  { "^You point an elemental staff at", MAGI_ATTACK },
  { "^As you point an elemental staff at", MAGI_ATTACK },
  { "^A bolt of lightning roars out from your hands as you cast a powerful spell", MAGI_ATTACK },
  { "^You raise a clenched fist and in obedience the earth rises in turn", MAGI_ATTACK },

  -- PRIEST_ATTACK
  { "^You utter a prayer and smite", PRIEST_ATTACK },
  { "^Your angel flares its wings and flaps them powerfully", PRIEST_ATTACK },
  { "^Your guardian angel becomes translucent as she floats first through you", PRIEST_ATTACK },
  { "^You lay your hands on yourself.", PRIEST_ATTACK },
  { "^Praying to the Gods, you lay a desolating rite on", PRIEST_ATTACK },

  -- MONK_ATTACK
  { "^You rummage quickly through", MONK_ATTACK },
  { "^You spin and strike", MONK_ATTACK },
  { "^You focus your rage in a single powerful sidekick", MONK_ATTACK },

  -- SYLVAN_ATTACK
  { "^You command the razor-edged thorny vines around you to lash out and rend the flesh", SYLVAN_ATTACK },
  { "^.* coughs and splutters as you channel a gout of water", SYLVAN_ATTACK },
  { "^.* stumbles about in fear and flails at his head as you summon", SYLVAN_ATTACK },
  { "A deadly root flies from your hand and burrows into", SYLVAN_ATTACK },
  { "^You form a small pebble, then channel air to fling it violently", SYLVAN_ATTACK },
  { "^Channeling arcane power through your air and earth channels", SYLVAN_ATTACK },
  { "^With a curt gesture you summon a whip of condensed air", SYLVAN_ATTACK },
  { "^Channeling large quantities of arcane power through your air channel", SYLVAN_ATTACK },
  { "^Calling upon the arcane power of Air, you conjure forth a", SYLVAN_ATTACK },
  { "^Channeling power through your water channel, you conjure forth", SYLVAN_ATTACK },
  { "^You summon a great vine to wrap itself around", SYLVAN_ATTACK },
  { "^You press your hand to the ground, beseeching Nature to rise up against your foe", SYLVAN_ATTACK },

  -- FIRELORD_ATTACK
  { "^A whip of liquid flame coalesces in your hand, and with a savage", FIRELORD_ATTACK },
  { "^You reach out and clasp the face of \\w+ between your hands", FIRELORD_ATTACK },
  { "^Hand lashing out, you strike \\w+ right between the eyes", FIRELORD_ATTACK },
  { "^You fashion a weave of flame and cast it about", FIRELORD_ATTACK },
  { "^You reach out to \\w+, brushing a finger over the brand", FIRELORD_ATTACK },
  { "^You lift a fiery appendage and point it at the brand", FIRELORD_ATTACK },
  -- FIRELORD_ORANGE
  { "^Studying \\w+, you determine that the pressure surrounding \\w+ is terminally elevated.", FIRELORD_ORANGE },

  -- AIRLORD_ATTACK
  { "^You call down a lightning bolt to destroy", AIRLORD_ATTACK },
  { "^You violently buffet", AIRLORD_ATTACK },
  { "^The wind rises again, battering", AIRLORD_ATTACK },
  { "^You rip the breath from", AIRLORD_ATTACK },
  { "^You form a localised twister, spinning it at incredible speed to form a drill that", AIRLORD_ATTACK },
  { "^You send a crushing wave of pressurised air", AIRLORD_ATTACK },
  { "^You raise the pressure surrounding", AIRLORD_ATTACK },
  { "^You bring a vacuum into being with", AIRLORD_ATTACK },

  -- EARTHLORD_ATTACK
  { "^You rain a flurry of blows down upon", EARTHLORD_ATTACK },
  { "^Raising an imperious stone digit", EARTHLORD_ATTACK },
  { "^You bring one of your stone fists down upon", EARTHLORD_ATTACK },
  { "^You manifest rocks directly above", EARTHLORD_ATTACK },
  { "^Wreathing yourself in magma, you charge into", EARTHLORD_ATTACK },
  { "^Imbuing your form with the might of earth", EARTHLORD_ATTACK },
  { "^You call up a column of magma to strike down", EARTHLORD_ATTACK },

  -- WATERLORD_ATTACK
  { "^You conjure a blade of ice and send it to lacerate the flesh", WATERLORD_ATTACK },
  { "^You manifest water around", WATERLORD_ATTACK },
  { "^You begin to draw the fluid from", WATERLORD_ATTACK },
  { "^You dehydrate the moisture from", WATERLORD_ATTACK },
  { "^You manifest icicles from the vapour surrounding you", WATERLORD_ATTACK },
  { "^You bring down a deluge upon", WATERLORD_ATTACK },
  { "^You call down a rain of needle-sharp spears of ice", WATERLORD_ATTACK },

  
  -- Misc solid-color rules (no named palette)
  { "^Damage dealt:", { 136, 178, 230 } },
  { "^A nearly invisible magical shield forms around", { 255, 255, 0 } },
  { "^Your shield completely absorbs the damage.$", { 255, 255, 130 } },
  { "^Health lost:", { 215, 51, 60 } },
  { "^You have gained .* experience", { 218, 196, 132 } },
  { "^You summon up the magma that courses beneath your outer layers", { 88, 210, 118 } },
  { "remaining in your rift to 0.", { 245, 255, 40 } },
  { "^You may boil your blood once again.$", { 0, 255, 0 } },
  { "^As you continue to draw the vital waters", { 0, 255, 0 } },
  { "^You may purge your great form of afflictions once again", { 0, 255, 0 } },
  { "^You have found a ", { 240, 160, 30 } },
}

-- ── Apply ────────────────────────────────────────────────────────────────

local function isGradient(color)
  return type(color[1]) == "table"
end

local function applySolid(color)
  selectCurrentLine()
  setFgColor(color[1], color[2], color[3])
end

local function applyGradient(stops)
  local len = #line
  if len == 0 then return end
  local n = #stops
  for i = 1, len do
    local t = (i - 1) / math.max(len - 1, 1)
    local s = t * (n - 1)
    local lo = math.floor(s) + 1
    local hi = math.min(lo + 1, n)
    local f = s - (lo - 1)
    local c1, c2 = stops[lo], stops[hi]
    local r = math.floor(c1[1] + (c2[1] - c1[1]) * f)
    local g = math.floor(c1[2] + (c2[2] - c1[2]) * f)
    local b = math.floor(c1[3] + (c2[3] - c1[3]) * f)
    selectSection(i - 1, 1)
    setFgColor(r, g, b)
  end
end

local function buildTriggers()
  for _, rule in ipairs(RULES) do
    local pattern, color = rule[1], rule[2]
    PkCore.trackTrigger(tempRegexTrigger(pattern, PkCore.protected("colorize.rule", function()
      if not PkCore.colorize.enabled then return end
      if isGradient(color) then
        applyGradient(color)
      else
        applySolid(color)
      end
    end)))
  end
end

buildTriggers()
