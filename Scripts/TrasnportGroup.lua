TrasnportGroup = {}

do
    TrasnportGroup.allGroups = {}
    TrasnportGroup.AllowTypes = {
        ---Vehicles
        ['M 818'] = {
            supplyCost = 100,   --pay only when first takeoff
            cargoCapacity = 3000, --units
            infantryCapacity = 30, --per person
            innerFuel = 1140, --kg
            category = 2,
        },

        ---Helicopters
        ['AH-64D_BLK_II'] = {
            supplyCost = 100,   --pay only when first takeoff
            cargoCapacity = 1700, --units
            infantryCapacity = 2, --per person
            innerFuel = 1140, --kg
            category = 1,
        },

        ---Planes
    }

    local spawnEV = {}
    function spawnEV:onEvent(event)
        if event.id == world.event.S_EVENT_BIRTH then
            if not event.initiator then return end

            local typeName = event.initiator:getTypeName()

            if TrasnportGroup.AllowTypes[typeName] then
                local group = event.initiator:getGroup()
                if not group then return end

                TransportGroup:new(group,TrasnportGroup.AllowTypes[typeName])
            end
        end
        
    end
    world.addEventHandler(spawnEV)

    function TransportGroup:new(groupOrGroupName,transportData)
        if not groupOrGroupName then return end
        local inputType = type(groupOrGroupName)
        if inputType ~= "table" and inputType ~= "string" then return end

        local group = groupOrGroupName
        if inputType ~= "table" then
            group = Group.getByName(groupOrGroupName)
            if not group then return end
        end

        local groupName = group:getName()

        if TransportGroup.allGroups[groupName] then 
            env.log(string.format(Languages:translate("TransportGroup [%s] already exist."),groupName))
            return 
        end

        local obj = {}
        obj.group = group
        obj.groupMenu = {}


        obj.infantryCapacity = transportData.infantryCapacity
        obj.infantryTemplates = {}
        obj.infantryNumber = 0

        obj.cargoCapacity = transportData.cargoCapacity
        obj.cargoWeight = 0

        --For AI automation
        obj.MonitorID = nil

        setmetatable(obj,self)
        self.__index = self

        TrasnportGroup.allGroups[groupName] = obj

        local deathEV = {}
        deathEV.context = obj

        function deathEV:onEvent(event)
            local context = self.context

            if event.id == world.event.S_EVENT_DEAD and event.initiator then
                local unit = event.initiator
                if not unit or not unit.getGroup then return end

                local group = unit:getGroup()
                if not group or not group.getName then return end

                local groupName = group:getName()

                if TransportGroup.allGroups[groupName] then
                    TransportGroup.allGroups[groupName]:removeTrasnportGroup()
                end
            end
        end

        world.addEventHandler(deathEV)

        return obj
    end

    function TransportGroup:removeTrasnportGroup()
        local group = self.group

        if group and group:isExist() then
            group:destroy()
        end

        if self.MonitorID then
            self:stop()
        end

        if TransportGroup.allGroups[self.groupName] then
            TransportGroup.allGroups[self.groupName] = nil
        end
    end

    function TransportGroup:addMenuItem()


    end
end