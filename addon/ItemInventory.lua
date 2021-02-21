---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Anders.
--- DateTime: 15.09.2019 20.41
---
local addonName, _ = ...
_G['ItemInventoryAddon'] = {}
local addon = _G['ItemInventoryAddon']

addon.utils = _G['BMUtils']
addon.utils = LibStub("BM-utils-1")

addon.inventory = _G['LibInventory']
addon.inventory = LibStub("LibInventory-0")

addon.itemLocations = _G['ItemLocations']
addon.character_name = addon.utils:GetCharacterString()

addon.Owners = _G['OwnersAddon']
addon.characterInfo = _G['CharacterData']

local mail = _G['LibInventoryMail']

local frame = CreateFrame("Frame"); -- Need a frame to respond to events
-- Event handler
function frame:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == "ItemInventory" then
        --@debug
        addon.utils:printf("%s loaded", addonName)
        --@end-debug

        frame:SetScript('OnEvent', function(self2, event2, ...)
            if _G['ItemInventoryEvents'][event2] == nil then
                error(addon.utils:sprintf('No event handler for %s', event2))
            end
            _G['ItemInventoryEvents'][event2](self2, ...)
        end)
        addon:init_variables()
        addon:scanBags()
        local character = addon.characterInfo:current()
        character:save()

        self:registerEvents()
    end
end

function frame:registerEvents()
    self:RegisterEvent('MAIL_INBOX_UPDATE')
    self:RegisterEvent('BAG_UPDATE')
    self:RegisterEvent('PLAYER_MONEY')
    self:RegisterEvent('GUILD_ROSTER_UPDATE')
    self:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
    self:RegisterEvent('BANKFRAME_OPENED')
    self:RegisterEvent('BANKFRAME_CLOSED')
    self:RegisterEvent('PLAYERBANKSLOTS_CHANGED')

    --if CanUseVoidStorage then
    --    self:RegisterEvent('VOID_STORAGE_OPEN')
    --    self:RegisterEvent('VOID_STORAGE_CLOSE')
    --end

    --if CanGuildBankRepair then
    --    self:RegisterEvent('GUILDBANKFRAME_OPENED')
    --    self:RegisterEvent('GUILDBANKFRAME_CLOSED')
    --    self:RegisterEvent('GUILDBANKBAGSLOTS_CHANGED')
    --end

    if _G['REAGENTBANK_CONTAINER'] ~= nil then
        self:RegisterEvent('PLAYERREAGENTBANKSLOTS_CHANGED')
    end
end
frame:SetScript("OnEvent", frame.OnEvent);
frame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded


---Save item location and quantity
---@param itemID number Item ID
---@param location string Location name
---@param quantity number Item quantity
function addon:saveItemLocation(itemID, location, quantity)
    local character = self.character_name
    if _G['ItemLocations'] == nil then
        _G['ItemLocations'] = {}
    end

    if _G['ItemLocations'][itemID] == nil then
        _G['ItemLocations'][itemID] = {}
    end
    if _G['ItemLocations'][itemID][character] == nil then
        _G['ItemLocations'][itemID][character] = {}
    end

    _G['ItemLocations'][itemID][character][location] = quantity
    --@debug@
    self.utils:printf('%s has %d of %d in %s', character, quantity, itemID, location)
    --@end-debug@
end

function addon:clearItemLocation(location)
    for itemID, characters in pairs(_G['ItemLocations']) do
        for character, locations in pairs(characters) do
            for loc, _ in pairs(locations) do
                if loc == location and character==self.character_name then
                    _G['ItemLocations'][itemID][character][loc] = nil
                end
            end
        end
    end
end

--/dump ItemInventoryAddon:getItemLocations(2321)
function addon:getItemLocations(itemID)
    if not _G['ItemLocations'][itemID] then
        return {}
    end
    return _G['ItemLocations'][itemID]
end

function addon:init_variables()
    if _G['ItemLocations'] == nil then
        _G['ItemLocations'] = {}
    end
end

