local dlcName = 'pdlc_highlandsFishingPack'

---@param filepath string
---@return string
---@nodiscard
local function getFilename(filepath)
    ---@diagnostic disable-next-line: return-type-mismatch
    return filepath:match("([^/\\]+)$")
end

---@class ModController
ModController = {}

---@type table <string, string>
ModController.XML_FILE_MAPPING = {}

ModController.STORE_ITEMS_FILES = {
    ['aquacultureVessel.xml'] = true,
    ['boatFishing.xml'] = true,

    ['bga500kw.xml'] = true,
    ['buyingStationManure.xml'] = true,
    ['buyingStationLiquidManure.xml'] = true,
    ['buyingStationPigFood.xml'] = true,
}

local ModController_mt = Class(ModController)

---@return ModController
---@nodiscard
function ModController.new()
    ---@type ModController
    local self = setmetatable({}, ModController_mt)

    addConsoleCommand('_copyDlcBoatXMLFiles', '', 'consoleCopyDlcBoatXMLFiles', self, 'outputPath')
    addModEventListener(self)

    return self
end

function ModController:consoleCopyDlcBoatXMLFiles(outputPath)
    if outputPath == nil then
        return '_copyDlcBoatXMLFiles <outputPath>'
    end

    if not outputPath:endsWith('/') then
        outputPath = outputPath .. '/'
    end

    if not folderExists(outputPath) then
        Logging.warning('Output path "%s" does not exist', outputPath)
        return
    end

    for _, item in ipairs(g_storeManager.items) do
        if item.dlcTitle ~= '' then
            if item.xmlFilename:endsWith('aquacultureVessel.xml') or item.xmlFilename:endsWith('boatFishing.xml') then
                Logging.info('File: "%s"', item.xmlFilename)

                ---@type XMLFile?
                local xmlFile = XMLFile.loadIfExists('_tmp', item.xmlFilename)

                if xmlFile ~= nil then
                    local filename = getFilename(item.xmlFilename)
                    local filepath = outputPath .. filename

                    Logging.info('  Writing XML to %s', filepath)

                    xmlFile:saveTo(filepath)
                    xmlFile:delete()
                end
            end
        end
    end
end

function ModController:updateDlcStoreItems()
    for _, storeItem in ipairs(g_storeManager.items) do
        if storeItem.dlcTitle ~= '' then
            local filename = getFilename(storeItem.xmlFilename)

            if ModController.STORE_ITEMS_FILES[filename] then
                Logging.info('  Store item: "%s"', storeItem.xmlFilename)
                storeItem.canBeSold = true
                storeItem.showInStore = true

                -- item.allowLeasing = true
                -- item.price = 0

                if storeItem.species == StoreSpecies.PLACEABLE then
                    self:updateDlcPlaceableStoreItem(storeItem)
                end
            end
        end
    end
end

---@param storeItem StoreItem
function ModController:updateDlcPlaceableStoreItem(storeItem)
    if storeItem.brush == nil then
        local constructionCategory = g_storeManager.constructionCategories[1]

        storeItem.brush = {
            type = 'placeable',
            parameters = {},
            category =
                constructionCategory,
            tab = constructionCategory.tabs[1]
        }
    end
end

function ModController:addMissingDlcStoreItems()
    if g_mpLoadingScreen.missionInfo.mapId ~= 'pdlc_highlandsFishingPack.HighlandsFishingMap' then
        ---@type ModItem
        local mod = g_modManager:getModByName(dlcName)

        g_storeManager:addModStoreItem('placeables/brandless/fishFarm/fishFarm.xml', mod.modDir, dlcName, false, false, mod.title)
    end
end

function ModController:addCustomDlcStoreItems()
    ---@type ModItem
    local mod = g_modManager:getModByName(dlcName)

    self:registerCustomDlcStoreItem(mod, 'vehicles/lizard/boatFishing/boatFishingCustom.xml', g_currentModDirectory .. 'data/boatFishingCustom.xml')
    self:registerCustomDlcStoreItem(mod, 'vehicles/lizard/aquacultureVessel/aquacultureVesselCustom.xml', g_currentModDirectory .. 'data/aquacultureVesselCustom.xml')
end

---@param mod ModItem
---@param dlcFilepath string
---@param overrideFilename string
function ModController:registerCustomDlcStoreItem(mod, dlcFilepath, overrideFilename)
    local absFilepath = Utils.getFilename(dlcFilepath, mod.modDir)
    ---@cast absFilepath -?

    ModController.XML_FILE_MAPPING[absFilepath] = overrideFilename
    g_storeManager:addModStoreItem(dlcFilepath, mod.modDir, dlcName, false, false, mod.title)
end

function ModController:loadMap()
    self:updateDlcStoreItems()
end

if g_modIsLoaded[dlcName] then
    Logging.info('DLC "%s" is loaded', dlcName)

    source(g_currentModDirectory .. 'scripts/extensions/BoatExtension.lua')
    source(g_currentModDirectory .. 'scripts/extensions/ShallowWaterSimulationExtension.lua')
    source(g_currentModDirectory .. 'scripts/extensions/XMLFileExtension.lua')

    ---@diagnostic disable-next-line: lowercase-global
    g_modController = ModController.new()
    g_modController:addMissingDlcStoreItems()
    g_modController:addCustomDlcStoreItems()

    source(g_currentModDirectory .. 'scripts/BoatDebug.lua')
else
    Logging.info('DLC "%s" is not loaded', dlcName)
end
