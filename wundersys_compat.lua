-- Terran eruption has a 10s cooldown that WunderSys doesn't track, so its active-heal
-- and lock-queue paths resend it every pass. Gate those two paths on our own cooldown.
local eruption = { ready = true }
local function eruptionUsed()
  eruption.ready = false
  if eruption.timer then killTimer(eruption.timer) end
  eruption.timer = PkCore.trackTimer(tempTimer(10, function()
    eruption.ready = true
    eruption.timer = nil
  end))
end
PkCore.trackTrigger(tempRegexTrigger("^You may purge yourself of weakness once again\\.$", function()
  eruption.ready = true
end))
local function guardEruption(fn)
  return function(...)
    local realSend = send
    send = function(cmd, ...)
      if cmd == "terran eruption" then
        if not eruption.ready then return end
        eruptionUsed()
      end
      return realSend(cmd, ...)
    end
    local ok, err = pcall(fn, ...)
    send = realSend
    if not ok then error(err, 0) end
  end
end

PkCore.onReady(function()
  local realHmsip = wsys.hmsip
  function wsys.hmsip(hm)
    if hm == "health" and wsys.classTimerExists("firelord") and wsys.aff.kkractlebrand then
      return -- server-side curing handles Kkractle's Brand now; suppress WunderSys's old workaround
    end
    return realHmsip(hm)
  end
  -- Disables WunderSys's own prompt redraw so the native server
  -- prompt (and our @tags) are what actually shows. 
  wsys.promptsub = function() end
   -- keep the unwrapped originals on wsys so a PkCore reload doesn't wrap the wrappers
  wsys.pkOriginal = wsys.pkOriginal or {
    classActiveHeal = wsys.classActiveHeal,
    baselockqueue = wsysbaselockqueue,
  }
  wsys.classActiveHeal = guardEruption(wsys.pkOriginal.classActiveHeal)
  wsysbaselockqueue = guardEruption(wsys.pkOriginal.baselockqueue)
end)
