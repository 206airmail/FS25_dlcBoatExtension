---@param objectName string
---@param superFunc function
---@param filename string
---@param schema? XMLSchema
---@return XMLFile?
local function inj_XMLFile_load(objectName, superFunc, filename, schema)
    local mapToFilename = g_modController.XML_FILE_MAPPING[filename]

    if mapToFilename ~= nil then
        local handle = loadXMLFile(objectName, mapToFilename)

        if handle ~= nil then
            return XMLFile.new(objectName, filename, handle, schema)
        end
    end

    return superFunc(objectName, filename, schema)
end

XMLFile.load = Utils.overwrittenFunction(XMLFile.load, inj_XMLFile_load)

---@param objectName string
---@param superFunc function
---@param filename string
---@param schema? XMLSchema
---@return XMLFile?
local function inj_XMLFile_loadIfExists(objectName, superFunc, filename, schema)
    local mapToFilename = g_modController.XML_FILE_MAPPING[filename]

    if mapToFilename ~= nil then
        local handle = loadXMLFile(objectName, mapToFilename)

        if handle ~= nil then
            return XMLFile.new(objectName, filename, handle, schema)
        end
    end

    if filename == nil or not fileExists(filename) then
        return nil
    end

    return XMLFile.load(objectName, filename, schema)
end

XMLFile.loadIfExists = Utils.overwrittenFunction(XMLFile.loadIfExists, inj_XMLFile_loadIfExists)

local function inj_loadXMLFile(objectName, superFunc, filename)
    local mapToFilename = g_modController.XML_FILE_MAPPING[filename]

    if mapToFilename ~= nil then
        return superFunc(objectName, mapToFilename)
    end

    return superFunc(objectName, filename)
end

local globalEnv = getmetatable(_G).__index

globalEnv.loadXMLFile = Utils.overwrittenFunction(globalEnv.loadXMLFile, inj_loadXMLFile)
