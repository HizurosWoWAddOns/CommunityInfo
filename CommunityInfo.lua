
local addon,ns = ...;
local L = ns.L;

local clubs,clubMembersPresence,clubMemberName,isMyID,frame = {},{},{},{},false;
local uniqueToonPresence,uniqueBNetPresence,tryCountMembers,newMembers = {},{},{},{};
local msgPrefix,presenceMsg = "CI",{
	-- from table Enum.ClubMemberPresence
	--[0] = "unknown",
	[1] = ERR_FRIEND_ONLINE_SS:gsub("\124Hplayer:%%s\124h%[%%s%]\124h",""):trim(),
	--[2] = 1,
	[3] = ERR_FRIEND_OFFLINE_S:gsub("%%s",""):trim(),
	[4] = 1,--CHAT_AFK_GET:gsub("%%s",""):gsub(":",""),
	[5] = 1,--CHAT_DND_GET:gsub("%%s",""):gsub(":","")
};
ns.overview = {online=0,num=0}
local failtry = {};

do
	local addon_short = "CI";
	local colors = {"0099ff","00ff00","ff6060","44ffff","ffff00","ff8800","ff44ff","ffffff"};
	local function colorize(...)
		local t,c,a1 = {tostringall(...)},1,...;
		if type(a1)=="boolean" then tremove(t,1); end
		if a1~=false then
			tinsert(t,1,"|cff0099ff"..((a1==true and addon_short) or (a1=="||" and "||") or addon).."|r"..(a1~="||" and ":" or ""));
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

local function sortClubs(a,b)
	return clubs[a].name<clubs[b].name;
end

ns.clubs = setmetatable({},{
	__index = function(t,k)
		if clubs[k] then
			return clubs[k];
		end
	end,
	__call = function(t,a,b)
		local list,i={},0;
		for k in pairs(clubs)do
			tinsert(list,k);
		end
		table.sort(list,sortClubs);
		local function iter()
			i=i+1;
			if list[i] then
				return list[i],clubs[list[i]];
			end
		end
		return iter;
	end
});

function ns.class_color(classID)
	if not classID then return "ffff0000"; end
	local classInfo = C_CreatureInfo.GetClassInfo(classID);
	local color = (_G.CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS or {})[classInfo.classFile:upper()];
	return (color~=nil and color.colorStr~=nil and color.colorStr) or "ffff0000";
end

function ns.numUniqueMembers()
	local oToons,nToons,oBNet,nBNet = 0,0,0,0;
	for guid,presence in pairs(uniqueToonPresence)do
		oToons,nToons = oToons+(presence~=3 and 1 or 0),nToons+1;
	end
	for guid,presence in pairs(uniqueBNetPresence)do
		oBNet,nBNet = oBNet+(presence~=3 and 1 or 0),nBNet+1;
	end
	return oToons,nToons,oBNet,nBNet;
end

function ns.updateOnline(clubId)
	clubs[clubId].online = 0;
	for k,v in pairs(clubMembersPresence)do
		if k:find("^"..clubId.."%-") and v~=3 then
			clubs[clubId].online = clubs[clubId].online+1;
		end
	end
end

function ns.channelColor(clubId)
	local color = {}; color.r,color.g,color.b = Chat_GetCommunitiesChannelColor(clubId,1);
	return color, ("ff%02x%02x%02x"):format(color.r*255,color.g*255,color.b*255);
end

local function update_club_members(clubId)
	local okay = true;
	local members = C_Club.GetClubMembers(clubId);

	if tryCountMembers[clubId]==nil then
		tryCountMembers[clubId] = 0;
	end

	tryCountMembers[clubId]=false;

	if clubs[clubId]==nil then
		clubs[clubId] = {};
	end

	clubs[clubId].online,clubs[clubId].numMembers = 0,#members;
	failed = false;

	for _,memberId in ipairs(members) do
		local info = C_Club.GetMemberInfo(clubId,memberId);
		if info and info.name and info.guid and info.presence>0 then
			local id = clubId.."-"..memberId;
			if info.isSelf then
				isMyID[id] = true;
			end
			clubMemberName[id] = info.name;
			if info.clubType==0 then
				uniqueBNetPresence[info.guid] = info.presence;
			else
				uniqueToonPresence[info.guid] = info.presence;
			end
			clubMembersPresence[id] = info.presence;
		else
			failed = true;
		end
	end

	ns.Broker_Update(clubId,"text");

	if #members<=2 and tryCountMembers[clubId]~=false and tryCountMembers[clubId]<3 then -- unstable api; return 0-1 members on cold login
		C_Timer.After(0.8,function()
			tryCountMembers[clubId] = tryCountMembers[clubId]+1;
			update_club_members(clubId);
		end);
	elseif failed then
		failtry[clubId] = (failtry[clubId] or 0) + 1;
		if failtry[clubId]>3 then
			failtry[clubId] = 0;
			return;
		end
		C_Timer.After(3, function()
			update_club_members(clubId);
		end);
	end
end

