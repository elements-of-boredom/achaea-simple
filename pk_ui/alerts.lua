PkCore.alerts = PkCore.alerts or {}
local alerts = PkCore.alerts

-- WunderSys's two displays: a boxed banner under the line, and a short warning in the prompt (@warning).
function alerts.banner(text, style)
  local msg, open = text:upper(), "<b><" .. style .. "> "
  local edge = string.rep("-", #msg + 10)
  PkCore.cecho("\n" .. open .. edge .. " <reset>\n" .. open .. "|    " .. msg .. "    | <reset>\n" .. open .. edge .. " <reset>")
end

-- One line for things that happen often. Outside a trigger cecho already starts its own line.
function alerts.notice(text, style)
  PkCore.cecho("<b><" .. style .. "> " .. text:upper() .. " <reset>")
end

function alerts.warn(text, seconds)
  alerts.current = { text = text, untilAt = PkCore.now() + seconds }
  PkCore.stateChanged()
end

PkCore.registerPromptTag("warning", function()
  local current = alerts.current
  if not current or PkCore.now() >= current.untilAt then return "" end
  return "<199,21,133># " .. current.text .. " #"
end)

-- Radiance names its caster only on the second line; the later stages reuse it.
local function radiancer()
  local r = alerts.radiancer
  if r and PkCore.now() - r.at < 28 then return r.name end
  return "someone"
end
local function radiance(stage)
  return function() return radiancer() .. " radiancing you (" .. stage .. "/7)" end
end

local KILL, DANGER, INFO, HOLY = "white:red", "black:orange", "black:yellow", "white:blue"

local RULES = {
  -- Instakills and channelled kills: move, shield or interrupt
  { [[^A deathly calm descends upon your surroundings as ([A-Z][a-z]+) draws \w+ up regally, eyes gleaming with murderous intent\.$]], "$1 devouring someone", 2, KILL },
  { [[^In a single, sinuous motion, ([A-Z][a-z]+) manoeuvres \w+ imposing form to encircle your feet, fixing you with a penetrating gaze as \w+ tremendous jaws open wide\.$]], "$1 devouring you", 2, KILL },
  { [[^In a single, sinuous motion, ([A-Z][a-z]+) manoeuvres \w+ imposing form to encircle ([A-Z][a-z]+)'s feet]], "$1 devouring $2", 2 },
  { [[^([A-Z][a-z]+) raises \w+ .+ over \w+ head and begins to swing it in a wide circle, gaining speed as \w+ goes\.$]], "$1 beheading someone", 2, KILL },
  { [[^([A-Z][a-z]+) begins to bear down on you with \w+ whirling \w+\.$]], "$1 beheading you", 2, KILL },
  { [[^([A-Z][a-z]+) raises .+ mace over you to pass judgement on your sins, and it begins to crackle with righteous fire\.$]], "$1 judging you (1/4)", 2, KILL },
  { [[^([A-Z][a-z]+) swings the crackling mace about \w+ head, gathering momentum as \w+ bears down on you\.$]], "$1 judging you (2/4)", 2 },
  { [[^([A-Z][a-z]+)'s mace begins to make a high-pitched keening sound as it rapidly spins over \w+ head\. You have only moments left to escape before you are judged!$]], "$1 judging you (3/4)", 2, KILL },
  { [[^A shiver runs down your spine, and you feel an instinctive urge to run as far and fast as you can\.$]], "radiance started on you (1/7)", 2, KILL },
  { [[^A shimmering image of the face of ([A-Z][a-z]+) appears fleetingly before you, frowning in concentration\.$]], function(w)
      alerts.radiancer = { name = w[1], at = PkCore.now() }
      return w[1] .. " radiancing you (2/7)"
    end, 2 },
  { [[^Sparks of multicoloured light begin to dance in your mind\.$]], radiance(3), 2 },
  { [[^An odd sensation of warmth begins to fill your body\.$]], radiance(4), 2 },
  { [[^Arcs of white light begin to flash across your vision, radiant and bright\.$]], radiance(5), 2 },
  { [[^Your heart thumps as you realise that you have but seconds left to escape whatever fate awaits you\.$]], radiance(6), 2, KILL },
  { [[^Fists clenched, ([A-Z][a-z]+) focuses on you with a deadly look in \w+ eyes\.$]], "$1 deathstriking you (1/2)", 2, KILL },
  { [[^Leaping forwards with lightning speed, ([A-Z][a-z]+) strikes you in the chest with a single, powerful blow\.]], "$1 deathstriking you (2/2)", 2, KILL },
  { [[^With a daegger in hand, ([A-Z][a-z]+) begins to close in on you\.$]], "$1 eliminating you", 2, KILL },
  { [[^The blade on the daegger splits into a semblance of teeth as ([A-Z][a-z]+) prepares for the final strike\.$]], "$1 eliminating you", 2, KILL },
  { [[^With a pop of \w+ knuckles, ([A-Z][a-z]+) buries \w+ foot under your back and flips you over onto your stomach\.$]], "$1 executing you", 2, KILL },
  { [[^Holding your head up, ([A-Z][a-z]+) snaps \w+ wrist, sending \w+ whip to wrap around your neck\.]], "$1 still executing you", 2 },
  { [[^([A-Z][a-z]+) rubs a tarot card on your arm\. You feel slightly nauseated and drained\.$]], "$1 making death tarot", 2 },
  { [[^([A-Z][a-z]+) flings a tarot card at you and upon impact, it disappears\. An ominous silence overtakes your surroundings\.$]], "$1 death tarot on you", 3, KILL },
  { [[^([A-Z][a-z]+) grows very still, \w+ unblinking gaze locking to your own\.]], "$1 chrono dooming you", 2, KILL },
  { [[^You know on an instinctive level that if ([A-Z][a-z]+) is allowed to continue, it shall be your end\.]], "$1 still chrono dooming you", 2 },
  { [[^([A-Z][a-z]+) begins slowly swinging \w+ crier's bell back and forth, each swing punctuated by a loud ring\.$]], "$1 started crier's bell", 2 },
  { [[^([A-Z][a-z]+) begins swinging a crier's bell faster and faster,]], "$1 crier's bell on you", 2, KILL },
  { [[^([A-Z][a-z]+) sets a jack-in-the-box on the ground and quickly winds it while whispering, '(\w+)\.']], "$1 jack-in-the-box on $2", 2 },
  { [[^The music of the jack-in-the-box becomes faster and more frantic and a loud voice from within yells, "(\w+), I'm a-cooomiiiiing!"$]], "jack-in-the-box coming for $1", 2, KILL },
  { [[^([A-Z][a-z]+) moves into the deeply mournful yet glorious tones of a funeral mass, directing the performance towards (\w+)\.$]], "$1 fmass on $2", 2, KILL },
  { [[^([A-Z][a-z]+) masterfully adds heavier, darker tones to \w+ song,]], "$1 still fmass", 2 },
  { [[^([A-Z][a-z]+) begins to regale (\w+) with a tale of a murder most foul\.]], "$1 endbringer on $2", 2, KILL },
  { [[^([A-Z][a-z]+) recounts to (\w+) Slith's battle with Thoth,]], "$1 still endbringer on $2", 2 },
  { [[^([A-Z][a-z]+) pulls back a.+, readying \w+ for a deadly strike\.$]], "$1 shatter", 2, KILL },
  { [[^([A-Z][a-z]+)'s eyes flutter and close as \w+ begins to rock back and forth, chanting ominously under \w+ breath\.$]], "$1 started tzantza", 2, KILL },
  { [[^A sudden nausea and lightheadedness takes hold of your body, and you struggle to hold on to consciousness under ([A-Z][a-z]+)'s assault\.$]], "$1 reaving you", 2, KILL },
  { [[^Readying .+, ([A-Z][a-z]+) begins to prowl towards you\.$]], "$1 severing your shadow", 3, KILL },
  { [[^As .+ begins to pulse with a sinister glow, ([A-Z][a-z]+) begins to close in on you\.$]], "$1 still severing your shadow", 3 },
  { [[^As the scythe comes away, the writhing figure of your shadow clings to the blade\.$]], "depthswalker has your shadow", 5, INFO },

  -- Changes what to do right now
  { [[^([A-Z][a-z]+) bows \w+ head in silent prayer\.$]], "$1 starting deliverance", 3, HOLY },
  { [[^([A-Z][a-z]+) slowly raises \w+ head and you see \w+ eyes glowing bright white\.$]], "deliverance up: don't hit $1", 10, HOLY },
  { [[is surrounded by a glowing white nimbus\.]], "deliverance in room", 5 },
  { [[^The lips of [A-Z][a-z]+ turn up in a sinister smile as \w+ gestures deliberately in your direction\.$]], "relapse incoming", 3, KILL },
  { [[^Lunging forward with one palm outstretched, ([A-Z][a-z]+) aims a blow at your heart\.]], "$1 heartseeded you", 3, KILL },
  { [[^The sickening sensation of something writhing and growing within your chest overwhelms you]], "heartseed growing", 3, KILL },
  { [[^Crackling flames erupt and surge across your skin in a frenzy\.$]], "flamefist: no rebounding", 3, DANGER },
  { [[^A thin rime of ice encases your body, numbing your extremities\.$]], "icefist: no tattoos", 3, DANGER },
  { [[^([A-Z][a-z]+) fashions a holocaust globe out of pure elemental fire and arms it\.$]], "$1 made holo", 5, DANGER },
  { [[^([A-Z][a-z]+) fashions a sphere of crackling electricity and arms it\.$]], "$1 made holo", 5, DANGER },
  { [[^A holocaust globe comes falling down from above to land with a 'THUMP\.'$]], "holo landed: move", 3, KILL },
  { [[^You groan in pain as [A-Z][a-z]+ twists the blade within your gut\.$]], "bladetwist", 2, KILL },
  { [[^As [A-Z][a-z]+ shifts the blade transfixing your gut, the loathsome kiss of metal ravages your insides\.$]], "impaleslash: turtle", 2, KILL },
  { [[^You feel your passage through time slow\.$]], "aeon", 3, DANGER },
  { [[\*\* Illusion \*\*]], "illusion", 2 },

  -- Our own state
  { [[^The elixir flows down your throat without effect\.$]], "immunity without voyria", 2, INFO },
  { [[^You grow still and begin to silently pray for preservation of your soul while you are out of the land\.$]], "quitting: herbs to rift", 5, INFO },
  { [[^You cease your praying\.$]], "qq stopped", 3, INFO },
}

local function fill(message, w)
  if type(message) == "function" then return message(w) end
  return (message:gsub("%$(%d)", function(i) return w[tonumber(i)] or "?" end))
end

for _, rule in ipairs(RULES) do
  local message, seconds, style = rule[2], rule[3], rule[4]
  addTrigger(rule[1], function(_, _, w)
    local text = fill(message, w)
    if seconds then alerts.warn(text, seconds) end
    if style then alerts.banner(text, style) end
  end, { type = "regex", caseSensitive = true })
end

-- A limb stepping down the ladder; the torso breaks from Lauryyn's claws only showed up on DIAG.
local function isLimb(name)
  return name:find("^broken") or name:find("^damaged") or name:find("^mangled") or name:find("trauma$")
end
-- brokenleftleg -> "broken left leg", mildtrauma -> "mild torso trauma"
local function describe(name)
  return (name:gsub("trauma$", " torso trauma"):gsub("left", " left "):gsub("right", " right "):gsub("head$", " head"))
end
onGMCPUpdate("Char.Afflictions.Add", function(entry)
  if type(entry) ~= "table" or type(entry.name) ~= "string" then return end
  local name = entry.name:lower()
  if isLimb(name) then alerts.notice(describe(name), "black:orange") end
end)

local LOKI_WINDOW = 30
local LOKI_COLOR = "\27[1;38;2;255;255;255;48;2;0;110;50m"
local NORMAL = "\27[0m\27[38;5;7m"   -- Achaea's colour 7, as in colorize.lua and prompt_tags.lua
alerts.loki = alerts.loki or {}
addTrigger([[^You are confused as to the effects of the venom\.$]], function(_, line)
  local now, recent = PkCore.now(), {}
  for _, at in ipairs(alerts.loki) do
    if now - at < LOKI_WINDOW then recent[#recent + 1] = at end
  end
  recent[#recent + 1] = now
  alerts.loki = recent
  if #recent >= 3 then alerts.banner("loki x" .. #recent .. ": diagnose!", "white:red") end
  return LOKI_COLOR .. line .. " (" .. #recent .. ")" .. NORMAL
end, { type = "regex", caseSensitive = true })