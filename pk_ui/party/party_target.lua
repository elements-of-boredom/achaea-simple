-- Party target calls, obeyed only from accepted callers. Reads Comm.Channel.Text, whose
-- `talker` comes from the server, so an illusion can't fake a call.
PkCore.partyTarget = PkCore.partyTarget or {}
local pt = PkCore.partyTarget
pt.callers = pt.callers or {} -- lowercased name -> display name
if pt.listening == nil then pt.listening = true end

-- Longest first: "target changed to" has to win over "target".
local CALL_PREFIXES = { "target changed to", "changed target to", "target change", "targeting", "target" }

local function capitalize(name)
  return name:sub(1, 1):upper() .. name:sub(2):lower()
end

function pt.callerList()
  local names = {}
  for _, display in pairs(pt.callers) do
    if display then table.insert(names, display) end
  end
  table.sort(names)
  return #names > 0 and table.concat(names, ", ") or "none"
end

function pt.addCaller(name)
  pt.callers[name:lower()] = capitalize(name)
  PkCore.note("target callers: " .. pt.callerList())
end

-- Rebuilt rather than callers[key] = nil: a nil'd key still shows up in pairs() here.
function pt.removeCaller(name)
  local kept = {}
  for key, display in pairs(pt.callers) do
    if display and key ~= name:lower() then kept[key] = display end
  end
  pt.callers = kept
  PkCore.note("target callers: " .. pt.callerList())
end

function pt.clearCallers()
  pt.callers = {}
  PkCore.note("target callers cleared")
end

function pt.setListening(on)
  pt.listening = on
  PkCore.note("party target calls " .. (on and "ON" or "OFF"))
end

-- pcaller | pcaller <name> | pcaller remove <name> | pcaller clear
function pt.command(args)
  args = type(args) == "string" and args:lower():match("^%s*(.-)%s*$") or ""
  if args == "" then
    PkCore.note("target callers: " .. pt.callerList() .. (pt.listening and "" or " (not listening)"))
    return
  end
  if args == "clear" or args == "off" then return pt.clearCallers() end
  local removeName = args:match("^remove%s+(%w+)$")
  if removeName then return pt.removeCaller(removeName) end
  local name = args:match("^(%w+)$")
  if name then return pt.addCaller(name) end
  PkCore.note("usage: pcaller [<name> | remove <name> | clear]")
end

-- "Target changed to Bob." -> "Bob"; nil when the speech isn't a target call.
local function calledTarget(speech)
  local lower = speech:lower()
  for _, prefix in ipairs(CALL_PREFIXES) do
    if lower:sub(1, #prefix) == prefix then
      return speech:sub(#prefix + 1):match("^:?%s*([%w'%-]+)[%.!]?%s*$")
    end
  end
end

local function onChannelText(msg)
  if type(msg) ~= "table" or msg.channel ~= "party" then return end
  local talker, text = msg.talker, msg.text
  if type(talker) ~= "string" or type(text) ~= "string" then return end
  local speech = text:gsub("\27%[[%d;]*m", ""):match('says, "(.*)"%s*$')
  if not speech then return end

  local lower = speech:lower()
  if lower:find("^i am calling targets") or lower:find("^i am now calling targets") then
    if PkCore.config.values.partyAutoCaller and not pt.callers[talker:lower()] then
      pt.addCaller(talker)
    end
    return
  end

  if not pt.listening or not pt.callers[talker:lower()] then return end
  local target = calledTarget(speech)
  if not target then return end
  send("st " .. target)
  PkCore.note("target -> " .. target .. " (called by " .. talker .. ")")
  if PkCore.reactor then tempTimer(0.15, PkCore.reactor.evaluate) end -- our target changed
end

onGMCPUpdate("Comm.Channel.Text", onChannelText)

PkCore.registerAlias("PkCore partyTarget caller", [[^pcaller(?:\s+(.+))?$]], [[PkCore.partyTarget.command(matches[2])]])
PkCore.registerAlias("PkCore partyTarget listen", [[^ptlisten\s+(on|off)$]], [[PkCore.partyTarget.setListening(matches[2] == "on")]])