local function update_clubs(obj)
	if obj then
		local club
		if tonumber(obj) then
			club = C_Club.GetClubInfo(obj);
		elseif type(obj)=="table" and obj.clubId then
			club = obj;
		end
		if not club then
			return;
		end
		if club.clubType~=2 then -- ignore guilds
			if not clubs[club.clubId] then
				clubs[club.clubId] = club;
				club.iconId = false;
			else
				if clubs[club.clubId].avatarId~=club.avatarId then
					-- avatarId has been changed
					clubs[club.clubId].iconId = false;
				end
				for k,v in pairs(club)do
					clubs[club.clubId][k]=v;
				end
				club = clubs[club.clubId];
			end
			if club.key==nil then
				club.key = "Club-"..club.clubId;
			end
			club.channel = Chat_GetCommunitiesChannelName(club.clubId,1);
			ns.Options_AddCommunity(club.clubId);
			ns.Broker_Register(club.clubId);
			ns.icons.register(club.clubId);
			C_Club.SetClubPresenceSubscription(club.clubId);
			update_club_members(club.clubId);
		end
	else
		ns.Broker_UpdateDirty(true);
		ns.Options_ResetCommunities();
		for _,club in ipairs(C_Club.GetSubscribedClubs()) do
			update_clubs(club);
		end
		ns.Broker_UpdateDirty();
	end
end

local function print_notifikation(event,clubId,memberId,presence)
	if not clubs[clubId] then return end
	local clubMemberId,clubMsgTarget = clubId.."-"..memberId,CommunityInfoDB["Club-"..clubId.."-msgTarget"];
	local member = C_Club.GetMemberInfo(clubId,memberId);

	if tonumber(presenceMsg[presence]) then -- replace presemceId
		presence = presenceMsg[presence];
	end

	if not clubMsgTarget or clubMsgTarget=="0" or notification_locked or isMyID[clubMemberId] or newMembers[clubMemberId] or clubMembersPresence[clubMemberId]==presence or ChannelFrame:IsShown() then
		return;
	end

	clubMembersPresence[clubMemberId] = presence; -- update presence

	local note,name,msg = "",member and member.name;

	local uniquePresence = uniqueToonPresence;
	if clubs[clubId].clubType==0 then
		uniquePresence = uniqueBNetPresence;
	end

	if member and member.guid and uniquePresence[member.guid]~=presence then
		uniquePresence[member.guid] = presence;
		ns.overview.online = ns.overview.online + (isOnlinr and 1 or -1);
	end

	if event=="CLUB_MEMBER_ADDED" then
		newMembers[clubMemberId] = nil;
		clubMembersPresence[clubMemberId] = member.presence;
		clubMemberName[clubMemberId] = member.name;
		msg = L["NotifyJoined"..(clubs[clubId].clubType==0 and "Lounge" or "Community")]; -- has joined the community.
	elseif event=="CLUB_MEMBER_REMOVED" then
		unsetMember = true;
		name = clubMemberName[clubMemberId];
		msg = L["NotifyLeaved"..(clubs[clubId].clubType==0 and "Lounge" or "Community")]; -- has leaved the community.
	elseif event=="CLUB_MEMBER_PRESENCE_UPDATED" and presenceMsg[presence] then
		msg = presenceMsg[presence];
	end

	if msg then
		local name = name or member.name or UNKNOWN;
		local clubName = clubs[clubId].name or UNKNOWN;

		if clubs[clubId].shortName and clubs[clubId].shortName~="" then
			clubName = clubs[clubId].shortName;
		end

		-- player link
		local nameColor = clubs[clubId].clubType==0 and "ff00ffff" or ns.class_color(member.classID);
		if name~=UNKNOWN and presence~=3 then
			name = "|Hplayer:"..member.name.."|h|c"..nameColor.."["..name.."]|r|h"; -- online, added, removed
		else
			name = "|c"..nameColor..name.."|r";
		end

		-- player note
		if CommunityInfoDB["Club-"..clubId.."-notes"] and member and member.memberNote and member.memberNote~="" then
			note = " |cffaaaaaa["..member.memberNote:trim().."]|r";
		end

		-- final message
		msg = "|cff0099ffCI|r: "..name.." "..msg.." ("..clubName..")"..note;

		-- channel color
		local color = {}; color.r,color.g,color.b = Chat_GetCommunitiesChannelColor(clubId,1);

		-- target channel
		if clubMsgTarget=="1" then
			DEFAULT_CHAT_FRAME:AddMessage(msg,color.r,color.g,color.b);
		elseif clubMsgTarget=="2" and chat then
			for i=1, FCF_GetNumActiveChatFrames() do
				local chatFrame,add = _G['ChatFrame'..i],false;
				if chatFrame~=COMBATLOG then
					for c=1, #chatFrame.channelList do
						if chatFrame.channelList[c]==chat then
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

	C_Timer.After(0.1,function()
		ns.Broker_Update(clubId,"text");
	end);

	if unsetMember then
		clubMembersPresence[clubMemberId] = nil;
		clubMemberName[clubMemberId] = nil;
	end
end

local function notification_unlock()
	notification_locked = false;
	update_clubs();
end

