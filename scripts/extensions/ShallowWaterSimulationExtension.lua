local CUSTOM_PROFILE = { 1024, 256 }

---@param self ShallowWaterSimulation
---@param superFunc function
local function inj_ShallowWaterSimulation_load(self, superFunc)
    self.foamAccumulationRate = 0.35
    self.foamDecayRate = 0.05

    local profileClass = Utils.getPerformanceClassId()
    local profileSetting = nil

    if profileClass <= GS_PROFILE_LOW then
        profileSetting = ShallowWaterSimulation.PROFILES.LOW
    elseif profileClass >= GS_PROFILE_HIGH then
        profileSetting = CUSTOM_PROFILE
    else
        profileSetting = ShallowWaterSimulation.PROFILES.MEDIUM
    end

    if profileClass <= GS_PROFILE_MEDIUM then
        self.foamAccumulationRate = 0
    end

    self.gridSizeX = profileSetting[1]
    self.gridSizeZ = profileSetting[1]
    self.sizeX = profileSetting[2]
    self.sizeZ = profileSetting[2]
    self.offsetDistance = self.sizeX / 3
    self.waterSim = createShallowWaterSimulation('shallowWaterSimulation', self.gridSizeX, self.gridSizeZ, self.sizeX, self.sizeZ, false)
    self.updateStepTime = 0.016666666666666666
    self.externalAcceleration = 1
    self.dampening = 0.998
    self.fakeExtraDepth = 5
    self.pmlDampeningFactor = 1
    self.pmlDampeningUpdateFactor = 0.5
    self.pmlDampeningDecay = 0.95
    self.pmlNumBorderCells = 16

    self:updateParameters()

    self.waterSimulationTexture = getShallowWaterSimulationOutputTexture(self.waterSim)
    self.waterSimulationVelocityUTexture = getShallowWaterSimulationOutputVelocityUTexture(self.waterSim)
    self.waterSimulationVelocityVTexture = getShallowWaterSimulationOutputVelocityVTexture(self.waterSim)

    addConsoleCommand('gsShallowWaterSimDebug', 'Toggle shallow water simulation debug mode', 'consoleCommandDebugToggle', self)
    addConsoleCommand('gsShallowWaterSimReset', 'Reset water simulation', 'consoleCommandReset', self)
    addConsoleCommand('gsShallowWaterSimParamSet', 'Set water simulation parameters', 'consoleCommandParamSet', self, 'updateStepTime; externalAcceleration; dampening')
    addConsoleCommand('gsShallowWaterSimExtraDepthSet', 'Set water simulation extra depth', 'consoleCommandSetExtraDepth', self, 'extraDepth')
    addConsoleCommand('gsShallowWaterSimPaint', 'Paint shape on simulation', 'consoleCommandPaint', self, '[circle|rect]; [velocityScale]; [radiusOrWidth]; [height]')
    addConsoleCommand('gsShallowWaterSimFoamParamSet', 'Set water simulation foam parameters', 'consoleCommandFoamParamSet', self, 'accumulationRate; decayRate')
    addConsoleCommand('gsShallowWaterSimSizeSet', 'Set water simulation size', 'consoleCommandSizeSet', self, 'simulation size in meters')
    addConsoleCommand('gsShallowWaterSimPMLParamSet', 'Set perfectly matched layer boundary condition params', 'consoleCommandPMLSet', self, 'dampeningFactor; dampeningUpdateFactor; dampeningDecay; numBorderCells')

    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.FRAME_LIMIT], self.updateParameters, self)

    return self
end

ShallowWaterSimulation.load = Utils.overwrittenFunction(ShallowWaterSimulation.load, inj_ShallowWaterSimulation_load)
