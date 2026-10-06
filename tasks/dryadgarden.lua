-- Visit four elemental shrines in sequence, recite the correct phrase at
-- each, then say SERENDIPITOUS. Ported directly from codex-ui's real,
-- working tasks.lua (buildDryadSteps) - room numbers/phrases are exact
-- quest text, not guessed.
local SHRINES = {
  { room = 5702, phrase = "Emerald grass and familiar soil, looming mountains with amazing girth, a volcano erasing a farmer's toil, proving dominion of the earth." },
  { room = 5704, phrase = "Comforting warmth and dancing light, rays of a sun that never tire, insatiable flames that rage out of sight, the machinations of the fire." },
  { room = 5691, phrase = "A touch of chill, a gentle breeze, phantom fingers through your hair, fearful tornado, destroying at ease, such is the power of the air." },
  { room = 5689, phrase = "Bluest ocean, harmonious rain, the lake that rests in tranquillity, terrible deluge, scarring terrain, there lies the strength of water and sea." },
}

local function pathTrack(room)
  return { send = "path track " .. room, wait = "You have arrived at your destination!", timeout = 120, settleDelay = 1.0 }
end

local function build()
  local steps = {}
  for i, shrine in ipairs(SHRINES) do
    table.insert(steps, pathTrack(shrine.room))
    table.insert(steps, { delay = 0.3 })
    table.insert(steps, { fn = function() send("say " .. shrine.phrase) end })
    if i < #SHRINES then
      table.insert(steps, { delay = 0.3 })
    end
  end
  table.insert(steps, { delay = 2 })
  table.insert(steps, { fn = function() send("say SERENDIPITOUS.") end })
  return steps
end

return {
  name = "DryadGarden",
  description = "Visit four elemental shrines and recite phrases.",
  build = build,
}
