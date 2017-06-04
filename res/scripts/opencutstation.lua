local laneutil = require "laneutil"
local paramsutil = require "paramsutil"
local func = require "func"
local coor = require "coor"
local trackEdge = require "trackedge"
local station = require "stationlib"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {-8, -10, -12}
local trackNumberList = {2, 3, 4, 5, 6, 7, 8, 10, 12}

local stairModels = {
    last = {
        model = "station/train/passenger/opencut/stairs_last.mdl",
        delta = coor.xyz(0, -1.25, 1)
    },
    rep = {
        model = "station/train/passenger/opencut/stairs.mdl",
        delta = coor.xyz(0, -1.25, 1)
    },
    flat = {
        model = "station/train/passenger/opencut/stairs_flat.mdl",
        delta = coor.xyz(0, -1, 0)
    },
    inter = {
        model = "station/train/passenger/opencut/stairs_inter.mdl",
        delta = coor.xyz(0, -1.75, 0)
    },
    side = {
        model = "station/train/passenger/opencut/stairs_flat_side.mdl",
        delta = coor.xyz(0, 0, 0)
    },
    base = {
        model = "station/train/passenger/opencut/stairs_base.mdl",
        delta = coor.xyz(0, 0, 1)
    },
    int = {
        model = "station/train/passenger/opencut/stairs_flat_int.mdl",
        delta = coor.xyz(0, 0, 0)
    },
}

local fence = "station/train/passenger/opencut/fence_flat_side.mdl"
local fenceInter = "station/train/passenger/opencut/fence_angle.mdl"

local stairsConfig = {
    {
        stairModels.inter,
        stairModels.rep, stairModels.rep, stairModels.rep, stairModels.rep, stairModels.flat,
        stairModels.rep, stairModels.rep, stairModels.rep, stairModels.last
    },
    {
        stairModels.inter,
        stairModels.rep, stairModels.rep, stairModels.rep, stairModels.rep, stairModels.rep, stairModels.flat,
        stairModels.rep, stairModels.rep, stairModels.rep, stairModels.rep, stairModels.last
    },
    {
        stairModels.inter,
        stairModels.rep, stairModels.rep, stairModels.rep, stairModels.rep, stairModels.flat,
        stairModels.rep, stairModels.rep, stairModels.rep, stairModels.rep, stairModels.flat,
        stairModels.rep, stairModels.rep, stairModels.rep, stairModels.last
    },
}

local newModel = function(m, ...)
    return {
        id = m,
        transf = coor.mul(...)
    }
end

