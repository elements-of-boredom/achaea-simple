PkCore.ui.theme = {
  black      = "020405",
  panel      = "081011",
  border     = "525a6a",
  text       = "ffffff",
  textBody   = "e8ece6",
  textMuted  = "c9ceca",
  mist       = "e6dcc5",
  line       = "69714f",
  line2      = "b18e55",
  violet     = "5b4b6f",
  violet2    = "b49bd3",
  green      = "5d8d57",
  green2     = "b5d78a",
  buttonBg   = "0c1613",
  blood      = "b85d66",
  blood2     = "6f343a",
  player     = "00dede",
  idMuted    = "8a9aa0",
  tabBg         = "04080a",
  tabText       = "8fa19b",
  tabTextActive = "e5eee8",
  tabAccent     = "a5d3ba",
  hp      = "5d8d57",
  hp2     = "b5d78a",
  mana       = "7a8fc3",
  mana2      = "a7b5de",
  endurance  = "d99a3c",
  endurance2 = "f2c572",
  willpower  = "b36cb7",
  willpower2 = "d9a0db",  
  target  = "c7796f",
  target2 = "e2a098",
  good     = "006400",
  warning  = "e6c800",
  critical = "dc3232",
}

function PkCore.ui.theme.rgba(hex, alpha)
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  return string.format("rgba(%d,%d,%d,%d)", r, g, b, alpha)
end

function PkCore.ui.theme.decimal(hex)
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)
  return string.format("%d,%d,%d", r, g, b)
end