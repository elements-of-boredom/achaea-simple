PkCore.ui = PkCore.ui or {}
PkCore.ui.limbs = PkCore.ui.limbs or {}
local limbs = PkCore.ui.limbs

local LIMBS = { "H", "T", "LA", "RA", "LL", "RL" }
limbs.KEYS = { H = "head", T = "torso", LA = "leftarm", RA = "rightarm", LL = "leftleg", RL = "rightleg" }

-- One limb strip (YOU or TARGET). Every part is bound to <prefix>_<limb>...; limbs.values fills them.
function limbs.row(owner, field, prefix)
  local cells = {}
  for _, limb in ipairs(LIMBS) do
    local key = (prefix or field) .. "_" .. limb
    cells[#cells + 1] = '<span class="mf-limb" data-limb="' .. limb .. '" data-damaged="false"'
      .. ' data-mud-bind-attr="data-damaged:' .. key .. 'Hurt">'
      .. '<b data-mud-bind="' .. key .. 'Label">' .. limb .. "</b>"
      .. '<em data-prepped="false" data-mud-bind="' .. key .. 'Pct" data-mud-bind-attr="data-prepped:' .. key .. 'Prepped">0</em>'
      .. '<i style="--mf-damage:0%" data-mud-bind-style="--mf-damage:' .. key .. 'Bar"></i></span>'
  end
  return '<div class="mf-limbs" data-field="' .. field .. '"><span class="mf-limb-owner">' .. owner .. "</span>"
    .. table.concat(cells) .. "</div>"
end

-- A limb view (opponent.limbView's shape) as bound values for one row.
function limbs.values(prefix, view)
  local values = {}
  for _, code in ipairs(LIMBS) do
    local cell = view[limbs.KEYS[code]] or {}
    local key = prefix .. "_" .. code
    local damage = math.floor((cell.damage or 0) + 0.5)
    values[key .. "Label"] = code .. (cell.level or "")
    values[key .. "Pct"] = tostring(damage)
    values[key .. "Bar"] = math.min(damage, 100) .. "%"
    values[key .. "Hurt"] = cell.level and "true" or "false"
    values[key .. "Prepped"] = cell.hits == 1 and "true" or "false"
  end
  return values
end