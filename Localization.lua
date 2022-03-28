
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
L["ModKeyA"] = "Alt"
L["MotdDesc"] = "Display community message of the day in tooltip"; -- Options.lua
L["MouseBtn"] = "Click"
L["NoteDesc"] = "Display member notes on notifigations"; -- Options.lua
L["NotifyJoinedCommunity"] = "has joined the community."; -- CommunityInfo.lua
L["NotifyLeavedCommunity"] = "has leaved the community."; -- CommunityInfo.lua
L["NotifyJoinedLounge"] = "has joined the lounge."; -- CommunityInfo.lua
L["NotifyLeavedLounge"] = "has leaved the lounge."; -- CommunityInfo.lua
L["NotificationTarget"] = "Show notifications in:"; -- Options.lua
L["NotificationTargetDesc"] = "Choose in which chat window the notifications should be displayed."; -- Options.lua
L["SelectedChatWindow"] = "Into same chat window like community chat messages"; -- Options.lua
L["NotificationFilter0"] = "Show notifications for all"
L["NotificationFilter1"] = "Show only notifications from ..."
L["NotificationFilter2"] = "Don't show notifications from ..."
--@end-do-not-package@

--@localization(locale="enUS", format="lua_additive_table", handle-subnamespaces="none", handle-unlocalized="ignore")@

if LOCALE_deDE then
--@do-not-package@
	L["AddOnLoaded"] = "AddOn geladen..."
	L["AddOnLoadedDesc"] = "Zeige 'AddOn geladen...' Nachricht beim Login"
	L["DescDesc"] = "Zeige Community Beschreibung im Tooltip"
	L["MinimapButton"] = "Minikarten Button"
	L["MinimapButtonDesc"] = "Erstellt einen Minikarten Button für den Community Broker. Gut für Benutzer ohne Panel AddOns wie Titan Panel, Bazooka und Co."
	L["ModKeyA"] = "Alt"
	L["MotdDesc"] = "Zeigt die Community Nachtricht des Tages im Tooltip"
	L["MouseBtn"] = "Klick"
	L["NoteDesc"] = "Zeigt die Mitgliedernotiz bei Benachrichtigungen"
	L["NotificationTarget"] = "Zeige Benachrichtigungen in:"
	L["NotificationTargetDesc"] = "Wähle, in welchem Chatfenster die Benachrichtigungen angezeigt werden sollen."
	L["NotifyJoinedCommunity"] = "ist der Community beigetreten."
	L["NotifyJoinedLounge"] = "ist der Lounge beigetreten."
	L["NotifyLeavedCommunity"] = "hat die Community verlassen."
	L["NotifyLeavedLounge"] = "hat die Lounge verlassen."
	L["SelectedChatWindow"] = "In das selbe Chatfenster wie die Community Chat Nachrichten"
	L["NotificationFilter0"] = "Zeige Benachrichtigungen für alle"
	L["NotificationFilter1"] = "Zeige nur Benachrichtigungen von ..."
	L["NotificationFilter2"] = "Zeige keine Benachrichtigungen von ..."
--@end-do-not-package@
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
