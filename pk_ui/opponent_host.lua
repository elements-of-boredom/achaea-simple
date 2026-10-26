Opponent = Opponent or {}
Opponent.host = {
    now = PkCore.now,
    note = PkCore.note,
    changed = PkCore.stateChanged,
    target = function() return PkCore.room.targetName() end,
    targetHealth = function() return PkCore.room.targetHpPercent end,
    onPrompt = PkCore.onVitalsChanged,
}
PkCore.opponent = Opponent