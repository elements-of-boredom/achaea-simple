PkCore.player = PkCore.player or {}
PkCore.playerStatus = PkCore.playerStatus or {}

local function onStatus()
  local status = gmcp and gmcp.Char and gmcp.Char.Status
  if not status then return end
  PkCore.player.level = status.level
  PkCore.player.lessons = tonumber(status.lessons)
  PkCore.player.boundCredits = tonumber(status.boundcredits)
  PkCore.player.unboundCredits = tonumber(status.unboundcredits)
  PkCore.player.unreadMsgs = tonumber(status.unread_msgs)
  PkCore.player.unreadNews = tonumber(status.unread_news)
  PkCore.player.gold = tonumber(status.gold)
  PkCore.player.bank = tonumber(status.bank)
  PkCore.player.class = status.class
  PkCore.stateChanged()
end

local function onVitalsStats()
  local charstats = gmcp and gmcp.Char and gmcp.Char.Vitals and gmcp.Char.Vitals.charstats
  if not charstats then return end
  for _, entry in ipairs(charstats) do
    local key, value = entry:match("^(%a+):%s*(%-?%d+)$")
    if key then
      PkCore.playerStatus[key:lower()] = tonumber(value)
    end
  end
end

PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Status", PkCore.protected("player.onStatus", onStatus)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Vitals", PkCore.protected("classStats.onVitals", onVitalsStats)))