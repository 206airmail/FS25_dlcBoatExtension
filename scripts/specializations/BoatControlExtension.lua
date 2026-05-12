source(g_currentModDirectory .. 'scripts/specializations/events/SetActiveControlGroupEvent.lua')
source(g_currentModDirectory .. 'scripts/specializations/hud/BoatControlHUDExtension.lua')

---@class BoatControlExtension_spec
---@field controlGroups ControlGroup[]
---@field activeControlGroupIndex number
---@field activeControlGroup ControlGroup
---@field actionEvents table
---@field hudExtension BoatControlHUDExtension

---@class BoatControlExtension : Vehicle, Boat, Cylindered, Dashboard
---@field spec_boatControl BoatControlExtension_spec
BoatControlExtension = {}

BoatControlExtension.SPEC_NAME = 'spec_' .. g_currentModName .. '.boatControlExtension'

BoatControlExtension.ACTION_NEXT_GROUP = 'BCE_CONTROL_GROUP_NEXT'
BoatControlExtension.ACTION_PREV_GROUP = 'BCE_CONTROL_GROUP_PREV'
BoatControlExtension.ACTION_RESET = 'BCE_CONTROL_GROUP_RESET'

BoatControlExtension.L10N_STRING = {
    CONTROL_GROUP_NEXT = g_i18n:getText('input_BCE_CONTROL_GROUP_NEXT'),
    CONTROL_GROUP_PREV = g_i18n:getText('input_BCE_CONTROL_GROUP_PREV'),
    CONTROL_GROUP_RESET = g_i18n:getText('input_BCE_CONTROL_GROUP_RESET'),
    PRIMARY_DRIVE = g_i18n:getText('ui_primaryDrive'),
    ACTIVE_CONTROL_GROUP = g_i18n:getText('ui_activeControlGroup'),
}

BoatControlExtension.INDEX_SEND_NUM_BITS = 4
BoatControlExtension.MAX_NUM_GROUPS = 2 ^ BoatControlExtension.INDEX_SEND_NUM_BITS - 1

function BoatControlExtension.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Boat, specializations) and SpecializationUtil.hasSpecialization(Cylindered, specializations)
end

function BoatControlExtension.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, 'getControlGroupByIndex', BoatControlExtension.getControlGroupByIndex)
    SpecializationUtil.registerFunction(vehicleType, 'setActiveControlGroup', BoatControlExtension.setActiveControlGroup)
    SpecializationUtil.registerFunction(vehicleType, 'getActiveControlGroup', BoatControlExtension.getActiveControlGroup)
    SpecializationUtil.registerFunction(vehicleType, 'getActiveControlGroupName', BoatControlExtension.getActiveControlGroupName)
    SpecializationUtil.registerFunction(vehicleType, 'getActiveControlGroupIndex', BoatControlExtension.getActiveControlGroupIndex)
    SpecializationUtil.registerFunction(vehicleType, 'updateActiveControlGroup', BoatControlExtension.updateActiveControlGroup)
end

function BoatControlExtension.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, 'onLoad', BoatControlExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onPreDelete', BoatControlExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onDelete', BoatControlExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onReadStream', BoatControlExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onWriteStream', BoatControlExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onRegisterActionEvents', BoatControlExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onRegisterDashboardValueTypes', BoatControlExtension)
    SpecializationUtil.registerEventListener(vehicleType, 'onDraw', BoatControlExtension)
end

