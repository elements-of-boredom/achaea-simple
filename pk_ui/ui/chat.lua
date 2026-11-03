-- Chat panel: tells and channels from GMCP Comm.Channel.Text, with All / Tells / Channels filters.

PkCore.ui = PkCore.ui or {}
PkCore.ui.chat = PkCore.ui.chat or {}
local chat = PkCore.ui.chat

local SAVE_KEY = "chatHistory"   -- for saveTable
local MAX_LINES = 600            -- lines kept, saved and shown
local TRIM_SLACK = 50            -- let the list run this far past MAX_LINES, then trim in one go
local SAVE_DELAY_MS = 5000       -- the world file reaches disk every 5 s anyway

-- Each line: { c = "tells"|"channels", a = raw ANSI text, s = parsed pieces (memory only) }.
-- Lines saved by older versions of this file look like { c, s } or { c, t }; they still load.
chat.lines = chat.lines or {}
chat.unread = chat.unread or {}
chat.active = chat.active or "all"

local TABS = {
    { key = "all",      label = "All" },
    { key = "tells",    label = "Tells" },
    { key = "channels", label = "Channels" },
}
local VALID_TAB = {}
for _, tab in ipairs(TABS) do VALID_TAB[tab.key] = true end

-- ── Saving ──────────────────────────────────────────────────────────────────

