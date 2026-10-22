PkCore.ui = PkCore.ui or {}
PkCore.ui.recovery = PkCore.ui.recovery or {}
local recovery = PkCore.ui.recovery

local TICK = 0.1
local PRIMARY = { { "balance", "Balance" }, { "equilibrium", "Equilibrium" } }
-- Two columns; the theme stretches the last one across both, so an odd count looks intentional.
local SECONDARY = {
  { "tree", "Tree" }, { "focus", "Focus" }, { "elixir", "Elixir" }, { "moss", "Moss" },
  { "herb", "Herb" }, { "pipe", "Pipe" }, { "salve", "Salve" },
}

-- a reload killed the old timer; forget its id so a new one starts
recovery.ticker = nil   

local function meters(list)
  local out = {}
  for _, c in ipairs(list) do
    local id, label = c[1], c[2]
    out[#out + 1] = '<div class="mf-cooldown" data-kind="' .. id .. '" data-state="ready"'
      .. ' data-mud-bind-attr="data-state:cd_' .. id .. '">'
      .. '<i class="mf-cooldown-fill" aria-hidden="true" data-mud-bind-style="width:cdFill_' .. id .. '"></i>'
      .. "<span>" .. label .. '</span><b class="mf-cooldown-value" data-mud-bind="cdText_' .. id .. '">Ready</b></div>'
  end
  return table.concat(out)
end

function recovery.html()
  return '<section class="mf-recovery" data-field="recovery">'
    .. '<div class="mf-panel-heading"><h2>Recovery</h2></div>'
    .. '<div class="mf-recovery-primary">' .. meters(PRIMARY) .. "</div>"
    .. '<div class="mf-recovery-secondary">' .. meters(SECONDARY) .. "</div>"
    .. "</section>"
end

local function meterValues(values, id)
  local B = PkCore.balances
  if B.isReady(id) then
    values["cd_" .. id] = "ready"
    values["cdFill_" .. id] = "100%"
    values["cdText_" .. id] = "Ready"
    return
  end
  values["cd_" .. id] = "cooling"
  local elapsed, expected = B.elapsed(id), B.expectedFor(id)
  if elapsed and expected and expected > 0 then
    values["cdFill_" .. id] = math.floor(math.min(1, elapsed / expected) * 100) .. "%"
    values["cdText_" .. id] = string.format("%.1fs", math.max(0, expected - elapsed))
  else
    values["cdFill_" .. id] = "0%"
    values["cdText_" .. id] = elapsed and string.format("+%.1fs", elapsed) or ""
  end
end

local startTicker

function recovery.render()
  local id = PkCore.ui.layout.widgets.sidebar
  if not id then return end
  local values = {}
  for _, c in ipairs(PRIMARY) do meterValues(values, c[1]) end
  for _, c in ipairs(SECONDARY) do meterValues(values, c[1]) end
  setBoundValues(id, values)
  if PkCore.balances.anyDown() then startTicker() end
end

startTicker = function()
  if recovery.ticker then return end
  recovery.ticker = tempTimer(TICK, function()
    recovery.render()
    if not PkCore.balances.anyDown() then
      killTimer(recovery.ticker)
      recovery.ticker = nil
    end
  end, true)
end

PkCore.onStateChanged("ui.recovery", recovery.render)