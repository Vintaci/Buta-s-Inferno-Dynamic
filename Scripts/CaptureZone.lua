CaptureZone = {}
do
    CaptureZone.MonitorRepeatTime = Config.CaptureZone.MonitorRepeatTime or 5 --Seconds
    CaptureZone.CaptureTime = Config.CaptureZone.CaptureTime

    CaptureZone.SiegeMonitor = {}
    CaptureZone.SiegeMonitor.ScanTimeInterval = 1 --Seconds

    CaptureZone.ZoneState = {
        Neutual = 'Neutual',
        Captured = 'Captured',
        isolated = 'isolated',
    }
    CaptureZone.InitialState = CaptureZone.ZoneState.Neutual

    CaptureZone.coalition = {
        Neutual = 0,
        Red = 1,
        Blue = 2,
        All = -1,
    }

    CaptureZone.Events = {
        Captured = Config.CustomEvent.Captured,
        Neutualized = Config.CustomEvent.Neutualized,
    }
    
    CaptureZone.COLOR = {
        [0] = {
            name = 'neutual',
            line = {1,1,1,0.5},
            fill = {1,1,1,0.3},
            flare = trigger.flareColor.White,
            smoke = trigger.smokeColor.White,
        },
        [1] = {
            name = 'red',
            line = {1,0,0,0.5},
            fill = {1,0,0,0.3},
            flare = trigger.flareColor.Red,
            smoke = trigger.smokeColor.Red,
        },
        [2] = {
            name = 'blue',
            line = {0,0,1,0.5},
            fill = {0,0,1,0.3},
            flare = trigger.flareColor.Green,
            smoke = trigger.smokeColor.Blue,
        },
    }

    CaptureZone.allZones = {}
    CaptureZone.FOBZone = {
        [1] = nil,
        [2] = nil,
    }

    CaptureZone.GroundUnits = {}
    local e = {}
    function e:onEvent(event)
        if event.id == world.event.S_EVENT_BIRTH and event.initiator:getDesc().category == Unit.Category.GROUND_UNIT then
            local unit = event.initiator
            CaptureZone.GroundUnits[unit:getName()] = unit

            trigger.action.outText(mist.utils.tableShow(CaptureZone.GroundUnits), 10) --Debug
        end
        
        if event.id == world.event.S_EVENT_DEAD and event.initiator:getDesc().category == Unit.Category.GROUND_UNIT then
            local unit = event.initiator
            CaptureZone.GroundUnits[unit:getName()] = nil

            trigger.action.outText(mist.utils.tableShow(CaptureZone.GroundUnits), 10) --Debug
        end
    end

    world.addEventHandler(e)

    function CaptureZone:New(zoneName,initCoalition)
        if not zoneName then return end

        local initCoalition = initCoalition or Config.coalition.Neutual
        
        if CaptureZone.allZones[zoneName] then

            if CaptureZone.allZones[zoneName].MonitorID then
                CaptureZone.allZones[zoneName]:stop()
            end

            CaptureZone.allZones[zoneName] = nil
        end

        local obj = {}

        obj.zone = trigger.misc.getZone(zoneName)
        if not obj.zone then 
            local msg = string.format(Languages:translate('Error: CaptureZone - New(): trigger zone named [%s] not found.', Config.lang),zoneName)
            env.error(msg, false)
            return 
        end

        obj.zoneName = zoneName
        obj.point = obj.zone.point
        obj.radius = obj.zone.radius

        obj.coalition = initCoalition
        obj.state = CaptureZone.InitialState

        obj.connections = {}
        
        obj.sapwnZones = {}

        obj.zoneDisplayName = CaptureZone.getDisplayName(obj.zoneName)
        obj.drawZoneID = Utils.selectAvailableIndex(Config.drawIndexTabel)
        obj.textID = Utils.selectAvailableIndex(Config.drawIndexTabel)

        obj.MonitorID = nil

        -- obj.inZoneUnits = {
        --     [1] = {},
        --     [2] = {},
        -- }
        obj.SiegeMonitor = {
            id = nil,
            progress = 0,
        }

        setmetatable(obj, self)
        self.__index = self

        CaptureZone.allZones[obj.zoneName] = obj
        obj:Init()

        return obj
    end

    function CaptureZone.getDisplayName(zoneName)
        local displayName = string.match(zoneName, '^Zone--(.*)')
        -- local displayName = zoneName:sub(6)
        if displayName then
            return displayName
        end

        return zoneName
    end

    function CaptureZone:getSpawnZones()
        local displayName = self.zoneDisplayName
        local spawnZones = {}

        if env.mission.triggers and env.mission.triggers.zones then
            for zone_ind, zone_data in pairs(env.mission.triggers.zones) do
				if type(zone_data) == 'table' then
                    for i=1,6 do
                        local spawnZoneName = "SpawnZone-"..displayName.."-"..i
                        if zone_data.name == spawnZoneName then
                            spawnZones[i] = zone_data.verticies
                        end
                    end
                end
            end
        end
    end

    function CaptureZone:getDefaultText()
        local msg = Languages:translate(self.zoneDisplayName)

        if self.SiegeMonitor.id then
            msg = msg..'\n'
            msg = msg..'['
            local percentage = math.abs(self.SiegeMonitor.progress)*10/CaptureZone.CaptureTime*10
            percentage = math.floor(percentage/10)

            for i=0,percentage,1 do
                if i>0 then
                    -- msg = msg..'▮'
                    msg = msg..'◆'
                end
            end

            for j=1,10-percentage,1 do
                -- msg = msg..'-'
                msg = msg..'◇'
            end
            msg = msg..']'
        end

        return msg
    end

    function  CaptureZone:changeText(newText)
        local textID = self.textID
        if not textID then return end

        local text = self:getDefaultText()

        if newText then
            text = text..newText
        end

        if Config.Debug then
            text = text..'\nzoneName: '..self.zoneName..'\n'
            text = text..'zoneDisplayName: '..self.zoneDisplayName..'\n'
            text = text..'coalition: '..self.coalition..'\n'
            text = text..'state: '..self.state..'\n'

            if self.MonitorID then
                text = text..'MonitorID: '..self.MonitorID..'\n'
            end 

            if self.SiegeMonitor.id then
                text = text..'SiegeMonitor ID: '..self.SiegeMonitor.id..'\n'
                text = text..'SiegeMonitor progress: '..self.SiegeMonitor.progress..'\n'
            end 
            
            -- text = text..'InZoneUnits_Red:\n'
            -- for unitName, unit in pairs(self.inZoneUnits[1]) do
            --     text = text .. unitName .. '\n'
            -- end
            
            -- text = text .. 'InZoneUnits_Blue:\n'
            -- for unitName, unit in pairs(self.inZoneUnits[2]) do
            --     text = text .. unitName .. '\n'
            -- end
        end
        
        trigger.action.setMarkupText(textID,text)
    end

    function CaptureZone:createZoneText()
        local textVec3 = {  
            x = self.zone.point.x,   
            y = self.zone.point.y,
            z = self.zone.point.z + self.radius
        }

        local msg = self:getDefaultText()

        trigger.action.textToAll(-1 , self.textID , textVec3 , {0,0,0,1}, {0,0,0,0},15,false,msg)
    end

    function CaptureZone:drawZoneCircle()
        --                        coalition id              center      radius      color                                  fillColor                              lineType
        trigger.action.circleToAll(-1,      self.drawZoneID,self.point,self.radius,CaptureZone.COLOR[self.coalition].line,CaptureZone.COLOR[self.coalition].fill,1)
    end

    function CaptureZone:setColor(lineCoalition,fillCoalition)
        local drawZoneID = self.drawZoneID
        if lineCoalition == nil then lineCoalition = self.coalition end
        local newLine = CaptureZone.COLOR[lineCoalition].line

        if fillCoalition == nil then fillCoalition = self.coalition end
        local newFill = CaptureZone.COLOR[fillCoalition].fill
        
        trigger.action.setMarkupColor(drawZoneID , newLine)
        trigger.action.setMarkupColorFill(drawZoneID , newFill)
    end

    function CaptureZone:drawRegionPolygon()
        local regionPolygonID = self.drawRegionPolygonID
        local points = self.regionGroup.wayPoints

        if #points == 3 then
            trigger.action.rectToAll(-1,regionPolygonID,points[1],points[2],points[3],CaptureZone.Region.COLOR[0].line,CaptureZone.Region.COLOR[0].fill,1)
        end

        if #points == 4 then
            trigger.action.quadToAll(-1,regionPolygonID,
                points[1],
                points[2],
                points[3],
                points[4],
                CaptureZone.Region.COLOR[0].line,CaptureZone.Region.COLOR[0].fill,1)
        end

        if #points > 4 then
            Utils.drawPolygon(-1,regionPolygonID,points,CaptureZone.Region.COLOR[0].line,CaptureZone.Region.COLOR[0].fill,1)
        end
    end

    function CaptureZone:changeRegionColor(lineCoalition,fillCoalition)
        local polygonID = self.drawRegionPolygonID

        if lineCoalition == nil then lineCoalition = self.coalition end
        local newLine = CaptureZone.Region.COLOR[lineCoalition].line

        if fillCoalition == nil then fillCoalition = self.coalition end
        local newFill = CaptureZone.Region.COLOR[fillCoalition].fill

        trigger.action.setMarkupColor(polygonID , newLine)
        trigger.action.setMarkupColorFill(polygonID , newFill)
    end

    function CaptureZone:Init()
        self.sapwnZones = self:getSpawnZones()
        -- self:drawRegionPolygon()
        self:drawZoneCircle()
        self:createZoneText()
        self:start()
    end

    function  CaptureZone:isInside(vec3)
        if not vec3 then return end

        local dist = Utils.get2DDist(vec3, self.point)
        return dist<self.radius
    end

    function CaptureZone:neutualize()
        self.coalition = 0
        -- self:setDissconnectFOB()
        self.state = CaptureZone.ZoneState.Neutual
        self:setColor(0,0)
        -- self:changeRegionColor(0,0)
    end

    function CaptureZone:capture(coalition)
        local newState = {
            [0] = CaptureZone.ZoneState.Neutual,
            [1] = CaptureZone.ZoneState.Captured,
            [2] = CaptureZone.ZoneState.Captured,
        }

        -- if coalition == 0 then self:setDissconnectFOB() end
        
        self.coalition = coalition
        self.state = newState[coalition]
        self:setColor(coalition,coalition)
        -- self:changeRegionColor(coalition,coalition)

        if coalition ~= 0 then
            trigger.action.smoke(self.point, CaptureZone.COLOR[coalition].smoke)
        end

        local event = {
            id = CaptureZone.Events.Captured,
            initiator = self,
            coalition = coalition,
        }

        world.onEvent(event)
    end

    function CaptureZone:UpdateZoneState(coalition)

        if coalition == 0 then self.SiegeMonitor.progress = 0 end
        if coalition == 1 then self.SiegeMonitor.progress = CaptureZone.CaptureTime end
        if coalition == 2 then self.SiegeMonitor.progress = 0-CaptureZone.CaptureTime end
        
        self:capture(coalition)
        if coalition ~= 0 then
            self:_SiegeMonitorStop()
        end

        -- self:updateConnection()
        self:changeText()
    end

    -- function CaptureZone:updateInZoneUnits()
    --     local unitCount = {
    --         [1] = 0,
    --         [2] = 0,
    --     }

    --     for unitName, unit in pairs(CaptureZone.GroundUnits) do
    --         if unit:isExist() then
    --             if unit:isActive() then
    --                 if unit:getLife() >= 1 then
    --                     if not self.inZoneUnits[unit:getCoalition()][unitName] then
    --                         local point = unit:getPoint()
    --                         if self:isInside(point) then
    --                             self.inZoneUnits[unit:getCoalition()][unitName] = unit
    --                         end
    --                     end
    --                 end
    --             end
    --         end
    --     end

    --     local unitsNeedRemove = {
    --         [1] = {},
    --         [2] = {},
    --     }

    --     for tCoalition, units in pairs(self.inZoneUnits) do
    --         for unitName, unit in pairs(units) do
    --             trigger.action.outText(self.zoneName..': unitName: '..unitName, 10) --Debug

    --             if not unit:isExist() then
    --                 table.insert(unitsNeedRemove[tCoalition],unitName)
    --             end

    --             if unit:isExist() then
    --                 if not unit:isActive() then
    --                     table.insert(unitsNeedRemove[tCoalition],unitName)
    --                 end

    --                 if unit:isActive() then
    --                     unitCount[tCoalition] = unitCount[tCoalition] + 1

    --                     local point = unit:getPoint()

    --                     if unit:getLife() < 1 or not self:isInside(point) then
    --                         table.insert(unitsNeedRemove[tCoalition],unitName)
    --                     end
    --                 end
    --             end
    --         end
    --     end

    --     for tCoalition, unitNames in ipairs(unitsNeedRemove) do
    --         for i, unitName in pairs(unitNames) do
    --             trigger.action.outText("remove: "..unitName, 10) --Debug
    --             self.inZoneUnits[tCoalition][unitName] = nil
    --             if unitCount[tCoalition] > 0 then
    --                 unitCount[tCoalition] = unitCount[tCoalition] - 1
    --             end
    --         end
    --     end

    --     return unitCount[1], unitCount[2]
    -- end

    function CaptureZone:updateInZoneUnits(countNumber)
        local unitCount = { [1] = 0, [2] = 0 }
        local groundUnits = CaptureZone.GroundUnits
        local isInside = self.isInside

        for unitName, unit in pairs(groundUnits) do
            if unit:isExist() and unit:isActive() and unit:getLife() >= 1 then
                local point = unit:getPoint()
                if isInside(self,point) then
                    local tCoalition = unit:getCoalition()
                    unitCount[tCoalition] = (unitCount[tCoalition] or 0) + 1

                    if tCoalition ~= self.coalition then
                        if not self.SiegeMonitor.id then
                            self:_SiegeMonitorStart()
                        end
                    end
                end
            end
        end

        if countNumber then
            return unitCount[1], unitCount[2]
        end

        return
    end

    function  CaptureZone._MonitorFunction(vars,time)
        local self = vars.context
        local repeatTime = vars.repeatTime

        self:updateInZoneUnits()

        self:changeText()
        -- if Config.Debug then
        --     self:debug()
        -- end

        return time + repeatTime
    end

    function CaptureZone:start(Delay,RepeatScanSeconds)
        local tDelay = Delay or 1
        local RepeatScanInterval = RepeatScanSeconds or CaptureZone.MonitorRepeatTime

        if self.MonitorID then
            self:stop()
        end

        self.MonitorID = timer.scheduleFunction(self._MonitorFunction,{context = self,repeatTime = RepeatScanInterval},timer.getTime() + tDelay)
    end

    function CaptureZone:stop()
        timer.removeFunction(self.MonitorID)
        self.MonitorID = nil
    end

    function CaptureZone._SiegeMonitor(vars,time)
        local self = vars.context

        local advantageSide = 'none'

        local unitNumber ={
            red = 0,
            blue = 0,
        }
       
        unitNumber.red, unitNumber.blue = self:updateInZoneUnits(true)
        trigger.action.outText("unitNumber.red: "..unitNumber.red.." unitNumber.blue: "..unitNumber.blue, 10) --Debug
        
        if unitNumber.red > unitNumber.blue then
            advantageSide = 'red'
        end

        if unitNumber.red < unitNumber.blue then
            advantageSide = 'blue'
        end

        if unitNumber.red > 0 and unitNumber.red == unitNumber.blue then
            advantageSide = 'equal'
        end


        if self.state == CaptureZone.ZoneState.Neutual then
            self.SiegeMonitor.progress = self.SiegeMonitor.progress or 0

            if self.SiegeMonitor.progress >= CaptureZone.CaptureTime then
                self:UpdateZoneState(1)
                return nil
            end

            if self.SiegeMonitor.progress <= 0-CaptureZone.CaptureTime then
                self:UpdateZoneState(2)
                return nil
            end

            if advantageSide == 'red' then
                self.SiegeMonitor.progress = self.SiegeMonitor.progress + CaptureZone.SiegeMonitor.ScanTimeInterval
            end

            if advantageSide == 'blue' then
                self.SiegeMonitor.progress = self.SiegeMonitor.progress - CaptureZone.SiegeMonitor.ScanTimeInterval
            end

            if advantageSide ~= 'red' and advantageSide ~= 'blue' then
                if self.SiegeMonitor.progress > 0 then
                    self.SiegeMonitor.progress = self.SiegeMonitor.progress - CaptureZone.SiegeMonitor.ScanTimeInterval
                end

                if self.SiegeMonitor.progress < 0 then
                    self.SiegeMonitor.progress = self.SiegeMonitor.progress + CaptureZone.SiegeMonitor.ScanTimeInterval
                end

                if self.SiegeMonitor.progress == 0 then
                    self:_SiegeMonitorStop()
                    return nil
                end
            end
        end

        if self.state == CaptureZone.ZoneState.Captured then
            if self.coalition == 1 then
                self.SiegeMonitor.progress = self.SiegeMonitor.progress or CaptureZone.CaptureTime
                
                if self.SiegeMonitor.progress <= 0 then
                    self:UpdateZoneState(0)
                    return time + CaptureZone.SiegeMonitor.ScanTimeInterval
                end

                if advantageSide == 'blue' then
                    self.SiegeMonitor.progress = self.SiegeMonitor.progress - CaptureZone.SiegeMonitor.ScanTimeInterval
                end

                if advantageSide == 'none' or advantageSide == 'red' then
                    if self.SiegeMonitor.progress < CaptureZone.CaptureTime then
                        self.SiegeMonitor.progress = self.SiegeMonitor.progress + CaptureZone.SiegeMonitor.ScanTimeInterval
                    end
                    
                    if self.SiegeMonitor.progress >= CaptureZone.CaptureTime then
                        self:_SiegeMonitorStop()
                        return nil
                    end
                end
            end

            if self.coalition == 2 then
                self.SiegeMonitor.progress = self.SiegeMonitor.progress or 0-CaptureZone.CaptureTime

                if self.SiegeMonitor.progress >= 0 then
                    self:UpdateZoneState(0)
                    return time + CaptureZone.SiegeMonitor.ScanTimeInterval
                end

                if advantageSide == 'red' then
                    self.SiegeMonitor.progress = self.SiegeMonitor.progress + CaptureZone.SiegeMonitor.ScanTimeInterval
                end

                if advantageSide == 'none' or advantageSide == 'blue' then
                    if self.SiegeMonitor.progress > 0-CaptureZone.CaptureTime then
                        self.SiegeMonitor.progress = self.SiegeMonitor.progress - CaptureZone.SiegeMonitor.ScanTimeInterval
                    end
                    
                    if self.SiegeMonitor.progress <= 0-CaptureZone.CaptureTime then
                        self:_SiegeMonitorStop()
                        return nil
                    end
                end
            end
        end

        self:changeText()

        -- if Config.Debug then
        --     self:debug()
        -- end

        return time + CaptureZone.SiegeMonitor.ScanTimeInterval
    end

    function CaptureZone:_SiegeMonitorStart()
        if self.SiegeMonitor.id then
            self:_SiegeMonitorStop()
        end

        self.SiegeMonitor.id = timer.scheduleFunction(self._SiegeMonitor,{context = self},timer.getTime()+0.5)
    end

    function CaptureZone:_SiegeMonitorStop()
        timer.removeFunction(self.SiegeMonitor.id)
        self.SiegeMonitor.id = nil
    end


    function CaptureZone:debug()
        local newText = '\nzoneName: '..self.zoneName..'\n'
        newText = newText..'zoneDisplayName: '..self.zoneDisplayName..'\n'
        newText = newText..'coalition: '..self.coalition..'\n'
        newText = newText..'state: '..self.state..'\n'

        if self.MonitorID then
            newText = newText..'MonitorID: '..self.MonitorID..'\n'
        end 

        if self.SiegeMonitor.id then
            newText = newText..'SiegeMonitor ID: '..self.SiegeMonitor.id..'\n'
            newText = newText..'SiegeMonitor progress: '..self.SiegeMonitor.progress..'\n'
        end 
        
        -- newText = newText..'InZoneUnits_Red:\n'
        -- for unitName, unit in pairs(self.inZoneUnits[1]) do
        --     newText = newText .. unitName .. '\n'
        -- end
        
        -- newText = newText .. 'InZoneUnits_Blue:\n'
        -- for unitName, unit in pairs(self.inZoneUnits[2]) do
        --     newText = newText .. unitName .. '\n'
        -- end

        self:changeText(newText)
    end


    --Debug
    local ev = {}
    function ev:onEvent(event)
        if event.id == CaptureZone.Events.Captured then
            local zone = event.initiator
            local coalition = event.coalition

            trigger.action.outText("Captured, zone: "..zone.zoneName.." coalition: "..coalition, 10)
        end

        if event.id == CaptureZone.Events.Neutualized then
            local zone = event.initiator
            local coalition = event.coalition

            trigger.action.outText("Neutualized, zone: "..zone.zoneName.." coalition: "..coalition, 10)
        end
    end
    world.addEventHandler(ev)
    --Debug


    
