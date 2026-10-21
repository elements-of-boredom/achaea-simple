PkCore.player = PkCore.player or {}

local function num(v)
  if v == nil or v == "" then return nil end
  return tonumber(v)
end

local function set(key, value, isNumber)
  if value == nil then return end
  if isNumber then value = num(value) end
  PkCore.player[key] = value
end

function PkCore.player.onStatus(status)
  if not status then return end
  set("level", status.level)                       -- "106 (18.30%)": keep it as text
  set("lessons", status.lessons, true)
  set("boundCredits", status.boundcredits, true)
  set("unboundCredits", status.unboundcredits, true)
  set("unreadMsgs", status.unread_msgs, true)
  set("unreadNews", status.unread_news, true)
  set("gold", status.gold, true)
  set("bank", status.bank, true)
  set("class", status.class)
  PkCore.stateChanged()
end

onGMCPUpdate("Char.Status", PkCore.player.onStatus)