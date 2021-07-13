local paramsutil = require "paramsutil"
local func = require "opencut_station/func"
local pipe = require "opencut_station/pipe"
local coor = require "opencut_station/coor"
local trackEdge = require "opencut_station/trackedge"
local station = require "opencut_station/stationlib"

local platformSegments = {2, 4, 8, 12, 16, 20, 24}
local heightList = {-8, -10, -12}
local trackNumberList = {2, 3, 4, 5, 6, 7, 8, 10, 12}

local tramType = {"NO", "YES", "ELECTRIC"}
local streetProfile = {
    {5.75, "standard/town_small_new.lua"},
    {7.75, "standard/town_medium_new.lua"},
    {11.75, "standard/town_large_new.lua"}
}

local platforms = {
    {
        platformRepeat = "station/opencut_station/era_a/platform_repeat.mdl",
        platformStart = "station/opencut_station/era_a/platform_start.mdl",
        platformEnd = "station/opencut_station/era_a/platform_end.mdl",
        platformDwlink = "station/opencut_station/era_a/platform_downstairs.mdl",
    },
    {
        platformRepeat = "station/opencut_station/era_b/platform_repeat.mdl",
        platformStart = "station/opencut_station/era_b/platform_start.mdl",
        platformEnd = "station/opencut_station/era_b/platform_end.mdl",
        platformDwlink = "station/opencut_station/era_b/platform_downstairs.mdl",
    },
    {
        platformRepeat = "station/opencut_station/era_c/platform_repeat.mdl",
        platformStart = "station/opencut_station/era_c/platform_start.mdl",
        platformEnd = "station/opencut_station/era_c/platform_end.mdl",
        platformDwlink = "station/opencut_station/era_c/platform_downstairs.mdl",
    }
}

local stairModels = {
    last = {
        model = "station/opencut_station/stairs_last.mdl",
        delta = coor.xyz(0, -1.25, 1)
    },
    rep = {
        model = "station/opencut_station/stairs.mdl",
        delta = coor.xyz(0, -1.25, 1)
    },
    flat = {
        model = "station/opencut_station/stairs_flat.mdl",
        delta = coor.xyz(0, -1, 0)
    },
    inter = {
        model = "station/opencut_station/stairs_inter.mdl",
        delta = coor.xyz(0, -1.75, 0)
    },
    side = {
        model = "station/opencut_station/stairs_flat_side.mdl",
        delta = coor.xyz(0, 0, 0)
    },
    base = {
        model = "station/opencut_station/stairs_base.mdl",
        delta = coor.xyz(0, 0, 1)
    },
    int = {
        model = "station/opencut_station/stairs_flat_int.mdl",
        delta = coor.xyz(0, 0, 0)
    },
    intnolane = {
        model = "station/opencut_station/stairs_flat_int_nolane.mdl",
        delta = coor.xyz(0, 0, 0)
    },
    sidenofence = {
        model = "station/opencut_station/stairs_flat_side_nofence.mdl",
        delta = coor.xyz(0, 0, 0)
    },
}

local fence = "station/opencut_station/fence_flat_side.mdl"
local fenceInter = "station/opencut_station/fence_angle.mdl"

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
    return pos, pos - w + 1, pos + w - 1
end

local makeBuilders = function(config, xOffsets, uOffsets)
    local offsets = func.concat(xOffsets, uOffsets)
    local offsetMax = func.max(offsets, function(l, r) return l.x < r.x end).x + 0.5 * station.trackWidth
    local offsetMin = func.min(offsets, function(l, r) return l.x < r.x end).x - 0.5 * station.trackWidth
    local zOffset = 0.8
    
    local buildSideStairs = function(pos, m, isSide)
        return pipe.new
            + func.mapFlatten(uOffsets, function(offset)
                return buildStairs(config, coor.o, m * coor.trans(coor.xyz(offset.x, pos, zOffset)))
            end)
            + (isSide and {} or func.map(xOffsets, function(offset)
                return newModel(stairModels.side.model, coor.rotZ(math.pi) * m * coor.trans(coor.xyz(offset.x, pos, zOffset)))
            end))
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
    
    local buildSidePasses = function(w, type, tramTrack, overpasses, canFree)
        local xposA, xposB = offsetMin, offsetMax
        
        local edges = pipe.new
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
                            func.range(offsets, 2, #offsets)
                            )(
                            function(f, t) return {
                                edge = station.toEdge(coor.xyz(f, pos, 0.8), coor.xyz(t - f, 0, 0)),
                                snap = {false, false},
                                align = true,
                                canFree = false
                            } end)
                        end
                        + station.toEdges(coor.xyz(xposA, pos, 0.8), coor.xyz(-1.5 * w, 0, 0))
                        * pipe.map2({{false, true}}, function(e, s) return {edge = e, snap = s, align = true, canFree = false} end)
                        + station.toEdges(coor.xyz(xposB, pos, 0.8), coor.xyz(1.5 * w, 0, 0))
                        * pipe.map2({{false, true}}, function(e, s) return {edge = e, snap = s, align = true, canFree = false} end)
                end)
        
        local alignedEdges = edges * pipe.filter(function(e) return e.align and e.canFree ~= nil end)
        local nonAlignedEdges = edges * pipe.filter(function(e) return not e.align and e.canFree ~= nil end)
        
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
            func.with(station.prepareEdges(alignedEdges), streetProto(true))
        }
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
                + buildSideStairs(pos > 0 and t + 0.5 or f - 0.5, pos > 0 and coor.I() or coor.rotZ(math.pi), true)
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
    
    return offsetMin, offsetMax, buildAllStairs, buildPass, buildFences, buildSidePasses