function BoatControlExtension.initSpecialization()
    local schema = Vehicle.xmlSchema
    local key = 'vehicle.boat.controlGroups.controlGroup(?)'

    schema:setXMLSpecializationType('BoatControlExtension')

    schema:register(XMLValueType.L10N_STRING, key .. '#name', 'Name displayed')
    schema:register(XMLValueType.STRING, key .. '#icon', 'Icon (propeller, side_thrusters)', 'propeller')
    schema:register(XMLValueType.INT, key .. '#propellerNodesIndex', 'Override use propeller nodes from another control group (1 = default)', nil, false)
    schema:register(XMLValueType.INT, key .. '#propellerForceNodesIndex', 'Override use propeller force nodes from another control group (1 = default)', nil, false)
    schema:register(XMLValueType.INT, key .. '#propellerEffectsIndex', 'Override use propeller effect nodes from another control group (1 = default)', nil, false)
    schema:register(XMLValueType.INT, key .. '#shallowWaterNodesIndex', 'Override use shallow water nodes from another control group (1 = default)', nil, false)
    schema:register(XMLValueType.INT, key .. '#rudderNodesIndex', 'Override use rudder nodes from another control group (1 = default)', nil, false)
    schema:register(XMLValueType.NODE_INDEX, key .. '.rudderNodes.rudderNode(?)#node', 'Visual rudder node')
    schema:register(XMLValueType.ANGLE, key .. '.rudderNodes.rudderNode(?)#maxRotation', 'Max. Y rotation in each direction', 45)
    schema:register(XMLValueType.ANGLE, key .. '#maxSteeringAngle', 'Max. steering angle - NOT USED', 40)
    schema:register(XMLValueType.FLOAT, key .. '#maxAccelerationSpeed', 'Max. acceleration speed (m/s2)', 1.5)
    schema:register(XMLValueType.FLOAT, key .. '#steeringForce', 'Max. steering force (kN)', 100)
    schema:register(XMLValueType.ANGLE, key .. '#steeringForceAngle', 'Steering force vertical angle', 25)
    schema:register(XMLValueType.ANGLE, key .. '#accelerationForceAngle', 'Acceleration force vertical angle', 25)
    schema:register(XMLValueType.FLOAT, key .. '.accelerationForce#reverseFactor', 'Multiplier of acceleration while going in reverse', 1)
    schema:register(XMLValueType.FLOAT, key .. '.accelerationForce#steeringFactor', 'Multiplier of acceleration while fully steered in', 1)
    schema:register(XMLValueType.FLOAT, key .. '.accelerationForce.key(?)#speed', 'Reference speed')
    schema:register(XMLValueType.FLOAT, key .. '.accelerationForce.key(?)#force', 'Max. force at this speed (kN)')
    schema:register(XMLValueType.NODE_INDEX, key .. '.forceNode(?)#node', 'Main propeller force node')
    schema:register(XMLValueType.NODE_INDEX, key .. '.propellerNodes.propellerNode(?)#node', 'Visual propeller node')
    schema:register(XMLValueType.ANGLE, key .. '.propellerNodes.propellerNode(?)#rotSpeed', 'Max. rot speed (deg/sec)', 360)
    schema:register(XMLValueType.NODE_INDEX, key .. '.shallowWaterNodes.shallowWaterNode(?)#node', 'Shallow water effect node')
    schema:register(XMLValueType.FLOAT, key .. '.shallowWaterNodes.shallowWaterNode(?)#radius', 'Radius of the shallow water effect node', 2)
    EffectManager.registerEffectXMLPaths(schema, key .. '.propellerEffects')
    ObjectChangeUtil.registerObjectChangesXMLPaths(schema, key)

    schema:register(XMLValueType.L10N_STRING, 'vehicle.boat.control#name', 'Name displayed', BoatControlExtension.L10N_STRING.PRIMARY_DRIVE)
    ObjectChangeUtil.registerObjectChangesXMLPaths(schema, 'vehicle.boat.control')

    schema:setXMLSpecializationType()
end

