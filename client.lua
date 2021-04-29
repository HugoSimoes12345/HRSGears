


local vehicle = nil
local numgears = nil
local topspeedGTA = nil
local topspeedms = nil
local acc = nil
local hash = nil
local selectedgear = 0 
local hbrake = nil

local manualon = false

local incar = false

local currspeedlimit = nil
local ready = false
local realistic = false

RegisterCommand("manual", function()
    if vehicle == nil then
        if manualon == false then
            manualon = true
        else
            manualon = false
        end
    end
end)

RegisterCommand("manualmode", function()
    if vehicle == nil then
        if manualon == false then
        
        else
            if realistic == true then
                realistic = false
            else
                realistic = true
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

        if newveh == vehicle then

        elseif newveh == 0 and vehicle ~= nil then
            resetvehicle()
        else
            if GetPedInVehicleSeat(newveh,-1) == ped then
                if class ~= 13 and class ~= 14 and class ~= 15 and class ~= 16 and class ~= 21 then
                    vehicle = newveh
                    hash = GetEntityModel(newveh)
                   
                    
                    if GetVehicleMod(vehicle,13) < 0 then
                        numgears = GetVehicleHandlingInt(newveh, "CHandlingData", "nInitialDriveGears")
                    else
                        numgears = GetVehicleHandlingInt(newveh, "CHandlingData", "nInitialDriveGears") + 1
                    end
                    
                    

                    hbrake = GetVehicleHandlingFloat(newveh, "CHandlingData", "fHandBrakeForce")
                    
                    topspeedGTA = GetVehicleHandlingFloat(newveh, "CHandlingData", "fInitialDriveMaxFlatVel")
                    topspeedms = (topspeedGTA * 1.32)/3.6

                    acc = GetVehicleHandlingFloat(newveh, "CHandlingData", "fInitialDriveForce")
                    --SetVehicleMaxSpeed(newveh,topspeedms)
                    selectedgear = 0
                    Citizen.Wait(50)
                    ready = true
                end
            end
        end

    end
end)

function resetvehicle()
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", acc)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel",topspeedGTA)
    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
    SetVehicleHighGear(vehicle, numgears)
    ModifyVehicleTopSpeed(vehicle,1)
    --SetVehicleMaxSpeed(vehicle,topspeedms)
    SetVehicleHandbrake(vehicle, false)
    
    vehicle = nil
    numgears = nil
    topspeedGTA = nil
    topspeedms = nil
    acc = nil
    hash = nil
    hbrake = nil
    selectedgear = 0
    currspeedlimit = nil
    ready = false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) 
        if manualon == true and vehicle ~= nil then
        DisableControlAction(0, 80, true)
        DisableControlAction(0, 21, true)
        end
    end

end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0) 
        
        if manualon == true and vehicle ~= nil then

            if vehicle ~= nil then


            
            -- Shift up and down
                if ready == true then
                    if IsDisabledControlJustPressed(0, 21) then
                        if selectedgear <= numgears - 1 then 
                            DisableControlAction(0, 71, true)
                            Wait(300)
                            selectedgear = selectedgear + 1
                            DisableControlAction(0, 71, false)
                            SimulateGears()
                        end
                    elseif IsDisabledControlJustPressed(0, 80) then
                        if selectedgear > -1 then
                           
                            DisableControlAction(0, 71, true)
                            Wait(300)
                            selectedgear = selectedgear - 1
                            DisableControlAction(0, 71, false)
                            SimulateGears()
                        end
                    end
                end
            end

        end

    end
end)



function SimulateGears()

    local engineup = GetVehicleMod(vehicle,11)      

    if selectedgear > 0 then
        
        local ratio 
        if Config.vehicles[hash] ~= nil then
            if selectedgear ~= 0 then
                if numgears ~= nil and selectedgear ~= nil then
                    ratio = Config.vehicles[hash][numgears][selectedgear] * (1/0.9)
                else

                end
            end
        
        else
            if selectedgear ~= 0 then
                if numgears ~= nil and selectedgear ~= nil then
                    ratio = Config.gears[numgears][selectedgear] * (1/0.9)
                else
                
                end
            
            end
        end

        if ratio ~= nil then
    
            SetVehicleHighGear(vehicle,1)
            newacc = ratio * acc
            newtopspeedGTA = topspeedGTA / ratio
            newtopspeedms = topspeedms / ratio

            --if GetEntitySpeed(vehicle) > newtopspeedms then
                --selectedgear = selectedgear + 1
            --else
        
            SetVehicleHandbrake(vehicle, false)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", newacc)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", newtopspeedGTA)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
            ModifyVehicleTopSpeed(vehicle,1)
            --SetVehicleMaxSpeed(vehicle,newtopspeedms)
            currspeedlimit = newtopspeedms 
            --end

        end
    elseif selectedgear == 0 then
        --SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", 0.0)
    elseif selectedgear == -1 then
        
        if GetEntitySpeedVector(vehicle,true).y > 0.1 then
            selectedgear = selectedgear + 1
        else
            SetVehicleHandbrake(vehicle, false)
            SetVehicleHighGear(vehicle,numgears)    
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveForce", acc)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel", topspeedGTA)
            SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
            ModifyVehicleTopSpeed(vehicle,1)
            
            --SetVehicleMaxSpeed(vehicle,topspeedms)
        end
    
    end
