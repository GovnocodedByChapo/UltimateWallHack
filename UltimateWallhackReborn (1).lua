require 'lib.moonloader'
local ffi = require 'ffi'
local mem = require "memory"
local imgui = require('imgui')
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local rkeys = require 'rkeys'
imgui.HotKey = require('imgui_addons').HotKey
local window = imgui.ImBool(false)
local getBonePosition = ffi.cast("int (__thiscall*)(void*, float*, int, bool)", 0x5E4280)
local fa = require 'fAwesome5' -- ICONS LIST: https://fontawesome.com/v5.15/icons?d=gallery&s=solid&m=free
local inicfg = require 'inicfg'
local directIni = 'UH_FpsUpByChapo.ini'
local ini = inicfg.load(inicfg.load({
    main = {
        active = false,
        open_bind = '[35]',
    },
    pl = {
        nicks = true,
        workonme = false,
        bones = true,
        box = true,
        tracers = false,
        tracers_mode = 0,
        tracers_thickness = 1,
        bones_thickness = 1,
        box_thickness = 1,
        box_mode = 0,
        bones_distance = 300,
        tracers_distance = 300,
        box_distance = 300,
    },
    ot = {
        pickups = false,
        text3d = false,
        textdraws = false,
        objects = false,
        objects_dist = 30,
    },
    cr = {
        box = false,
        box_thickness = 1,
        box_mode = 0,
        box_dist = 100,
        info = false,
        info_dist = 100,
        workonme = false,
        info_srvid = true,
        info_model = true,
        info_hp = true,
        info_driver = true,
    },
    se = {
        type = 0,
        hotkey = '[18,83]',        
    }
}, directIni))
inicfg.save(ini, directIni)
local tabs = {'PLAYERS', 'VEHICLES', 'OTHER', 'SETTINGS'}
local other_font = renderCreateFont('Tahoma', 8, 5)
local car_font = renderCreateFont('Tahoma', 8, 5)

open_bind = {v = decodeJson(ini.main.open_bind)}

local se = {
    type = imgui.ImInt(ini.se.type),
}

local tab = 1
local active = imgui.ImBool(ini.main.active)
local pl = {
    nicks = imgui.ImBool(ini.pl.nicks),
    workonme = imgui.ImBool(ini.pl.workonme),
    bones = imgui.ImBool(ini.pl.bones),
    box = imgui.ImBool(ini.pl.box),
    tracers = imgui.ImBool(ini.pl.tracers),
    tracers_mode = imgui.ImInt(ini.pl.tracers_mode),
    tracers_thickness = imgui.ImInt(ini.pl.tracers_thickness),
    bones_thickness = imgui.ImInt(ini.pl.bones_thickness),
    box_thickness = imgui.ImInt(ini.pl.box_thickness),
    box_mode = imgui.ImInt(ini.pl.box_mode),

    nicks_distance = imgui.ImFloat(ini.pl.bones_distance),
    bones_distance = imgui.ImFloat(ini.pl.bones_distance),
    tracers_distance = imgui.ImFloat(ini.pl.tracers_distance),
    box_distance = imgui.ImFloat(ini.pl.box_distance),
}

local ot = {
    pickups = imgui.ImBool(ini.ot.pickups),
    text3d = imgui.ImBool(ini.ot.text3d),
    textdraws = imgui.ImBool(ini.ot.textdraws),
    objects = imgui.ImBool(ini.ot.objects),
    objects_dist = imgui.ImFloat(ini.ot.objects_dist),
}

local cr = {
    box = imgui.ImBool(ini.cr.box),
    box_thickness = imgui.ImInt(ini.cr.box_thickness),
    box_mode = imgui.ImInt(ini.cr.box_mode),
    box_dist = imgui.ImFloat(ini.cr.box_dist),
    info = imgui.ImBool(ini.cr.info),
    info_dist = imgui.ImFloat(ini.cr.info_dist),
    workonme = imgui.ImBool(ini.cr.workonme),

    info_srvid = imgui.ImBool(ini.cr.info_srvid),
    info_model = imgui.ImBool(ini.cr.info_model),
    info_hp = imgui.ImBool(ini.cr.info_hp),
    info_driver = imgui.ImBool(ini.cr.info_driver),
}

function onSendRpc(id, bs)
    if id == 50 then
        local cmd_len = raknetBitStreamReadInt32(bs)
        local cmd_text = raknetBitStreamReadString(bs, cmd_len)
        if cmd_text == '/uwh' then
            window.v = not window.v
            return false
        end
    end
end

local font_nick = renderCreateFont('Tahoma', 10, 4)
local font_nick_stats = renderCreateFont('Tahoma', 9, 4)