function BoatControlExtension:onLoad()
    ---@type BoatControlExtension_spec
    local spec = self[BoatControlExtension.SPEC_NAME]
    self.spec_boatControl = spec

    ---@type Boat_spec
    local boat_spec = self[Boat.SPEC_TABLE_NAME]

    ---@type XMLFile
    local xmlFile = self.xmlFile

    spec.controlGroups = {}
    spec.activeControlGroupIndex = 1

    ---@type ControlGroup
    local boatControlGroup = {
        name = xmlFile:getValue('vehicle.boat.control#name', BoatControlExtension.L10N_STRING.PRIMARY_DRIVE, self.customEnvironment),
        icon = 'PROPELLER',
        maxSteeringAngle = boat_spec.maxSteeringAngle,
        maxAccelerationSpeed = boat_spec.maxAccelerationSpeed,
        steeringForce = boat_spec.steeringForce,
        steeringForceAngle = boat_spec.steeringForceAngle,
        accelerationForceAngle = boat_spec.accelerationForceAngle,
        reverseAccelerationFactor = boat_spec.reverseAccelerationFactor,
        steeringAccelerationFactor = boat_spec.steeringAccelerationFactor,
        accelerationForceCurve = boat_spec.accelerationForceCurve,
        propellerNodes = boat_spec.propellerNodes,
        propellerForceNodes = boat_spec.propellerForceNodes,
        rudderNodes = boat_spec.rudderNodes,
        propellerEffects = boat_spec.propellerEffects,
        shallowWaterNodes = boat_spec.shallowWaterNodes,
        changeObjects = {},
    }

    ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, 'vehicle.boat.objectChanges', boatControlGroup.changeObjects, self.components, self)
    ObjectChangeUtil.setObjectChanges(boatControlGroup.changeObjects, true, self, self.setMovingToolDirty, true)

    table.insert(spec.controlGroups, boatControlGroup)
    spec.activeControlGroup = boatControlGroup

    for index, groupKey in xmlFile:iterator('vehicle.boat.controlGroups.controlGroup') do
        if #spec.controlGroups == BoatControlExtension.MAX_NUM_GROUPS then
            Logging.xmlWarning(xmlFile, 'Maximum number of controlGroup entries reached (%d)', BoatControlExtension.MAX_NUM_GROUPS)
            break
        end

        ---@type ControlGroup
        ---@diagnostic disable-next-line: missing-fields
        local group = {
            name = xmlFile:getValue(groupKey .. '#name', string.format('Group %d', index + 2), self.customEnvironment, false),
            icon = xmlFile:getValue(groupKey .. '#icon', 'propeller'),
            maxSteeringAngle = xmlFile:getValue(groupKey .. '#maxSteeringAngle', 40),
            maxAccelerationSpeed = xmlFile:getValue(groupKey .. '#maxAccelerationSpeed', 1.5),
            steeringForce = xmlFile:getValue(groupKey .. '#steeringForce', 100),
            steeringForceAngle = xmlFile:getValue(groupKey .. '#steeringForceAngle', 25),
            accelerationForceAngle = xmlFile:getValue(groupKey .. '#accelerationForceAngle', 25),
            reverseAccelerationFactor = xmlFile:getValue(groupKey .. '.accelerationForce#reverseFactor', 1),
            steeringAccelerationFactor = xmlFile:getValue(groupKey .. '.accelerationForce#steeringFactor', 1),
            accelerationForceCurve = AnimCurve.new(linearInterpolator1),
            propellerForceNodes = {},
            propellerNodes = {},
            propellerEffects = {},
            shallowWaterNodes = {},
            rudderNodes = {},
            changeObjects = {},
            propellerNodesIndex = xmlFile:getValue(groupKey .. '#propellerNodesIndex'),
            propellerForceNodesIndex = xmlFile:getValue(groupKey .. '#propellerForceNodesIndex'),
            propellerEffectsIndex = xmlFile:getValue(groupKey .. '#propellerEffectsIndex'),
            shallowWaterNodesIndex = xmlFile:getValue(groupKey .. '#shallowWaterNodesIndex'),
            rudderNodesIndex = xmlFile:getValue(groupKey .. '#rudderNodesIndex'),
        }

        group.icon = group.icon:upper()

        for _, key in xmlFile:iterator(groupKey .. '.accelerationForce.key') do
            local speed = xmlFile:getValue(key .. '#speed')
            local force = xmlFile:getValue(key .. '#force')

            if speed ~= nil and force ~= nil then
                group.accelerationForceCurve:addKeyframe({ force, time = speed }, xmlFile, key)
            end
        end

        for _, key in xmlFile:iterator(groupKey .. '.forceNode') do
            local node = xmlFile:getValue(key .. '#node', nil, self.components, self.i3dMappings)

            if node ~= nil then
                table.insert(group.propellerForceNodes, { node = node, lastSpeedReal = 0 })
            end
        end

        if group.propellerEffectsIndex == nil and #group.propellerForceNodes == 0 then
            Logging.xmlWarning(xmlFile, 'Missing propeller forceNodes in controlGroup "%s"', groupKey .. '.forceNode(?)')
        end

        for _, key in xmlFile:iterator(groupKey .. '.propellerNodes.propellerNode') do
            local node = xmlFile:getValue(key .. '#node', nil, self.components, self.i3dMappings)
            local rotSpeed = xmlFile:getValue(key .. '#rotSpeed', 360) * 0.001

            if node ~= nil then
                table.insert(group.propellerNodes, { node = node, rotSpeed = rotSpeed, curRot = 0 })
            end
        end

        for _, key in xmlFile:iterator(groupKey .. '.shallowWaterNodes.shallowWaterNode') do
            local node = xmlFile:getValue(key .. '#node', nil, self.components, self.i3dMappings)
            local radius = xmlFile:getValue(key .. '#radius', 2)

            if node ~= nil then
                table.insert(group.shallowWaterNodes, { node = node, radius = radius })
            end
        end

        for _, key in xmlFile:iterator(groupKey .. '.rudderNodes.rudderNode') do
            local node = xmlFile:getValue(key .. '#node', nil, self.components, self.i3dMappings)
            local maxRotation = xmlFile:getValue(key .. '#maxRotation', 45)

            if node ~= nil then
                table.insert(group.rudderNodes, { node = node, maxRotation = maxRotation })
            end
        end

        if self.isClient then
            group.propellerEffects = g_effectManager:loadEffect(xmlFile, groupKey .. '.propellerEffects', self.components, self, self.i3dMappings)
        end

        ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, groupKey .. '.objectChanges', group.changeObjects, self.components, self)
        ObjectChangeUtil.setObjectChanges(group.changeObjects, false, self, self.setMovingToolDirty, true)

        table.insert(spec.controlGroups, group)
    end

    if #spec.controlGroups == 1 then
        Logging.xmlWarning(xmlFile, 'No control groups defined in "vehicle.boat.controlGroups"')
        SpecializationUtil.removeEventListener(self, 'onPreDelete', BoatControlExtension)
        SpecializationUtil.removeEventListener(self, 'onDelete', BoatControlExtension)
        SpecializationUtil.removeEventListener(self, 'onWriteStream', BoatControlExtension)
        SpecializationUtil.removeEventListener(self, 'onReadStream', BoatControlExtension)
        SpecializationUtil.removeEventListener(self, 'onRegisterActionEvents', BoatControlExtension)
        SpecializationUtil.removeEventListener(self, 'onRegisterDashboardValueTypes', BoatControlExtension)
    end

    if self.isClient then
        spec.hudExtension = BoatControlHUDExtension.new(self)
    end
