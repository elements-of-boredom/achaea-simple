PkCore.ui.vitals = PkCore.ui.vitals or {}

local GAUGE_BACK = "#2c313a"
local GAUGE_TEXT_CSS = [[background-color: transparent;]]
local ORB_SIZE = 16

local t = PkCore.ui.theme
local GAUGES = {
  { key = "hp", label = "HP", color = "#" .. t.hp,      color2 = "#" .. t.hp2 },
  { key = "mp", label = "MP", color = "#" .. t.mana,       color2 = "#" .. t.mana2 },
  { key = "ep", label = "EP", color = "#" .. t.endurance,  color2 = "#" .. t.endurance2 },
  { key = "wp", label = "WP", color = "#" .. t.willpower,  color2 = "#" .. t.willpower2 },
}

local function gaugeStyle(color1, color2)
  return string.format(
    [[background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 %s, stop:1 %s); border: none;]],
    color1, color2)
end

local function orbStyle(colorHex, filled)
  if filled then
    return string.format("background-color: #%s; border: 1px solid #%s; border-radius: %dpx;",
      colorHex, colorHex, ORB_SIZE / 2)
  end
  return string.format("background-color: transparent; border: 2px solid #%s; border-radius: %dpx;",
    colorHex, ORB_SIZE / 2)
end

function PkCore.ui.vitals.cleanup()
  PkCore.ui.vitals.gauges = nil
  PkCore.ui.vitals.target = nil
  PkCore.ui.vitals.orbs = nil
end

function PkCore.ui.vitals.ensureGauges()
  if PkCore.ui.vitals.gauges then return PkCore.ui.vitals.gauges end
  if not (PkCore.ui and PkCore.ui.sections and PkCore.ui.sections.playerVitals) then return nil end

   local positions = {
    { x = "0%+5px",  y = "0%+4px"  },  -- hp
    { x = "50%+2px", y = "0%+4px"  },  -- mp
    { x = "0%+5px",  y = "50%+1px" },  -- ep
    { x = "50%+2px", y = "50%+1px" },  -- wp
  }

  local gauges = {}
  for index, def in ipairs(GAUGES) do
    local pos = positions[index]
    local gauge = Geyser.Gauge:new({
      name = "PkCore_vitals_" .. def.key,
      x = pos.x, y = pos.y, width = "50%-8px", height = "50%-6px",
      font = "SF Mono", fontSize = 10,
    }, PkCore.ui.sections.playerVitals)
    gauge:setStyleSheet(gaugeStyle(def.color, def.color2), gaugeStyle(GAUGE_BACK, GAUGE_BACK), GAUGE_TEXT_CSS)
    gauge:setFgColor("#0a0a0a")
    gauge:setAlignment("c")
    gauges[def.key] = gauge
    raiseWindow("PkCore_vitals_" .. def.key)
  end
  PkCore.ui.vitals.gauges = gauges
  return gauges
end

function PkCore.ui.vitals.ensureTarget()
    if PkCore.ui.vitals.target then return PkCore.ui.vitals.target end
    if not (PkCore.ui and PkCore.ui.sections and PkCore.ui.sections.target) then return nil end

    local container = PkCore.ui.sections.target

    local orb = Geyser.Label:new({
        name = "PkCore_target_orb",
        x = "4px", y = "4px", width = "40px", height = "40px",
        fontSize=32
    }, container)
    orb:setStyleSheet(string.format([[border-image: url(%s) 0 0 0 0 stretch stretch;]],  getMudletHomeDir() .. "/pk/assets/target-enemy-64.png"))

    local title = Geyser.Label:new({
        name = "PkCore_target_title",
        x = "54px", y = "2%", width = "70%", height = "40%",
        font = "SF Mono", fontSize = 10,
    }, container)
    title:setStyleSheet("background-color: transparent;")

    local bar = Geyser.Gauge:new({
        name = "PkCore_target_bar",
        x = "54px", y = "52%", width = "68%", height = "38%",
        font = "SF Mono", fontSize = 10,
    }, container)
    bar:setStyleSheet(gaugeStyle("#" .. t.target, "#" .. t.target2), gaugeStyle(GAUGE_BACK, GAUGE_BACK), GAUGE_TEXT_CSS)
    bar:setFgColor("#0a0a0a")
    bar:setAlignment("c")
    raiseWindow("PkCore_target_orb")
    raiseWindow("PkCore_target_title")
    raiseWindow("PkCore_target_bar")

    PkCore.ui.vitals.target = { title = title, bar = bar }
    return PkCore.ui.vitals.target
end

function PkCore.ui.vitals.ensureBalanceOrbs()
  if PkCore.ui.vitals.orbs then return PkCore.ui.vitals.orbs end
  if not (PkCore.ui and PkCore.ui.sections and PkCore.ui.sections.balanceOrbs) then return nil end

  local container = PkCore.ui.sections.balanceOrbs

  local balOrb = Geyser.Label:new({
    name = "PkCore_vitals_orb_balance",
    x = 7, y = "20%-" .. (ORB_SIZE / 2), width = ORB_SIZE, height = ORB_SIZE,
  }, container)

  local eqOrb = Geyser.Label:new({
    name = "PkCore_vitals_orb_eq",
    x = 7, y = "60%-" .. (ORB_SIZE / 2), width = ORB_SIZE, height = ORB_SIZE,
  }, container)

  PkCore.ui.vitals.orbs = { balance = balOrb, equilibrium = eqOrb }
  return PkCore.ui.vitals.orbs
end

function PkCore.ui.vitals.renderBalanceOrbs()
  local orbs = PkCore.ui.vitals.ensureBalanceOrbs()
  if not orbs then return end
  orbs.balance:setStyleSheet(orbStyle(t.hp, PkCore.balance.balance))
  orbs.equilibrium:setStyleSheet(orbStyle(t.mana, PkCore.balance.equilibrium))
end

function PkCore.ui.vitals.render()
  PkCore.ui.vitals.renderBalanceOrbs() 
  local gauges = PkCore.ui.vitals.ensureGauges()
  if not gauges then return end
  for _, def in ipairs(GAUGES) do
    local current, max = PkCore.vitals[def.key], PkCore.vitals["max" .. def.key]
    if current and max and max > 0 then
      gauges[def.key]:setValue(math.min(max,current), max, string.format("%s %d/%d (%d%%)", def.label, current, max, tostring(math.min(100, current/max * 100))))
    end
  end
end
function PkCore.ui.vitals.renderTarget()
    local target = PkCore.ui.vitals.ensureTarget()
    if not target then return end

    local name = PkCore.room.targetName()
    if not name then
        target.title:echo("Target · —", "#9aa8a1")
        target.bar:setValue(0, 100, "")
        return
    end

    target.title:echo("Target · " .. name, "#e4eee6")
    local percent = PkCore.room.targetHpPercent or 0
    target.bar:setValue(percent, 100, string.format("Health %d%%", percent))
end

PkCore.registerSystem("ui.vitals", { cleanup = PkCore.ui.vitals.cleanup, rebuild = PkCore.ui.vitals.render })
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Vitals", PkCore.protected("ui.vitals.render", PkCore.ui.vitals.render)))
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed", PkCore.protected("ui.vitals.renderTarget", PkCore.ui.vitals.renderTarget)))
