turfData = {
    {name = 'Weed', chatName = '^2Weed^0', gangOwner = "N/A", commission = 0, beingCaptured = false, cooldown = 0, membersInTurf = {}, turfBlocked = false}, -- weed
    {name = 'Cocaine', chatName = '^0Cocaine', gangOwner = "N/A", commission = 0, beingCaptured = false, cooldown = 0, membersInTurf = {}, turfBlocked = false}, -- cocaine
    {name = 'Meth', chatName = '^4Meth^0', gangOwner = "N/A", commission = 0, beingCaptured = false, cooldown = 0, membersInTurf = {}, turfBlocked = false}, -- meth
    {name = 'Heroin', chatName = '^1Heroin^0', gangOwner = "N/A", commission = 0, beingCaptured = false, cooldown = 0, membersInTurf = {}, turfBlocked = false}, -- heroin
    {name = 'LargeArms', chatName = '^0Large Arms', gangOwner = "N/A", commission = 0, beingCaptured = false, cooldown = 0, membersInTurf = {}, turfBlocked = false}, -- large arms
    {name = 'LSDNorth', chatName = '^6LSD North^0', gangOwner = "N/A", commission = 0, beingCaptured = false, cooldown = 0, membersInTurf = {}, turfBlocked = false}, -- lsd north
    {name = 'LSDSouth', chatName = '^6LSD South^0', gangOwner = "N/A", commission = 0, beingCaptured = false, cooldown = 0, membersInTurf = {}, turfBlocked = false} -- lsd south
}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        for k,v in pairs(turfData) do
            if v.cooldown > 0 then
                v.cooldown = v.cooldown - 1
            end
        end
    end
end)


RegisterNetEvent('nexa:refreshTurfOwnershipData')
AddEventHandler('nexa:refreshTurfOwnershipData', function()
    local source = source
	local user_id = nexa.getUserId(source)
	local data = turfData
	MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
		if #rows > 0 then
			local gangName = rows[1].gangname
			for k,v in pairs(data) do
				data[k].ownership = false
				if v.gangOwner == gangName then
					data[k].ownership = true
				end
				TriggerClientEvent('nexa:updateTurfOwner', source, k, v.gangOwner)
			end
		end
		TriggerClientEvent('nexa:gotTurfOwnershipData', source, data)
		TriggerClientEvent('nexa:recalculateLargeArms', source, data[5].commission)
	end)
end)

RegisterNetEvent('nexa:checkTurfCapture')
AddEventHandler('nexa:checkTurfCapture', function(turfid)
    local source = source
	local user_id = nexa.getUserId(source)
	if turfData[turfid].cooldown > 0 then 
		nexaclient.notify(source, {'~r~This turf is on cooldown for another '..turfData[turfid].cooldown..' seconds.'})
		return
	end
	MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
		if #rows > 0 then
			local gangName = rows[1].gangname
			local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
			for K,V in pairs(gotGangs) do
				local array = json.decode(V.gangmembers)
				if array[tostring(user_id)] then
					if turfData[turfid].gangOwner == V.gangname then
						TriggerClientEvent('nexa:captureOwnershipReturned', source, turfid, true, turfData[turfid].name)
					else
						TriggerClientEvent('nexa:captureOwnershipReturned', source, turfid, false, turfData[turfid].name)
					end
				end
			end
		end
	end)
end)

RegisterNetEvent('nexa:gangDefenseLocationUpdate')
AddEventHandler('nexa:gangDefenseLocationUpdate', function(turfname, atkdfnd, trueorfalse)
    local source = source
	local user_id = nexa.getUserId(source)
	local turfID = 0
	for k,v in pairs(turfData) do
		if v.name == turfname then
			turfID = k
		end
	end
	if atkdfnd == 'Attackers' then
		if trueorfalse then
			turfData[turfID].membersInTurf[source] = nil
			if not next(turfData[turfID].membersInTurf) then
				turfData[turfID].beingCaptured = false
				TriggerClientEvent('chatMessage', -1, "^0The "..turfData[turfID].chatName.." trader is no longer being captured.", { 128, 128, 128 }, message, "alert")
			end
		end
	elseif atkdfnd == 'Defenders' then
		if trueorfalse then
			turfData[turfID].turfBlocked = true
			TriggerClientEvent('nexa:setBlockedStatus', -1, turfname, true)
		else
			if turfData[turfID].turfBlocked then
				turfData[turfID].turfBlocked = false
				TriggerClientEvent('nexa:setBlockedStatus', -1, turfname, false)
			end
		end
	end
	
end)

RegisterNetEvent('nexa:failCaptureTurfOwned')
AddEventHandler('nexa:failCaptureTurfOwned', function(x)
    local source = source
	local user_id = nexa.getUserId(source)
end)

