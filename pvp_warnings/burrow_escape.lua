PkCore.trackTrigger(tempRegexTrigger(
  "^(.+?) stares down at you, the ground violently shuddering with some grim portent\\.$",
  PkCore.protected("burrow.onPortent", function()
    send("cq all|burrow up")
    wsys.boxDisplay("Burrow up now!", "white:red")
  end)))