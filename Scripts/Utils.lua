Utils = {}

do
    Utils.Stack = {}
    function Utils.Stack:new()
        local obj = {data = {}, size = 0}
        setmetatable(obj, self)
        self.__index = self
        return obj
    end

    function Utils.Stack:push(x)
        self.size = self.size + 1
        self.data[self.size] = x
    end

    function Utils.Stack:pop()
        if self.size > 0 then
            local x = self.data[self.size]
            self.data[self.size] = nil
            self.size = self.size - 1
            return x
        else
            return nil
        end
    end

    function Utils.Stack:empty()
        return self.size == 0
    end

    Utils.MaxEventID = world.event.S_EVENT_MAX
    function Utils.NewEvent()
        local eventID = Utils.MaxEventID + 1
        Utils.MaxEventID = eventID
        return eventID
    end

    function Utils.messageToAll(text,displayTime,clearview)
        local displayTime = displayTime or 5
        local clearview = clearview or false
        trigger.action.outText(text, displayTime, clearview)
    end


    function Utils.getTableSize(table)
        local tableSize = 0
        for _,_ in pairs(table) do
            tableSize = tableSize + 1
        end

        return tableSize
    end

    function Utils.getIndexTable(min,max,interval)
        local table = {}
        local interval = interval or 1
        for i=min,max,interval do
            table[i] = true
        end

        return table
    end

    function Utils.selectAvailableIndex(table)
        local index = nil
        if not table then
            env.info(languages.Utils.log.Error.TableNotExist[Config.lang])
            return index
        end

        for num,v in pairs(table) do
            if v then 
                index = num
                table[num] = false
                break
            end
        end

        return index
    end

    function Utils.setIndexAvailable(table,index)
        if not table then
            env.info(languages.Utils.log.Error.TableNotExist[Config.lang])
            return index
        end
        
        table[index] = true
    end

    function Utils.vec2Translate(vec3,rad,distance)
        local point = {x = vec3.x,y = vec3.z or vec3.y,}
        
        if distance == 0 then return point end
    
        local radian = math.rad(rad)
    
        point.x = point.x + distance * math.cos(radian)
        point.y = point.y + distance * math.sin(radian)
        return point
    end

    function Utils.getObjHeading(object)
        if not object then return false end

        local objectPos = object:getPosition()
        local objectHeading = math.atan2(objectPos.x.z, objectPos.x.x)

        objectHeading = objectHeading*180/math.pi
        return objectHeading
    end

    function Utils.getDirection(vec3_1,vec3_2)
        local p1 = mist.utils.makeVec3GL(vec3_1)
        local p2 = mist.utils.makeVec3GL(vec3_2)
        local dir = mist.utils.getDir(mist.vec.sub(p1, p2))

        return dir
    end
    
    function Utils.getWayPoints(groupIdent)
		-- search by groupId and allow groupId and groupName as inputs
		local gpId = groupIdent
		if type(groupIdent) == 'string' and not tonumber(groupIdent) then
			local group = Group.getByName(groupIdent)
            if not group then return end

            gpId = group:getID()
		end

		for coa_name, coa_data in pairs(env.mission.coalition) do
			if  type(coa_data) == 'table' then
				if coa_data.country then --there is a country table
					for cntry_id, cntry_data in pairs(coa_data.country) do
						for obj_cat_name, obj_cat_data in pairs(cntry_data) do
							if obj_cat_name == "helicopter" or obj_cat_name == "ship" or obj_cat_name == "plane" or obj_cat_name == "vehicle" then	-- only these types have points
								if ((type(obj_cat_data) == 'table') and obj_cat_data.group and (type(obj_cat_data.group) == 'table') and (#obj_cat_data.group > 0)) then	--there's a group!
									for group_num, group_data in pairs(obj_cat_data.group) do
										if group_data and group_data.groupId == gpId then -- this is the group we are looking for
											if group_data.route and group_data.route.points and #group_data.route.points > 0 then
												local points = {}
												for point_num, point in pairs(group_data.route.points) do
													if not point.point then
														points[point_num] = { x = point.x, y = point.y }
													else
														points[point_num] = point.point	--it's possible that the ME could move to the point = Vec2 notation.
													end
												end
												return points
											end
											return
										end	--if group_data and group_data.name and group_data.name == 'groupname'
									end --for group_num, group_data in pairs(obj_cat_data.group) do
								end --if ((type(obj_cat_data) == 'table') and obj_cat_data.group and (type(obj_cat_data.group) == 'table') and (#obj_cat_data.group > 0)) then
							end --if obj_cat_name == "helicopter" or obj_cat_name == "ship" or obj_cat_name == "plane" or obj_cat_name == "vehicle" or obj_cat_name == "static" then
						end --for obj_cat_name, obj_cat_data in pairs(cntry_data) do
					end --for cntry_id, cntry_data in pairs(coa_data.country) do
				end --if coa_data.country then --there is a country table
			end --if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then
		end --for coa_name, coa_data in pairs(mission.coalition) do
	end

    --- Creates a deep copy of a object.
	-- Usually this object is a table.
	-- See also: from http://lua-users.org/wiki/CopyTable
	-- @param object object to copy
	-- @return copy of object
	function Utils.deepCopy(object)
		local lookup_table = {}
		local function _copy(object)
			if type(object) ~= "table" then
				return object
			elseif lookup_table[object] then
				return lookup_table[object]
			end
			local new_table = {}
			lookup_table[object] = new_table
			for index, value in pairs(object) do
				new_table[_copy(index)] = _copy(value)
			end
			return setmetatable(new_table, getmetatable(object))
		end
		return _copy(object)
	end

    --- Converts a Vec2 to a Vec3.
	-- @tparam Vec2 vec the 2D vector
	-- @param y optional new y axis (altitude) value. If omitted it's 0.
	function Utils.makeVec3(vec, y)
		if not vec.z then
			if vec.alt and not y then
				y = vec.alt
			elseif not y then
				y = 0
			end
			return {x = vec.x, y = y, z = vec.y}
		else
			return {x = vec.x, y = vec.y, z = vec.z}	-- it was already Vec3, actually.
		end
	end

    function Utils.pointInPolygon(point, poly, maxalt)
        point = Utils.makeVec3(point)
        local px = point.x
        local pz = point.z
        local cn = 0
        local newpoly = Utils.deepCopy(poly)
    
        if not maxalt or (point.y <= maxalt) then
            local polysize = #newpoly
            newpoly[#newpoly + 1] = newpoly[1]
    
            newpoly[1] = Utils.makeVec3(newpoly[1])
    
            for k = 1, polysize do
                newpoly[k+1] = Utils.makeVec3(newpoly[k+1])
                if ((newpoly[k].z <= pz) and (newpoly[k+1].z > pz)) or ((newpoly[k].z > pz) and (newpoly[k+1].z <= pz)) then
                    local vt = (pz - newpoly[k].z) / (newpoly[k+1].z - newpoly[k].z)
                    if (px < newpoly[k].x + vt*(newpoly[k+1].x - newpoly[k].x)) then
                        cn = cn + 1
                    end
                end
            end
    
            return cn%2 == 1
        else
            return false
        end
    end

    function Utils.doString(s)
        local f, err = loadstring(s)
        if f then
            return true, f()
        else
            return false, err
        end
    end

    function Utils.drawPolygon(Coalition,MarkID,vecs,Color,FillColor,LineType,ReadOnly,Text)
        local s=string.format("trigger.action.markupToAll(7, %d, %d,", Coalition, MarkID)
        for _,vec in pairs(vecs) do
            --s=s..string.format("%s,", UTILS._OneLineSerialize(vec))
            s=s..string.format("{x=%.1f, y=%.1f, z=%.1f},", vec.x, vec.y, vec.z)
        end
        s=s..string.format("{%.3f, %.3f, %.3f, %.3f},", Color[1], Color[2], Color[3], Color[4])
        s=s..string.format("{%.3f, %.3f, %.3f, %.3f},", FillColor[1], FillColor[2], FillColor[3], FillColor[4])
        s=s..string.format("%d,", LineType or 1)
        s=s..string.format("%s", tostring(ReadOnly))
        if Text and type(Text)=="string" and string.len(Text)>0 then
            s=s..string.format(", \"%s\"", tostring(Text))
        end
        s=s..")"

        -- Execute string command
        local success=Utils.doString(s)
                
        if not success then
            self:E("ERROR: Could not draw polygon")
            env.info(s)
        end
    end

    function Utils.get2DDist(point1, point2)
        if not point1 then
            log:warn("mist.utils.get2DDist  1st input value is nil") 
        end
        if not point2 then
            log:warn("mist.utils.get2DDist  2nd input value is nil") 
        end
		point1 = Utils.makeVec3(point1)
		point2 = Utils.makeVec3(point2)

        local vec = {x = point1.x - point2.x, y = 0, z = point1.z - point2.z} --Vector magnitude
		return (vec.x^2 + vec.y^2 + vec.z^2)^0.5
	end

    function Utils.getNearestAirbase(vec2)
        local airbases = world.getAirbases()
        if not airbases then return nil end
        
        local closest = nil
        local minDist = 999999
        for i,base in ipairs(airbases) do
            local distance = Utils.get2DDist(vec2, base:getPoint())
            if distance < minDist then
                closest = base
                minDist = distance
            end
        end
    
        return closest
    end
end