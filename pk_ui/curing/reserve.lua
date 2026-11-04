PkCore.reserve = PkCore.reserve or {}
local reserve = PkCore.reserve

-- Herbs that break a lock, kept in the pack: with both arms broken the curing can't OUTR, only eat
-- what we carry. Addiction eats the pack down with every herb, so while it's on we keep it topped up.
reserve.HERBS = { bloodroot = 5, kelp = 5, goldenseal = 5 }
reserve.inv = reserve.inv or {}
reserve.sentAt = reserve.sentAt or {}
local RESEND = 0.5   -- seconds: the inventory update lands ~0.1s after an outr

-- GMCP names a stack "a piece of kelp" or "5 pieces of kelp".
local function count(herb)
  local total = 0
  for _, item in pairs(reserve.inv) do
    local name = type(item.name) == "string" and item.name:lower() or ""
    if name:find(herb, 1, true) then total = total + (tonumber(name:match("(%d+)")) or 1) end
  end
  return total
end
reserve.count = count

-- OUTR needs both arms whole and unbound.
local ARMS = {
  "brokenleftarm", "brokenrightarm", "damagedleftarm", "damagedrightarm",
  "mangledleftarm", "mangledrightarm", "bound", "webbed", "entangled", "transfixation",
}
local function armsFree()
  for _, aff in ipairs(ARMS) do
    if PkCore.afflictions.has(aff) then return false end
  end
  return true
end

function reserve.update()
  if not PkCore.config.values.herbReserve then return end
  if not armsFree() then return end
  local now = PkCore.now()
  for herb, want in pairs(reserve.HERBS) do
    local short = want - count(herb)
    if short > 0 and not PkCore.slowed.busy() and now - (reserve.sentAt[herb] or 0) >= PkCore.slowed.resendAfter(RESEND) then
      reserve.sentAt[herb] = now
      send("outr " .. short .. " " .. herb)
    end
  end
end

local function isInv(update) return type(update) == "table" and update.location == "inv" end
onGMCPUpdate("Char.Items.List", function(list)
  if not isInv(list) then return end
  reserve.inv = {}
  for _, item in ipairs(list.items or {}) do
    if type(item) == "table" and item.id then reserve.inv[item.id] = item end
  end
end)
onGMCPUpdate("Char.Items.Add", function(update)
  if isInv(update) and type(update.item) == "table" then reserve.inv[update.item.id] = update.item end
end)
onGMCPUpdate("Char.Items.Update", function(update)
  if isInv(update) and type(update.item) == "table" then reserve.inv[update.item.id] = update.item end
end)
onGMCPUpdate("Char.Items.Remove", function(update)
  if isInv(update) and type(update.item) == "table" then reserve.inv[update.item.id] = nil end
end)
-- The server only sends inventory changes once it's been asked for the list.
sendGMCP('Char.Items.Inv ""')

registerCommand("reserve", function()
  local parts = {}
  for herb, want in pairs(reserve.HERBS) do parts[#parts + 1] = herb .. " " .. count(herb) .. "/" .. want end
  table.sort(parts)
  return "herb reserve: " .. table.concat(parts, ", ")
end, "Lock-breaking herbs carried against what addiction tops up to")

PkCore.onVitalsChanged("reserve", reserve.update)

-- Refill on the eat, not on the next prompt: Lauryyn broke both arms 1.6s after an addicted eat
-- emptied the stack. The short delay lets the inventory update for the eaten herb land first.
addTrigger([[^You eat (?:a|an|some) (.+)\.$]], function(_, _, w)
  local eaten = w[1]:lower()
  for herb in pairs(reserve.HERBS) do
    if eaten:find(herb, 1, true) then
      setTimeout(reserve.update, 200)
      return
    end
  end
end, { type = "regex" })
