local hasAlreadyEnteredMarker, isInKonbiniMarker, menuIsShowed, currentActionData, lastZone = false, false, false, {}, false
local kvStores = nil

RegisterNetEvent('esx_konbini:closeMenu')
AddEventHandler('esx_konbini:closeMenu', function()
	SetNuiFocus(false)
	menuIsShowed = false
	SendNUIMessage({ hideAll = true })
end)

RegisterNUICallback('escape', function(data, cb)
	TriggerEvent('esx_konbini:closeMenu')
	cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
	TriggerServerEvent('esx_konbini:buyItem', data.name, data.amount, currentActionData.zone)
	cb('ok')
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
	TriggerServerEvent('esx_konbini:withdrawMoney', data.amount)
	cb('ok')
end)


-- Create blips
Citizen.CreateThread(function()
	for k, v in pairs(Config.Zones) do
		for i = 1, #v.Pos, 1 do
			if v.ShowBlip then
				local blip = AddBlipForCoord(v.Pos[i])

				SetBlipSprite(blip, v.Type)
				SetBlipScale(blip, v.Size)
				SetBlipColour(blip, v.Color)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName('STRING')
				AddTextComponentSubstringPlayerName(_U('shops'))
				EndTextCommandSetBlipName(blip)
			end
		end
	end
end)

-- Activate menu when player is inside marker
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())

		local letSleep, currentZone, location = true, false, nil
		isInKonbiniMarker = false

		for k, v in pairs(Config.Zones) do
			for i = 1, #v.Pos, 1 do
				local distance = #(playerCoords - v.Pos[i])

				if distance < Config.DrawDistance then
					if v.ShowMarker then
						DrawMarker(Config.MarkerType, v.Pos[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.MarkerSize.x, Config.MarkerSize.y, Config.MarkerSize.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, nil, nil, false)
					end
					letSleep = false

					if distance < 2.0 then
						isInKonbiniMarker = true
						currentZone = k
						lastZone = k
						local x, y, z = table.unpack(v.Pos[i])
						location = string.format("%.1f,%.1f,%.1f", x, y, z)
					end
				end
			end
		end

		if isInKonbiniMarker and not hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = true
			currentActionData.zone = currentZone
			currentActionData.location = location
			letSleep = false
		end

		if not isInKonbiniMarker and hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = false
			SetNuiFocus(false)
			menuIsShowed = false
			letSleep = false

			SendNUIMessage({ hideAll = true })
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end
end)

-- Menu interactions
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if isInKonbiniMarker and not menuIsShowed then

			ESX.ShowHelpNotification(_U('press_menu'))
			if IsControlJustReleased(0, 38) and IsPedOnFoot(PlayerPedId()) then
				menuIsShowed = true

				ESX.ShowFloatingHelpNotification(string.format("%s%s", currentActionData.zone, currentActionData.location))

				ESX.TriggerServerCallback('esx_konbini:shopInventory', function(data)
					SendNUIMessage({
						showMenu = true,
						products = data,
						player = player,
						store = currentActionData.zone
					})
				end, currentActionData.zone, currentActionData.location)

				SetNuiFocus(true, true)
			end

		else
			Citizen.Wait(500)
		end
	end
end)


-- close the menu when script is stopping to avoid being stuck in NUI focus
AddEventHandler('onResourceStop', function(resource)
	kvStores = nil
	if resource == GetCurrentResourceName() then
		if menuIsShowed then
			TriggerEvent('esx_konbini:closeMenu')
		end
	end
end)
