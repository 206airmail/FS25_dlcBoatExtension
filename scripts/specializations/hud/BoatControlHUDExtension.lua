---@class BoatControlHUDExtension
---@field vehicle BoatControlExtension
---@field priority number
---@field totalHeight number
---@field textSize number
---@field textOffsetX number
---@field backgroundTop Overlay
---@field backgroundScale Overlay
---@field backgroundBottom Overlay
---@field controlGroupIcon Overlay
---@field controlGroupIconOffsetX number
---@field controlGroupIconOffsetY number
---@field activeNameTextOffsetY number
---@field activeIndexTextOffsetY number
---@field headerText string
---@field headerTextOffsetY number
BoatControlHUDExtension = {}
BoatControlHUDExtension.TEXTURE_FILENAME = g_currentModDirectory .. 'data/hud_elements.png'
BoatControlHUDExtension.ICON_UVS = {
    PROPELLER = GuiUtils.getUVs('0 0 0.5 0.5', { 256, 256 }),
    SIDE_THRUSTERS = GuiUtils.getUVs('0.5 0 0.5 0.5', { 256, 256 }),
}

local BoatControlHUDExtension_mt = Class(BoatControlHUDExtension)

---@param vehicle BoatControlExtension
---@return BoatControlHUDExtension
---@nodiscard
function BoatControlHUDExtension.new(vehicle)
    ---@type BoatControlHUDExtension
    local self = setmetatable({}, BoatControlHUDExtension_mt)

    self.vehicle = vehicle
    self.priority = GS_PRIO_HIGH
    self.headerText = string.upper(BoatControlExtension.L10N_STRING.ACTIVE_CONTROL_GROUP)

    local r, g, b, a = unpack(HUD.COLOR.BACKGROUND)
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.backgroundTop = g_overlayManager:createOverlay('gui.hudExtension_top', 0, 0, 0, 0)
    self.backgroundTop:setColor(r, g, b, a)
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.backgroundScale = g_overlayManager:createOverlay('gui.hudExtension_middle', 0, 0, 0, 0)
    self.backgroundScale:setColor(r, g, b, a)
    ---@diagnostic disable-next-line: assign-type-mismatch
    self.backgroundBottom = g_overlayManager:createOverlay('gui.hudExtension_bottom', 0, 0, 0, 0)
    self.backgroundBottom:setColor(r, g, b, a)

    self.controlGroupIcon = Overlay.new(BoatControlHUDExtension.TEXTURE_FILENAME, 0, 0, 0, 0)
    self.controlGroupIcon:setUVs(BoatControlHUDExtension.ICON_UVS.PROPELLER)

    self:storeScaledValues()

    g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.UI_SCALE], self.storeScaledValues, self)

    return self
end

function BoatControlHUDExtension:delete()
    self.backgroundTop:delete()
    self.backgroundScale:delete()
    self.backgroundBottom:delete()

    g_messageCenter:unsubscribeAll(self)
end

function BoatControlHUDExtension:storeScaledValues()
    local padding = { 16, 16 }
    local displaySizeX, displaySizeY = 330, 64
    local iconSize = 42

    local paddingX = ModUtils.getHUDNormalizedXValue(padding[1])

    local totalWidth = ModUtils.getHUDNormalizedXValue(displaySizeX)
    self.totalHeight = ModUtils.getHUDNormalizedYValue(displaySizeY)
    local halfHeight = self.totalHeight / 2

    local backgroundHeight = ModUtils.getHUDNormalizedYValue(6)
    local backgroundScaleY = self.totalHeight - 2 * backgroundHeight

    self.backgroundTop:setDimension(totalWidth, backgroundHeight)
    self.backgroundBottom:setDimension(totalWidth, backgroundHeight)
    self.backgroundScale:setDimension(totalWidth, backgroundScaleY)

    local iconWidth, iconHeight = ModUtils.getHUDNormalizedValues(iconSize, iconSize)

    local iconPosX, iconPosY = padding[1], -(displaySizeY - iconSize) / 2

    self.controlGroupIcon:setDimension(iconWidth, iconHeight)
    self.controlGroupIconOffsetX, self.controlGroupIconOffsetY = ModUtils.getHUDNormalizedValues(iconPosX, iconPosY)

    self.textSize = ModUtils.getHUDNormalizedYValue(12)
    self.textOffsetX = paddingX * 2 + iconWidth

    self.headerTextSize = ModUtils.getHUDNormalizedYValue(10)
    self.headerTextOffsetY = halfHeight + ModUtils.getHUDNormalizedYValue(9) - self.headerTextSize / 2
    self.activeNameTextOffsetY = halfHeight - ModUtils.getHUDNormalizedYValue(6) - self.textSize / 2
    self.activeIndexTextOffsetY = halfHeight - self.textSize / 2
end

---@return number
function BoatControlHUDExtension:getHeight()
    return self.totalHeight
end

---@param inputHelpDisplay InputHelpDisplay
---@param posX number
---@param posY number
---@return number
function BoatControlHUDExtension:draw(inputHelpDisplay, posX, posY)
    local spec = self.vehicle.spec_boatControl

    self.backgroundTop:setPosition(posX, posY - self.backgroundTop.height)
    self.backgroundScale:setPosition(posX, self.backgroundTop.y - self.backgroundScale.height)
    self.backgroundBottom:setPosition(posX, self.backgroundScale.y - self.backgroundBottom.height)
    self.backgroundTop:render()
    self.backgroundScale:render()
    self.backgroundBottom:render()

    posY = self.backgroundBottom.y

    local iconUVs = BoatControlHUDExtension.ICON_UVS[spec.activeControlGroup.icon] or BoatControlHUDExtension.ICON_UVS.PROPELLER
    self.controlGroupIcon:setUVs(iconUVs)
    self.controlGroupIcon:setPosition(posX + self.controlGroupIconOffsetX, posY - self.controlGroupIconOffsetY)
    self.controlGroupIcon:render()

    local activeControlGroupName = self.vehicle:getActiveControlGroupName()

    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextColor(1, 1, 1, 1)
    setTextBold(true)
    renderText(posX + self.textOffsetX, posY + self.headerTextOffsetY, self.headerTextSize, self.headerText)
    setTextBold(false)
    renderText(posX + self.textOffsetX, posY + self.activeNameTextOffsetY, self.textSize, activeControlGroupName)

    local indexText = string.format('%d / %d', spec.activeControlGroupIndex, #spec.controlGroups)

    setTextAlignment(RenderText.ALIGN_RIGHT)
    setTextBold(true)
    renderText(posX + self.backgroundScale.width - self.controlGroupIconOffsetX, posY + self.activeIndexTextOffsetY, self.textSize, indexText)
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)

    return self.backgroundBottom.y
end
