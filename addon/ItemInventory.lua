---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Anders.
--- DateTime: 15.09.2019 20.41
---
local addonName, addon = ...
_G['ItemInventoryAddon'] = addon

---@type BMUtils
addon.utils = _G.LibStub('BM-utils-2')
--assert(minor >= 6, ('BMUtils 1.6 or higher is required, found 1.%d'):format(minor))

---@type LibInventoryAce
local lib_inventory = _G.LibStub("AceAddon-3.0"):GetAddon('LibInventoryAce')
--Allow development versions
if not lib_inventory.version:len() == 7 then
    local version_check = _G['BMUtils-Version'].version_check(lib_inventory.version, 0, 10)
    assert(version_check, ('LibInventory v0.10 or higher is required, found v%s'):format(lib_inventory.version))
end
---@type LibInventoryLocations
local inventory = lib_inventory:GetModule('LibInventoryLocations')
---@type LibInventoryCharacter
local characters = lib_inventory:GetModule('LibInventoryCharacter')

local is_classic = _G.WOW_PROJECT_ID ~= _G.WOW_PROJECT_MAINLINE

addon.location_color = 'ffffffff'
addon.quantity_color = 'ff00ff00'

function addon:itemCountTooltip(itemID)
    for character, locations in pairs(inventory:getItemLocation(itemID)) do
        if next(locations) ~= nil then
            local sum = 0
            local location_strings = {}
            local name, realm = self.utils.character.splitCharacterString(character)
            for location, quantity in pairs(locations) do
                location = inventory:locationName(location)
                local location_string = self.utils.text.colorize(location .. ': ', self.location_color)
                local quantity_string = self.utils.text.colorize(quantity, self.quantity_color)

                sum = sum + quantity
                table.insert(location_strings, location_string .. quantity_string)
            end

            ---@type CharacterData
            local characterInfo = characters:load(realm, name)
            local right_text = table.concat(location_strings, '||')
            if characterInfo then
                local color = characterInfo:color()
                local icon = ('|A:raceicon-%s-%s:12:12|a'):format(
                        characterInfo.raceFile,
                        characterInfo:genderString()
                )
                _G.GameTooltip:AddDoubleLine(icon .. ' ' .. color:WrapTextInColorCode(characterInfo.name), right_text)
            else
                _G.GameTooltip:AddDoubleLine(name, right_text)
            end
        end
    end
end

local function tooltip_handler(self)
    if addonName ~= "ItemInventory" then
        return
    end
    local _, link = self:GetItem()
    if not link then
        return
    end
    local itemID = addon.utils.itemIdFromLink(link)
    addon:itemCountTooltip(itemID)
end

if is_classic then
    _G.GameTooltip:HookScript("OnTooltipSetItem", tooltip_handler)
else
    _G.TooltipDataProcessor.AddTooltipPostCall(_G.Enum.TooltipDataType.Item, function(self)
        if self == _G.GameTooltip then
            tooltip_handler(self)
        end
    end)
end