SetVehicleMod(vehicle,11,engineup,false)
	
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if manualon == true and vehicle ~= nil then
            if selectedgear == -1 then
                if GetVehicleCurrentGear(vehicle) == 1 then
                    DisableControlAction(0, 71, true)
                end
            elseif selectedgear > 0 then
                if GetEntitySpeedVector(vehicle,true).y < 0.0 then   
                    DisableControlAction(0, 72, true)
                end
            elseif selectedgear == 0 then
                SetVehicleHandbrake(vehicle, true)
                if IsControlPressed(0, 76) == false then
                    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", 0.0)
                else
                    SetVehicleHandlingFloat(vehicle, "CHandlingData", "fHandBrakeForce", hbrake)
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
        if realistic == true then
            if manualon == true and vehicle ~= nil then
                if selectedgear > 1 then
                    if IsControlPressed(0,71) then
                        local speed = GetEntitySpeed(vehicle) 
                        local minspeed = currspeedlimit / 7 

                        if speed < minspeed then
                            if GetVehicleCurrentRpm(vehicle) < 0.4 then
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
            SetVehicleEngineOn(vehicle,false,true,false)
            Citizen.Wait(1000)
                
            disable = false
        end   

    end
end)

Citizen.CreateThread(function()
    while true do
            
        Citizen.Wait(0)
        if vehicle ~= nil and selectedgear ~= 0 then 
            local speed = GetEntitySpeed(vehicle) 
            
            if currspeedlimit ~= nil then
                
            if speed >= currspeedlimit then
                local num = GetVehicleNumberOfWheels(vehicle)
                
                SetVehicleCurrentRpm(vehicle,1.0)
                for i = 0 , num ,1 do
                    --if GetVehicleWheelPower(vehicle,i) > 0.0 then
                    
                        local wheelspeed = GetVehicleWheelRotationSpeed(vehicle,i)
                        if wheelspeed < 0.0 then
                            if wheelspeed < -currspeedlimit then
                            SetVehicleWheelRotationSpeed(vehicle,i,-currspeedlimit)
                            end
                            --print('ola')
                        
                        else 
                            if wheelspeed > currspeedlimit then
                            SetVehicleWheelRotationSpeed(vehicle,i,currspeedlimit)
                            end
                        end
                    
                    --end
                end
                SetVehicleCurrentRpm(vehicle,1.0)
                

            end
            
            else
                
                if speed >= topspeedms then
                    local num = GetVehicleNumberOfWheels(vehicle)
                    
                    SetVehicleCurrentRpm(vehicle,1.0)
                    for i = 0 , num ,1 do
                        --if GetVehicleWheelPower(vehicle,i) > 0.0 then
                        
                            local wheelspeed = GetVehicleWheelRotationSpeed(vehicle,i)
                            if wheelspeed < 0.0 then
                                if wheelspeed < -topspeedms then
                                SetVehicleWheelRotationSpeed(vehicle,i,-topspeedms)
                                end
                                --print('ola')
                            
                            else 
                                if wheelspeed > topspeedms then
                                SetVehicleWheelRotationSpeed(vehicle,i,topspeedms)
                                end
                            end
                        
                        --end
                    end
    
                    SetVehicleCurrentRpm(vehicle,1.0)
    
                end


            end
        

            
        
        
        end

    end
end)





---------------debug

Citizen.CreateThread(function()

    Citizen.Wait(100)

if Config.gearhud == 1 then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if manualon == true and vehicle ~= nil then
    
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.3)
            SetTextColour(128, 128, 128, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
        
            AddTextComponentString("~r~Gear: ~w~"..getinfo(selectedgear))
        
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
            if manualon == true and vehicle ~= nil then
    
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.0, 0.3)
            SetTextColour(128, 128, 128, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
        
            AddTextComponentString("~r~Gear: ~w~"..getinfo(selectedgear).." ~r~Km/h: ~w~"..round((GetEntitySpeed(vehicle)*3.6),0).." ~r~RPM: ~w~"..round(GetVehicleCurrentRpm(vehicle),2))
        
            DrawText(0.015, 0.78)
            else
                Citizen.Wait(100)
            end
        end
    end)
end

end)






function getinfo(gea)
    if gea == 0 then
        return "N"
    elseif gea == -1 then
        return "R"
    else
        return gea
    end
end

function round(value, numDecimalPlaces)
	if numDecimalPlaces then
		local power = 10^numDecimalPlaces
		return math.floor((value * power) + 0.5) / (power)
	else
		return math.floor(value + 0.5)
	end
end



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
        if manualon == true then
            if realistic == false then
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
