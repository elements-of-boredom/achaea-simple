PkCore.ui.limbs = PkCore.ui.limbs or {}

local LIMB_ORDER_MINE = { "head", "torso", "left arm", "right arm", "left leg", "right leg" }
local LIMB_LABELS = { head="H", torso="T", ["left arm"]="LA", ["right arm"]="RA", ["left leg"]="LL", ["right leg"]="RL" }
local LIMB_ORDER_TARGET = { "head", "torso", "leftarm", "rightarm", "leftleg", "rightleg" }
local LIMB_LABELS_TARGET = { head="H", torso="T", leftarm="LA", rightarm="RA", leftleg="LL", rightleg="RL" }

local function tierColor(value)
  value = value or 0
  if value >= 100 then return "#ff4040" end
  if value >= 50 then return "#ffb020" end
  return "#80c080"
end

local function buildLine(values, order, labels)
  local parts = {}
  for _, key in ipairs(order) do
    local v = values and values[key] or 0
    table.insert(parts, string.format('<span style="color:%s">%s:%d</span>', tierColor(v), labels[key], v))
  end
  return table.concat(parts, " ")
end

function PkCore.ui.limbs.cleanup()
  PkCore.ui.limbs.mine = nil
  PkCore.ui.limbs.target = nil
end

function PkCore.ui.limbs.ensure()
  if PkCore.ui.limbs.mine then return end
  if not (PkCore.ui.sections and PkCore.ui.sections.myLimbs and PkCore.ui.sections.targetLimbs) then return end
  PkCore.ui.limbs.mine = Geyser.Label:new({
    name = "PkCore_limbs_mine", x = "0%", y = "0%", width = "100%", height = "100%",
    font = "SF Mono", fontSize = 12,
  }, PkCore.ui.sections.myLimbs)
  PkCore.ui.limbs.target = Geyser.Label:new({
    name = "PkCore_limbs_target", x = "0%", y = "0%", width = "100%", height = "100%",
    font = "SF Mono", fontSize = 12,
  }, PkCore.ui.sections.targetLimbs)
end

function PkCore.ui.limbs.render()
  PkCore.ui.limbs.ensure()
  if not PkCore.ui.limbs.mine then return end

  local mineValues = wsys and wsys.selfLimbCounter and wsys.selfLimbCounter.percentages
  PkCore.ui.limbs.mine:echo(buildLine(mineValues, LIMB_ORDER_MINE, LIMB_LABELS))

  local target = PkCore.room.targetName()
  local targetValues = target and ak and ak.limbs and ak.limbs.limbcount and ak.limbs.limbcount[target]
  PkCore.ui.limbs.target:echo(buildLine(targetValues, LIMB_ORDER_TARGET, LIMB_LABELS_TARGET))
end

PkCore.registerSystem("ui.limbs", { cleanup = PkCore.ui.limbs.cleanup, rebuild = PkCore.ui.limbs.render })
PkCore.trackHandler(registerAnonymousEventHandler("PkCore state changed", PkCore.protected("ui.limbs.render", PkCore.ui.limbs.render)))
PkCore.trackHandler(registerAnonymousEventHandler("gmcp.Char.Vitals", PkCore.protected("ui.limbs.render", PkCore.ui.limbs.render)))