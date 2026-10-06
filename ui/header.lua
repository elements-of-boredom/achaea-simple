PkCore.ui.header = PkCore.ui.header or {}

local HEADER_HEIGHT = 36
local HEADER_BG_CSS = PkCore.ui.PANEL_CSS
local HEADER_TEXT_CSS = [[background: transparent; color: #e4eee6; font-weight: 700;]]

function PkCore.ui.header.create(container, name, title)
  local bg = Geyser.Label:new({
    name = name .. "_header_bg",
    x = "0%", y = "0%", width = "100%", height = HEADER_HEIGHT,
  }, container)
  bg:setStyleSheet(HEADER_BG_CSS)

  local titleLabel = Geyser.Label:new({
    name = name .. "_header_title",
    x = "0%", y = "0%", width = "100%", height = HEADER_HEIGHT,
    font = "Georgia", fontSize = 12, format = "c",
  }, container)
  titleLabel:setStyleSheet(HEADER_TEXT_CSS)
  titleLabel:echo(title:upper(), "#e4eee6")

  return HEADER_HEIGHT
end