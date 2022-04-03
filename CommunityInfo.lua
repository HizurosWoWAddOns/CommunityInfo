
local addon, ns = ...;
local L = ns.L;

local icons,members,clubs,notificationLock,frame
local clubChkChangedKeys,isMyID = {},{};
local clubInitCustomVars = {
	iconId = false,
	numOnline = 0,
	numMembers = 0,
}
local onlineMsg = ERR_FRIEND_ONLINE_SS:gsub("\124Hplayer:%%s\124h%[%%s%]\124h",""):trim();
local msgPrefix,presenceMsg = addon,{
	-- from table Enum.ClubMemberPresence
	--[0] = "unknown",
	[1] = onlineMsg,
	[2] = onlineMsg.." (mobile)",
	[3] = ERR_FRIEND_OFFLINE_S:gsub("%%s",""):trim(),
	[4] = onlineMsg.." (AFK)",--CHAT_AFK_GET:gsub("%%s",""):gsub(HEADER_COLON,""):trim(),
	[5] = onlineMsg.." (DND)",--CHAT_DND_GET:gsub("%%s",""):gsub(HEADER_COLON,""):trim()
};
local validClubTypes = {
	--[0] = true, -- bnet lounge
	[1] = true, -- wow community
}

do
	local addon_short = "CI";
	local colors = {"82c5ff","00ff00","ff6060","44ffff","ffff00","ff8800","ff44ff","ffffff"};
	local function colorize(...)
		local t,c,a1 = {tostringall(...)},1,...;
		if type(a1)=="boolean" then tremove(t,1); end
		if a1~=false then
			tinsert(t,1,"|cff82c5ff"..((a1==true and addon_short) or (a1=="||" and "||") or addon).."|r"..(a1~="||" and HEADER_COLON or ""));
			c=2;
		end
		for i=c, #t do
			if not t[i]:find("\124c") then
				t[i],c = "|cff"..colors[c]..t[i].."|r", c<#colors and c+1 or 1;
			end
		end
		return unpack(t);
	end
	function ns.print(...)
		print(colorize(...));
	end
	function ns.debug(...)
		ConsolePrint(date("|cff999999%X|r"),colorize(...));
		--ns.print("|cff999999<debug>|r",colorize(...));
	end
end

function ns.intIncrease(t,k,v)
	t[k] = (t[k] or 0) + (v or 1);
end

function ns.intDecrease(t,k,v)
	t[k] = (t[k] or 0) - (v or 1);
end

do
	local function sortClubs(a,b)
		return ns.clubs[a].name<ns.clubs[b].name;
	end

	ns.clubs = setmetatable({},{
		__call = function(t,a,b)
			if a=="updateCounter" and tonumber(b) then
				t[b].numMembers = 0;
				t[b].numOnline = 0;
				for k,v in pairs(t[b].members)do
					ns.intIncrease(t[b],"numMembers");
					if v.presence~=3 then
						ns.intIncrease(t[b],"numOnline");
					end
				end
			else
				local list,i={},0;
				for k in pairs(t)do
					tinsert(list,k);
				end
				table.sort(list,sortClubs);
				local function iter()
					i=i+1;
					if list[i] then
						return list[i],t[list[i]];
					end
				end
				return iter;
			end
		end
	});
end

function ns.class_color(classID)
	if not classID then return "ffff0000"; end
	local classInfo = C_CreatureInfo.GetClassInfo(classID);
	local color = (_G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS or {})[classInfo.classFile:upper()];
	return (color~=nil and color.colorStr~=nil and color.colorStr) or "ffff0000";
end

function ns.channelColor(clubId)
	local color = {}; color.r,color.g,color.b = Chat_GetCommunitiesChannelColor(clubId,1);
	return color, ("ff%02x%02x%02x"):format(color.r*255,color.g*255,color.b*255);
end

