---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Anders.
--- DateTime: 15.09.2019 20.41
---
local addonName, addon = ...
_G['ItemInventoryAddon'] = addon

local minor
---@type BMUtils
addon.utils, minor = _G.LibStub('BM-utils-1')
assert(minor >= 6, ('BMUtils 1.6 or higher is required, found 1.%d'):format(minor))

---@type LibInventory
addon.inventory = _G.LibStub('LibInventory-0')
addon.characterInfo = _G['CharacterData']

local frame = _G.CreateFrame("Frame"); -- Need a frame to respond to events
-- Event handler

frame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ItemInventory" then
        --@debug
        addon.utils:printf("%s loaded", addonName)
        --@end-debug

        local character = addon.characterInfo:current()
        character:save()
    end
end);
frame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded

addon.location_color = 'ffffffff'
addon.quantity_color = 'ff00ff00'

function addon:itemCountTooltip(itemID)
    for character, locations in pairs(self.inventory.main:getItemLocation(itemID)) do
        if next(locations) ~= nil then
            local sum = 0
            local location_strings = {}
            local name, realm = self.utils:SplitCharacterString(character)
            for location, quantity in pairs(locations) do
                location = self.inventory.main:locationName(location)
                local location_string = self.utils:colorize(location .. ': ', self.location_color)
                local quantity_string = self.utils:colorize(quantity, self.quantity_color)

                sum = sum + quantity
                table.insert(location_strings, location_string .. quantity_string)
            end

            ---@type CharacterData
            local characterInfo = _G['CharacterData']:load(realm, name)
            local right_text = table.concat(location_strings, '||')
            if characterInfo then
                local color = characterInfo:color()
                local icon = self.utils:sprintf('|A:raceicon-%s-%s:12:12|a',
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

_G.GameTooltip:HookScript("OnTooltipSetItem", function(self)
    if addonName ~= "ItemInventory" then
        return
    end
    local _, link = self:GetItem()
    if not link then
        return
    end
    local itemID = addon.utils:ItemIdFromLink(link)
    addon:itemCountTooltip(itemID)
end)
