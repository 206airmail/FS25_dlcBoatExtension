--[[
    Add optional ignoreDirectionZ setting for obstacle nodes.
    This will enable water pushing effects for both forwards and backwards direction,
    where as by default it will only work in forwards direction.

    Example:

    <shallowWaterObstacle>
        <obstacleNode node="riverFerry_main_component" size="9 3 23" offset="0 1 0" ignoreDirectionZ="true" />
    </shallowWaterObstacle>
]]

---@param self ShallowWaterObstacles
---@param superFunc fun(...): boolean
---@param xmlFile XMLFile
---@param key string
---@param obstacleNode ObstacleNode
---@return boolean
local function inj_ShallowWaterObstacles_loadObstacleNodeFromXML(self, superFunc, xmlFile, key, obstacleNode)
    if superFunc(self, xmlFile, key, obstacleNode) then
        obstacleNode.ignoreDirectionZ = xmlFile:getBool(key .. '#ignoreDirectionZ', false)

        return true
    end

    return false
end

---@param obstacleNode ObstacleNode
---@param superFunc fun(obstacleNode: ObstacleNode): number, number, number
local function inj_ShallowWaterObstacles_getShallowWaterParameters(obstacleNode, superFunc)
    local dx, dz, yRot = superFunc(obstacleNode)

    if obstacleNode.ignoreDirectionZ and obstacleNode.vehicle.lastSignedSpeed < 0 then
        dx = -dx
        dz = -dz
        yRot = (yRot + math.pi) % (math.pi * 2)
    end

    return dx, dz, yRot
end

ShallowWaterObstacles.loadObstacleNodeFromXML = Utils.overwrittenFunction(ShallowWaterObstacles.loadObstacleNodeFromXML, inj_ShallowWaterObstacles_loadObstacleNodeFromXML)
ShallowWaterObstacles.getShallowWaterParameters = Utils.overwrittenFunction(ShallowWaterObstacles.getShallowWaterParameters, inj_ShallowWaterObstacles_getShallowWaterParameters)