local function notification_lock()
	-- blizzard firing wild CLUB_MEMBER_PRESENCE_UPDATED on open community frame.
	-- this includes incorrect presence states for user there are using 'offline' status in battle net client.
	-- for blizzard lounge and communities...
	notification_locked = true;
	C_Timer.After(2, notification_unlock);
end


 --                             --
-- New member data request queue --
 --                             --
local newMember = {queue={}};
-- addon must wait to get memberInfo for new members...

function newMember.tickerFunc()
	if #newMember.queue>0 then
		local event, clubId, memberId, presence = unpack(newMember.queue[1]);
		local memberInfo = C_Club.GetMemberInfo(clubId, memberId);
		if memberInfo and memberInfo.name then
			tremove(newMember.queue,1);
			print_notifikation(event, clubId, memberId, presence);
		end
	elseif newMember.ticker then
		newMember.ticker:Cancel();
		newMember.ticker = nil;
	end
end

function newMember.add(...)
	tinsert(newMember.queue,{...});
	if not newMember.ticker then
		newMember.ticker = C_Timer.NewTicker(0.1,newMember.tickerFunc);
	end
end


 --                  --
-- AvatarId to IconId --
 --                  --
ns.icons = {queue={},ids={}};

function ns.icons.tickerFunc()
	if #ns.icons.queue>0 then
		local clubId = ns.icons.queue[1];
		if ns.icons.ids[clubs[clubId].avatarId..";"..clubs[clubId].clubType] then
			local id = ns.icons.ids[clubs[clubId].avatarId..";"..clubs[clubId].clubType];
			clubs[clubId].iconId = id;
			ns.Broker_Update(clubId,"icon");
			tremove(ns.icons.queue,1);
		else
			C_Club.SetAvatarTexture(frame.icon, clubs[clubId].avatarId, clubs[clubId].clubType);
			local id = frame.icon:GetTexture();
			if id then
				ns.icons.ids[clubs[clubId].avatarId..";"..clubs[clubId].clubType] = id;
				clubs[clubId].iconId = id;
				ns.Broker_Update(clubId,"icon");
				tremove(ns.icons.queue,1);
			end
		end
	elseif ns.icons.ticker then
		ns.icons.ticker:Cancel();
		ns.icons.ticker = nil;
	end
end

function ns.icons.register(clubId)
	tinsert(ns.icons.queue,clubId);
	if not ns.icons.ticker then
		ns.icons.ticker = C_Timer.NewTicker(0.1,ns.icons.tickerFunc);
	end
end


 --          --
-- EventFrame --
 --          --
frame = CreateFrame("frame");

frame:SetScript("OnEvent",function(self,event,...)
	if event=="ADDON_LOADED" then
		local addonName = ...;
		if addonName==addon then
			frame.icon = frame:CreateTexture(nil,"ARTWORK");
			ns.Options_Register();
			if CommunityInfoDB.addonloaded then
				ns.print(L["AddOnLoaded"]);
			end
		elseif addonName=="Blizzard_Communities" then
			CommunitiesFrame:HookScript("OnShow",notification_lock);
			CommunitiesFrame:HookScript("OnHide",function()
				for _,club in ipairs(C_Club.GetSubscribedClubs()) do
					C_Club.SetClubPresenceSubscription(club.clubId); -- reSubscribe OnHide after C_Club.ClearClubPresenceSubscription and C_Club.Flush
				end
			end);
		end
		return;
	elseif event=="PLAYER_LOGIN" then
		frame.PL = true;
		C_Timer.After(10,function()
			if frame.PL then
				update_clubs();
				frame.PL = nil;
			end
		end);
	elseif event=="CLUB_ADDED" or event=="CLUB_REMOVED" then
		local clubId = ...;
		update_clubs(clubId);
		if frame.PL then
			frame.PL = nil;
		end
	elseif event=="CLUB_MEMBER_ADDED" then
		local clubId, memberId = ...;
		newMembers[clubId.."-"..memberId] = true;
		newMember.add(event,clubId,memberId,1);
	elseif event=="CLUB_MEMBER_REMOVED" or event=="CLUB_MEMBER_PRESENCE_UPDATED" then
		local clubId, memberId, presence = ...;
		print_notifikation(event,clubId,memberId,presence or 1);
	end
end);

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_LOGIN");
frame:RegisterEvent("CLUB_ADDED");
frame:RegisterEvent("CLUB_REMOVED");
frame:RegisterEvent("CLUB_MEMBER_ADDED");
frame:RegisterEvent("CLUB_MEMBER_REMOVED");
frame:RegisterEvent("CLUB_MEMBER_PRESENCE_UPDATED");
--frame:RegisterEvent("CHAT_MSG_ADDON");

--#known problems
--#- member join bnet lounge. no notification
--#- member goes offline. no or wrong notification
--#
--#TODO
--#- member status detection by C_ChatInfo.SendAddonMessage(addon, "1", "CHANNEL", club.channel) for invisible members?
--#- alert frames for motd
--#- add option for copy invite code from invite link (right click?)
--#- tooltip lines click functions (invite & wispher)
--#- join and leave message not enough tested yet -.-
--#- detect community changes: chat color, name, description, motd
