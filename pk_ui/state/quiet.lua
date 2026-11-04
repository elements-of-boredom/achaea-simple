-- Handle silencing the automated messages we send to setup.
PkCore.quiet = PkCore.quiet or {}
local quiet = PkCore.quiet
quiet.pending = {}

function quiet.send(kind, command)
  quiet.pending[kind] = (quiet.pending[kind] or 0) + 1
  send(command)
end
function quiet.expecting(kind) return (quiet.pending[kind] or 0) > 0 end
function quiet.finish(kind)
  if quiet.expecting(kind) then quiet.pending[kind] = quiet.pending[kind] - 1 end
end

-- Replies no other trigger matches, each with the line that ends it.
local REPLIES = {
  prompt = { lines = { [[^Your custom prompt is now:$]] }, last = [[^\[\*s\] \*h/]] },
  tree = { lines = {}, last = [[^Automatic usage of the tree tattoo (?:enabled|disabled)\.$]] },
}
for kind, reply in pairs(REPLIES) do
  for _, pattern in ipairs(reply.lines) do
    addTrigger(pattern, function() if quiet.expecting(kind) then return false end end, { type = "regex" })
  end
  addTrigger(reply.last, function()
    if not quiet.expecting(kind) then return end
    quiet.finish(kind)
    return false
  end, { type = "regex" })
end

-- The set list ends with a blank line after its total; gag that one blank line and no other.
addTrigger([[^$]], function()
  if quiet.blankAfterSets then
    quiet.blankAfterSets = false
    return false
  end
end, { type = "regex" })