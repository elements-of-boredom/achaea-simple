PkCore.ui.room = PkCore.ui.room or {}

-- Lifecycle -- 
function PkCore.ui.room.cleanup()
  PkCore.ui.room.widget = nil
  PkCore.ui.room.itemsWidget = nil
end

-- ── widget ───────────────────────────────────────────────────────────────
function PkCore.ui.room.ensureWidget()
  if PkCore.ui.room.widget then return PkCore.ui.room.widget end
  if not (PkCore.ui and PkCore.ui.sections and PkCore.ui.sections.room) then return nil end

  local headerHeight = PkCore.ui.header.create(PkCore.ui.sections.room, "PkCore_room", "Room Information") + 10

  local function makeConsole(name, x, width)
    local console = Geyser.MiniConsole:new({
      name = name,
      x = x, y = headerHeight, width = width, height = "100%-" .. headerHeight,
    }, PkCore.ui.sections.room)
    setBackgroundColor(name, 0, 0, 0, 0)
    setBgColor(name, 0, 0, 0, 0)
    console:disableAutoWrap()
    console:setFont("SF Mono")
    console:setFontSize(9)
    tempTimer(0, function()
      local fontWidth = console:calcFontSize()
      local charactersWidth = math.max(1, math.floor(console:get_width() / fontWidth))
      console:setWrap(charactersWidth)
      console:setFont("SF Mono")
      console:setFontSize(9)
    end)
    return console
  end

  PkCore.ui.room.widget = makeConsole("PkCore_room_console", "2%", "40%")
  PkCore.ui.room.itemsWidget = makeConsole("PkCore_room_items_console", "44%", "55%")
  
  return PkCore.ui.room.widget
end

function PkCore.ui.room.render()
  local widget = PkCore.ui.room.ensureWidget()
  if not widget then return end
  local itemsWidget = PkCore.ui.room.itemsWidget
  widget:clear()
  itemsWidget:clear()
  local t = PkCore.ui.theme

  widget:hecho("|b|c" .. t.text .. tostring(PkCore.room.name or "Unknown Room") .. "|r\n")
  widget:hecho("|b|c" .. t.text .. "[Exits]:|r |c" .. t.textBody .. table.concat(PkCore.room.sortedExits(), ", ") .. "|r\n\n")

  widget:hecho("|b|c" .. t.text .. "[Players]:|r\n")
  if #PkCore.room.playerNames() > 0 then
    widget:hecho("|c" .. t.player .. table.concat(PkCore.room.playerNames(), "|r, |c" .. t.player) .. "|r\n")
  end
  widget:hecho("\n")

  widget:hecho("|b|c" .. t.text .. "Mobs:|r\n")
  for _, entry in ipairs(PkCore.room.mobEntries()) do
    if PkCore.room.targetId and tostring(entry.id) == PkCore.room.targetId then
      widget:hecho("|c" .. t.target .. "> " .. entry.name .. " |c" .. t.idMuted .. " @" .. tostring(entry.id) .. "|r\n")
    else
      widget:hecho("|c" .. t.textBody .. entry.name .. " |c" .. t.idMuted .. " @" .. tostring(entry.id) .. "|r\n")
    end
  end

  itemsWidget:hecho("|b|c" .. t.text .. "Items:|r\n")
  local rows = PkCore.room.itemEntries()
  local shown = math.min(#rows, 15)
  for i = 1, shown do
    local entry = rows[i]
    itemsWidget:hecho("|c" .. t.textMuted .. entry.name .. (entry.count > 1 and (" x" .. entry.count) or (" @" .. entry.id)) .. "|r\n")
  end
  if #rows > shown then
    itemsWidget:hecho("|c" .. t.textMuted .. "(+" .. (#rows - shown) .. " more)|r\n")
  end
end

PkCore.registerSystem("ui.room", { cleanup = PkCore.ui.room.cleanup, rebuild = PkCore.ui.room.render })
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed", PkCore.protected("ui.room.render", PkCore.ui.room.render)))