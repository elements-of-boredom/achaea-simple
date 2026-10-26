local opponent = Opponent

-- Who is in the room with us (GMCP Room.*). Someone out of sight longer than LOST_SIGHT may have
-- cured anything we couldn't see, so they come back with a fresh state (but the same class).
opponent.LOST_SIGHT = 6
-- GMCP gives a player as a table (name, fullname) or a bare name; a JSON null isn't a string.
function opponent.playerName(player)
    if type(player) == "table" then
        player = player.name
    end
    return type(player) == "string" and player ~= "" and player:lower() or nil
end

function opponent.lostSight(key)
    local target = opponent.targets[key]
    if target and not target.leftAt then
        target.leftAt = opponent.host.now()
    end
end

function opponent.inSight(key)
    local target = opponent.targets[key]
    if not target or not target.leftAt then
        return
    end
    if opponent.host.now() - target.leftAt > opponent.LOST_SIGHT then
        local classes, class = target.classes, target.class
        opponent.apply({ kind = "reset", name = target.name })
        local fresh = opponent.targets[key]
        fresh.classes, fresh.class = classes, class
        opponent.host.changed()
    else
        target.leftAt = nil
    end
end

onGMCPUpdate("Room.Players", function(data)
    if type(data) == "table" and type(data.players) == "table" then
        data = data.players
    end
    local here = {}
    for _, player in ipairs(type(data) == "table" and data or {}) do
        local key = opponent.playerName(player)
        if key then
            here[key] = true
        end
    end
    for key in pairs(opponent.targets) do
        if here[key] then
            opponent.inSight(key)
        else
            opponent.lostSight(key)
        end
    end
end)
onGMCPUpdate("Room.AddPlayer", function(data)
    local key = opponent.playerName(data)
    if key then
        opponent.inSight(key)
    end
end)
onGMCPUpdate("Room.RemovePlayer", function(data)
    local key = opponent.playerName(data)
    if key then
        opponent.lostSight(key)
    end
end)

-- We can't find our target where we are: they left (perhaps shrouded, so no GMCP), or we did.
-- These lines name nobody, so they mean the current target.
local NOT_HERE = {
    [[^You detect nothing here by that name\.$]],
}
for _, pattern in ipairs(NOT_HERE) do
    addTrigger(pattern, function()
        local name = opponent.host.target()
        if name then
            opponent.lostSight(name:lower())
        end
    end, { type = "regex" })
end