---@class SetActiveControlGroupEvent : Event
---@field vehicle BoatControlExtension
---@field index number
SetActiveControlGroupEvent = {}

local SetActiveControlGroupEvent_mt = Class(SetActiveControlGroupEvent, Event)

InitEventClass(SetActiveControlGroupEvent, 'SetActiveControlGroupEvent')

---@return SetActiveControlGroupEvent
---@nodiscard
function SetActiveControlGroupEvent.emptyNew()
    return Event.new(SetActiveControlGroupEvent_mt)
end

---@param vehicle BoatControlExtension
---@param index number
---@return SetActiveControlGroupEvent
---@nodiscard
function SetActiveControlGroupEvent.new(vehicle, index)
    local self = SetActiveControlGroupEvent.emptyNew()

    self.vehicle = vehicle
    self.index = index

    return self
end

---@param streamId number
---@param connection Connection
function SetActiveControlGroupEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUIntN(streamId, self.index, BoatControlExtension.INDEX_SEND_NUM_BITS)
end

---@param streamId number
---@param connection Connection
function SetActiveControlGroupEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.index = streamReadUIntN(streamId, BoatControlExtension.INDEX_SEND_NUM_BITS)

    self:run(connection)
end

---@param connection Connection
function SetActiveControlGroupEvent:run(connection)
    if not connection:getIsServer() then
        g_server:broadcastEvent(self, nil, connection, self.vehicle)
    end

    if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
        self.vehicle:setActiveControlGroup(self.index, true)
    end
end

---@param vehicle BoatControlExtension
---@param index number
---@param noEventSend? boolean
function SetActiveControlGroupEvent.sendEvent(vehicle, index, noEventSend)
    if not noEventSend then
        local event = SetActiveControlGroupEvent.new(vehicle, index)

        if g_server ~= nil then
            g_server:broadcastEvent(event, nil, nil, vehicle)
        else
            g_client:getServerConnection():sendEvent(event)
        end
    end
end