end

function BoatControlExtension:onPreDelete()
    self:setActiveControlGroup(1, true)
end

function BoatControlExtension:onDelete()
    local spec = self.spec_boatControl

    for index, group in ipairs(spec.controlGroups) do
        if index > 1 then
            g_effectManager:deleteEffects(group.propellerEffects)
            group.propellerEffects = {}
        end
    end

    if spec.hudExtension ~= nil then
        g_currentMission.hud:removeInfoExtension(spec.hudExtension)
        spec.hudExtension:delete()
    end
end

function BoatControlExtension:onDraw()
    local spec = self.spec_boatControl

    if spec.hudExtension ~= nil then
        g_currentMission.hud:addInfoExtension(spec.hudExtension)
    end
end

---@param index number
---@return ControlGroup?
function BoatControlExtension:getControlGroupByIndex(index)
    return self.spec_boatControl.controlGroups[index]
end

---@param index number
---@param noEventSend? boolean
function BoatControlExtension:setActiveControlGroup(index, noEventSend)
    local spec = self.spec_boatControl

    index = math.clamp(index, 1, #spec.controlGroups)

    if spec.activeControlGroupIndex ~= index then
        SetActiveControlGroupEvent.sendEvent(self, index, noEventSend)

        local previousGroup = spec.activeControlGroup

        spec.activeControlGroupIndex = index
        spec.activeControlGroup = spec.controlGroups[index]

        if spec.activeControlGroup ~= previousGroup then
            self:updateActiveControlGroup(previousGroup)
        end
    end
end

---@param previous ControlGroup
function BoatControlExtension:updateActiveControlGroup(previous)
    ---@type Boat_spec
    local boat_spec = self[Boat.SPEC_TABLE_NAME]
    local spec = self.spec_boatControl
    local controlGroups = spec.controlGroups
    local group = spec.activeControlGroup

    boat_spec.maxSteeringAngle = group.maxSteeringAngle
    boat_spec.maxAccelerationSpeed = group.maxAccelerationSpeed
    boat_spec.steeringForce = group.steeringForce
    boat_spec.steeringForceAngle = group.steeringForceAngle
    boat_spec.accelerationForceAngle = group.accelerationForceAngle
    boat_spec.reverseAccelerationFactor = group.reverseAccelerationFactor
    boat_spec.steeringAccelerationFactor = group.steeringAccelerationFactor
    boat_spec.accelerationForceCurve = group.accelerationForceCurve

    local propellerNodesGroup = controlGroups[group.propellerNodesIndex] or group
    local propellerForceNodesGroup = controlGroups[group.propellerForceNodesIndex] or group
    local propellerEffectsGroup = controlGroups[group.propellerEffectsIndex] or group
    local shallowWaterNodesGroup = controlGroups[group.shallowWaterNodesIndex] or group
    local rudderNodesGroup = controlGroups[group.rudderNodesIndex] or group

    boat_spec.propellerNodes = propellerNodesGroup.propellerNodes

    if boat_spec.propellerForceNodes ~= propellerForceNodesGroup.propellerForceNodes then
        for _, forceNode in ipairs(boat_spec.propellerForceNodes) do
            forceNode.lastSpeedReal = 0
        end
        boat_spec.propellerForceNodes = propellerForceNodesGroup.propellerForceNodes
    end

    if boat_spec.propellerEffects ~= propellerEffectsGroup.propellerEffects then
        if boat_spec.propellerEffectsActive then
            g_effectManager:stopEffects(boat_spec.propellerEffects)
            boat_spec.propellerEffectsActive = false
        end
        boat_spec.propellerEffects = propellerEffectsGroup.propellerEffects
    end

    boat_spec.shallowWaterNodes = shallowWaterNodesGroup.shallowWaterNodes
    boat_spec.rudderNodes = rudderNodesGroup.rudderNodes

    if #boat_spec.propellerForceNodes == 0 then
        Logging.error('BoatControlExtension:updateActiveControlGroup() #propellerForceNodes = 0')
    end

    if not self.isDeleting and not self.isDeleted then
        ObjectChangeUtil.setObjectChanges(previous.changeObjects, false, self, self.setMovingToolDirty)
        ObjectChangeUtil.setObjectChanges(group.changeObjects, true, self, self.setMovingToolDirty)
    end
end

---@return ControlGroup
---@nodiscard
function BoatControlExtension:getActiveControlGroup()
    return self.spec_boatControl.activeControlGroup
end

---@return string
function BoatControlExtension:getActiveControlGroupName()
    return self.spec_boatControl.activeControlGroup.name
end

---@return number
function BoatControlExtension:getActiveControlGroupIndex()
    return self.spec_boatControl.activeControlGroupIndex
end

function BoatControlExtension:onRegisterDashboardValueTypes()
    local spec = self.spec_boatControl

    local groupIndex = DashboardValueType.new('boat', 'boatControlIndex')

    groupIndex:setValue(spec, function ()
        return spec.activeControlGroupIndex
    end)

    self:registerDashboardValueType(groupIndex)
end

---@param isActiveForInput boolean
---@param isActiveForInputIgnoreSelection boolean
function BoatControlExtension:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
    if self.isClient then
        local spec = self.spec_boatControl

        if isActiveForInputIgnoreSelection then
            local _, actionEventId = self:addActionEvent(spec.actionEvents, BoatControlExtension.ACTION_NEXT_GROUP, self, BoatControlExtension.actionEventControlGroupNext, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventText(actionEventId, BoatControlExtension.L10N_STRING.CONTROL_GROUP_NEXT)

            _, actionEventId = self:addActionEvent(spec.actionEvents, BoatControlExtension.ACTION_PREV_GROUP, self, BoatControlExtension.actionEventControlGroupPrevious, false, true, false, true, nil, nil, true)
            g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
            g_inputBinding:setActionEventText(actionEventId, BoatControlExtension.L10N_STRING.CONTROL_GROUP_PREV)

            if #spec.controlGroups > 2 then
                _, actionEventId = self:addActionEvent(spec.actionEvents, BoatControlExtension.ACTION_RESET, self, BoatControlExtension.actionEventControlGroupReset, false, true, false, true, nil, nil, true)
                g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
                g_inputBinding:setActionEventText(actionEventId, BoatControlExtension.L10N_STRING.CONTROL_GROUP_RESET)
            end
        end
    end
end

function BoatControlExtension:actionEventControlGroupNext()
    local spec = self.spec_boatControl

    local index = spec.activeControlGroupIndex + 1

    if index > #spec.controlGroups then
        self:setActiveControlGroup(1)
    else
        self:setActiveControlGroup(index)
    end
end

function BoatControlExtension:actionEventControlGroupPrevious()
    local spec = self.spec_boatControl

    local index = spec.activeControlGroupIndex - 1

    if index < 1 then
        self:setActiveControlGroup(#spec.controlGroups)
    else
        self:setActiveControlGroup(index)
    end
end

function BoatControlExtension:actionEventControlGroupReset()
    self:setActiveControlGroup(1)
end

---@param streamId number
---@param connection Connection
function BoatControlExtension:onWriteStream(streamId, connection)
    local spec = self.spec_boatControl

    streamWriteUIntN(streamId, spec.activeControlGroupIndex, BoatControlExtension.INDEX_SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function BoatControlExtension:onReadStream(streamId, connection)
    local index = streamReadUIntN(streamId, BoatControlExtension.INDEX_SEND_NUM_BITS)
    self:setActiveControlGroup(index, true)
end

g_soundManager:registerModifierType('BOAT_CONTROL_GROUP_INDEX', BoatControlExtension.getActiveControlGroupIndex)
