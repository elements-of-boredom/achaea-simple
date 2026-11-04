-- Our bees are free to order once they're here; their stings sometimes paralyse.
PkCore.bees = PkCore.bees or {}
local bees = PkCore.bees
local NAME = "a swarm of bees"
bees.CLAIM_WINDOW = 10   -- a swarm arriving this soon after we call is ours

-- Disloyal: the order didn't take. Give it again once disloyalty is cured.
addTrigger([[^You stand in such dishonour that not even your loyal friends will help you\.$]], function()
  bees.orderedFor = nil
end, { type = "regex" })

addTrigger([[^Barely within the range of normal hearing, you utter a buzz-like hum from deep within your throat\.$]], function()
  bees.calledAt = PkCore.now()
end, { type = "regex" })
-- Wrong swarm: forget it, the next call claims the right one. Disloyal, they refuse even when they're ours.
addTrigger([[^A swarm of bees will not follow your orders\.$]], function()
  if PkCore.afflictions.has("disloyalty") then return end
  bees.mine, bees.orderedFor = nil, nil
end, { type = "regex" })

-- Disloyal, our own bees sting us
addTrigger([[^The swarm of bees angrily stings you in multiple places\.$]], function()
  bees.turned = true
end, { type = "regex" })

-- Cured: tell them to be nice to us!
addTrigger([[^You no longer will inspire disloyalty among friends\.$]], function()
  bees.orderedFor = nil
  local fighting = PkCore.reactor.mode == "pk" and PkCore.room.targetName()
  if bees.turned and bees.mine and not fighting then
    send("order " .. bees.mine .. " passive")
  end
  bees.turned = false
end, { type = "regex" })

onGMCPUpdate("Char.Items.Add", function(update)
  if type(update) ~= "table" or update.location ~= "room" or type(update.item) ~= "table" then return end
  local item = update.item
  if item.name ~= NAME then return end
  if bees.calledAt and PkCore.now() - bees.calledAt <= bees.CLAIM_WINDOW then
    bees.mine, bees.calledAt = item.id, nil
  end
  if item.id == bees.mine then bees.orderedFor = nil end   -- they've followed us in: order them again
end)

local function here()
  for _, item in ipairs(PkCore.room.items) do
    if item.id == bees.mine then return true end
  end
  return false
end

function bees.update()
  if PkCore.reactor.mode ~= "pk" or not bees.mine or not here() then return end
  local name = PkCore.room.targetName()
  if not name or bees.orderedFor == name:lower() or PkCore.slowed.busy() then return end
  if PkCore.afflictions.has("disloyalty") then return end
  bees.orderedFor = name:lower()
  send("order " .. bees.mine .. " kill " .. name)
end
PkCore.onVitalsChanged("bees", bees.update)