end


---------Init--------
do
    function initCaptureZones()
        local triggerZones = env.mission.triggers.zones
    
        for zone_id, zone_data in pairs(triggerZones) do
            if type(zone_data) == 'table' then
                if string.sub(zone_data.name, 1, 5) == "Zone-" then
                    trigger.action.outText("zone: "..zone_data.name,5)
                    CaptureZone:New(zone_data.name)
                end
            end 
        end
    end

    local triggerZones = env.mission.triggers.zones
    
    for zone_id, zone_data in pairs(triggerZones) do
        if type(zone_data) == 'table' then
            if string.sub(zone_data.name, 1, 5) == "Zone-" then
                local coalition = Config.coalition.Neutual
                if zone_data.name == "Zone-Sochi" then
                    coalition = 2
                end

                trigger.action.outText("zone: "..zone_data.name,5)
                CaptureZone:New(zone_data.name,coalition)
            end
        end 
    end

    CaptureZone.allZones['Zone-Sochi']:capture(2)
    CaptureZone.allZones['Zone-Batumi']:capture(1)
end

function debugFunc(templateName, groupName, zoneNumber,tCoalition, parkingId)
    local zoneNames = {
        "Zone-Senaki",
        "Zone-Charlie",
        "Zone-Port",
    
    }
    
    local zone = trigger.misc.getZone(zoneNames[zoneNumber])
    local group = Group.getByName(templateName)
    
    
    local groupName = groupName
    local spawnPoint = {
        x = zone.point.x,
        y = zone.point.z,
    }
    
    local function getClosestAirbase(point)
        local airbases = world.getAirbases()
        local closest = nil
        local minDist = 999999
        for i,base in ipairs(airbases) do
            local distance = Utils.get2DDist(point, base:getPoint())
            if distance < minDist then
                closest = base
                minDist = distance
            end
        end
    
        return closest
    end
    
    local closestAirbase = getClosestAirbase(spawnPoint)
    local parkings = closestAirbase:getParking(true)
    
    if not parkings then 
        trigger.action.outText('No parking',10)
    end

    local msg = ''
    for i, parking in ipairs(parkings) do

        if parking.Term_Index then
            msg = msg..parking.Term_Index..'\n'
        end

        if not parking.Term_Index then
            trigger.action.circleToAll(-1,Utils.selectAvailableIndex(Config.drawIndexTabel),parking.vTerminalPos,50,{1,0,0,0.5},{1,0,0,0.3},1)
        end
    end

    if msg then
        trigger.action.outText(msg,10)
    end

    local spawnData = {}
    spawnData.name = groupName
    spawnData.task = 'Nothing'
    local unitsTable = {}
    for i, unit in ipairs(group:getUnits()) do
        local unitData = {}
        unitData.name = groupName..'-'..i
        unitData.type = unit:getTypeName()
        unitData.x = spawnPoint.x
        unitData.y = spawnPoint.y 
        unitData.speed = 162
        unitData.alt = 610
        unitData.alt_type = "RADIO"
        table.insert(unitsTable,unitData)
    end
    spawnData.uncontrolled = true
    spawnData.route = {
        ["points"] = 
        {
            [1] = 
            {
                ["type"] = "TakeOffParking",
                ['airdromeId'] = closestAirbase:getID(),
            }, -- end of [1]
        }, -- end of ["points"]
    }
    
    spawnData.units = unitsTable

    if parkingId then
        spawnData.units[1]['parking_id'] = parkingId
    end

    local newGroup = coalition.addGroup(Config.Country[tCoalition],group:getCategory(),spawnData)

    if newGroup.getName then
        local newGroupName = newGroup:getName()
        trigger.action.outText('newGroupName: '..newGroupName,10)
    end
end

-- debugFunc('固定翼-1','固定翼-2',1,2)

-- local group = Group.getByName('固定翼-2')
-- -- local groupController = group:getUnit(1):getController()
-- local groupController = group:getController()
-- groupController:setCommand({
--     id = 'Start', 
--     params = { 
--     } 
-- })