function renderDrawBar(posX, posY, sizeX, sizeY, value, shownumber, color)
    renderDrawBoxWithBorder(posX, posY, sizeX, sizeY, color, 2, 0x80000000)
    renderFontDrawText(font_nick_stats, value, posX + sizeX / 2 - renderGetFontDrawTextLength(font_nick_stats, tostring(value)) / 2, posY + sizeY / 2 - renderGetFontDrawHeight(font_nick_stats) / 2, 0xFFFFFFFF, 0x90000000)
end

function main()
    while not isSampAvailable() do wait(200) end
    hotkey_id = rkeys.registerHotKey(open_bind.v, 1, false,
        function()
            if not sampIsChatInputActive() and not sampIsDialogActive() then
                active.v = not active.v
                addOneOffSound(0.0, 0.0, 0.0, 1139)
            end
        end
    )

    
    imgui.Process = false
    window.v = false  --show window on start
    --print()
    while true do
        wait(0)
        imgui.Process = window.v
        if active.v then
            --PEDS
            for k, v in pairs(getAllChars()) do
                if pl.workonme.v == false and v ~= PLAYER_PED or pl.workonme.v == true then 
                    
                    local resX, resY = getScreenResolution()
                    local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                    local pedX, pedY, pedZ = getCharCoordinates(v)
                    local prX, prY = convert3DCoordsToScreen(pedX, pedY, pedZ)
                    local result, id = sampGetPlayerIdByCharHandle(v)
                    if result and isCharOnScreen(v) then
                        local color = tonumber("0xFF"..(("%X"):format(sampGetPlayerColor(id))):gsub(".*(......)", "%1"))--sampGetPlayerColor(id)
                        -- BONES
                        
                        local dist = getDistanceBetweenCoords3d(myX, myY, myZ, pedX, pedY, pedZ)
                        if pl.bones.v and pl.bones_distance.v >= dist then
                            local i = v
                            local thickness = pl.bones_thickness.v
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(6, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(7, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(7, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(8, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(8, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(6, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)

                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(1, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(4, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(4, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(8, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)

                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(21, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(22, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(22, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(23, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(23, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(24, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(24, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(25, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)

                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(31, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(32, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(32, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(33, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(33, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(34, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(34, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(35, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)

                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(1, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(51, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(51, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(52, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(52, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(53, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(53, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(54, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)

                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(1, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(41, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(41, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(42, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(42, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(43, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                            
                            pos1X, pos1Y, pos1Z = getBodyPartCoordinates(43, i)
                            pos2X, pos2Y, pos2Z = getBodyPartCoordinates(44, i)
                            
                            pos1, pos2 = convert3DCoordsToScreen(pos1X, pos1Y, pos1Z)
                            pos3, pos4 = convert3DCoordsToScreen(pos2X, pos2Y, pos2Z)
                            renderDrawLine(pos1, pos2, pos3, pos4, thickness, color)
                        end
                        --TRACERS 
                        if pl.tracers.v and pl.tracers_distance.v >= dist then
                            local tracer_pointFrom = {x = 0, y = 0} 
                            if pl.tracers_mode.v == 0 then
                                tracer_pointFrom.x, tracer_pointFrom.y = convert3DCoordsToScreen(myX, myY, myZ)
                            elseif pl.tracers_mode.v == 1 then
                                tracer_pointFrom.x, tracer_pointFrom.y = resX / 2, 0
                            elseif pl.tracers_mode.v == 2 then
                                tracer_pointFrom.x, tracer_pointFrom.y = resX / 2, resY
                            end
                            if isPointOnScreen(pedX, pedY, pedZ, 1) then
                                renderDrawLine(tracer_pointFrom.x, tracer_pointFrom.y, prX, prY, pl.tracers_thickness.v, color)
                            end
                        end
                        -- BOXES
                        if pl.box.v and pl.box_distance.v >= dist then
                            if pl.box_mode.v == 0 then
                                local c = getCharModelCornersIn2d(getCharModel(v), v)
                                renderDrawLine(c[1][1], c[1][2], c[2][1], c[2][2], pl.box_thickness.v, color)
                                renderDrawLine(c[2][1], c[2][2], c[3][1], c[3][2], pl.box_thickness.v, color)
                                renderDrawLine(c[3][1], c[3][2], c[4][1], c[4][2], pl.box_thickness.v, color)
                                renderDrawLine(c[4][1], c[4][2], c[1][1], c[1][2], pl.box_thickness.v, color)
                                renderDrawLine(c[5][1], c[5][2], c[6][1], c[6][2], pl.box_thickness.v, color)
                                renderDrawLine(c[6][1], c[6][2], c[7][1], c[7][2], pl.box_thickness.v, color)
                                renderDrawLine(c[7][1], c[7][2], c[8][1], c[8][2], pl.box_thickness.v, color)
                                renderDrawLine(c[8][1], c[8][2], c[5][1], c[5][2], pl.box_thickness.v, color)
                                renderDrawLine(c[1][1], c[1][2], c[5][1], c[5][2], pl.box_thickness.v, color)
                                renderDrawLine(c[2][1], c[2][2], c[8][1], c[8][2], pl.box_thickness.v, color)
                                renderDrawLine(c[3][1], c[3][2], c[7][1], c[7][2], pl.box_thickness.v, color)
                                renderDrawLine(c[4][1], c[4][2], c[6][1], c[6][2], pl.box_thickness.v, color)
                            elseif pl.box_mode.v == 1 then
                                size = 1
                                size_vertical = 0.3
                                --type 1 (by Head)
                                local head_pos = {getBodyPartCoordinates(8, v)}
                                local leg_pos = {getBodyPartCoordinates(44, v)}
                                local pos_1 = {convert3DCoordsToScreen(head_pos[1], head_pos[2], head_pos[3] + 0.2)}
                                local pos_2 = {convert3DCoordsToScreen(head_pos[1], head_pos[2], head_pos[3] - (head_pos[3] - leg_pos[3]) - 0.1)}
                                a = boxWidth(pos_1[2], pos_2[2])
                                local box_corners = {
                                    {pos_1[1] - a, pos_1[2]},
                                    {pos_1[1] + a, pos_1[2]},
                                    {pos_2[1] - a, pos_2[2]},
                                    {pos_2[1] + a, pos_2[2]}
                                }
                                renderDrawLine(box_corners[1][1], box_corners[1][2], box_corners[2][1], box_corners[2][2], pl.box_thickness.v, color)
                                renderDrawLine(box_corners[3][1], box_corners[3][2], box_corners[4][1], box_corners[4][2], pl.box_thickness.v, color)
                                renderDrawLine(box_corners[1][1], box_corners[1][2], box_corners[3][1], box_corners[3][2], pl.box_thickness.v, color)
                                renderDrawLine(box_corners[2][1], box_corners[2][2], box_corners[4][1], box_corners[4][2], pl.box_thickness.v, color)
                            end
                        end

                        -- NAMES
                        if pl.nicks.v and pl.nicks_distance.v >= dist then
                            headX, headY, headZ = getBodyPartCoordinates(1, v)
                            nrX, nrY = convert3DCoordsToScreen(headX, headY, headZ - 1)
                            local nicktext = sampGetPlayerNickname(id)..' {ffffff}['..id..']'
                            renderFontDrawText(font_nick, nicktext, nrX - renderGetFontDrawTextLength(font_nick, nicktext) / 2, nrY, color, 0x90000000)

                            
                            local size = {x = 50, y = 10}
                            renderFontDrawText(font_nick_stats, '{ff004d}HP: {ffffff}'.. sampGetPlayerHealth(id), nrX - renderGetFontDrawTextLength(font_nick_stats, 'HP: '.. getCharHealth(v)) / 2, nrY + 20, 0xFFFFFFFF, 0x90000000)
                            --renderDrawBar(nrX - size.x / 2, nrY + 20, size.x, size.y, getCharHealth(v), true, 0xFFff004d)

                            local armour = sampGetPlayerArmor(id)
                            if armour > 0 then
                                renderFontDrawText(font_nick_stats, '{00a2ff}AR:{ffffff} '.. armour, nrX - renderGetFontDrawTextLength(font_nick_stats, 'AR: '.. armour) / 2, nrY + 20, 0xFFFFFFFF, 0x90000000)
                            
                                --renderDrawBar(nrX - size.x / 2, nrY + 50, size.x, size.y, armour, true, 0xFF00a2ff)
                            end

                        end
                    end
                end
            end 

            -- VEHS
            for k, v in pairs(getAllVehicles()) do
                if cr.workonme.v == false and v ~= getSelfVeh() or cr.workonme.v == true then 
                    if isCarOnScreen(v) then
                        local x, y, z = getCarCoordinates(v)
                        local rx, ry = convert3DCoordsToScreen(x, y, z)
                        local driver = getDriverOfCar(v)
                         
                        if driver == -1 or driver == nil then
                            color = -1
                            driverId = 0
                        else
                            driverId = select(2, sampGetPlayerIdByCharHandle(v))
                            color = tonumber("0xFF"..(("%X"):format(sampGetPlayerColor(driverId))):gsub(".*(......)", "%1"))
                        end
                        local myX, myY, myZ = getCharCoordinates(PLAYER_PED)
                        if cr.box.v and getDistanceBetweenCoords3d(myX, myY, myZ, x, y, z) < cr.box_dist.v then
                            local c = getCarModelCornersIn2d(getCarModel(v), v)
                            if cr.box_mode.v == 0 then

                                renderDrawLine(c[1][1], c[1][2], c[2][1], c[2][2], cr.box_thickness.v, color)
                                renderDrawLine(c[2][1], c[2][2], c[3][1], c[3][2], cr.box_thickness.v, color)
                                renderDrawLine(c[3][1], c[3][2], c[4][1], c[4][2], cr.box_thickness.v, color)
                                renderDrawLine(c[4][1], c[4][2], c[1][1], c[1][2], cr.box_thickness.v, color)
                                renderDrawLine(c[5][1], c[5][2], c[6][1], c[6][2], cr.box_thickness.v, color)
                                renderDrawLine(c[6][1], c[6][2], c[7][1], c[7][2], cr.box_thickness.v, color)
                                renderDrawLine(c[7][1], c[7][2], c[8][1], c[8][2], cr.box_thickness.v, color)
                                renderDrawLine(c[8][1], c[8][2], c[5][1], c[5][2], cr.box_thickness.v, color)
                                renderDrawLine(c[1][1], c[1][2], c[5][1], c[5][2], cr.box_thickness.v, color)
                                renderDrawLine(c[2][1], c[2][2], c[8][1], c[8][2], cr.box_thickness.v, color)
                                renderDrawLine(c[3][1], c[3][2], c[7][1], c[7][2], cr.box_thickness.v, color)
                                renderDrawLine(c[4][1], c[4][2], c[6][1], c[6][2], cr.box_thickness.v, color)
                            elseif cr.box_mode.v == 0 then
                                size = 1
                                size_vertical = 0.3
                                --type 1 (by Head)

                                local head_pos = {c[1]}
                                local leg_pos = {c[6]}
                                local pos_1 = {convert3DCoordsToScreen(head_pos[1], head_pos[2], head_pos[3] + 0.2)}
                                local pos_2 = {convert3DCoordsToScreen(head_pos[1], head_pos[2], head_pos[3] - (head_pos[3] - leg_pos[3]) - 0.1)}
                                a = boxWidth(pos_1[2], pos_2[2])
                                local box_corners = {
                                    {pos_1[1] - a, pos_1[2]},
                                    {pos_1[1] + a, pos_1[2]},
                                    {pos_2[1] - a, pos_2[2]},
                                    {pos_2[1] + a, pos_2[2]}
                                }
                                renderDrawLine(box_corners[1][1], box_corners[1][2], box_corners[2][1], box_corners[2][2], cr.box_thickness.v, color)
                                renderDrawLine(box_corners[3][1], box_corners[3][2], box_corners[4][1], box_corners[4][2], cr.box_thickness.v, color)
                                renderDrawLine(box_corners[1][1], box_corners[1][2], box_corners[3][1], box_corners[3][2], cr.box_thickness.v, color)
                                renderDrawLine(box_corners[2][1], box_corners[2][2], box_corners[4][1], box_corners[4][2], cr.box_thickness.v, color)
                            
                            end
                        end
                        if cr.info.v and getDistanceBetweenCoords3d(myX, myY, myZ, x, y, z) < cr.info_dist.v and select(1, sampGetVehicleIdByCarHandle(v)) then

                            local text = (cr.info_srvid.v and 'ID: '..select(2, sampGetVehicleIdByCarHandle(v))..'\n' or '')..(cr.info_model.v and 'Model: '..getNameOfVehicleModel(getCarModel(v))..' ('..getCarModel(v)..')\n' or '')..(cr.info_hp.v and 'HP: '..getCarHealth(v)..'\n' or '')..(cr.info_driver.v and 'Driver: '..' ('..driverId..')'..'\n' or '')

                            
                            renderFontDrawText(car_font, text, rx, ry, color, 0x90000000)
                        end
                    end
                end
            end

            -- OTHER
            if ot.objects.v then
                for k, v in pairs(getAllObjects()) do
                    local mx, my, mz = getCharCoordinates(PLAYER_PED)
                    local x, y, z = getObjectCoordinates(v)
                    if isObjectOnScreen(v) and getDistanceBetweenCoords3d(mx, my, mz, x, y, z) < ot.objects_dist.v then
                        local rx, ry = convert3DCoordsToScreen(x, y, z)
                        local model = getObjectModel(v)
                        local id = sampGetObjectSampIdByHandle(v)
                        local text = 'Object | ID: '..id..', Model: '..model
                        renderFontDrawText(other_font, text, rx - renderGetFontDrawTextLength(other_font, text) / 2, ry, 0xFFFFFFFF, 0x90000000)
                    end
                end
            end
            -- PICKUPS
            if ot.pickups.v then
                for i = 0, 4096 do
                    local handle = sampGetPickupHandleBySampId(i)  
                    if doesPickupExist(handle) then
                        local x, y, z = getPickupCoordinates(handle)
                        if isPointOnScreen(x, y, z, 1) then
                            local rx, ry = convert3DCoordsToScreen(x, y, z)
                            local pip_text = 'Pickup ID: '..i
                            renderFontDrawText(other_font, pip_text, rx - renderGetFontDrawTextLength(other_font, pip_text) / 2, ry - renderGetFontDrawHeight(other_font), 0xFFFFFFFF, 0x90000000)
                        end
                    end
                end
            end

            if ot.text3d.v then
                for i = 0, 4096 do
                    if sampIs3dTextDefined(i) then
                        local string, color, x, y, z, distance, ignoreWalls, playerId, vehicleId = sampGet3dTextInfoById(i)
                        if isPointOnScreen(x, y, z, 1) then
                            local rx, ry = convert3DCoordsToScreen(x, y, z)
                            local pip_text = '3D Text: ID: '..i..', Dist:'..distance..', ignoreWalls: '..tostring(ignoreWalls)..', playerId: '..playerId..', vehId: '..vehicleId
                            renderFontDrawText(other_font, pip_text, rx - renderGetFontDrawTextLength(other_font, pip_text) / 2, ry - renderGetFontDrawHeight(other_font), 0xFFFFFFFF, 0x90000000)
                        end
                    end
                end
            end

            if ot.textdraws.v then
                for i = 0, 4096 do
                    if sampTextdrawIsExists(i) then
                        local x, y = sampTextdrawGetPos(i)
                        local rx, ry = convertGameScreenCoordsToWindowScreenCoords(x, y)
                        renderFontDrawText(other_font, i, rx, ry, 0xFFFFFFFF, 0x90000000)
                    end
                end
            end
        end
    end
end

function getSelfVeh()
    if isCharInAnyCar(PLAYER_PED) then
        return storeCarCharIsInNoSave(PLAYER_PED)
    else
        return -2281337
    end
end
   
local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fa-solid-900.ttf', 14.0, font_config, fa_glyph_ranges)
    end
end


function save()
    ini.pl.bones_distance = pl.nicks_distance.v
    ini.pl.bones_distance = pl.bones_distance.v
    ini.pl.tracers_distance = pl.tracers_distance.v
    ini.pl.box_distance = pl.box_distance.v

    ini.cr.info_srvid = cr.info_srvid.v
    ini.cr.info_model = cr.info_model.v
    ini.cr.info_hp = cr.info_hp.v
    ini.cr.info_driver = cr.info_driver.v

    ini.pl.nicks = pl.nicks.v
    ini.main.open_bind = encodeJson(open_bind.v)
    ini.pl.workonme = pl.workonme.v
    ini.pl.bones = pl.bones.v
    ini.pl.box = pl.box.v
    ini.pl.tracers = pl.tracers.v
    ini.pl.tracers_mode = pl.tracers_mode.v
    ini.pl.tracers_thickness = pl.tracers_thickness.v
    ini.pl.bones_thickness = pl.bones_thickness.v
    ini.pl.box_thickness = pl.box_thickness.v
    ini.pl.box_mode = pl.box_mode.v

    ini.ot.pickups = ot.pickups.v
    ini.ot.text3d = ot.text3d.v
    ini.ot.textdraws = ot.textdraws.v
    ini.ot.objects = ot.objects.v
    ini.ot.objects_dist = ot.objects_dist.v

    ini.cr.box = cr.box.v
    ini.cr.box_thickness = cr.box_thickness.v
    ini.cr.box_mode = cr.box_mode.v
    ini.cr.box_dist = cr.box_dist.v
    ini.cr.info = cr.info.v
    ini.cr.info_dist = cr.info_dist.v
    ini.cr.workonme = cr.workonme.v

    inicfg.save(ini, directIni)
end

function updateFont(font_handle, name, size, flags)
    if font_handle ~= nil then
        renderReleaseFont(font_handle)
    end
    font_handle = renderCreateFont(hame, size, flags)
end

function imgui.OnDrawFrame()
    if window.v then
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 400, 200 -- WINDOW SIZE
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2 - sizeX / 2, resY / 2 - sizeY / 2), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.Begin('chapo\'s Ultimate Wallhack', window, imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.NoResize)
        --window code
        
        
        imgui.BeginChild('tabs', imgui.ImVec2(100, sizeY - 5), true)
        imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.16, 0.18, 0.22, 1))
        imgui.Checkbox('Enabled', active)
        imgui.PopStyleColor()
        imgui.CTab(fa.ICON_FA_USER, 'PLAYERS', 1)
        imgui.CTab(fa.ICON_FA_CAR, 'CAR', 2)
        imgui.CTab(fa.ICON_FA_ELLIPSIS_H, 'OTHER', 3)
        imgui.CTab(fa.ICON_FA_SLIDERS_H, 'SETTINGS', 4)
        imgui.SetCursorPos(imgui.ImVec2(100 / 2 - imgui.CalcTextSize('UWH by chapo').x / 2, sizeY - 22))
        imgui.Text('UWH by chapo')
        imgui.EndChild()

        imgui.SetCursorPos(imgui.ImVec2(5 + 100 + 5, 5))
        imgui.BeginChild('main', imgui.ImVec2(sizeX - 10 - 100 - 5, sizeY - 5), true)
            imgui.PushStyleColor(imgui.Col.FrameBg, imgui.ImVec4(0.16, 0.18, 0.22, 1))
        
            imgui.SetCursorPos(imgui.ImVec2(5, 8))
            imgui.Text(string.upper("chapo's Ultimate Wallhack: "..tabs[tab]))
            imgui.SetCursorPos(imgui.ImVec2(sizeX - 10 - 100 - 5 - 20 - 5, 5))
            if imgui.Button(fa.ICON_FA_TIMES, imgui.ImVec2(20, 20)) then window.v = false save() end
            imgui.Separator()
            local click_icon = fa.ICON_FA_MOUSE_POINTER
            if tab == 1 then
                imgui.Checkbox('Names', pl.nicks) if imgui.IsItemClicked(1) then imgui.OpenPopup('Nicks WH') end
                imgui.Checkbox('Work on me', pl.workonme)
                imgui.Checkbox('BOX '..click_icon, pl.box) if imgui.IsItemClicked(1) then imgui.OpenPopup('Box WH') end
                imgui.Checkbox('Bone '..click_icon, pl.bones) if imgui.IsItemClicked(1) then imgui.OpenPopup('Bone WH') end
                imgui.Checkbox('Tracers '..click_icon, pl.tracers) if imgui.IsItemClicked(1) then imgui.OpenPopup('Tracers WH') end
            elseif tab == 2 then
                
                imgui.Checkbox('Work on my car', cr.workonme)
                imgui.Checkbox('BOX '..click_icon, cr.box) if imgui.IsItemClicked(1) then imgui.OpenPopup('Car Box WH') end
                imgui.Checkbox('Info '..click_icon, cr.info) if imgui.IsItemClicked(1) then imgui.OpenPopup('Car Info WH') end
            elseif tab == 3 then
                imgui.Checkbox('Textdraws', ot.textdraws)
                imgui.Checkbox('3D Text', ot.text3d)
                imgui.Checkbox('Pickups', ot.pickups)
                imgui.Checkbox('Objects '..click_icon, ot.objects) if imgui.IsItemClicked(1) then imgui.OpenPopup('Objects WH') end
            elseif tab == 4 then
                imgui.Text('Enable/Disable:')
                imgui.SameLine()

                if imgui.HotKey("##open_bind", open_bind, {}, 180) then
                    rkeys.changeHotKey(hotkey_id, open_bind.v)
                end
                if imgui.Button('Unload', imgui.ImVec2(50, 20)) then
                    window.v = false
                    lua_thread.create(function()
                        wait(1000)
                        thisScript():unload()
                    end)
                end
                imgui.SameLine()
                if imgui.Button('Reload', imgui.ImVec2(50, 20)) then
                    imgui.Process = false
                    lua_thread.create(function()
                        wait(1000)
                        thisScript():reload()
                    end)
                end
            end
            imgui.PopStyleColor()
            imgui.SetCursorPosY(sizeY - 60)
            --imgui.TextDisabled('Tip: Use RMB to change settings')
            -- POPUPS
            --[[
                if imgui.BeginPopup('Bone WH') then
    
                
                if imgui.Button('Close', imgui.ImVec2(100, 20)) then
                    imgui.CloseCurrentPopup()
                end
                imgui.EndPopup()
            end
            ]]

            
            
            if imgui.BeginPopup('Nicks WH') then
                imgui.SliderFloat('Max Dist', pl.nicks_distance, 1, 500)
                imgui.EndPopup()
            end

            if imgui.BeginPopup('Objects WH') then
                imgui.SliderFloat('Max Dist', ot.objects_dist, 1, 500)
                imgui.EndPopup()
            end
            
            if imgui.BeginPopup('Tracers WH') then
                imgui.SliderInt('Thickness##tracers', pl.tracers_thickness, 1, 10)
                imgui.Combo('From', pl.tracers_mode, {'PED', 'Screen TOP', 'Screen BOTTOM'}, -1)
                imgui.SliderFloat('Max Dist', pl.tracers_distance, 1, 500)
                imgui.EndPopup()
            end

            if imgui.BeginPopup('Car Info WH') then         
                imgui.SliderFloat('Max Dist', cr.info_dist, 1, 500)
                imgui.Checkbox('Show id', cr.info_srvid)
                imgui.Checkbox('Show model', cr.info_model)
                imgui.Checkbox('Show hp', cr.info_hp)
                imgui.Checkbox('Show driver', cr.info_driver)
                imgui.EndPopup()
            end

            if imgui.BeginPopup('Box WH') then
                imgui.SliderInt('Thickness', pl.box_thickness, 1, 10)
                imgui.Combo('Mode', pl.box_mode, {'3D', '2D'}, -1)
                imgui.SliderFloat('Max Dist', pl.box_distance, 1, 500)
                imgui.EndPopup()
            end


            if imgui.BeginPopup('Bone WH') then
                imgui.SliderInt(u8'Thickness', pl.bones_thickness, 1, 10)
                imgui.SliderFloat('Max Dist', pl.bones_distance, 1, 500)
                imgui.EndPopup()
            end

            if imgui.BeginPopup('Car Box WH') then
                imgui.SliderInt('Thickness', cr.box_thickness, 1, 10)
                imgui.SliderFloat('Max Dist', cr.box_dist, 1, 500)
                imgui.Combo('Mode', cr.box_mode, {'3D', '2D'}, -1)
                imgui.EndPopup()
            end
        imgui.EndChild()

        imgui.End()
        
    end
end

function boxWidth(a,b)
    h = b - a
    ang = (7 * math.pi)/180
    x = (h * math.tan(ang)) * 2
    return x
end

function getCharModelCornersIn2d(id, handle)
    local x1, y1, z1, x2, y2, z2 = getModelDimensions(id)
    local t = {
        [1] = {convert3DCoordsToScreen(getOffsetFromCharInWorldCoords(handle, x1         , y1 * -1.1, z1))}, -- {x = x1, y = y1 * -1.0, z = z1},
        [2] = {convert3DCoordsToScreen(getOffsetFromCharInWorldCoords(handle, x1 * -1.0  , y1 * -1.1, z1))}, -- {x = x1 * -1.0, y = y1 * -1.0, z = z1},
        [3] = {convert3DCoordsToScreen(getOffsetFromCharInWorldCoords(handle, x1 * -1.0  , y1       , z1))}, -- {x = x1 * -1.0, y = y1, z = z1},
        [4] = {convert3DCoordsToScreen(getOffsetFromCharInWorldCoords(handle, x1         , y1       , z1))}, -- {x = x1, y = y1, z = z1},
        [5] = {convert3DCoordsToScreen(getOffsetFromCharInWorldCoords(handle, x2 * -1.0  , y2       , z2))}, -- {x = x2 * -1.0, y = 0, z = 0},
        [6] = {convert3DCoordsToScreen(getOffsetFromCharInWorldCoords(handle, x2 * -1.0  , y2 * -0.9, z2))}, -- {x = x2 * -1.0, y = y2 * -1.0, z = z2},
        [7] = {convert3DCoordsToScreen(getOffsetFromCharInWorldCoords(handle, x2         , y2 * -0.9, z2))}, -- {x = x2, y = y2 * -1.0, z = z2},
        [8] = {convert3DCoordsToScreen(getOffsetFromCharInWorldCoords(handle, x2         , y2       , z2))}, -- {x = x2, y = y2, z = z2},
    }
    return t
end

function getCarModelCornersIn2d(id, handle)
    local x1, y1, z1, x2, y2, z2 = getModelDimensions(id)
    local t = {
        [1] = {convert3DCoordsToScreen(getOffsetFromCarInWorldCoords(handle, x1         , y1 * -1, z1))},
        [2] = {convert3DCoordsToScreen(getOffsetFromCarInWorldCoords(handle, x1 * -1.0  , y1 * -1, z1))},
        [3] = {convert3DCoordsToScreen(getOffsetFromCarInWorldCoords(handle, x1 * -1.0  , y1       , z1))},
        [4] = {convert3DCoordsToScreen(getOffsetFromCarInWorldCoords(handle, x1         , y1       , z1))},
        [5] = {convert3DCoordsToScreen(getOffsetFromCarInWorldCoords(handle, x2 * -1.0  , y2       , z2))},
        [6] = {convert3DCoordsToScreen(getOffsetFromCarInWorldCoords(handle, x2 * -1.0  , y2 * -1, z2))},
        [7] = {convert3DCoordsToScreen(getOffsetFromCarInWorldCoords(handle, x2         , y2 * -1, z2))},
        [8] = {convert3DCoordsToScreen(getOffsetFromCarInWorldCoords(handle, x2         , y2       , z2))},
    }
    return t
end

function getBodyPartCoordinates(id, handle)
    if doesCharExist(handle) then
        local pedptr = getCharPointer(handle)
        local vec = ffi.new("float[3]")
        getBonePosition(ffi.cast("void*", pedptr), vec, id, true)
        return vec[0], vec[1], vec[2]
    end
end

function imgui.CTab(icon, text, selected)
    save()
    local sX, sY = 100, 30
    local cur = imgui.GetCursorPos()
    if imgui.Selectable('##'..text, tab == selected, 0, imgui.ImVec2(sX, sY)) then tab = selected end
    local iconSize = imgui.CalcTextSize(icon)
    local textSize = imgui.CalcTextSize(text)
    imgui.SetCursorPos(imgui.ImVec2(cur.x, cur.y + sY / 2 - iconSize.y / 2))
    imgui.Text(icon)
    imgui.SetCursorPos(imgui.ImVec2(cur.x + sX / 2 - textSize.x / 2, cur.y + sY / 2 - textSize.y / 2))
    imgui.Text(text)
    if selected == tab then
        imgui.SetCursorPos(imgui.ImVec2(cur.x - 5, cur.y + sY / 2 - 10))
        imgui.Button('##s'..selected, imgui.ImVec2(5, 20))
    end
    imgui.SetCursorPos(imgui.ImVec2(cur.x, cur.y + sY + 10))
end

function BH_theme()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
  
    style.WindowPadding = ImVec2(6, 4)
    style.WindowRounding = 5.0
    style.ChildWindowRounding = 5.0
    style.FramePadding = ImVec2(5, 2)
    style.FrameRounding = 5.0
    style.ItemSpacing = ImVec2(7, 5)
    style.ItemInnerSpacing = ImVec2(1, 1)
    style.TouchExtraPadding = ImVec2(0, 0)
    style.IndentSpacing = 6.0
    style.ScrollbarSize = 12.0
    style.ScrollbarRounding = 5.0
    style.GrabMinSize = 20.0
    style.GrabRounding = 2.0
    style.WindowTitleAlign = ImVec2(0.5, 0.5)
    
        
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.28, 0.30, 0.35, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.16, 0.18, 0.22, 0)
    colors[clr.ChildWindowBg]          = ImVec4(0.19, 0.22, 0.26, 1)
    colors[clr.PopupBg]                = ImVec4(0.16, 0.18, 0.22, 0.90)
    colors[clr.Border]                 = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.FrameBgHovered]         = ImVec4(0.22, 0.25, 0.30, 1.00)
    colors[clr.FrameBgActive]          = ImVec4(0.22, 0.25, 0.29, 1.00)
    colors[clr.TitleBg]                = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.19, 0.22, 0.26, 0.59)
    colors[clr.MenuBarBg]              = ImVec4(0.19, 0.22, 0.26, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.20, 0.25, 0.30, 0.60)
    colors[clr.ScrollbarGrab]          = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.49, 0.63, 0.86, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.49, 0.63, 0.86, 1.00)
    colors[clr.ComboBg]                = ImVec4(0.20, 0.20, 0.20, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.90, 0.90, 0.90, 0.50)
    colors[clr.SliderGrab]             = ImVec4(1.00, 1.00, 1.00, 0.30)
    colors[clr.SliderGrabActive]       = ImVec4(0.80, 0.50, 0.50, 1.00)
    colors[clr.Button]                 = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ButtonHovered]          = ImVec4(0.49, 0.62, 0.85, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.49, 0.62, 0.85, 1.00)
    colors[clr.Header]                 = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.HeaderHovered]          = ImVec4(0.43, 0.57, 0.80, 1.00)
    colors[clr.HeaderActive]           = ImVec4(0.43, 0.57, 0.80, 1.00)
    colors[clr.Separator]              = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.SeparatorActive]        = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ResizeGripHovered]      = ImVec4(0.49, 0.61, 0.83, 1.00)
    colors[clr.ResizeGripActive]       = ImVec4(0.49, 0.62, 0.83, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.CloseButtonHovered]     = ImVec4(0.50, 0.63, 0.84, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.PlotLines]              = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.41, 0.55, 0.78, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.16, 0.18, 0.22, 0.76)
    
    
end
BH_theme()

