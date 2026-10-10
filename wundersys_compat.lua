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
end)
