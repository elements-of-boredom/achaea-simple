-- Quest helpers, from the Mudlet profile's "Quest Triggers": a line from the quest and the answer to it.
-- An answer is a command, or a function of the captures that returns one. delay waits that many ms first.
local QUESTS = {
  -- Morpho: help the caterpillar out of its cocoon
  { [[^The caterpillar quickly becomes exhausted by the effort and struggles to pull at the silken threads]], "pull caterpillar", delay = 1000 },
  { [[^Inside the cocoon, the caterpillar struggles in vain to pull silken threads around itself]], "pull caterpillar", delay = 1000 },
  { [[^The caterpillar makes a weak effort to turn the cocoon but is far too exhausted]], "turn caterpillar", delay = 1000 },
  { [[^Loose threads dangle uselessly from the cocoon, becoming brittle and breaking off as they harden in]], "push caterpillar", delay = 1000 },

  -- Maim de Vermiis
  { [[Maim de Vermiis points up to the sky, which suddenly crackles with lightning]], "pull rope" },
  { [[Maim de Vermiis pours a glowing reddish liquid into the corpse of a young boy]], "push lever" },
  { [[Maim de Vermiis rubs the puppet on the body of]], "turn crank" },
  { [[Maim de Vermiis touches the orb and chants, causing the orb to glow blue]], "pull lever" },

  -- Istarion
  { [[^A flood of ancient knowledge rushes into your mind, an unintelligible voice whispering in the]], "say At rien-kai 'amhu, lo-kile lamath 'raia laid 'lo" },
  { [[A simple wooden torch is affixed here\.]], "light torch" },

  -- Narcisse
  { [[^Nuxila's voice finds you admist the flurry, frantic and demanding]], "jump" },
  { [[^Nuxila's voice rings out above the heaving mass, commanding you to act]], "jump" },
  { [[^Once more, Nuxila's voice breaks through the din,]], "duck" },
  { [[^Satisfied with the mixture, Nuxila holds it close to her face and breathes deep\. With a nod, ]], "drink bowl" },

  -- Rheo
  { [[^A translucent ghost zooms in]], "grab ghost" },

  -- Falq'tor
  { [[^As Pryla'ari reaches for the phocine flyer, it rears back and turns to flee\.]], "pull flyer" },
  { [[^A sickly phocine flyer utters a deep growl that is both menacing and plaintive as Pryla'ari presses]], "press flyer" },
  { [[^A sickly phocine flyer's wings twitch and flap in irritation as Pryla'ari whispers to it in an]], "rub flyer" },

  -- Bagwar
  { [[Jitaka .* such as\.\.\. (\w+)]], function(w) return "say " .. w[1] end },

  -- Alcazar
  { [[^Oethapios, the butler says, "Tell me, what sort of knife is this\?]], "say Dinner Knife" },
  { [[Oethapios, the butler says, "Where should this fork be pointed\?"]], "say left" },

  -- Bopalopia
  { [[If (\d+) eggs were lain each by (\d+) chickens]], function(w) return "say " .. tonumber(w[1]) * tonumber(w[2]) end },
}

for _, entry in ipairs(QUESTS) do
  local answer, delay = entry[2], entry.delay
  addTrigger(entry[1], function(_, _, w)
    local command = type(answer) == "function" and answer(w) or answer
    if delay then
      setTimeout(function() send(command) end, delay)
    else
      send(command)
    end
  end, { type = "regex" })
end

-- The grotto's two oaths, two seconds apart.
PkCore.registerAlias("PkCore grotto", [[^grotto$]],
  [[send("say I swear that my intentions are good.") setTimeout(function() send("say I swear to uphold the pact.") end, 2000)]])