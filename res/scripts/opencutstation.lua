local paramsutil = require "paramsutil"
local func = require "opencut/func"
local pipe = require "opencut/pipe"
local coor = require "opencut/coor"
local trackEdge = require "opencut/trackedge"
local station = require "opencut/stationlib"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {-8, -10, -12}
local trackNumberList = {2, 3, 4, 5, 6, 7, 8, 10, 12}

local tramType = {"NO", "YES", "ELECTRIC"}
local streetProfile = {
    {5.75, "new_small.lua"},
    {8.75, "new_medium.lua"},
    {11.75, "new_large.lua"}
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
    sidenofence = {
        model = "station/train/passenger/opencut/stairs_flat_side_nofence.mdl",
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

local ignoreIf = function(sw) return function(value) return sw and {} or value end end

local retrivePos = function(p)
    local pos, w = table.unpack(p)
    return pos, pos - w + 1, pos + w - 1
end

local makeBuilders = function(config, xOffsets, uOffsets)
    local offsets = func.concat(xOffsets, uOffsets)
    local offsetMax = func.max(offsets, function(l, r) return l.x < r.x end).x + 0.5 * station.trackWidth
    local offsetMin = func.min(offsets, function(l, r) return l.x < r.x end).x - 0.5 * station.trackWidth
    local zOffset = 0.8
    
    local buildSideStairs = function(pos, m)
        return pipe.new
            + func.mapFlatten(uOffsets, function(offset)
                return buildStairs(config, coor.o, m * coor.trans(coor.xyz(offset.x, pos, zOffset)))
            end)
            + func.map(xOffsets, function(offset)
                return newModel(stairModels.side.model, coor.rotZ(math.pi) * m * coor.trans(coor.xyz(offset.x, pos, zOffset)))
            end)
            + func.map({offsetMin, offsetMax}, function(offset)
                return newModel(stairModels.sidenofence.model, coor.scaleX(0.08), coor.rotZ(math.pi) * m * coor.trans(coor.xyz(offset, pos, zOffset)))
            end)
    end
    
    local buildAllStairs = function()
        return pipe.new
            + buildSideStairs(0.5, coor.I())
            + buildSideStairs(-0.5, coor.rotZ(math.pi))
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
            + func.mapFlatten({offsetMin, offsetMax}, function(offset) return
                {
                    newModel(stairModels.intnolane.model, coor.scaleX(0.08), coor.transX(offset) * coor.transZ(zOffset)),
                    newModel(stairModels.intnolane.model, coor.scaleX(0.08), coor.rotZ(math.pi) * coor.transX(offset) * coor.transZ(zOffset)),
                }
            end)
    end
    
    
    local sidePassesLimits = function(w, length, overpasses)
        local intersections = pipe.new * func.map(overpasses, retrivePos)
        return
            offsetMin - 1 - w,
            offsetMax + 1 + w,
            (offsetMin + offsetMax) * 0.5,
            table.unpack(
                (
                pipe.from(-length * 0.5 + 3 * w)
                * function(p) return
                    intersections
                    * pipe.filter(function(p) return p < 0 end)
                    * function(ls) return #ls == 0 and {p} or (ls[1] > p + 2 * w and ls / p or ls) end
                end
                +
                pipe.from(length * 0.5 - 3 * w)
                * function(p) return
                    intersections
                    * pipe.filter(function(p) return p > 0 end)
                    * function(ls) return #ls == 0 and {p} or (ls[1] < p - 2 * w and ls / p or ls) end
                end
                )
                * function(yOffsets) return {yOffsets + {3 + w, -3 - w, 0}, yOffsets + {-8 - w, 8 + w}} end
                * pipe.map(pipe.sort(function(x, y) return x < y end))
    )
    end
    
    local buildSidePasses = function(w, type, tramTrack, length, overpasses, sideA, sideB, canFree)
        
        local xposA, xposB, _, yOffsetsB, yOffsetsA = sidePassesLimits(w, length, overpasses)
        local makeSide = function(xpos, yOffsets, fixed)
            return
                pipe.from(coor.xyz(xpos, yOffsets[1], 0.8), fixed - coor.xyz(xpos, yOffsets[1], 0.8))
                * function(o, vec) return
                    station.toEdges(o, vec, vec * 0.5)
                    * pipe.map2({{false, false}, {false, true}}, function(e, s) return {edge = e, snap = s, align = true, canFree = canFree} end)
                end
                +
                pipe.new * func.map2(func.range(yOffsets, 1, #yOffsets - 1), func.range(yOffsets, 2, #yOffsets),
                    function(f, t) return {
                        edge = station.toEdge(coor.xyz(xpos, f, 0.8), coor.xyz(0, t - f, 0)),
                        snap = { canFree == nil, false },
                        align = false,
                        stopMarker = (t - f > 0 and t - f < w + 3) and {0.1, 0.1} or false
                    } end)
                * pipe.map2({true, false}, function(e, f) return func.with(e, {canFree = f and canFree}) end)
        end
                
        local edges = pipe.new
            + makeSide(xposA, func.filter(yOffsetsA, function(y) return y <= 0 end), coor.xyz(xposA - 2 * w, -length * 0.5, 0.16)) * ignoreIf(not sideA)
            + makeSide(xposA, func.rev(func.filter(yOffsetsA, function(y) return y >= 0 end)), coor.xyz(xposA - 2 * w, length * 0.5, 0.16)) * ignoreIf(not sideA)
            + makeSide(xposB, func.filter(yOffsetsB, function(y) return y <= 0 end), coor.xyz(xposB + 2 * w, -length * 0.5, 0.16)) * ignoreIf(not sideB)
            + makeSide(xposB, func.rev(func.filter(yOffsetsB, function(y) return y >= 0 end)), coor.xyz(xposB + 2 * w, length * 0.5, 0.16)) * ignoreIf(not sideB)
            + ignoreIf(not sideB or length < 160)(
                {
                    {edge = station.toEdge(coor.xyz(xposB, 0, 0.8), coor.xyz(2 * w, 0, -0.8)), snap = {false, true}, align = true, canFree = false}
                }
            )
            + ignoreIf(not sideA)(
                {
                    {edge = {{-17.25 + xposA - w, 0, 0}, {xposA, -8 - w, 0.8}, {0, -1, 0}, {1, 0, 0}}, snap = {false, false}, align = true, canFree = canFree, stopMarker = {nil, 0.7}},
                    {edge = {{-17.25 + xposA - w, 0, 0}, {xposA, 8 + w, 0.8}, {0, 1, 0}, {1, 0, 0}}, snap = {false, false}, align = true, canFree = canFree, stopMarker = {nil, 0.7}},
                    {edge = station.toEdge(coor.xyz(-17.25 + xposA - w, 0, 0), coor.xyz(-25, 0, 0)), snap = {false, true}, align = true, canFree = canFree}
                })
            + func.mapFlatten(overpasses,
                function(overpass)
                    local pos, _ = retrivePos(overpass)
                    return
                        pipe.from(uOffsets)
                        * pipe.map(pipe.select("x"))
                        * pipe.concat({xposA, xposB})
                        * pipe.sort(function(x, y) return x < y end)
                        * function(offsets) return pipe.mapn(
                            func.range(offsets, 1, #offsets - 1), 
                            func.range(offsets, 2, #offsets),
                            func.seq(1, #offsets - 1)
                        )(
                            function(f, t, i) return {
                                edge = station.toEdge(coor.xyz(f, pos, 0.8), coor.xyz(t - f, 0, 0)), 
                                snap = { i == 1 and canFree == nil and sideA, (i == #offsets - 1) and canFree == nil and sideB}, 
                                align = false, 
                                canFree = false
                            } end)
                        end

                        + station.toEdges(coor.xyz(xposA, pos, 0.8), coor.xyz(-3, 0, 0), coor.xyz(-1, 0, 0))
                        * pipe.map2({{false, false}, {false, true}}, function(e, s) return {edge = e, snap = s, align = true, canFree = false} end)
                        * ignoreIf(sideA)
                        + station.toEdges(coor.xyz(xposB, pos, 0.8), coor.xyz(3, 0, 0), coor.xyz(1, 0, 0))
                        * pipe.map2({{false, false}, {false, true}}, function(e, s) return {edge = e, snap = s, align = true, canFree = false} end)
                        * ignoreIf(sideB)
                end)
        
        local alignedEdges = edges * pipe.filter(function(e) return e.align and e.canFree ~= nil end)
        local nonAlignedEdges = edges * pipe.filter(function(e) return not e.align and e.canFree ~= nil end)
        
        local stopList = (nonAlignedEdges + alignedEdges)
            * pipe.map(function(e) return e.stopMarker or false end)
            * function(m) return m * pipe.zip(func.seq(0, #m - 1), {"m", "i"}) end
            * pipe.filter(pipe.select("m"))
        
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
                snapNodes = (sideA and canFree ~= nil) and {} or {1}
            }
        }, stopList
    end
    
    local buildPass = function(pos, hasEntry, config)
        return func.mapFlatten(pos, function(p)
            local pos, f, t = retrivePos(p)
            return
                pipe.new
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
                +
                pipe.new
                * func.seq(f, t)
                * pipe.mapFlatten(function(yOffset)
                    return
                        func.mapFlatten({offsetMin, offsetMax}, function(offset) return
                            {
                                newModel(stairModels.intnolane.model, coor.scaleX(0.08), coor.trans(coor.xyz(offset, yOffset, zOffset))),
                                newModel(stairModels.intnolane.model, coor.scaleX(0.08), coor.rotZ(math.pi), coor.trans(coor.xyz(offset, yOffset, zOffset))),
                                newModel(stairModels.sidenofence.model, coor.scaleX(0.08), coor.trans(coor.xyz(offset, f - 0.5, zOffset))),
                                newModel(stairModels.sidenofence.model, coor.scaleX(0.08), coor.rotZ(math.pi) * coor.trans(coor.xyz(offset, t + 0.5, zOffset))),
                            }
                        end)
                end)
                + buildSideStairs(pos > 0 and t + 0.5 or f - 0.5, pos > 0 and coor.I() or coor.rotZ(math.pi))
                * function(ls) return hasEntry and ls or {} end
                + func.mapFlatten(xOffsets, function(offset) return
                    {
                        newModel(stairModels.side.model, coor.trans(coor.xyz(offset.x, f - 0.5, zOffset))),
                        newModel(stairModels.side.model, coor.rotZ(math.pi) * coor.trans(coor.xyz(offset.x, t + 0.5, zOffset))),
                    }
                end)
                + func.mapFlatten(uOffsets, function(offset) return
                    hasEntry
                    and {
                        newModel(config.passEntry, pos > 0 and coor.I() or coor.rotZ(math.pi),
                            coor.trans(coor.xyz(offset.x, pos > 0 and t - 2.75 or f + 2.75, 0))),
                        pos > 0
                        and newModel(stairModels.side.model, coor.trans(coor.xyz(offset.x, f - 0.5, zOffset)))
                        or newModel(stairModels.side.model, coor.rotZ(math.pi) * coor.trans(coor.xyz(offset.x, t + 0.5, zOffset)))
                    }
                    or {
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
                    return func.seq(math.floor(f - 1), math.ceil(t + 1))
                end)
        
        return pipe.new
            * func.seq(-nSeg * station.segmentLength * 0.5 + 1, nSeg * station.segmentLength * 0.5 - 1)
            * pipe.filter(function(p) return not func.contains(taken, p) end)
            * pipe.mapFlatten(function(i) return {{x = offsetMin - 0.4, n = i}, {x = offsetMax + 0.4, n = i}} end)
            * pipe.map(function(v) return {v.x, v.n, zOffset} end)
            * pipe.map(function(v) return newModel(fence, coor.rotZ(math.pi * 0.5), coor.trans(coor.xyz(table.unpack(v)))) end)
            + pipe.new
            * func.mapFlatten(gaps,
                function(p)
                    local _, f, t = retrivePos(p)
                    return
                        {
                            newModel(fenceInter, coor.flipX(), coor.trans(coor.xyz(offsetMin + 0.25, t, zOffset))),
                            newModel(fenceInter, coor.flipY(), coor.flipX(), coor.trans(coor.xyz(offsetMin + 0.25, f, zOffset))),
                            newModel(fenceInter, coor.trans(coor.xyz(offsetMax - 0.25, t, zOffset))),
                            newModel(fenceInter, coor.flipY(), coor.trans(coor.xyz(offsetMax - 0.25, f, zOffset)))
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
        {
            key = "streetType",
            name = _("Street Type"),
            values = {_("S"), _("M"), _("L")},
            defaultIndex = 0
        },
        paramsutil.makeTramTrackParam1(),
        paramsutil.makeTramTrackParam2(),
        {
            key = "overpassEntry",
            name = _("Entry on overpasses"),
            values = {_("No"), _("Yes")},
            defaultIndex = 1
        },
        {
            key = "busStop",
            name = _("Bus/Tram Stop"),
            values = {_("No"), _("Yes")},
            defaultIndex = 1
        },
        {
            key = "freeNodes",
            name = _("Free streets"),
            values = {_("No"), _("Yes"), ("Not build")},
            defaultIndex = 0
        }
    }
end

local function defaultParams(param)
    local function limiter(d, u)
        return function(v) return v and v < u and v or d end
    end
    
    func.forEach(
        func.filter(params(), function(p) return p.key ~= "tramTrack" end),
        function(i)param[i.key] = limiter(i.defaultIndex or 0, #i.values)(param[i.key]) end)
    
    param.overpassEntry = param.length < 2 and 0 or param.overpassEntry
end

local function updateFn(config)
    local platformPatterns = function(n)
        return pipe.new
            * func.seq(1, n * 0.5)
            * pipe.map(function(x) return x % 2 == 0 and config.platformRepeat or config.platformDwlink end)
            * function(ls) return ls * pipe.rev() + ls end
            * function(ls) return ls * pipe.with({[1] = config.platformStart, [n] = config.platformEnd}) end
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
            defaultParams(params)
            
            local result = {}
            
            local trackType = ({"standard.lua", "high_speed.lua"})[params.trackType + 1]
            local catenary = params.catenary == 1
            local nSeg = platformSegments[params.length + 1]
            local length = nSeg * station.segmentLength
            local nbTracks = trackNumberList[params.nbTracks + 1]
            local height = heightList[params.platformHeight + 1]
            local tramTrack = tramType[params.tramTrack + 1]
            local streetWidth, streetType = table.unpack(streetProfile[params.streetType + 1])
            
            local stairs = stairsConfig[params.platformHeight + 1]
            local overpassEntry = params.overpassEntry == 1
            
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
            
            local x = function()
                if (not overpassEntry) then
                    return (nSeg / 4 + 0.5) * station.segmentLength
                else
                    local pos = (nSeg * 0.5) % 2 and (nSeg * 0.5) or (nSeg * 0.5 - 1)
                    return (pos - 1) * station.segmentLength - 1.5 - streetWidth
                end
            end
            
            local overpasses = pipe.new
                + (func.contains({1, 3}, params.overpass) and {{-x(), streetWidth}} or {})
                + (func.contains({2, 3}, params.overpass) and {{x(), streetWidth}} or {})
            
            local sideA, sideB = func.contains({1, 3}, params.sidepass), func.contains({2, 3}, params.sidepass)
            
            local sideEdges, stops = buildSidePasses(streetWidth, streetType, tramTrack, length, overpasses, sideA, sideB, ({false, true, nil})[params.freeNodes + 1])
            local railEdges = pipe.new + normal + ext1 + ext2
            result.edgeLists = pipe.new
                + {trackEdge.normal(catenary, trackType, false, snapRule(#normal))(railEdges)}
                + sideEdges
            
            local sideWalls =
                pipe.new
                * func.seq(0, nSeg)
                * pipe.map(function(i) return i * station.segmentLength - 0.5 * (station.segmentLength + length) + 0.5 * station.segmentLength end)
                * pipe.map2(sideWallPatterns(nSeg + 1), function(y, m) return {y = y, m = m} end)
                * pipe.mapFlatten(function(s) return {{m = s.m, v = {xMin - 0.45, s.y, height}}, {m = s.m, v = {xMax + 0.45, s.y, height}}} end)
                * pipe.map(function(s)
                    return newModel(s.m,
                        coor.scaleZ((-height + 0.8) / 10),
                        coor.trans(coor.xyz(table.unpack(s.v)))
                ) end)
            
            local paving =
                pipe.new
                * func.seq(-1, nSeg * 4 + 2)
                * pipe.map(function(i) return i * 5 - 0.5 * (5 + length) end)
                * pipe.mapFlatten(function(s) return {{xMin + 0.1, s, height}, {xMax - 0.1, s, height}} end)
                * pipe.map(function(s) return newModel(config.paving, coor.trans(coor.xyz(table.unpack(s)))) end)
            
            result.models =
                pipe.new
                + station.makePlatforms(uOffsets, platformPatterns(nSeg), coor.transZ(0))
                + sideWalls
                + paving
                + buildAllStairs()
                + buildFences(nSeg, overpasses / {0, 1})
                + buildPass(overpasses, overpassEntry, config)
                + {newModel(stationHouse, coor.rotZ(-math.pi * 0.5), coor.transX(xMin - 4.5))}
                + {newModel(config.passEntry, coor.rotZ(math.pi * 0.5), coor.transX(xMax + 4.75))}
            
            result.terminalGroups = station.makeTerminals(xuIndex)
            
            local fPasses = pipe.from(sidePassesLimits(streetWidth, length, overpasses))
                * function(xposA, xposB, _, y, _)
                    local passLength = y[#y] - y[1] + 2 * streetWidth
                    
                    return pipe.new
                        + overpasses
                        * pipe.map(retrivePos)
                        * pipe.map(function(pos) return station.surfaceOf(
                            coor.xyz(4 + streetWidth, 2 * streetWidth, 1),
                            coor.xyz(0.5 * (xposA - 4 + xposA + streetWidth), pos, 0.8)
                        ) end)
                        * ignoreIf(sideA)
                        
                        + overpasses
                        * pipe.map(retrivePos)
                        * pipe.map(function(pos) return station.surfaceOf(
                            coor.xyz(4 + streetWidth, 2 * streetWidth, 1),
                            coor.xyz(0.5 * (xposB + 4 + xposB - streetWidth), pos, 0.8)
                        ) end)
                        * ignoreIf(sideB)
                        
                        + station.surfaceOf(
                            coor.xyz(2 * streetWidth, passLength * 0.5 - 9 - 2 * streetWidth, 1),
                            coor.xyz(xMin - streetWidth - 2, 9 + passLength * 0.25, 0.8)
                        )
                        * function(f) return sideA and {f} or {} end
                        
                        + station.surfaceOf(
                            coor.xyz(2 * streetWidth, passLength * 0.5 - 9 - 2 * streetWidth, 1),
                            coor.xyz(xMin - streetWidth - 2, -9 - passLength * 0.25, 0.8)
                        )
                        * function(f) return sideA and {f} or {} end
                        
                        + station.surfaceOf(
                            coor.xyz(2 * streetWidth, passLength, 1),
                            coor.xyz(xMax + streetWidth + 2, 0, 0.8)
                        )
                        * function(f) return sideB and {f} or {} end
                end
            
            local fBase = station.surfaceOf(coor.xyz(xMax - xMin + 0.5, yMax - yMin, 0), coor.xyz((xMax + xMin) * 0.5, 0, height))
            local fSlot0 = station.surfaceOf(coor.xyz(xMax - xMin - 1.2, yMax - yMin, 0), coor.xyz((xMax + xMin) * 0.5, 0, height))
            local fSlot1 = station.surfaceOf(coor.xyz(2.5, length + 20, 0), coor.xyz(xMin + 0.6, 0, height))
            local fSlot2 = station.surfaceOf(coor.xyz(2.5, length + 20, 0), coor.xyz(xMax - 0.6, 0, height))
            local fOutter = station.surfaceOf(coor.xyz(xMax - xMin + 4, yMax - yMin + 4, 0), coor.xyz((xMax + xMin) * 0.5, 0, 0.8))
            local fHouse = station.surfaceOf(coor.xyz(18, 18, 0), coor.xyz(-7.5, 0, 0))
            
            result.groundFaces = {
                {face = fBase, modes = {{type = "FILL", key = "industry_gravel_small_01"}}},
                {face = fBase, modes = {{type = "STROKE_OUTER", key = "building_paving"}}},
                {face = fHouse, modes = {{type = "FILL", key = "industry_gravel_small_01"}}},
                {face = fHouse, modes = {{type = "STROKE_OUTER", key = "building_paving"}}},
                {face = fSlot1, modes = {{type = "FILL", key = "hole"}}},
                {face = fSlot2, modes = {{type = "FILL", key = "hole"}}},
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
                    faces = {fSlot0},
                    slopeLow = 1e5,
                }
            }
            
            if (params.busStop == 1) then
                result.edgeObjects =
                    func.mapFlatten(stops, function(m)
                        return func.filter({
                            {
                                edge = m.i + #railEdges * 0.5,
                                param = m.m[1],
                                left = false,
                                model = "station/bus/small_new.mdl" -- see res/models/model/
                            },
                            {
                                edge = m.i + #railEdges * 0.5,
                                param = m.m[2],
                                left = true,
                                model = "station/bus/small_new.mdl" -- see res/models/model/
                            }
                        }, pipe.select("param"))
                    end)
            end
            
            result.cost = 60000 + nbTracks * 24000
            result.maintenanceCost = result.cost / 6
            return result
        end
end


local opencutstation = {
    dataCallback = function(config)
        return function()
            return {
                type = "RAIL_STATION",
                description = {
                    name = _("name"),
                    description = _("An open-cut station with passes options.")
                },
                availability = config.availability,
                skipCollision = true,
                autoRemovable = false,
                order = config.order,
                soundConfig = config.soundConfig,
                params = params(),
                updateFn = updateFn(config)
            }
        end
    end
}

return opencutstation
