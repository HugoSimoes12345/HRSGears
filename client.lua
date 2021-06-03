local hg = {
    vehicle = nil,
    numgears = nil,
    topspeedGTA = nil,
    topspeedms = nil,
    acc = nil,
    hash = nil,
    selectedgear = 0,
    hbrake = nil,
    manualon = false,
    currspeedlimit = nil,
    ready = false,
    realistic = false
}

function Status()
    -- Export function
    return hg
end

local function resetvehicle()
    SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fInitialDriveForce", hg.acc)
    SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fInitialDriveMaxFlatVel",hg.topspeedGTA)
    SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fHandBrakeForce", hg.hbrake)
    SetVehicleHighGear(hg.vehicle, hg.numgears)
    ModifyVehicleTopSpeed(hg.vehicle,1)
    --SetVehicleMaxSpeed(vehicle,topspeedms)
    SetVehicleHandbrake(hg.vehicle, false)

    hg.vehicle = nil
    hg.numgears = nil
    hg.topspeedGTA = nil
    hg.topspeedms = nil
    hg.acc = nil
    hg.hash = nil
    hg.hbrake = nil
    hg.selectedgear = 0
    hg.currspeedlimit = nil
    hg.ready = false
end

local function SimulateGears()
    local engineup = GetVehicleMod(hg.vehicle,11)

    if hg.selectedgear > 0 then
        local ratio
        if Config.vehicles[hg.hash] ~= nil then
            if hg.selectedgear ~= 0 and hg.selectedgear ~= nil  then
                if hg.numgears ~= nil and hg.selectedgear ~= nil then
                    ratio = Config.vehicles[hg.hash][hg.numgears][hg.selectedgear] * (1/0.9)
                else
		    ratio = Config.gears[hg.numgears][hg.selectedgear] * (1/0.9)
                end
            end
        else
            if hg.selectedgear ~= 0 and hg.selectedgear ~= nil then
                if hg.numgears ~= nil and hg.selectedgear ~= nil then
                    ratio = Config.gears[hg.numgears][hg.selectedgear] * (1/0.9)
                end
            end
        end

        if ratio ~= nil then
            SetVehicleHighGear(hg.vehicle,1)
            local newacc = ratio * hg.acc
            local newtopspeedGTA = hg.topspeedGTA / ratio
            local newtopspeedms = hg.topspeedms / ratio

            --if GetEntitySpeed(vehicle) > newtopspeedms then
                --selectedgear = selectedgear + 1
            --else

            SetVehicleHandbrake(hg.vehicle, false)
            SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fInitialDriveForce", newacc)
            SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", newtopspeedGTA)
            SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fHandBrakeForce", hg.hbrake)
            ModifyVehicleTopSpeed(hg.vehicle,1)
            --SetVehicleMaxSpeed(vehicle,newtopspeedms)
            hg.currspeedlimit = newtopspeedms
            --end

        end
    elseif hg.selectedgear == 0 then
        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", 0.0)
    elseif hg.selectedgear == -1 then
        --if GetEntitySpeedVector(vehicle,true).y > 0.1 then
            --selectedgear = selectedgear + 1
        --else
            SetVehicleHandbrake(hg.vehicle, false)
            SetVehicleHighGear(hg.vehicle,hg.numgears)
            SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fInitialDriveForce", hg.acc)
            SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", hg.topspeedGTA)
            SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fHandBrakeForce", hg.hbrake)
            ModifyVehicleTopSpeed(hg.vehicle,1)
            --SetVehicleMaxSpeed(vehicle,topspeedms)
        --end
    end
    SetVehicleMod(hg.vehicle,11,engineup,false)
end

RegisterCommand("manual", function()
    if hg.vehicle == nil then
        if hg.manualon == false then
            hg.manualon = true
			--TriggerEvent('chatMessage', '', {255, 255, 255}, '^7' .. 'Manual Mode ON' .. '^7.')
        else
            hg.manualon = false
			--TriggerEvent('chatMessage', '', {255, 255, 255}, '^7' .. 'Manual Mode OFF' .. '^7.')
        end
    end
end)