-- The saved form: raw text only, so the stored table stays small. A legacy line with no raw
-- text keeps what it has (s or t) until it ages out of the history.
local function savedForm()
    local out = {}
    local lines = chat.lines
    local first = math.max(1, #lines - MAX_LINES + 1)
    for i = first, #lines do
        local l = lines[i]
        if l.a then
            out[#out + 1] = { c = l.c, a = l.a }
        else
            out[#out + 1] = { c = l.c, s = l.s, t = l.t }
        end
    end
    return out
end

local function writeNow()
    if not chat.restored then return end
    saveTable(SAVE_KEY, { lines = savedForm(), unread = chat.unread, active = chat.active })
end

local saveTimer = nil

-- Ask for a save. A burst of lines becomes ONE save, SAVE_DELAY_MS after the first.
local function save()
    if not chat.restored or saveTimer then return end
    saveTimer = addTimer(SAVE_DELAY_MS, function()
        saveTimer = nil
        writeNow()
    end)
    if saveTimer == "" then   -- timer refused (disconnected, or a limit): save right away
        saveTimer = nil
        writeNow()
    end
end

-- Write any pending save now. Called when the plugin stops, so the last lines are kept.
function chat.flush()
    if saveTimer then
        removeTimer(saveTimer)
        saveTimer = nil
    end
    writeNow()
end

-- After a full restart loadTable hands back nested tables that don't act like Lua tables (type() isn't
-- "table"; # and ipairs can fail), so copy the saved lines out one by one, keeping only plain strings.
local function savedLines(saved)
    local out = {}
    local ok, lines = pcall(function() return saved.lines end)
    if not ok or lines == nil then return out end
    for i = 1, MAX_LINES + TRIM_SLACK do
        local got, line = pcall(function() return lines[i] end)
        if not got or line == nil then break end
        local c, a, t = line.c, line.a, line.t
        if (c == "tells" or c == "channels") and (type(a) == "string" or type(t) == "string") then
            out[#out + 1] = { c = c, a = type(a) == "string" and a or nil, t = type(t) == "string" and t or nil }
        end
    end
    return out
end

local function restore()
    if chat.restored or storageStatus() ~= "ready" then return end
    local saved = loadTable(SAVE_KEY) or {}
    local lines = savedLines(saved)
    -- Lines that arrived before storage was ready go after the restored history.
    for _, line in ipairs(chat.lines) do
        lines[#lines + 1] = line
    end
    chat.lines = lines
    for _, tab in ipairs(TABS) do
        local ok, n = pcall(function() return saved.unread[tab.key] end)
        chat.unread[tab.key] = ok and tonumber(n) or chat.unread[tab.key]
    end
    local ok, active = pcall(function() return saved.active end)
    if ok and VALID_TAB[active] then chat.active = active end
    chat.restored = true
end
restore()

-- Save once more when the plugin is turned off, reloaded or its session closes. Chains any
-- onDisable another module defined before this one.
local previousOnDisable = onDisable
function onDisable()
    chat.flush()
    if previousOnDisable then previousOnDisable() end
end

-- ── The widget page ─────────────────────────────────────────────────────────

-- Filtering is pure CSS: the log's data-filter hides other families' lines; "all" hides nothing.
local CSS = [[
.mf-chat-log[data-filter="tells"] > div:not([data-channel="tells"]),
.mf-chat-log[data-filter="channels"] > div:not([data-channel="channels"]) { display: none; }
.mf-chat-log > div { white-space: pre-wrap; }
]]

-- Lua sends { replay = bool, lines = [ {c, s} or {c, t} ] }. Text goes in via textContent, never
-- as HTML. Lines are queued and drawn once per frame: one scroll check, one insert, one scroll.
-- A replay (fresh page) is marked aria-busy, so screen readers don't read out the whole history.
local SCRIPT = [[
<script>
(function () {
  var log = document.querySelector(".mf-chat-log");
  var MAX = ]] .. MAX_LINES .. [[;
  var queue = [];
  var scheduled = false;

  function lineEl(line) {
    var div = document.createElement("div");
    div.setAttribute("data-channel", line.c);
    if (line.t) { div.textContent = line.t; return div; }
    var segs = Array.isArray(line.s) ? line.s : Object.values(line.s || {});
    for (var i = 0; i < segs.length; i++) {
      var seg = segs[i];
      var span = document.createElement("span");
      span.textContent = seg.text;
      if (seg.color) span.style.color = seg.color;
      if (seg.backgroundColor) span.style.backgroundColor = seg.backgroundColor;
      if (seg.italic) span.style.fontStyle = "italic";
      if (seg.underline) span.style.textDecoration = "underline";
      div.appendChild(span);
    }
    return div;
  }

  function flush() {
    scheduled = false;
    var pinned = log.scrollHeight - log.scrollTop - log.clientHeight < 20;
    // Only the newest MAX lines can survive the trim, so don't build the rest.
    var start = Math.max(0, queue.length - MAX);
    var frag = document.createDocumentFragment();
    for (var i = start; i < queue.length; i++) frag.appendChild(lineEl(queue[i]));
    queue = [];
    log.appendChild(frag);
    var extra = log.children.length - MAX;
    while (extra-- > 0) log.removeChild(log.firstChild);
    if (pinned) log.scrollTop = log.scrollHeight;
    log.removeAttribute("aria-busy");
  }

  mudforge.onMessage(function (payload) {
    var msg = JSON.parse(payload);
    var lines = Array.isArray(msg.lines) ? msg.lines : Object.values(msg.lines || {});
    if (msg.replay) {
      log.textContent = "";
      queue = [];
      log.setAttribute("aria-busy", "true");
    }
    for (var i = 0; i < lines.length; i++) queue.push(lines[i]);
    if (!scheduled) { scheduled = true; requestAnimationFrame(flush); }
  });
  mudforge.send("ready", {});
})();
</script>
]]

function chat.html()
    local buttons = {}
    for _, tab in ipairs(TABS) do
        buttons[#buttons + 1] = '<button data-channel="' .. tab.key .. '"' ..
            ' data-mud-action="chatFilter" data-mud-data="' .. tab.key .. '"' ..
            ' data-mud-bind-attr="aria-pressed:chatOn_' .. tab.key .. '">' .. tab.label ..
            '<span data-mud-bind="chatUnread_' .. tab.key .. '"></span></button>'
    end
    return "<style>" .. CSS .. "</style>" .. '<section class="mf-chat" data-field="chat">' ..
        '<div class="mf-panel-heading"><h2>Chat</h2></div>' ..
        '<div class="mf-chat-filters" role="group" aria-label="Chat filters">' .. table.concat(buttons) ..
        "</div>" ..
        '<div class="mf-chat-log" role="log" aria-live="polite" data-mud-bind-attr="data-filter:chatFilter"></div>' ..
        "</section>" .. SCRIPT
end

-- ── Talking to the widget ───────────────────────────────────────────────────

local function widget()
    return PkCore.ui.layout.widgets.chat
end

-- Colour pieces for a line, parsed once and kept in memory.
local function pieces(line)
    if not line.s and line.a then line.s = parseAnsiText(line.a) end
    return line.s
end

local function push(lines, replay)
    local id = widget()
    if not id or (#lines == 0 and not replay) then return end
    local out = {}
    local first = math.max(1, #lines - MAX_LINES + 1)   -- the widget keeps MAX_LINES anyway
    for i = first, #lines do
        local l = lines[i]
        if l.t and not l.a then
            out[#out + 1] = { c = l.c, t = l.t }
        else
            out[#out + 1] = { c = l.c, s = pieces(l) }
        end
    end
    sendWidgetMessage(id, json.encode({ replay = replay and true or false, lines = out }))
end

-- What each tab binding last showed. Only changed values are sent.
local lastSent = {}

function chat.refreshTabs()
    local id = widget()
    if not id then return end
    local changed, any = {}, false
    local function set(name, value)
        if lastSent[name] ~= value then
            lastSent[name] = value
            changed[name] = value
            any = true
        end
    end
    set("chatFilter", chat.active)
    for _, tab in ipairs(TABS) do
        local n = chat.unread[tab.key] or 0
        local active = chat.active == tab.key
        set("chatOn_" .. tab.key, active and "true" or "false")
        set("chatUnread_" .. tab.key, (n > 0 and not active) and (" (" .. n .. ")") or "")
    end
    if any then setBoundValues(id, changed) end
end

function chat.select(key)
    if not VALID_TAB[key] then return end
    chat.active = key
    chat.unread[key] = 0
    chat.refreshTabs()
    save()
end

local function noteActivity(key)
    if key ~= chat.active then
        chat.unread[key] = (chat.unread[key] or 0) + 1
    end
end

-- Drop the oldest lines in one go once the list is TRIM_SLACK past the limit.
local function trim()
    local lines = chat.lines
    local excess = #lines - MAX_LINES
    if excess < TRIM_SLACK then return end
    local kept = {}
    for i = excess + 1, #lines do kept[#kept + 1] = lines[i] end
    chat.lines = kept
end

function chat.onText(message)
    restore()
    if type(message) ~= "table" or type(message.text) ~= "string" then return end
    local channel = type(message.channel) == "string" and string.lower(message.channel) or ""
    local family = string.find(channel, "tell", 1, true) and "tells" or "channels"
    local line = { c = family, a = message.text }

    chat.lines[#chat.lines + 1] = line
    trim()
    push({ line }, false)
    save()

    noteActivity("all")
    noteActivity(family)
    chat.refreshTabs()
end

function chat.attach(id)
    unregisterWidgetEvent(id, "luamsg")
    unregisterWidgetEvent(id, "action")
    registerWidgetEvent(id, "luamsg", function(m)
        if m.event == "ready" then
            -- A fresh page: send the whole history once and every tab value again.
            restore()
            push(chat.lines, true)
            lastSent = {}
            chat.refreshTabs()
        end
    end)
    registerWidgetEvent(id, "action", function(e)
        if e.action == "chatFilter" then chat.select(e.data) end
    end)
    lastSent = {}
    chat.refreshTabs()
end

onGMCPUpdate("Comm.Channel.Text", chat.onText)
PkCore.ui.layout.setContent("chat", chat.html, chat.attach)