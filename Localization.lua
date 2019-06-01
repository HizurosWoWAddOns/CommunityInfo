
local L,addon, ns = {},...;

ns.L = setmetatable(L,{
	__index = function(t,k)
		local v = tostring(k);
		rawset(t,k,v);
		return v;
	end
});

-- Do you want to help localizations? https://wow.curseforge.com/projects/communityinfo/localization

--@do-not-package@
L["AddOnLoaded"] = "AddOn loaded..."; -- CommunityInfo.lua | Options.lua
L["AddOnLoadedDesc"] = "Display 'AddOn loaded...' message on login"; -- Options.lua
L["DescDesc"] = "Display community description in tooltip"; -- Options.lua
L["MinimapButton"] = "Minimap button"; -- Options.lua
L["MinimapButtonDesc"] = "Add community broker to minimap. Good for user without panel addons like titan panel, bazooka and co."; -- Options.lua
L["MotdDesc"] = "Display community message of the day in tooltip"; -- Options.lua
L["NoteDesc"] = "Display member notes on notifigations"; -- Options.lua
L["NotifyJoinedCommunity"] = "has joined the community."; -- CommunityInfo.lua
L["NotifyLeavedCommunity"] = "has leaved the community."; -- CommunityInfo.lua
L["NotifyJoinedLounge"] = "has joined the lounge."; -- CommunityInfo.lua
L["NotifyLeavedLounge"] = "has leaved the lounge."; -- CommunityInfo.lua
L["NotificationTarget"] = "Show notifications in:"; -- Options.lua
L["NotificationTargetDesc"] = "Choose in which chat window the notifications should be displayed."; -- Options.lua
L["SelectedChatWindow"] = "Into same chat window like community chat messages"; -- Options.lua
--@end-do-not-package@

--@localization(locale="enUS", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@

if LOCALE_deDE then
--@localization(locale="deDE", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_esES then
--@localization(locale="esES", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_esMX then
--@localization(locale="esMX", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_frFR then
--@localization(locale="frFR", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_itIT then
--@localization(locale="itIT", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_koKR then
--@localization(locale="koKR", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_ptBR or LOCALE_ptPT then
--@localization(locale="ptBR", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_ruRU then
--@localization(locale="ruRU", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_zhCN then
--@localization(locale="zhCN", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end

if LOCALE_zhTW then
--@localization(locale="zhTW", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@
end