RegisterCommand("manualmode", function()
    if hg.vehicle == nil then
        if hg.manualon == false then

        else
            if hg.realistic == true then
                hg.realistic = false
				--TriggerEvent('chatMessage', '', {255, 255, 255}, '^7' .. 'Manual Mode SIMPLE' .. '^7.')
            else
                hg.realistic = true
				--TriggerEvent('chatMessage', '', {255, 255, 255}, '^7' .. 'Manual Mode REALISTIC' .. '^7.')
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(100)

        local ped = PlayerPedId()
        local newveh = GetVehiclePedIsIn(ped,false)
        local class = GetVehicleClass(newveh)

        if newveh == hg.vehicle then

        elseif newveh == 0 and hg.vehicle ~= nil then
            resetvehicle()
        else
            if GetPedInVehicleSeat(newveh,-1) == ped then
                if class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16 and class ~= 21 then
                    hg.vehicle = newveh
                    hg.hash = GetEntityModel(newveh)

                    if GetVehicleMod(hg.vehicle,13) < 0 then
                        hg.numgears = GetVehicleHandlingInt(newveh, "CHandlingData", "nInitialDriveGears")
                    else
                        hg.numgears = GetVehicleHandlingInt(newveh, "CHandlingData", "nInitialDriveGears") + 1
                    end


                    hg.hbrake = GetVehicleHandlingFloat(newveh, "CHandlingData", "fHandBrakeForce")
                    hg.topspeedGTA = GetVehicleHandlingFloat(newveh, "CHandlingData", "fInitialDriveMaxFlatVel")
                    hg.topspeedms = (hg.topspeedGTA * 1.32)/3.6
                    hg.acc = GetVehicleHandlingFloat(newveh, "CHandlingData", "fInitialDriveForce")
                    --SetVehicleMaxSpeed(newveh,topspeedms)
                    hg.selectedgear = 0
                    Citizen.Wait(50)
                    hg.ready = true
                end
            end
        end

    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if hg.manualon == true and hg.vehicle ~= nil then
        DisableControlAction(0, 80, true)
        DisableControlAction(0, 21, true)
        end
    end

end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if hg.manualon == true and hg.vehicle ~= nil then
            if hg.vehicle ~= nil then
                -- Shift up and down
                if hg.ready == true then
                    if IsDisabledControlJustPressed(0, 21) then
                        if hg.selectedgear <= hg.numgears - 1 then
                            DisableControlAction(0, 71, true)
                            Wait(300)
                            hg.selectedgear = hg.selectedgear + 1
                            DisableControlAction(0, 71, false)
                            SimulateGears()
                        end
                    elseif IsDisabledControlJustPressed(0, 80) then
                        if hg.selectedgear > -1 then
                            DisableControlAction(0, 71, true)
                            Wait(300)
                            hg.selectedgear = hg.selectedgear - 1
                            DisableControlAction(0, 71, false)
                            SimulateGears()
                        end
                    end
                end
            end
        end

    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if hg.manualon == true and hg.vehicle ~= nil then
            if hg.selectedgear == -1 then
                if GetVehicleCurrentGear(hg.vehicle) == 1 then
                    DisableControlAction(0, 71, true)
                end
            elseif hg.selectedgear > 0 then
                if GetEntitySpeedVector(hg.vehicle,true).y < 0.0 then
                    DisableControlAction(0, 72, true)
                end
            elseif hg.selectedgear == 0 then
                SetVehicleHandbrake(hg.vehicle, true)
                if IsControlPressed(0, 76) == false then
                    SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fHandBrakeForce", 0.0)
                else
                    SetVehicleHandlingFloat(hg.vehicle, "CHandlingData", "fHandBrakeForce", hg.hbrake)
                end
            end
        else
            Citizen.Wait(100)
        end
    end
end)

