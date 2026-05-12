---@class ModUtils
ModUtils = {}

---@param filepath string
---@return string
---@nodiscard
function ModUtils.getFilename(filepath)
    ---@diagnostic disable-next-line: return-type-mismatch
    return filepath:match("([^/\\]+)$")
end

---@param mass number
---@return string
function ModUtils.formatMass(mass)
    local str = string.format("%.0f", mass * 1000)

    str = str:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^%,", "")

    return str .. ' kg'
end

---@param x number
---@param y number
---@return number x
---@return number y
function ModUtils.getHUDNormalizedValues(x, y)
    return ModUtils.getHUDNormalizedXValue(x), ModUtils.getHUDNormalizedYValue(y)
end

---@param number number
---@return number
function ModUtils.getHUDNormalizedXValue(number)
    local screenSizeValue = g_referenceScreenWidth
    local scalingValue = g_aspectScaleX
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)

    local value = number / screenSizeValue * scalingValue * uiScale

    return value
end

---@param number number
---@return number
function ModUtils.getHUDNormalizedYValue(number)
    local screenSizeValue = g_referenceScreenHeight
    local scalingValue = g_aspectScaleY
    local uiScale = g_gameSettings:getValue(GameSettings.SETTING.UI_SCALE)

    local value = number / screenSizeValue * scalingValue * uiScale

    return value
end