local function AddChatMsg(club,member,msg)
	-- player color
	local nameColor = "|c"..(club.clubType==0 and "ff00ffff" or ns.class_color(member.classID));

	-- player name/link
	local name = nameColor..(member.name or UNKNOWN).."|r";
	if member.presence~=3 then
		name = "|Hplayer:"..member.name.."|h"..nameColor.."["..(member.name or UNKNOWN).."]|r|h"; -- online, added, removed
	end

	-- mobile icon
	if member.presence==2 then
		name = "|T457650:0|t "..name;
	end

	-- player note
	local note=""
	if CommunityInfoDB["Club-"..club.clubId]["notes"] and member and member.memberNote and member.memberNote~="" then
		note = " |cffaaaaaa["..member.memberNote:trim().."]|r";
	end

	-- channel color
	local color = ns.channelColor(club.clubId);

	-- club name
	local clubName = club.name or UNKNOWN;
	if club.shortName and club.shortName~="" then
		clubName = club.shortName;
	end

	-- final message
	local msg = "|cff0099ffCI|r: "..name.." "..msg.." ("..clubName..")"..note;

	-- target channel
	local clubMsgTarget = CommunityInfoDB["Club-"..club.clubId]["msgTarget"];
	local clubMsgTargetChannel = CommunityInfoDB["Club-"..club.clubId]["msgTargetChannel"] or false;
	if clubMsgTarget=="1" then
		-- default chat frame
		DEFAULT_CHAT_FRAME:AddMessage(msg,color.r,color.g,color.b);
	elseif clubMsgTarget=="2" and clubMsgTargetChannel then
		for i=1, FCF_GetNumActiveChatFrames() do
			local chatFrame,add = _G['ChatFrame'..i],false;
			if chatFrame~=COMBATLOG then
				for c=1, #chatFrame.channelList do
					if chatFrame.channelList[c]==clubMsgTargetChannel then
						add = true;
						break;
					end
				end
				if add then
					chatFrame:AddMessage(msg,color.r,color.g,color.b);
				end
			end
		end
	end
end

icons = {
	update=function()
		local failed = false;
		for key,club in pairs(ns.clubs)do
			if tonumber(key) and club.avatarId and club.iconId==false then
				C_Club.SetAvatarTexture(frame.icon, club.avatarId, club.clubType);
				local iconId = frame.icon:GetTexture();
				if iconId then
					club.iconId = iconId;
					ns.Broker_Update(club.clubId,"icon");
				else
					failed = true;
				end
			end
		end
		if failed then
			C_Timer.After(0.314159,function() icons.update() end);
		end
	end,
};

