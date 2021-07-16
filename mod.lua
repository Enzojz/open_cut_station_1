local func = require "opencut_station/func"
function data()
    return {
        info = {
            minorVersion = 1,
            severityAdd = "NONE",
            severityRemove = "CRITICAL",
            name = _("MOD_NAME"),
            description = _("MOD_DESC"),
            authors = {
                {
                    name = "Enzojz",
                    role = "CREATOR",
                    text = "Idee, Scripting",
                    steamProfile = "enzojz",
                    tfnetId = 27218,
                },
            },
            tags = {"Train Station", "Underground Station", "Passenger Station", "Station", "Open-cut station", "Track Asset", "Asset"},
        },
        postRunFn = function(settings, params)
            local tracks = api.res.trackTypeRep.getAll()
            local trackList = {}
            local trackNames = {}
            for __, trackName in pairs(tracks) do
                local track = api.res.trackTypeRep.get(api.res.trackTypeRep.find(trackName))
                local pos = #trackList + 1
                if trackName == "standard.lua" then
                    pos = 1
                elseif trackName == "high_speed.lua" then
                    pos = trackList[1] == "standard.lua" and 2 or 1
                end
                table.insert(trackList, pos, trackName)
                table.insert(trackNames, pos, track.name)
            end
            
            
            local streets = api.res.streetTypeRep.getAll()
            local streetList = {
                {}, {}, {}, {}
            }

            for __, streetName in pairs(streets) do
                local street = api.res.streetTypeRep.get(api.res.streetTypeRep.find(streetName))
                if (#street.categories > 0 and not streetName:match("street_depot/") and not streetName:match("street_station/")) then 
                    local nBackward = #(func.filter(street.laneConfigs, function(l) return (l.forward == false) end))
                    local isOneWay = nBackward == #street.laneConfigs or nBackward == 0
                    table.insert(streetList[(street.country and 2 or 0) + (isOneWay and 2 or 1)], {streetName, street.streetWidth + street.sidewalkWidth * 2, street.sidewalkWidth * 0.5, street.name})
                end
            end
            
            streetList = func.flatten(streetList)
            local streetNames = func.map(streetList, function(s) return s[4] end)
            
            local con = api.res.constructionRep.get(api.res.constructionRep.find("station/opencut_station.con"))
            for i = 1, #con.params do
                local p = con.params[i]
                local param = api.type.ScriptParam.new()
                param.key = p.key
                param.name = p.name
                if (p.key == "trackType") then
                    param.values = trackNames
                elseif (p.key == "streetType") then
                    param.values = streetNames
                else
                    param.values = p.values
                end
                param.defaultIndex = p.defaultIndex or 0
                param.uiType = p.uiType
                con.params[i] = param
            end
            con.updateScript.fileName = "construction/station/opencut_station.updateFn"
            con.updateScript.params = {
                trackList = trackList,
                streetList = streetList,
            }
        end
    }
end