local buildStairs = function(seq, c, m, mr)
    m = m or coor.I()
    mr = mr or coor.I()
    local function build(result, left, c)
        if (#left == 0) then
            return result
        else
            local model = table.remove(left)
            return build(func.concat(result, {newModel(model.model, mr, coor.trans(c), m)}), left, c - (model.delta .. mr))
        end
    end
    
    return build({}, func.rev(seq), c)
end

local buildAllStairs = function(config, xOffsets, uOffsets)
    local offsetMax = func.max(func.flatten({uOffsets, xOffsets}), function(l, r) return l.x < r.x end).x
    local offsetMin = func.min(func.flatten({uOffsets, xOffsets}), function(l, r) return l.x < r.x end).x
    local zOffset = 0.8
    return
        func.flatten({
            func.mapFlatten(uOffsets, function(offset)
                return buildStairs(config, coor.o, coor.trans(coor.xyz(offset.x, 0.5, zOffset)))
            end),
            func.mapFlatten(uOffsets, function(offset)
                return buildStairs(config, coor.o, coor.rotZ(math.pi) * coor.trans(coor.xyz(offset.x, -0.5, zOffset)))
            end),
            func.mapFlatten(xOffsets, function(offset)
                return {
                    newModel(stairModels.side.model, coor.trans(coor.xyz(offset.x, -0.5, zOffset))),
                    newModel(stairModels.side.model, coor.rotZ(math.pi) * coor.trans(coor.xyz(offset.x, 0.5, zOffset))),
                }
            end),
            func.mapFlatten(func.concat(xOffsets, uOffsets), function(offset)
                return {
                    newModel(stairModels.int.model, coor.transX(offset.x) * coor.transZ(zOffset)),
                    newModel(stairModels.int.model, coor.rotZ(math.pi) * coor.transX(offset.x) * coor.transZ(zOffset)),
                }
            end),
            func.mapFlatten(uOffsets, function(offset)
                return
                    buildStairs(
                        func.map(func.filter(config, function(m) return m.delta.z > 0 end), function(_) return stairModels.base end),
                        coor.o,
                        coor.transZ(-1 + zOffset) * coor.transX(offset.x)
            )
            end
            ),
            {
                newModel(fenceInter, coor.flipX(), coor.transX(offsetMin - 0.5 * station.trackWidth) * coor.transZ(zOffset)),
                newModel(fenceInter, coor.transX(offsetMax + 0.5 * station.trackWidth) * coor.transZ(zOffset)),
                newModel(fenceInter, coor.flipY(), coor.flipX(), coor.transX(offsetMin - 0.5 * station.trackWidth) * coor.transZ(zOffset)),
                newModel(fenceInter, coor.flipY(), coor.transX(offsetMax + 0.5 * station.trackWidth) * coor.transZ(zOffset))
            }
        })
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
            values = func.map(func.map(heightList, math.floor), tostring),
            defaultIndex = 0
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
        local platforms = func.seqMap({1, n}, function(_) return config.platformRepeat end)
        platforms[0.5 * n] = config.platformDwlink
        platforms[0.5 * n + 1] = config.platformDwlink
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
            
            local stairs = stairsConfig[params.platformHeight + 1]
            
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
            
            local offsets = func.flatten({xOffsets, uOffsets})
            table.sort(offsets, function(l, r) return l.x < r.x end)
            
            local xMin = offsets[1].x - 0.5 * station.trackWidth - 1
            local xMax = offsets[#offsets].x + 0.5 * station.trackWidth + 1
            local yMin = -0.5 * length - 20
            local yMax = -yMin
            
            result.edgeLists = {
                trackEdge.normal(catenary, trackType, false, snapRule(#normal))(func.flatten({normal, ext1, ext2})),
                {
                    type = "STREET",
                    params =
                    {
                        type = "station_new_small.lua",
                        tramTrackType = "NO"
                    },
                    edges = {
                        {{-17.25, 0, 0}, {-20, 0, 0}},
                        {{-37.25, 0, 0}, {-20, 0, 0}}
                    },
                    snapNodes = {1}
                }
            }
            
            local sideWalls =
                func.p
                * func.seq(1, nSeg)
                * func.pi.map(function(i) return i * station.segmentLength - 0.5 * (station.segmentLength + length) end)
                * func.pi.map2(sideWallPatterns(nSeg), function(y, m) return {y = y, m = m} end)
                * func.pi.mapFlatten(function(s) return {{m = s.m, v = {xMin, s.y, height}}, {m = s.m, v = {xMax, s.y, height}}} end)
                * func.pi.map(function(s)
                    return newModel(s.m,
                        -- coor.shearX(math.atan(0.1)),
                        coor.scaleX(2),
                        coor.scaleZ((-height + 0.8) / 10),
                        coor.trans(coor.xyz(table.unpack(s.v)))
                ) end)
                / 0
            
            local wallFences =
                func.p
                * func.seq(2, nSeg * station.segmentLength * 0.5 - 2)
                * func.pi.mapFlatten(function(i) return {{x = xMin + 0.35, n = i}, {x = xMax - 0.35, n = i}} end)
                * func.pi.mapFlatten(function(v) return {{v.x, v.n + 0.75, 0.8}, {v.x, -v.n - 0.75, 0.8}} end)
                * func.pi.map(function(v) return newModel(fence, coor.rotZ(math.pi * 0.5), coor.trans(coor.xyz(table.unpack(v)))) end)
                / 0
            
            result.models = func.flatten(
                {
                    station.makePlatforms(uOffsets, platformPatterns(nSeg), coor.transZ(0)),
                    sideWalls,
                    buildAllStairs(stairs, xOffsets, uOffsets),
                    {newModel(stationHouse, coor.rotZ(-math.pi * 0.5), coor.transX(xMin - 3.75))},
                    wallFences
                }
            )
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
            
            
            local basePt = {
                coor.xyz(-0.5, -0.5, 0),
                coor.xyz(0.5, -0.5, 0),
                coor.xyz(0.5, 0.5, 0),
                coor.xyz(-0.5, 0.5, 0)
            }
            
            local fBase = func.map(basePt,
                function(f) return (f .. coor.scaleX(xMax - xMin) * coor.scaleY(yMax - yMin) * coor.transX((xMax + xMin) * 0.5) * coor.transZ(height)):toTuple() end)
            local fOutter = func.map(basePt,
                function(f) return (f .. coor.scaleX(xMax - xMin + 4) * coor.scaleY(yMax - yMin + 4) * coor.transX((xMax + xMin) * 0.5)):toTuple() end)
            
            local fHouse = func.map(basePt,
                function(f) return (f .. coor.scaleX(18) * coor.scaleY(18) * coor.transX(-7.5)):toTuple() end)
            
            result.groundFaces = {
                {face = fBase, modes = {{type = "FILL", key = "industry_gravel_small_01"}}},
                {face = fBase, modes = {{type = "STROKE_OUTER", key = "building_paving"}}},
                {face = fHouse, modes = {{type = "FILL", key = "industry_gravel_small_01"}}},
                {face = fHouse, modes = {{type = "STROKE_OUTER", key = "building_paving"}}}
            }
            
            result.terrainAlignmentLists = {
                {
                    type = "EQUAL",
                    faces = {fHouse}
                },
                {
                    type = "LESS",
                    faces = {fOutter},
                },
                {
                    type = "EQUAL",
                    faces = {fBase},
                    slopeLow = 0,
                }
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