members = {
	fails = {},
	queue = {},
	presenceByBNetGuid={},
	presenceByToonGuid={},

	update = function(clubId)
		if not (type(clubId)=="number" and ns.clubs[clubId]) then return end
		local club = ns.clubs[clubId];

		local failed = false;
		local memberIds = C_Club.GetClubMembers(club.clubId);

		if members.fails[club.clubId]==nil then
			members.fails[club.clubId] = 0;
		end

		if ns.clubs[club.clubId]==nil then
			ns.clubs[club.clubId] = club;
		end

		ns.clubs[club.clubId].numOnline = 0;
		ns.clubs[club.clubId].numMembers = #members;

--@do-not-package@
		if club.members==nil then
		--	club.members={};
			ns.print("<MembersUpdate>","<ERROR>",club.clubId);
		end
--@end-do-not-package@

		--[[
		Enum.ClubMemberPresence
			0 	Unknown
			1 	Online
			2 	OnlineMobile
			3 	Offline
			4 	Away
			5 	Busy
		]]

		for _,memberId in ipairs(memberIds) do
			local memberInfo = C_Club.GetMemberInfo(club.clubId,memberId);
			if type(memberInfo)=="table" and memberInfo.name and memberInfo.guid then
				if memberInfo.isSelf then
					isMyID[club.clubId.."-"..memberId] = true;
				end
				club.members[memberId] = memberInfo;
				if memberInfo.presence>0 and memberInfo.presence~=3 then
					ns.intIncrease(ns.clubs[club.clubId],"numOnline");
				end
			else
				failed = true;
			end
		end

		ns.Broker_Update(clubId,"text");

		local maxTryouts,timeout = 0,0;
		if #memberIds<=2 then -- slow network connects; return 0-1 members on login
			maxTryouts,timeout = 6,0.8;
		elseif failed then
			maxTryouts,timeout = 3,3;
		end

		if maxTryouts>0 then
			ns.intIncrease(members.fails,club.clubId);
			if members.fails[club.clubId]>maxTryouts then
				members.fails[club.clubId] = nil;
				return; -- stop try to update member list
			end
			C_Timer.After(timeout,function()
				members.update(club.clubId);
			end);
		elseif members.fails[club.clubId]~=nil then
			members.fails[club.clubId] = nil;
		end
	end,

	updatePresence=function(clubId,memberId)
		local club = ns.clubs[clubId];
		local memberInfo,msg = C_Club.GetMemberInfo(clubId,memberId);

		if memberInfo then
			if club.members[memberId]==nil then
				club.members[memberId] = {presence=0};
			end
			if club.members[memberId].presence~=memberInfo.presence then
				msg = presenceMsg[memberInfo.presence];
				club.members[memberId].presence = memberInfo.presence;
				ns.Broker_Update(clubId,"text");
			end
		end

		members.queue[clubId.."-"..memberId]=nil;

		if msg and not ((CommunityInfoDB["Club-"..clubId].enableInOrExclude==1 and CommunityInfoDB["Club-"..clubId][memberInfo.guid]) -- include
			or (CommunityInfoDB["Club-"..clubId].enableInOrExclude==2 and not CommunityInfoDB["Club-"..clubId][memberInfo.guid])) -- exclude
		then
			-- final message
			AddChatMsg(club,memberInfo,msg);
		end
	end,

	add = function(clubId,memberId)
		if not ns.clubs[clubId] then return end
		local club = ns.clubs[clubId];
		local memberInfo = C_Club.GetMemberInfo(clubId,memberId);
		if memberInfo then
			club.members[memberId] = memberInfo;
			ns.intIncrease(club,"numMembers");
			AddChatMsg(club,memberInfo,L["NotifyJoined"..(club.clubType==0 and "Lounge" or "Community")]);
			ns.Broker_Update(clubId,"text");
		end
	end,

	remove = function(clubId,memberId)
		if not ns.clubs[clubId] then return end
		local club = ns.clubs[clubId];
		local memberInfo = club.members[memberId];
		if memberInfo then
			AddChatMsg(club,memberInfo,L["NotifyLeaved"..club.clubType==0 and "Lounge" or "Community"]);
			club.members[memberId] = nil;
			ns.intDecrease(club,"numMembers");
			ns.Broker_Update(clubId,"text");
		end
	end
};

clubs = {
	update = function(club)
		if tonumber(club) then
			club = C_Club.GetClubInfo(club);
		end

		--[[
			0 BattleNet Lounge (BattleNet account based)
			1 WoW Community (Character based)
			2 Guild
			3 Other?
		--]]

		if not (type(club)=="table" and club.clubId and (club.clubType==1 --[[ or club.clubType==0 ]])) then
			return false;
		end

		if not ns.clubs[club.clubId] then
			ns.clubs[club.clubId] = club;
			Mixin(club,clubInitCustomVars);
			club.members = {};
			club.key = "Club-"..club.clubId;
			club.channel = Chat_GetCommunitiesChannelName(club.clubId,1);
			ns.Options_AddCommunity(club.clubId);
			ns.Broker_Register(club.clubId);
			C_Club.SetClubPresenceSubscription(club.clubId);
		else
			if ns.clubs[club.clubId].avatarId~=club.avatarId then
				-- avatarId has been changed
				ns.clubs[club.clubId].iconId = false;
			end
			for k,v in pairs(club)do
				if clubChkChangedKeys[k] and ns.clubs[club.clubId][k]~=v then
					ns.clubs[club.clubId].hasChanged = true; -- for later use in option panel?
				end
				ns.clubs[club.clubId][k] = v;
			end
		end

		return true;
	end,

	updateBroker = function()
		ns.Broker_UpdateDirty(true);
		for _,club in ipairs(C_Club.GetSubscribedClubs()) do
			if clubs.update(club) then
				members.update(club.clubId);
			end
		end
		ns.Broker_UpdateDirty();
	end,

	remove = function(clubId)
		-- hide minimap icon
		-- replace icon, text and tooltip (for panels)
		-- look for unregistration

		--ns.clubs[clubId] = nil;
	end,
}

