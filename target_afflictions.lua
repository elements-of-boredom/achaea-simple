PkCore.target = PkCore.target or {}
PkCore.target.afflictions = PkCore.target.afflictions or {}

local function syncFromAK()
    local list = {}
    if type(affstrack) == "table" and type(affstrack.score) == "table" then
        for name, value in pairs(affstrack.score) do
            if type(value) == "number" and value > 0 then
                table.insert(list, name)
            end
        end
    end
    table.sort(list)
    PkCore.target.afflictions = list
    PkCore.stateChanged()
end

PkCore.trackHandler(registerAnonymousEventHandler("AK got aff", PkCore.protected("target.onAkGotAff", syncFromAK)))
PkCore.trackHandler(registerAnonymousEventHandler("AK lost aff", PkCore.protected("target.onAkLostAff", syncFromAK)))