RegisterNetEvent('nexa:initiateGangCapture')
AddEventHandler('nexa:initiateGangCapture', function(x,y)
    local source = source
	local user_id = nexa.getUserId(source)
	if nexa.getUserId(turfData[x].playerCapturing) == nil then
		turfData[x].beingCaptured = false
		turfData[x].playerCapturing = nil
	end
	if not turfData[x].beingCaptured then
		MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
			if #rows > 0 then
				local gangName = rows[1].gangname
				local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
				for K,V in pairs(gotGangs) do
					local array = json.decode(V.gangmembers)
					if array[tostring(user_id)] then
						TriggerClientEvent('nexa:initiateGangCaptureCheck', source, y, true)
						turfData[x].membersInTurf[source] = true
						for I,L in pairs(json.decode(V.gangmembers)) do
							local usource = nexa.getUserSource(tonumber(I))
							if usource ~= nil and usource ~= source then
								TriggerClientEvent('nexa:initiateGangCaptureCheck', usource, y, true)
								TriggerClientEvent('nexa:attackGangCapture', usource, x, y)
								turfData[x].membersInTurf[usource] = true
							end
						end
						turfData[x].beingCaptured = true 
						turfData[x].playerCapturing = source
						turfData[x].captureStarted = os.time()
						TriggerClientEvent('chatMessage', -1, "^0The "..turfData[x].chatName.." trader is being attacked by "..V.gangname..".", { 128, 128, 128 }, message, "alert")
						turfData[x].cooldown = 300
						if turfData[x].gangOwner ~= 'N/A' then
							MySQL.query("nexa/get_gang_info", {gangname = turfData[x].gangOwner}, function(rows, affected)
								if #rows > 0 then
									local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = turfData[x].gangOwner})
									for K,V in pairs(gotGangs) do
										if V.gangname == turfData[x].gangOwner then
											for I,L in pairs(json.decode(V.gangmembers)) do
												local usource = nexa.getUserSource(tonumber(I))
												if usource ~= nil then
													--TriggerClientEvent('nexa:defendGangCapture', usource, x, y)
													TriggerClientEvent('nexa:smallAnnouncement', usource,'Turf attack',"Someone is attacking your owned turf - "..turfData[x].name, 27, 10000)
												end
											end
										end
									end
								end
							end)
						end
					end
				end
			end
		end)
	else
		nexaclient.notify(source, {'~r~This turf is currently being captured.'})
	end
end)

RegisterNetEvent('nexa:gangCaptureSuccess')
AddEventHandler('nexa:gangCaptureSuccess', function(turfname)
    local source = source
	local user_id = nexa.getUserId(source)
	for k,v in pairs(turfData) do
		if v.name == turfname and v.beingCaptured and os.time() >= (v.captureStarted + 300) then
			MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
				if #rows > 0 then
					local gangName = rows[1].gangname
					local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
					for K,V in pairs(gotGangs) do
						for I,L in pairs(json.decode(V.gangmembers)) do
							if tostring(user_id) == I then
								TriggerClientEvent('chatMessage', -1, "^0The "..v.chatName.." trader has been captured by "..V.gangname..".", { 128, 128, 128 }, message, "alert")
								for a,b in pairs(json.decode(V.gangmembers)) do
									turfData[k].gangOwner = V.gangname
									turfData[k].cooldown = 300
									turfData[k].beingCaptured = false
									turfData[k].ownership = true
									turfData[k].playerCapturing = nil
									turfData[k].membersInTurf = {}
									TriggerClientEvent('nexa:updateTurfOwner', -1, k, V.gangname)
									if nexa.getUserSource(tonumber(a)) ~= nil then
										TriggerClientEvent('nexa:gotTurfOwnershipData', nexa.getUserSource(tonumber(a)), turfData)
									end
								end
							end
						end
					end
				end
			end)
		end
	end
end)

RegisterNetEvent('nexa:gangDefenseSuccess')
AddEventHandler('nexa:gangDefenseSuccess', function(turfname)
    local source = source
	local user_id = nexa.getUserId(source)
	MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
		if #rows > 0 then
			local gangName = rows[1].gangname
			local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
			for K,V in pairs(gotGangs) do
				for I,L in pairs(json.decode(V.gangmembers)) do
					if tostring(user_id) == I then
						for a,b in pairs(turfData) do
							if b.name == turfname then
								TriggerClientEvent('chatMessage', -1, "^0The "..b.chatName.." trader is no longer being attacked.", { 128, 128, 128 }, message, "alert")
								turfData[a] = {ownership = true, gangOwner = V.gangname, commission = b.commission, cooldown = 300, beingCaptured = false}
								TriggerClientEvent('nexa:gotTurfOwnershipData', -1, turfData)
								return
							end
						end
					end
				end
			end
		end
	end)
end)

function nexa.turfSaleToGangFunds(amount, drugtype)
	for k,v in pairs(turfData) do
		if v.name == drugtype then
			if v.commission == nil then
				v.commission = 0
			end
			amount = amount*(v.commission/100)
			exports['ghmattimysql']:execute('UPDATE nexa_gangs SET funds = funds+@funds WHERE gangname = @gangname', {funds = amount, gangname = v.gangOwner})
		end
	end
end