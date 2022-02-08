local cache = {}

MySQL.ready(function()
	MySQL.Async.fetchAll("SELECT SI.id, SI.store, SI.location, SI.item_name 'name', SI.stock,  SI.stock_max 'max', CASE WHEN SI.price_override is NULL THEN I.price ELSE SI.price_override END 'price', I.label, I.picture FROM shops_inventories SI INNER JOIN items I ON I.name = SI.item_name ORDER BY I.label ASC", {},
		function(result)
			for _,row in ipairs(result) do
				local key = string.format("%s%s", row.store, row.location)
				if (cache[key] == nil) then
					cache[key] = {}
				end
				local e = cache[key]
				e[row.name] = row
				cache[key] = e
			end
		end)
end)

RegisterServerEvent('esx_konbini:buyItem')
RegisterServerEvent('esx_konbini:withdrawMoney')

AddEventHandler('esx_konbini:withdrawMoney', function(amount)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	amount = ESX.Math.Round(amount)

	xPlayer.addMoney(amount)
end)

AddEventHandler('esx_konbini:buyItem', function(itemName, amount, zone)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	amount = ESX.Math.Round(amount)

	if amount < 0 then
		print('esx_konbini: ' .. xPlayer.identifier .. ' attempted to exploit the shop!')
		return
	end

	-- get price
	local price = 0
	local itemLabel = ''

	for i=1, #Config.Zones[zone].Items, 1 do
		local item = Config.Zones[zone].Items[i]
		if item.name == itemName then
			price = item.price
			itemLabel = item.label
			break
		end
	end

	price = price * amount

	-- can the player afford this item?
	if xPlayer.getMoney() >= price then
		-- can the player carry the said amount of x item?
		if xPlayer.canCarryItem(itemName, amount) then
			xPlayer.removeMoney(price)
			xPlayer.addInventoryItem(itemName, amount)
			xPlayer.showNotification(_U('bought', amount, itemLabel, ESX.Math.GroupDigits(price)))
		else
			xPlayer.showNotification(_U('player_cannot_hold'))
		end
	else
		local missingMoney = price - xPlayer.getMoney()
		xPlayer.showNotification(_U('not_enough', ESX.Math.GroupDigits(missingMoney)))
	end
end)

ESX.RegisterServerCallback('esx_konbini:shopInventory', function(source, cb, store, location)
	local key = string.format("%s%s", store, location)

	if cache[key] ~= nil then
		cb(cache[key])
	else
		cb({})
	end

	--[[MySQL.Async.fetchAll("SELECT SI.id, SI.item_name 'itemName', SI.stock,  SI.stock_max 'max',  CASE WHEN SI.price_override is NULL THEN I.price ELSE SI.price_override END 'price', I.label, I.picture FROM shops_inventories SI INNER JOIN items I ON I.name = SI.item_name WHERE SI.store = ? and SI.location = ?", {store, location},
	function(result)

		ESX.Trace('Query done')
		cb(result)
	end)
	--]]
end)

ESX.RegisterServerCallback('esx_konbini:takeItem', function(source, cb, store, location, itemName)
	MySQL.Async.fetchScalar('SELECT stock FROM shops_inventories WHERE store = ? and location = ? and item_name = ?', {store, location, itemName},
	function(result)
		if result then
			if (result.stock > 0) then
				MySQL.Async.update('UPDATE shops_inventories SET stock = ? WHERE store = ? and location = ? and item_name = ?', {result.stock -1, store, location, itemName},
				function(rowsChanged)
					if rowsChanged == 1 then
						cb(true)
						return
					end
				end)
			end
		end
		cb(false)
	end)
end)

ESX.RegisterServerCallback('esx_konbini:putBackItem', function(source, cb, store, location, itemName)

	MySQL.Async.fetchScalar('SELECT stock FROM shops_inventories WHERE store = ? and location = ? and item_name = ?', {store, location, itemName},
	function(result)
		if result then
			if (result.stock < result.stock_max) then
				MySQL.Async.update('UPDATE shops_inventories SET stock = ? WHERE store = ? and location = ? and item_name = ?', {result.stock + 1, store, location, itemName},
				function(rowsChanged)
				end)
			end
		end
		cb(true)
	end)
end)
