PkCore.ui = PkCore.ui or {}
PkCore.ui.chat = PkCore.ui.chat or {}
local chat = PkCore.ui.chat

chat.lines = chat.lines or {}      -- { { c = "tells"|"channels", t = ansi segments }, ... } oldest first
chat.unread = chat.unread or {}
chat.active = chat.active or "all"

local MAX_LINES = 600
local TABS = {
  { key = "all", label = "All" },
  { key = "tells", label = "Tells" },
  { key = "channels", label = "Channels" },
}

-- Filtering is pure CSS: the log's data-filter hides other families' lines; "all" hides nothing.
local CSS = [[
.mf-chat-log[data-filter="tells"] > div:not([data-channel="tells"]),
.mf-chat-log[data-filter="channels"] > div:not([data-channel="channels"]) { display: none; }
.mf-chat-log > div { white-space: pre-wrap; }
]]

-- Appends lines Lua pushes in (a JSON array of {c, t}). Text goes in via textContent, never
-- as HTML. Stays pinned to the bottom unless the player has scrolled up to read.
local SCRIPT = [[
<script>
(function () {
  var log = document.querySelector(".mf-chat-log");
  var MAX = ]] .. MAX_LINES .. [[;
  mudforge.onMessage(function (payload) {
    var pinned = log.scrollHeight - log.scrollTop - log.clientHeight < 20;
    JSON.parse(payload).forEach(function (line) {
      var div = document.createElement("div");
      div.setAttribute("data-channel", line.c);
      if (line.t) {                       // plain-text lines buffered before colour support
        div.textContent = line.t;
      } else {
        var segs = Array.isArray(line.s) ? line.s : Object.values(line.s || {});
        segs.forEach(function (seg) {
          var span = document.createElement("span");
          span.textContent = seg.text;
          if (seg.color) span.style.color = seg.color;
          if (seg.backgroundColor) span.style.backgroundColor = seg.backgroundColor;
          if (seg.italic) span.style.fontStyle = "italic";
          if (seg.underline) span.style.textDecoration = "underline";
          div.appendChild(span);
        });
      }
      log.appendChild(div);
    });
    while (log.children.length > MAX) log.removeChild(log.firstChild);
    if (pinned) log.scrollTop = log.scrollHeight;
  });
  mudforge.send("ready", {});
})();
</script>
]]

function chat.html()
  local buttons = {}
  for _, tab in ipairs(TABS) do
    buttons[#buttons + 1] = '<button data-channel="' .. tab.key .. '"'
      .. ' data-mud-action="chatFilter" data-mud-data="' .. tab.key .. '"'
      .. ' data-mud-bind-attr="aria-pressed:chatOn_' .. tab.key .. '">'
      .. tab.label .. '<span data-mud-bind="chatUnread_' .. tab.key .. '"></span></button>'
  end
  return "<style>" .. CSS .. "</style>"
    .. '<section class="mf-chat" data-field="chat">'
    .. '<div class="mf-panel-heading"><h2>Chat</h2></div>'
    .. '<div class="mf-chat-filters" role="group" aria-label="Chat filters">' .. table.concat(buttons) .. "</div>"
    .. '<div class="mf-chat-log" role="log" aria-live="polite" data-mud-bind-attr="data-filter:chatFilter"></div>'
    .. "</section>"
    .. SCRIPT
end

local function widget()
  return PkCore.ui.layout.widgets.chat
end

local function push(lines)
  local id = widget()
  if id and #lines > 0 then sendWidgetMessage(id, json.encode(lines)) end
end

function chat.refreshTabs()
  local id = widget()
  if not id then return end
  local values = { chatFilter = chat.active }
  for _, tab in ipairs(TABS) do
    local n = chat.unread[tab.key] or 0
    local active = chat.active == tab.key
    values["chatOn_" .. tab.key] = active and "true" or "false"
    values["chatUnread_" .. tab.key] = (n > 0 and not active) and (" (" .. n .. ")") or ""
  end
  setBoundValues(id, values)
end

function chat.select(key)
  chat.active = key
  chat.unread[key] = 0
  chat.refreshTabs()
end

local function noteActivity(key)
  if key == chat.active then return end
  chat.unread[key] = (chat.unread[key] or 0) + 1
end

function chat.onText(message)
  if type(message) ~= "table" or type(message.text) ~= "string" then return end
  local channel = type(message.channel) == "string" and string.lower(message.channel) or ""
  local family = string.find(channel, "tell") and "tells" or "channels"
  local line = { c = family, s = parseAnsiText(message.text) }

  table.insert(chat.lines, line)
  if #chat.lines > MAX_LINES then table.remove(chat.lines, 1) end
  push({ line })

  noteActivity("all")
  noteActivity(family)
  chat.refreshTabs()
end

function chat.attach(id)
  unregisterWidgetEvent(id, "luamsg")
  unregisterWidgetEvent(id, "action")
  registerWidgetEvent(id, "luamsg", function(m)
    if m.event == "ready" then push(chat.lines) end   -- fresh document: replay history
  end)
  registerWidgetEvent(id, "action", function(e)
    if e.action == "chatFilter" then chat.select(e.data) end
  end)
  chat.refreshTabs()
end

onGMCPUpdate("Comm.Channel.Text", chat.onText)
PkCore.ui.layout.setContent("chat", chat.html, chat.attach)