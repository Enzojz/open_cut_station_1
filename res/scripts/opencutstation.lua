local laneutil = require "laneutil"
local paramsutil = require "paramsutil"
local func = require "func"
local pipe = require "pipe"
local coor = require "coor"
local trackEdge = require "trackedge"
local station = require "stationlib"
local dump = require "datadumper"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {-8, -10, -12}
local trackNumberList = {2, 3, 4, 5, 6, 7, 8, 10, 12}

local tramType = {"NO", "YES", "ELECTRIC"}
local streetProfile = {
    {6, "new_small.lua"},
    {9, "new_medium.lua"},
    {12, "new_large.lua"}
}

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
    intnolane = {
        model = "station/train/passenger/opencut/stairs_flat_int_nolane.mdl",
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

local function snapRule(n) return function(e) return func.filter(func.seq(0, #e - 1), function(i) return (i > n) and (i - 3) % 4 == 0 end) end end

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

local retrivePos = function(p)
    local pos, w = table.unpack(p)
    pos = station.segmentLength * pos
    return pos, pos - w + 1, pos + w - 1
end

local makeBuilders = function(config, xOffsets, uOffsets)
    local offsets = func.concat(xOffsets, uOffsets)
    local offsetMax = func.max(offsets, function(l, r) return l.x < r.x end).x + 0.5 * station.trackWidth
    local offsetMin = func.min(offsets, function(l, r) return l.x < r.x end).x - 0.5 * station.trackWidth
    local zOffset = 0.8
    local buildAllStairs = function()
        return pipe.new
            + func.mapFlatten(uOffsets, function(offset)
                return buildStairs(config, coor.o, coor.trans(coor.xyz(offset.x, 0.5, zOffset)))
            end)
            + func.mapFlatten(uOffsets, function(offset)
                return buildStairs(config, coor.o, coor.rotZ(math.pi) * coor.trans(coor.xyz(offset.x, -0.5, zOffset)))
            end)
            + func.mapFlatten(xOffsets, function(offset) return
                {
                    newModel(stairModels.side.model, coor.trans(coor.xyz(offset.x, -0.5, zOffset))),
                    newModel(stairModels.side.model, coor.rotZ(math.pi) * coor.trans(coor.xyz(offset.x, 0.5, zOffset))),
                }
            end)
            + func.mapFlatten(func.concat(xOffsets, uOffsets), function(offset) return
                {
                    newModel(stairModels.int.model, coor.transX(offset.x) * coor.transZ(zOffset)),
                    newModel(stairModels.int.model, coor.rotZ(math.pi) * coor.transX(offset.x) * coor.transZ(zOffset)),
                }
            end)
            + func.mapFlatten(uOffsets, function(offset) return
                pipe.new
                * func.filter(config, function(m) return m.delta.z > 0 end)
                * pipe.map(function(_) return stairModels.base end)
                * func.bind(buildStairs, nil, coor.o, coor.transZ(-1 + zOffset) * coor.transX(offset.x))
            end)
    end
    
    local sidePassesLimits = function(w, length, overpasses)
        local intersections = pipe.new * func.map(overpasses, retrivePos)
        return
            offsetMin - 2 - w,
            offsetMax + 2 + w,
            (offsetMin + offsetMax) * 0.5,
            table.unpack(
                (
                pipe.from(-length * 0.5 + 3 * w)
                * function(p) return
                    intersections
                    * pipe.filter(function(p) return p < 0 end)
                    * function(ls) return #ls == 0 and {p} or (ls[1] > p + 1.5 * w and ls / p or ls) end
                end
                +
                pipe.from(length * 0.5 - 3 * w)
                * function(p) return
                    intersections
                    * pipe.filter(function(p) return p > 0 end)
                    * function(ls) return #ls == 0 and {p} or (ls[1] < p - 1.5 * w and ls / p or ls) end
                end
                )
                * function(yOffsets) return {yOffsets / 0, yOffsets + {-8 - w, 8 + w}} end
                * pipe.map(pipe.sort(function(x, y) return x < y end))
    )
    end
    
    local buildSidePasses = function(w, type, tramTrack, length, overpasses, sideA, sideB)
        local xposA, xposB, xCent, yOffsetsB, yOffsetsA = sidePassesLimits(w, length, overpasses)
        
        local makeSide = function(xpos, yOffsets, fixed)
            return
                pipe.from(coor.xyz(xpos, yOffsets[1], 0.8), fixed - coor.xyz(xpos, yOffsets[1], 0.8))
                * function(o, vec) return
                    station.toEdges(o, vec, vec * 0.25)
                    * pipe.map2({{false, false}, {false, true}}, function(e, s) return {edge = e, snap = s, align = true} end)
                end
                + func.map2(func.range(yOffsets, 1, #yOffsets - 1), func.range(yOffsets, 2, #yOffsets),
                    function(f, t) return {edge = station.toEdge(coor.xyz(xpos, f, 0.8), coor.xyz(0, t - f, 0)), snap = {false, false}, align = false} end)
        end
        
        local ignore = function(sw) return function(value) return sw and value or {} end end
        
        local edges = pipe.new
            + makeSide(xposA, func.filter(yOffsetsA, function(y) return y <= 0 end), coor.xyz(xposA - 2 * w, -length * 0.5, 0.16)) * ignore(sideA)
            + makeSide(xposA, func.rev(func.filter(yOffsetsA, function(y) return y >= 0 end)), coor.xyz(xposA - 2 * w, length * 0.5, 0.16)) * ignore(sideA)
            + makeSide(xposB, func.filter(yOffsetsB, function(y) return y <= 0 end), coor.xyz(xposB + 2 * w, -length * 0.5, 0.16)) * ignore(sideB)
            + makeSide(xposB, func.rev(func.filter(yOffsetsB, function(y) return y >= 0 end)), coor.xyz(xposB + 2 * w, length * 0.5, 0.16)) * ignore(sideB)
            + ignore(sideA)(
                {
                    {edge = {{-17.25 + xposA - w, 0, 0}, {xposA, -8 - w, 0.8}, {0, -1, 0}, {1, 0, 0}}, snap = {false, false}, align = true},
                    {edge = {{-17.25 + xposA - w, 0, 0}, {xposA, 8 + w, 0.8}, {0, 1, 0}, {1, 0, 0}}, snap = {false, false}, align = true},
                    {edge = station.toEdge(coor.xyz(-17.25 + xposA - w, 0, 0), coor.xyz(-5 - w, 0, 0)), snap = {false, true}, align = true}
                })
            + func.mapFlatten(overpasses,
                function(overpass)
                    local pos, _ = retrivePos(overpass)
                    return
                        pipe.from(uOffsets)
                        * pipe.map(pipe.select("x"))
                        * pipe.concat({offsetMin, offsetMax, xposA, xposB})
                        * pipe.sort(function(x, y) return x < y end)
                        * function(offsets) return func.map2(func.range(offsets, 1, #offsets - 1), func.range(offsets, 2, #offsets),
                            function(f, t) return {edge = station.toEdge(coor.xyz(f, pos, 0.8), coor.xyz(t - f, 0, 0)), snap = {false, false}, align = false} end)
                        end
                        + station.toEdges(coor.xyz(xposA, pos, 0.8), coor.xyz(-2, 0, 0), coor.xyz(-2, 0, 0))
                        * pipe.map2({{false, false}, {false, true}}, function(e, s) return {edge = e, snap = s, align = true} end)
                        * ignore(not sideA)
                        + station.toEdges(coor.xyz(xposB, pos, 0.8), coor.xyz(2, 0, 0), coor.xyz(2, 0, 0))
                        * pipe.map2({{false, false}, {false, true}}, function(e, s) return {edge = e, snap = s, align = true} end)
                        * ignore(not sideB)
                end)
        
        local alignedEdges = edges * pipe.filter(function(e) return e.align end)
        local nonAlignedEdges = edges * pipe.filter(function(e) return not e.align end)
        
        local streetProto = function(aligned)
            return {
                type = "STREET",
                alignTerrain = aligned,
                params = {
                    type = type,
                    tramTrackType = tramTrack
                }
            }
        end
        
        return {
            func.with(station.prepareEdges(nonAlignedEdges), streetProto(false)),
            func.with(station.prepareEdges(alignedEdges), streetProto(true)),
            {
                type = "STREET",
                params =
                {
                    type = "station_new_small.lua",
                    tramTrackType = tramTrack
                },
                edges = coor.make(
                    {
                        sideA and station.toEdge(coor.xyz(-17.25, 0, 0), coor.xyz(xposA - w, 0, 0)) or station.toEdge(coor.xyz(-17.25, 0, 0), coor.xyz(-20, 0, 0))
                    }
                ),
                snapNodes = sideA and {} or {1}
            }
        }
    end
    
    local buildPass = function(pos)
        return func.mapFlatten(pos, function(p)
            local pos, f, t = retrivePos(p)
            return pipe.new
                * func.seq(f, t)
                * pipe.mapFlatten(function(yOffset)
                    return
                        func.mapFlatten(offsets, function(offset) return
                            {
                                newModel(stairModels.intnolane.model, coor.trans(coor.xyz(offset.x, yOffset, zOffset))),
                                newModel(stairModels.intnolane.model, coor.rotZ(math.pi) * coor.trans(coor.xyz(offset.x, yOffset, zOffset))),
                            }
                        end)
                end)
                + func.mapFlatten(offsets, function(offset) return
                    {
                        newModel(stairModels.side.model, coor.trans(coor.xyz(offset.x, f - 0.5, zOffset))),
                        newModel(stairModels.side.model, coor.rotZ(math.pi) * coor.trans(coor.xyz(offset.x, t + 0.5, zOffset))),
                    }
                end)
                + func.mapFlatten({f, t, pos}, function(o) return
                    func.mapFlatten(uOffsets, function(offset) return
                        pipe.new
                        * func.filter(config, function(m) return m.delta.z > 0 end)
                        * pipe.map(function(_) return stairModels.base end)
                        * func.bind(buildStairs, nil, coor.o, coor.trans(coor.xyz(offset.x, o, -1 + zOffset)))
                    
                    end
                ) end
        )
        end
    )
    end
    
    local buildFences = function(nSeg, gaps)
        local taken =
            pipe.new
            * func.mapFlatten(gaps,
                function(p)
                    local _, f, t = retrivePos(p)
                    return func.seq(f - 1, t + 1)
                end)
        
        return pipe.new
            * func.seq(-nSeg * station.segmentLength * 0.5 + 1, nSeg * station.segmentLength * 0.5 - 1)
            * pipe.filter(function(p) return not func.contains(taken, p) end)
            * pipe.mapFlatten(function(i) return {{x = offsetMin + 0.35 - 1, n = i}, {x = offsetMax - 0.35 + 1, n = i}} end)
            * pipe.map(function(v) return {v.x, v.n, zOffset} end)
            * pipe.map(function(v) return newModel(fence, coor.rotZ(math.pi * 0.5), coor.trans(coor.xyz(table.unpack(v)))) end)
            + pipe.new
            * func.mapFlatten(gaps,
                function(p)
                    local _, f, t = retrivePos(p)
                    return
                        {
                            newModel(fenceInter, coor.flipX(), coor.trans(coor.xyz(offsetMin, t, zOffset))),
                            newModel(fenceInter, coor.flipY(), coor.flipX(), coor.trans(coor.xyz(offsetMin, f, zOffset))),
                            newModel(fenceInter, coor.trans(coor.xyz(offsetMax, t, zOffset))),
                            newModel(fenceInter, coor.flipY(), coor.trans(coor.xyz(offsetMax, f, zOffset)))
                        }
                end)
    
    end
    
    return offsetMin, offsetMax, buildAllStairs, buildPass, buildFences, buildSidePasses, sidePassesLimits
end

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
        {
            key = "overpass",
            name = _("Overpasses"),
            values = {_("None"), _("A"), _("B"), _("A + B")},
            defaultIndex = 0
        },
        {
            key = "sidepass",
            name = _("Side Passes"),
            values = {_("None"), _("A"), _("B"), _("A + B")},
            defaultIndex = 0
        },
        paramsutil.makeTramTrackParam1(),
        paramsutil.makeTramTrackParam2(),
        {
            key = "streetType",
            name = _("Street Type"),
            values = {_("S"), _("M"), _("L")},
            defaultIndex = 0
        },
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
            local tramTrack = tramType[params.tramTrack + 1]
            local streetWidth, streetType = table.unpack(streetProfile[params.streetType + 1])
            
            local platforms = platformPatterns(nSeg)
            local stairs = stairsConfig[params.platformHeight + 1]
            
            local levels =
                {
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
            
            local xMin, xMax, buildAllStairs, buildPass, buildFences, buildSidePasses, sidePassesLimits = makeBuilders(stairs, xOffsets, uOffsets)
            local yMin = -0.5 * length - 20
            local yMax = -yMin
            
            local overpasses = pipe.new
                + (func.contains({1, 3}, params.overpass) and {{-nSeg / 4 - 0.5, streetWidth}} or {})
                + (func.contains({2, 3}, params.overpass) and {{nSeg / 4 + 0.5, streetWidth}} or {})
            
            local sideA, sideB = func.contains({1, 3}, params.sidepass), func.contains({2, 3}, params.sidepass)
            
            result.edgeLists = pipe.new
                + {trackEdge.normal(catenary, trackType, false, snapRule(#normal))(pipe.new + normal + ext1 + ext2)}
                + buildSidePasses(streetWidth, streetType, tramTrack, length, overpasses, sideA, sideB)
            
            local sideWalls =
                pipe.new
                * func.seq(1, nSeg)
                * pipe.map(function(i) return i * station.segmentLength - 0.5 * (station.segmentLength + length) end)
                * pipe.map2(sideWallPatterns(nSeg), function(y, m) return {y = y, m = m} end)
                * pipe.mapFlatten(function(s) return {{m = s.m, v = {xMin - 1, s.y, height}}, {m = s.m, v = {xMax + 1, s.y, height}}} end)
                * pipe.map(function(s)
                    return newModel(s.m,
                        coor.scaleX(2),
                        coor.scaleZ((-height + 0.8) / 10),
                        coor.trans(coor.xyz(table.unpack(s.v)))
                ) end)
            
            result.models =
                pipe.new
                + station.makePlatforms(uOffsets, platformPatterns(nSeg), coor.transZ(0))
                + sideWalls
                + buildAllStairs()
                + buildFences(nSeg, overpasses / {0, 1})
                + buildPass(overpasses)
                + {newModel(stationHouse, coor.rotZ(-math.pi * 0.5), coor.transX(xMin - 4.75))}
            
            result.terminalGroups = station.makeTerminals(xuIndex)
            
            local basePt = pipe.new * {
                coor.xyz(-0.5, -0.5, 0),
                coor.xyz(0.5, -0.5, 0),
                coor.xyz(0.5, 0.5, 0),
                coor.xyz(-0.5, 0.5, 0)
            }
            
            local fPasses = pipe.from(sidePassesLimits(streetWidth, length, overpasses))
                * function(xposA, xposB, _, y, _)
                    local passLength = y[#y] - y[1] + 2 * streetWidth
                    local ignoreIf = function(c) return function(value) return c and {} or value end end
                    
                    return pipe.new
                        + overpasses
                        * pipe.map(retrivePos)
                        * pipe.map(function(pos) return basePt
                            * pipe.map(function(f) return (f ..
                                coor.scaleX(xposB - xposA + 8)
                                * coor.scaleY(2 * streetWidth)
                                * coor.trans(coor.xyz(0.5 * (xposA + xposB), pos, 0.8))
                                ):toTuple() end)
                        end)
                        * ignoreIf(sideA)
                        
                        + basePt
                        * pipe.map(function(f) return (f ..
                            coor.scaleX(2 * streetWidth)
                            * coor.scaleY(passLength)
                            * coor.transX(xMin - streetWidth - 2)
                            * coor.transZ(0.8)):toTuple() end)
                        * function(f) return sideA and {f} or {} end
                        
                        + overpasses
                        * pipe.map(retrivePos)
                        * pipe.map(function(pos) return basePt
                            * pipe.map(function(f) return (f ..
                                coor.scaleX(xposB - xposA + 8)
                                * coor.scaleY(2 * streetWidth)
                                * coor.trans(coor.xyz(0.5 * (xposA + xposB), pos, 0.8))
                                ):toTuple() end)
                        end)
                        * ignoreIf(sideB)
                        
                        + basePt
                        * pipe.map(function(f) return (f ..
                            coor.scaleX(2 * streetWidth)
                            * coor.scaleY(passLength)
                            * coor.transX(xMax + streetWidth + 2)
                            * coor.transZ(0.8)
                            ):toTuple() end)
                        * function(f) return sideB and {f} or {} end
                end
            
            local fBase = func.map(basePt,
                function(f) return (f .. coor.scaleX(xMax - xMin + 2) * coor.scaleY(yMax - yMin) * coor.transX((xMax + xMin) * 0.5) * coor.transZ(height)):toTuple() end)
            local fOutter = func.map(basePt,
                function(f) return (f .. coor.scaleX(xMax - xMin + 4) * coor.scaleY(yMax - yMin + 4) * coor.transX((xMax + xMin) * 0.5) * coor.transZ(0.8)):toTuple() end)
            
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
                    type = "LESS",
                    faces = {fOutter},
                },
                {
                    type = "EQUAL",
                    faces = fPasses / fHouse
                },
                {
                    type = "EQUAL",
                    faces = {fBase},
                    slopeLow = 0,
                }
            }
            
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