--== notificationLock ==--

notificationLock = {
	state = false,
	unset = function()
		notificationLock.state = false;
		clubs.update();
	end,
	set = function()
		-- blizzard firing wild CLUB_MEMBER_PRESENCE_UPDATED on open community frame.
		-- this includes incorrect presence states for user there are using 'offline' status in battle net client.
		-- for blizzard lounge and communities...
		notificationLock.state = true;
		C_Timer.After(2, notificationLock.unset);
	end
};

--== EventFrame ==--

frame = CreateFrame("Frame");
local events

frame:SetScript("OnEvent",function(self,event,...)
	if events[event] then
		--ns.print("<Testing>","<event>",event,...);
		events[event](...)
	end
end);

events = {
	VARIABLES_LOADED=function(...)
		frame.icon = frame:CreateTexture(); -- for avatarId to iconId
		ns.Options_Register();
--@do-not-package@
		if not C_ChatInfo.RegisterAddonMessagePrefix(msgPrefix) then
			ns.debug("<RegisterAddonMessagePrefix>","failed");
		end
		--ns.RegisterCommunityMotDAlertSystem();
--@end-do-not-package@
		if CommunityInfoDB.addonloaded or IsShiftKeyDown() then
			ns.print(L["AddOnLoaded"]);
		end
	end,

	ADDON_LOADED=function(addonName)
		if addonName=="Blizzard_Communities" then
			CommunitiesFrame:HookScript("OnShow",function() notificationLock.set(); end);
			CommunitiesFrame:HookScript("OnHide",function()
				for clubId in pairs(ns.clubs) do
					-- reSubscribe; CommunitiesFrame using C_Club.ClearClubPresenceSubscription and C_Club.Flush on hide
					C_Club.SetClubPresenceSubscription(clubId);
				end
			end);
			frame:UnregisterEvent("ADDON_LOADED");
		end
	end,

	PLAYER_LOGIN=function(...)
		C_Timer.After(12, function()
			clubs.updateBroker();
			icons.update();
			frame.PL=true;
		end);
	end,

	CLUB_ADDED=function(clubId)
		clubs.update(C_Club.GetClubInfo(clubId));
		icons.update();
	end,

	CLUB_REMOVED=function(clubId)
		clubs.remove(clubId);
	end,

	CLUB_MEMBER_PRESENCE_UPDATED=function(clubId, memberId, presence)
		if not ns.clubs[clubId] then return end
		if not members.queue[clubId.."-"..memberId] then
			members.queue[clubId.."-"..memberId] = true;
			C_Timer.After(3.14159265359*0.5,function() members.updatePresence(clubId,memberId); end);
		end
	end,

	CLUB_MEMBER_ADDED=function(clubId,memberId)
		members.add(clubId,memberId);
	end,

	CLUB_MEMBER_REMOVED=function(clubId,memberId)
		members.remove(clubId,memberId);
	end,

	--[[
	CHANNEL_UI_UPDATE=function(...)
	end,

	CHAT_MSG_ADDON=function(...)
		if msgPrefix==... then
			ns.debug("<ChatMsgAddOn>",...);
		end
	end,
	]]

};

for event in pairs(events)do
	frame:RegisterEvent(event);
end


--== Slash command ==--

SlashCmdList.COMMUNITYINFO = function(cmd)
	ns.Options_Toggle()
end

SLASH_COMMUNITYINFO1 = "/ci"
SLASH_COMMUNITYINFO2 = "/communityinfo"