local disable = false
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if hg.realistic == true then
            if hg.manualon == true and hg.vehicle ~= nil then
                if hg.selectedgear > 1 then
                    if IsControlPressed(0,71) then
                        local speed = GetEntitySpeed(hg.vehicle)
                        local minspeed = hg.currspeedlimit / 7

                        if speed < minspeed then
                            if GetVehicleCurrentRpm(hg.vehicle) < 0.4 then
                                disable = true
                            end
                        end
                    end
                end
            else
                Citizen.Wait(100)
            end
        else
            Citizen.Wait(100)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if disable == true then
            SetVehicleEngineOn(hg.vehicle,false,true,false)
            Citizen.Wait(1000)
            disable = false
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if hg.vehicle ~= nil and hg.selectedgear ~= 0 then
            local speed = GetEntitySpeed(hg.vehicle)

            if hg.currspeedlimit ~= nil then
                if speed >= hg.currspeedlimit then
                    if Config.enginebrake == true then
                        if speed / hg.currspeedlimit > 1.1 then
                        --print('dead')
                        local hhhh = speed / hg.currspeedlimit
                        SetVehicleCurrentRpm(hg.vehicle,hhhh)
                        SetVehicleCheatPowerIncrease(hg.vehicle,-100.0)
                        --SetVehicleBurnout(vehicle,true)
                        else
                        --SetVehicleBurnout(vehicle,false)
                        SetVehicleCheatPowerIncrease(hg.vehicle,0.0)
                        end
                    else
                        SetVehicleCheatPowerIncrease(hg.vehicle,0.0)
                    end
                    --SetVehicleHandbrake(vehicle, true)
                    --if IsControlPressed(0, 76) == false then
                        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 0.0)
                   -- else
                        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                    --end
                else
                    --SetVehicleHandbrake(vehicle, false)
                    --if IsControlPressed(0, 76) == false then
                    --else
                        --SetVehicleHandbrake(vehicle, true)
                        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                    --end  
                end
            else
                if speed >= hg.topspeedms then
                    SetVehicleCheatPowerIncrease(hg.vehicle,0.0)
                    --SetVehicleHandbrake(vehicle, true)
                    --if IsControlPressed(0, 76) == false then
                        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 0.0)
                    --else
                        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                    --end
                else
                    --SetVehicleHandbrake(vehicle, false)
                    --if IsControlPressed(0, 76) == false then
                    --else
                        --SetVehicleHandbrake(vehicle, true)
                        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
                    --end
                end
            end
        end
    end
end)

---------------debug

local function getinfo(gea)
    if gea == 0 then
        return "N"
    elseif gea == -1 then
        return "R"
    else
        return gea
    end
end

local function round(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end

Citizen.CreateThread(function()
    Citizen.Wait(100)
    if Config.gearhud == 1 then
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                if hg.manualon == true and hg.vehicle ~= nil then
                    SetTextFont(0)
                    SetTextProportional(1)
                    SetTextScale(0.0, 0.3)
                    SetTextColour(128, 128, 128, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(1, 0, 0, 0, 255)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("~r~Gear: ~w~"..getinfo(hg.selectedgear))
                    DrawText(0.015, 0.78)
                else
                    Citizen.Wait(100)
                end
            end
        end)
    elseif Config.gearhud == 2 then
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(0)
                if hg.manualon == true and hg.vehicle ~= nil then
                    SetTextFont(0)
                    SetTextProportional(1)
                    SetTextScale(0.0, 0.3)
                    SetTextColour(128, 128, 128, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(1, 0, 0, 0, 255)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextEntry("STRING")
                    AddTextComponentString("~r~Gear: ~w~"..getinfo(hg.selectedgear).." ~r~Km/h: ~w~"..round((GetEntitySpeed(hg.vehicle)*3.6),0).." ~r~RPM: ~w~"..round(GetVehicleCurrentRpm(hg.vehicle),2))
                    DrawText(0.015, 0.78)
                else
                    Citizen.Wait(100)
                end
            end
        end)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        --if manualon == true and vehicle ~= nil then
        SetTextFont(0)
        SetTextProportional(1)
        SetTextScale(0.0, 0.2)
        SetTextColour(128, 128, 128, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(1, 0, 0, 0, 255)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")

        if hg.manualon == true then
            if hg.realistic == false then
                AddTextComponentString("~r~HRSGears: ~g~On ~r~Mode: ~g~Arcade")
            else
                AddTextComponentString("~r~HRSGears: ~g~On ~r~Mode: ~g~Realistic")
            end
        else
            AddTextComponentString("~r~HRSGears: ~w~Off")
        end

        DrawText(0.95, 0.005)
    end
end)
