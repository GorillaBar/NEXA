
local client_areas = {}

-- free client areas when leaving
AddEventHandler("nexa:playerLeave",function(user_id,source)
  client_areas[source] = nil 
end)

-- create/update a player area
function nexa.setArea(source,name,x,y,z,radius,height,cb_enter,cb_leave)
  local areas = client_areas[source] or {}
  client_areas[source] = areas

  areas[name] = {enter=cb_enter,leave=cb_leave}
  nexaclient.setArea(source,{name,x,y,z,radius,height})
end

-- delete a player area
function nexa.removeArea(source,name)
  -- delete remote area
  nexaclient.removeArea(source,{name})

  -- delete local area
  local areas = client_areas[source]
  if areas then
    areas[name] = nil
  end
end

-- TUNNER SERVER API

function tnexa.enterArea(name)
  local areas = client_areas[source]
  if areas then
    local area = areas[name] 
    if area and area.enter then -- trigger enter callback
      area.enter(source,name)
    end
  end
end

function tnexa.leaveArea(name)
  local areas = client_areas[source]

  if areas then
    local area = areas[name] 
    if area and area.leave then -- trigger leave callback
      area.leave(source,name)
    end
  end
end