end

local function params()
    return {
        {
            key = "nbTracks",
            name = _("MENU_TRACK_NR"),
            values = func.map(trackNumberList, tostring),
        },
        {
            key = "length",
            name = _("MENU_PLATFORM_LENGTH"),
            values = func.map(platformSegments, function(l) return _(tostring(l * station.segmentLength)) end),
            defaultIndex = 2
        },
        {
            key = "trackType",
            name = _("MENU_TRACK_TYPE"),
            uiType = "COMBOBOX",
            values = {_("Standard"), _("High-speed")},
            yearTo = 0
        },
        {
            key = "catenary",
            name = _("MENU_CATENARY"),
            values = {_("No"), _("Yes")},
            defaultIndex = 1,
            yearFrom = 1900,
            yearTo = 0
        },
        {
            key = "trackLayout",
            name = _("MENU_TRACK_LAYOUT"),
            values = func.map({1, 2, 3, 4}, tostring),
            defaultIndex = 0
        },
        {
            key = "platformHeight",
            name = _("MENU_DEPTH") .. "(m)",
            values = func.map(func.map(heightList, math.floor), tostring),
            defaultIndex = 0
        },
        {
            key = "overpass",
            name = _("MENU_OVERPASS"),
            values = {_("MENU_NONE"), _("A"), _("B"), _("A + B")},
            defaultIndex = 0
        },
        {
            key = "overpassEntry",
            name = _("MENU_OVERPASS_ENTRY"),
            values = {_("No"), _("Yes")},
            defaultIndex = 1
        },
        {
            key = "entryType",
            uiType = "ICON_BUTTON",
            name = _("MENU_ENTRY_TYPE"),
            values = func.seqMap({1, 5}, function(i) return ("ui/construction/station/opencut_station/main_building_%d.tga"):format(i) end),
            defaultIndex = 4
        },
        {
            key = "platformEra",
            name = _("MENU_PLATFORM_ERA"),
            values = {_("MENU_ERA_A"), _("MENU_ERA_B"), _("MENU_ERA_C")},
            defaultIndex = 2
        },
        {
            key = "wallType",
            name = _("MENU_WALL_STYLE"),
            values = {
                "ui/construction/station/opencut_station/concrete.tga",
                "ui/construction/station/opencut_station/brick.tga",
                "ui/construction/station/opencut_station/brick_2.tga"
            },
            uiType = "ICON_BUTTON",
            defaultIndex = 0
        },
        {
            key = "streetType",
            name = _("MENU_STREET_TYPE"),
            uiType = "COMBOBOX",
            values = {_("S"), _("M"), _("L")},
            defaultIndex = 0
        },
        paramsutil.makeTramTrackParam1(),
        paramsutil.makeTramTrackParam2(),
        {
            key = "freeNodes",
            name = _("MENU_FREENODE"),
            values = {_("No"), _("Yes"), ("MENU_NO_BUILD")},
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

local function updateFn(params, closureParams)
    
    local config = func.with(
        {
            passEntry = "station/opencut_station/pass_entry.mdl",
            paving = "station/opencut_station/paving_base.mdl",
        }
        , platforms[params.platformEra + 1])
    
    local platformPatterns = function(n)
        return pipe.new
            * func.seq(1, n * 0.5)
            * pipe.map(function(x) return x % 2 == 0 and config.platformRepeat or config.platformDwlink end)
            * function(ls) return ls * pipe.rev() + ls end
            * function(ls) return ls * pipe.with({[1] = config.platformStart, [n] = config.platformEnd}) end
    end
    
    local sideWall = ("station/opencut_station/wall_%d.mdl"):format(params.wallType + 1)
    local sideWallPatterns = function(n)
        local sideWalls = func.map(func.seq(1, n), function(i) return sideWall end)
        return sideWalls
    end
    
    local stationHouse = ("station/opencut_station/entry/main_building_%d.mdl"):format(params.entryType + 1)
    local sizeHouse = (
        {
            {coor.xyz(8, 15, 0), coor.xyz(-7, 0, 0)},
            {coor.xyz(10, 19, 0), coor.xyz(-8, 0, 0)},
            {coor.xyz(8, 22, 0), coor.xyz(-7, 0, 0)},
            {coor.xyz(11, 15, 0), coor.xyz(-7.5, 0, 0)},
            {coor.xyz(16, 25, 0), coor.xyz(-11, 0, 0)}
        }
        )[params.entryType + 1]
    
    
    local result = {}
    
    local trackList = closureParams.trackList
    local trackType = trackList[params.trackType + 1]
    
    -- local trackType = ({"standard.lua", "high_speed.lua"})[params.trackType + 1]
    local catenary = params.catenary == 1
    local nSeg = platformSegments[params.length + 1]
    local length = nSeg * station.segmentLength
    local nbTracks = trackNumberList[params.nbTracks + 1]
    local height = heightList[params.platformHeight + 1]
    local tramTrack = tramType[params.tramTrack + 1]

    
    local streetType, streetWidth = table.unpack(closureParams.streetList[params.streetType + 1])
    streetWidth = (streetWidth - 0.5) * 0.5
    -- local streetWidth, streetType = table.unpack(streetProfile[params.streetType + 1])
    
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
    
    local xMin, xMax, buildAllStairs, buildPass, buildFences, buildSidePasses = makeBuilders(stairs, xOffsets, uOffsets)
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
    
    local sideEdges = buildSidePasses(streetWidth, streetType, tramTrack, overpasses, ({false, true, nil})[params.freeNodes + 1])
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
        + {newModel(stationHouse, coor.rotZ(-math.pi * 0.5), coor.transX(xMin - 0.5))}
        + {newModel(config.passEntry, coor.rotZ(math.pi * 0.5), coor.transX(xMax + 4.75))}
    
    result.terminalGroups = station.makeTerminals(xuIndex)
    
    local fBase = station.surfaceOf(coor.xyz(xMax - xMin + 0.5, yMax - yMin, 0), coor.xyz((xMax + xMin) * 0.5, 0, height))
    local fSlot0 = station.surfaceOf(coor.xyz(xMax - xMin - 1.2, yMax - yMin, 0), coor.xyz((xMax + xMin) * 0.5, 0, height))
    local fSlot1 = station.surfaceOf(coor.xyz(2.5, length + 20, 0), coor.xyz(xMin + 0.6, 0, height))
    local fSlot2 = station.surfaceOf(coor.xyz(2.5, length + 20, 0), coor.xyz(xMax - 0.6, 0, height))
    local fOutter = station.surfaceOf(coor.xyz(xMax - xMin + 4, yMax - yMin + 4, 0), coor.xyz((xMax + xMin) * 0.5, 0, 0.8))
    local fHouse = station.surfaceOf(table.unpack(sizeHouse))
    
    result.groundFaces = {
        {face = fBase, modes = {{type = "FILL", key = "industry_gravel_small_01.lua"}}},
        {face = fBase, modes = {{type = "STROKE_OUTER", key = "building_paving.lua"}}},
        {face = fHouse, modes = {{type = "FILL", key = "industry_gravel_small_01.lua"}}},
        {face = fHouse, modes = {{type = "STROKE_OUTER", key = "building_paving.lua"}}},
        {face = fSlot1, modes = {{type = "FILL", key = "hole.lua"}}},
        {face = fSlot2, modes = {{type = "FILL", key = "hole.lua"}}},
    }
    
    result.terrainAlignmentLists = {
        {
            type = "LESS",
            faces = {fOutter},
        },
        {
            type = "EQUAL",
            faces = {fHouse}
        },
        {
            type = "EQUAL",
            faces = {fSlot0},
            slopeLow = 1e5,
        }
    }
    
    result.cost = 60000 + nbTracks * 24000
    result.maintenanceCost = result.cost / 6
    return result
end

return {
    type = "RAIL_STATION",
    description = {
        name = _("MENU_NAME"),
        description = _("MENU_DESC")
    },
    availability = {
        yearFrom = 1850
    },
    order = 5023,
    soundConfig = {
        soundSet = {name = "station_passenger_new"}
    },
    skipCollision = true,
    autoRemovable = false,
    params = params(),
    updateFn = updateFn
}
