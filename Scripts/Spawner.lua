Spawner = {}

do
    Spawner.MissionCategory = {
        Plane = {
            "CAP",
            "CAS",
        },
        Helicopter = {

        },
        Ground = {

        },
        Ship = {

        },
    }

    Spawner.groupTemplate = {
        [coalition.side.RED] = {

        },
        [coalition.side.BLUE] = {

        },
    }

    Spawner.staticTemplate = {

    }

    function Spawner.addGroup()
        
    end

    function Spawner:addGroundGroup(groupName, template, spawnPoint)
        local templateGroup = template.group

        local Category = templateGroup:getCategory()
        local tCoalition = templateGroup:getCoalition()
        
        local spawnData = {}
        spawnData.name = groupName
        spawnData.task = "Ground nothing"
        local unitsTable = {}
        for i, unit in ipairs(group:getUnits()) do
            local unitData = {}
            unitData.name = groupName..'-'..i
            unitData.type = unit:getTypeName()
            unitData.x = spawnPoint.x
            unitData.y = spawnPoint.y
            table.insert(unitsTable,unitData)
        end

        spawnData.units = unitsTable
        local newGroup = coalition.addGroup(Config.Country[tCoalition],Category,spawnData)

        if not newGroup then 
            return false
        end

        return newGroup
    end

    function Spawner.addPlaneGroup(groupName, template, spawnPoint, speed, altitude, altType, coldStart, uncontrolled)
        if not groupName then return false end
        if not template then return false end
        if not spawnPoint then return false end
        
        local templateGroup = template.group
        local tCoalition = templateGroup:getCoalition()

        local groupData = {}
        groupData.name = groupName
        groupData.task = 'Nothing'

        groupData.units = {}

        for i, unit in ipairs(templateGroup:getUnits()) do
            local unitData = {}
            unitData.name = groupName..'-'..i
            unitData.type = unit:getTypeName()
            unitData.x = spawnPoint.x
            unitData.y = spawnPoint.y

            unitData.speed = speed or 162 --m/s 350knots
            unitData.alt = altitude or 610 --meters  2000ft
            unitData.alt_type = altType or "RADIO" --string "BARO" or "RADIO" for Above sea level or above ground level

            table.insert(groupData.units,unitData)
        end

        if coldStart then
            if uncontrolled then
                groupData.uncontrolled = true
            end

            local airbase = Utils.getNearestAirbase(spawnPoint)
            if not airbase then 
                env.warning(string.format(Languages:translate('There is no available airbase for %s to spawn',Config.lang),groupName))
                return false 
            end

            local airbaseID = airbase:getID()

            groupData.route.points[1].airdromeId = airbaseID
        end

        local newGroup = coalition.addGroup(Config.Country[tCoalition],templateGroup:getCategory(),groupData)

        if not newGroup then 
            return false
        end

        return newGroup
    end

    function Spawner.addHeloGroup()
        
    end

    function Spawner.addStaticGroup()
        
    end

    function Spawner.getTemplateList()
        
    end

    function Spawner.getGroupDataInMission(groupIdent)
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
							if ((type(obj_cat_data) == 'table') and obj_cat_data.group and (type(obj_cat_data.group) == 'table') and (#obj_cat_data.group > 0)) then	--there's a group!
                                for group_num, group_data in pairs(obj_cat_data.group) do
                                    if group_data and group_data.groupId == gpId then -- this is the group we are looking for
                                        return group_data
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        return
    end

    function Spawner.generateGroupTemplate(groupOrGroupName,templateName,coalition)
        local group = groupOrGroupName

        if not group.getID then
            group = Group.getByName(groupOrGroupName)
        end
        
        if not group then return end

        local groupData = Spawner.getGroupDataInMission(group:getID())
        if not groupData then return end
        
        local templateData = {}
        templateData.templateName = templateName or groupData.name
        templateData.name = templateName or groupData.name
        templateData.task = groupData.task or "Nothing"
        templateData.units = {}

        for i, unit in ipairs(groupData.units) do
            local unitData = {}
            unitData.name = unit.name
            unitData.type = unit.type
            unitData.paylod = unit.payload

            table.insert(templateData.units,unitData)
        end

        return templateData
    end

    function Spawner.addGroupTemplate(groupName,templateName,coalition)
        local group = Group.getByName(groupName)
        if not group then return end

        local tCoalition = coalition or group:getCoalition()
        local tCategory = group:getCategory()

        local templateData = Spawner.generateGroupTemplate(group,templateName,coalition)
        if not templateData then return end

        Spawner.groupTemplate[tCoalition] = Spawner.groupTemplate[tCoalition] or {}
        Spawner.groupTemplate[tCoalition][tCategory] = Spawner.groupTemplate[tCoalition][tCategory] or {}
        Spawner.groupTemplate[tCoalition][tCategory][templateData.task] = Spawner.groupTemplate[tCoalition][tCategory][templateData.task] or {}

        table.insert(Spawner.groupTemplate[tCoalition][tCategory][templateData.task],templateData)
    end

    function Spawner.generateStaticTemplate(groupNames,templateName,coalition)
        local centerObject = StaticObject.getbyName(groupNames[1])
        if not centerObject then return end

        local newTemplate = {}
        newTemplate.templateName = templateName
        newTemplate.units = {}

        for i, groupName in ipairs(groupNames) do
            local staticObject = StaticObject:getbyName(groupName)
            if not staticObject then break end

            local staticData = {}
            staticData.name = groupName
            staticData.type = staticObject:getTypeName()
            staticData.heading = Utils.getObjHeading(staticObject)

            staticData.disFromCenter = 0
            staticData.angleFromCenter = 0

            if i ~= 1 then
                local centerPoint = centerObject:getPoint()
                local objectPoint = staticObject:getPoint()

                staticData.disFromCenter = Utils.get2DDist(centerPoint,objectPoint)
                staticData.angleFromCenter = Utils.getDirection(centerPoint,objectPoint)
            end

            table.insert(newTemplate.units,staticData)
        end

        return newTemplate
    end

    function Spawner.addStaticTemplate(groupNames, templateName, coalition)
        
        local newTemplate = Spawner.generateStaticTemplate(groupNames,templateName,coalition)
        if not newTemplate then return end
        
        Spawner.staticTemplate[coalition][templateName] = newTemplate
    end
end