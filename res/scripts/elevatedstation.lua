local laneutil = require "laneutil"
local paramsutil = require "paramsutil"
local func = require "func"
local coor = require "coor"
local trackEdge = require "trackedge"
local station = require "stationlib"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {-10, -12.5, -20}
local trackNumberList = {2, 3, 4, 5, 6, 7, 8, 10, 12}

local newModel = function(m, ...)
    return {
        id = m,
        transf = coor.mul(...)
    }
end

local function snapRule(n) return function(e) return func.filter(func.seq(0, #e - 1), function(i) return (i > n) and (i - 3) % 4 == 0 end) end end

local function params()
    return {
        {
            key = "nbTracks",
            name = _("Number of tracks"),
            values = func.map(trackNumberList, tostring),
        },
        {
            key = "length",
            name = _("Platform length") .. "(m)",
            values = func.map(platformSegments, function(l) return _(tostring(l * station.segmentLength)) end),
            defaultIndex = 2
        },
        paramsutil.makeTrackTypeParam(),
        paramsutil.makeTrackCatenaryParam(),
        {
            key = "trackLayout",
            name = _("Track Layout"),
            values = func.map({1, 2, 3, 4}, tostring),
            defaultIndex = 0
        },
        {
            key = "platformHeight",
            name = _("Depth") .. "(m)",
            values = func.map(heightList, tostring),
            defaultIndex = 1
        },
        paramsutil.makeTramTrackParam1(),
        paramsutil.makeTramTrackParam2()
    }
end



local function defaultParams(params)
    params.trackType = params.trackType or 0
    params.catenary = params.catenary or 1
    params.length = params.length or 2
    params.nbTracks = params.nbTracks or 0
    params.platformHeight = params.platformHeight or 1
    params.tramTrack = params.tramTrack or 0
    params.trackLayout = params.trackLayout or 0
end

local function updateFn(config)
    
    local platformPatterns = function(n)
        local platforms = func.map(func.seq(1, n), function(i) return (i == 0.5 * n) and config.platformDwlink or config.platformRepeat end)
        platforms[1] = config.platformStart
        platforms[n] = config.platformEnd
        return platforms
    end
    local stationHouse = config.stationHouse
    local staires = config.staires
    local sideWall = config.sideWall
    local sideWallFst = config.sideWallFst
    local sideWallLst = config.sideWallLst
    
    
    local sideWallPatterns = function(n, triangle)
        local sideWalls = func.map(func.seq(1, n), function(i) return sideWall end)
        if (triangle) then
            sideWalls[1] = config.sideWallFst
            sideWalls[n] = config.sideWallLst
        end
        return sideWalls
    end
    
    return
        function(params)
            
            local result = {}
            
            local trackType = ({"standard.lua", "high_speed.lua"})[params.trackType + 1]
            local catenary = params.catenary == 1
            local nSeg = platformSegments[params.length + 1]
            local length = nSeg * station.segmentLength
            local nbTracks = trackNumberList[params.nbTracks + 1]
            local height = heightList[params.platformHeight + 1]
            
            local platforms = platformPatterns(nSeg)
            local tramTrack = ({"NO", "YES", "ELECTRIC"})[params.tramTrack + 1]
            
            local levels = {
                {
                    mz = coor.transZ(height),
                    mr = coor.I(),
                    mdr = coor.I(),
                    id = 1,
                    nbTracks = nbTracks,
                    baseX = 0,
                    ignoreFst = ({true, false, true, false})[params.trackLayout + 1],
                    ignoreLst = (nbTracks % 2 == 0 and {false, false, true, true} or {true, true, false, false})[params.trackLayout + 1],
                }
            }
            
            local xOffsets, uOffsets, xuIndex, xParity = station.buildCoors(nSeg)(levels, {}, {}, {}, {})
            
            local function resetParity(offset)
                return {
                    mpt = offset.mpt,
                    mvec = offset.mvec,
                    parity = coor.I(),
                    id = offset.id,
                    x = offset.x
                }
            end
            
            local normal = station.generateTrackGroups(xOffsets, length)
            local ext1 = coor.applyEdges(coor.transY(length * 0.5 + 5), coor.I())(station.generateTrackGroups(func.map(xOffsets, resetParity), 10))
            local ext2 = coor.applyEdges(coor.flipY(), coor.flipY())(ext1)
            
            result.edgeLists = {
                trackEdge.normal(catenary, trackType, false, snapRule(#normal))(func.flatten({normal, ext1, ext2})),
            }
            
            local offsets = func.flatten({xOffsets, uOffsets})
            table.sort(offsets, function(l, r) return l.x < r.x end)
            
            local xMin = offsets[1].x - station.trackWidth
            local xMax = offsets[#offsets].x + station.trackWidth
            local yMin = -0.5 * length - 20
            local yMax = -yMin
            
            local sideWalls = func.mapFlatten({xMin, xMax},
                function(xOffset)
                    return func.map2(func.seq(1, nSeg), sideWallPatterns(nSeg), function(i, p)
                        return newModel(p,
                            coor.scaleZ(-height / 10),
                            coor.trans(coor.xyz(xOffset, i * station.segmentLength - 0.5 * (station.segmentLength + length), height))
                    ) end
                )
                end)
            
            result.models = func.concat(station.makePlatforms(uOffsets, platformPatterns(nSeg), coor.transZ(0.3)), sideWalls)
            
            result.terminalGroups = station.makeTerminals(xuIndex)
            
            -- End of generation
            -- Slope, Height, Mirror treatment
            -- setHeight(result, height)
            local f = {
                {xMin, yMax, height},
                {xMin, yMin, height},
                {xMax, yMin, height},
                {xMax, yMax, height}
            }
            
            result.groundFaces = {
                {face = f, modes = {{type = "FILL", key = "industry_gravel_small_01"}}},
                {face = f, modes = {{type = "STROKE_OUTER", key = "building_paving"}}}
            }
            
            result.terrainAlignmentLists = {
                {
                    type = "LESS",
                    faces = {{
                        {xMin - 2, yMax, 0},
                        {xMin - 2, yMin, 0},
                        {xMin, yMin, 0},
                        {xMin, yMax, 0}
                    }},
                    slopeLow = 0.35,
                    slopeHigh = 0.6,
                },
                {
                    type = "LESS",
                    faces = {{
                        {xMax + 2, yMax, 0},
                        {xMax + 2, yMin, 0},
                        {xMax, yMin, 0},
                        {xMax, yMax, 0}
                    }},
                    slopeLow = 0.35,
                    slopeHigh = 0.6,
                },
                {
                    type = "EQUAL",
                    faces = {f},
                    slopeLow = 0,
                },
            }
            
            
            -- func.forEach(entryLocations, func.bind(addEntry, result))
            result.cost = 60000 + nbTracks * 24000
            result.maintenanceCost = result.cost / 6
            
            return result
        end
end


local elevatedstation = {
    dataCallback = function(config)
        return function()
            return {
                type = "RAIL_STATION",
                description = {
                    name = _("Underground / Multi-level Passenger Station"),
                    description = _("An underground / multi-level passenger station")
                },
                availability = config.availability,
                order = config.order,
                soundConfig = config.soundConfig,
                params = params(),
                updateFn = updateFn(config)
            }
        end
    end
}

return elevatedstation
