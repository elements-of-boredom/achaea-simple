PkCore.ui = PkCore.ui or {}
PkCore.ui.limbs = PkCore.ui.limbs or {}
local limbs = PkCore.ui.limbs

local LIMBS = { "H", "T", "LA", "RA", "LL", "RL" }

-- One limb strip (YOU or TARGET). Static, every limb undamaged, until AK is ported.
function limbs.row(owner, field)
  local cells = {}
  for _, limb in ipairs(LIMBS) do
    cells[#cells + 1] = '<span class="mf-limb" data-limb="' .. limb .. '" data-damaged="false">'
      .. "<b>" .. limb .. '</b><em>0</em><i style="--mf-damage:0%"></i></span>'
  end
  return '<div class="mf-limbs" data-field="' .. field .. '"><span class="mf-limb-owner">' .. owner .. "</span>"
    .. table.concat(cells) .. "</div>"
end