--Scan bags, bank, mail
--/run ItemInventoryAddon:scanBags()
--[[function addon:scanBags2()
    self.inventory:ScanAllBags()
    local count
    local slotInfo
    local stacks
    for itemID, locations in pairs(self.inventory.locations) do
        count = 0
        stacks = self.inventory:FindItemStacks(itemID)
        for _, stack in pairs(stacks) do
            count = count + stack['itemCount']
        end
        self:saveItemLocation(itemID, "Bags", count)
    end
end]]


function addon:scanContainers(from, to)
    local bagCount = {}
    for bag = from, to do
        --@debug@
        self.utils:printf('Scan container/bag %d', bag)
        --@end-debug@

        self.inventory:ScanBag(bag)

        for _, item in pairs(self.inventory.inventory[bag]) do
            if not bagCount[item['itemID']] then
                bagCount[item['itemID']] = item['itemCount']
            else
                bagCount[item['itemID']] = bagCount[item['itemID']] + item['itemCount']
            end
        end
    end
    return bagCount
end

function addon:saveContainerLocations(from, to, location)
    local items = self:scanContainers(from, to)
    for itemID, quantity in pairs(items) do
        self:saveItemLocation(itemID, location, quantity)
    end
    return items
end

--/dump ItemInventoryAddon:scanBags()
function addon:scanBags()
    self:clearItemLocation('Bags')
    return self:saveContainerLocations(BACKPACK_CONTAINER, NUM_BAG_SLOTS, 'Bags')
end

function addon:scanBank()
    self:clearItemLocation('Bank')
    self:saveContainerLocations(1 + NUM_BAG_SLOTS, NUM_BANKBAGSLOTS + NUM_BAG_SLOTS, 'Bank')
    self:saveContainerLocations(BANK_CONTAINER, BANK_CONTAINER, 'Bank')
    if _G['REAGENTBANK_CONTAINER'] ~= nil then
        self:clearItemLocation('Reagent Bank')
        self:saveContainerLocations(_G['REAGENTBANK_CONTAINER'], _G['REAGENTBANK_CONTAINER'], 'Reagent Bank')
    end
end

function addon:scanMail()
    self:clearItemLocation('Mail')
    local mails = mail:NumMails()
    --@debug@
    self.utils:printf('Scan %d mail(s)', mails)
    --@end-debug@
    local items
    if mails == 0 then
        return
    end
    local mailItemCount = {}
    for mailIndex = 1, mails do
        items = mail:GetMailItems(mailIndex)
        for _, item in ipairs(items) do
            if mailItemCount[item["itemID"]] == nil then
                mailItemCount[item["itemID"]] = item["itemCount"]
            else
                mailItemCount[item["itemID"]] = mailItemCount[item["itemID"]] + item["itemCount"]
            end
        end
    end
    for itemID, itemCount in pairs(mailItemCount) do
        self:saveItemLocation(itemID, 'Mail', itemCount)
    end
end

function addon:itemCountTooltip(itemID)
    local line
    for character, locations in pairs(self:getItemLocations(itemID)) do
        if next(locations) ~= nil then
            local sum = 0
            local location_strings = {}
            local name, realm = self.utils:SplitCharacterString(character)

            for location, quantity in pairs(locations) do
                line = self.utils:sprintf('%s: %d', location, quantity)
                sum = sum + quantity
                table.insert(location_strings, line)
            end

            ---@type CharacterData
            local characterInfo = _G['CharacterData']:load(realm, name)
            local color = characterInfo:color()

            local right_text = table.concat(location_strings, '||')
            local icon = self.utils:sprintf('|A:raceicon-%s-%s:12:12|a',
                    characterInfo.raceFile,
                    characterInfo:genderString()
            )

            GameTooltip:AddDoubleLine(icon .. ' ' .. color:WrapTextInColorCode(characterInfo.name), right_text)
        end
    end
end

GameTooltip:HookScript("OnTooltipSetItem", function(self)
    if not addonName == "ItemInventory" then
        print('Tooltip from wrong addon', addonName)
        return
    end
    local _, link = self:GetItem()
    if not link then
        return
    end
    local itemID = addon.utils:ItemIdFromLink(link)
    addon:itemCountTooltip(itemID)
end)
