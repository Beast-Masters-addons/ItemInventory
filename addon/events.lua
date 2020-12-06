_G['ItemInventoryEvents'] = {}
local events = _G['ItemInventoryEvents']
local addon = _G['ItemInventoryAddon']

function events:ADDON_LOADED()
    --DEFAULT_CHAT_FRAME:AddMessage(string.format('Event loaded %s', arg))
end

---This event is fired when the inbox changes in any way.
---https://wow.gamepedia.com/MAIL_INBOX_UPDATE
function events:MAIL_INBOX_UPDATE()
    --@debug@
    addon.utils:printf('Mail inbox updated')
    --@end-debug@
    addon:scanMail()
end

---Fired when a bags inventory changes.
---https://wow.gamepedia.com/BAG_UPDATE
function events:BAG_UPDATE(bag)
    --@debug@
    addon.utils:printf('Bag %d updated', bag)
    --@end-debug@

    addon:scanBags()
end

---Fired when the client's guild info cache has been updated after a call to GuildRoster
---or after any data change in any of the guild's data, excluding the Guild Information window.
---https://wow.gamepedia.com/GUILD_ROSTER_UPDATE
function events:GUILD_ROSTER_UPDATE()
    if addon.utils:IsWoWClassic() then
        return
    end
end

function events:BANKFRAME_OPENED()
    self.atBank = true
end

function events:BANKFRAME_CLOSED()
    if self.atBank then
        addon:scanBank()
        self.atBank = false
    end
end

function events:PLAYERBANKSLOTS_CHANGED(slot)
    --@debug@
    addon.utils:sprintf('Bank slot %d changed', slot)
    --@end-debug@
    addon:scanBank()
end

function events:PLAYER_EQUIPMENT_CHANGED()
    --addon:scanEquipment()
end

function events:PLAYER_MONEY()

end