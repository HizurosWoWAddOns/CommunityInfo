
local addon,ns = ...;
local L = ns.L;

local LDB = LibStub("LibDataBroker-1.1");
local LDBI = LibStub("LibDBIcon-1.0");
local LQT = LibStub("LibQTip-1.0");

local C = WrapTextInColorCode;
local CYellow,CYellowLight,CGreen,CBNet,CBlue,CGray,CCopper = "ffffcc00","fffff569","ff00ff00","ff82c5ff","ff00aaff","ffaaaaaa","fff0a55f";
local broker,patternMembers,broker_OnLeave = {},"|C%s%s|C%s/%s|r";

local COMMUNITY_MEMBER_ROLE_NAMES = {
	[Enum.ClubRoleIdentifier.Owner] = COMMUNITY_MEMBER_ROLE_NAME_OWNER,
	[Enum.ClubRoleIdentifier.Leader] = COMMUNITY_MEMBER_ROLE_NAME_LEADER,
	[Enum.ClubRoleIdentifier.Moderator] = COMMUNITY_MEMBER_ROLE_NAME_MODERATOR,
	[Enum.ClubRoleIdentifier.Member] = COMMUNITY_MEMBER_ROLE_NAME_MEMBER,
};

local function MouseIsOver(region, topOffset, bottomOffset, leftOffset, rightOffset)
	if region and region.IsMouseOver then -- blizzard's own version does not check if region exists...
		return region:IsMouseOver(topOffset, bottomOffset, leftOffset, rightOffset);
	end
end

local function GetTooltip(parent,clubId)
	local club,ttColumns,ttAlign = ns.clubs[clubId],1,{"LEFT"}

	if club.clubType==0 then -- Blizzard Lounge
		ttColumns, ttAlign = 3, {"LEFT", "LEFT", "LEFT"};
	elseif club.clubType==1 then -- WoW Community
		ttColumns, ttAlign = 6, {"RIGHT", "LEFT", "LEFT", "LEFT","LEFT","LEFT"};
	end

	local tooltip = LQT:Acquire(club.key,  ttColumns, unpack(ttAlign));

	tooltip:SmartAnchorTo(parent);

	-- skinning supports
	if _G.TipTac and _G.TipTac.AddModifiedTip then
		_G.TipTac:AddModifiedTip(tooltip, true); -- Tiptac Support for LibQTip Tooltips
	elseif AddOnSkins and AddOnSkins.SkinTooltip then
		AddOnSkins:SkinTooltip(tooltip); -- AddOnSkins support
	end

	if club.clubType==1 then
		tooltip:SetScript("OnLeave",function()
			broker_OnLeave(parent,clubId);
		end);
	end

	club.tooltip = tooltip;

	return tooltip;
end

local function strCut(str,limit)
	if not str then return ""; end
	if str:len()>limit-3 then str = strsub(str,1,limit-3).."..." end
	return str;
end

local function strWrap(text, limit, insetCount, insetChr, insetLastChr)
	if not text then
		return "";
	elseif text:len()<=limit then
		return text;
	end
	if text:match("\n") or text:match("%|n") then
		local txt = text:gsub("%|n","\n");
		local strings,tmp = {strsplit("\n",txt)},{};
		for i=1, #strings do
			tinsert(tmp,strWrap(strings[i], limit, insetCount, insetChr, insetLastChr));
		end
		return table.concat(tmp,"\n");
	end
	local tmp,result,inset = "",{},"";
	if type(insetCount)=="number" then
		inset = (insetChr or " "):rep(insetCount-(insetLastChr or ""):len())..(insetLastChr or "");
	end
	for str in text:gmatch("([^ \n]+)") do
		local tmp2 = (tmp.." "..str):trim();
		if tmp2:len()>=limit then
			tinsert(result,tmp);
			tmp = str:trim();
		else
			tmp = tmp2;
		end
	end
	if tmp~="" then
		tinsert(result,tmp);
	end
	return table.concat(result,"\n"..inset)
end

local function scm(str,all,str2) -- screen capture mode
	if str==nil then return "" end
	str2,str = (str2 or "*"),tostring(str);
	local length = str:len();
	if length>0 and CommunityInfoDB.screencapturemode==true then
		local res = {strsplit("\n",str)};
		for i,v in ipairs(res)do
			v = {strsplit(" ",v)};
			for I,V in ipairs(v)do
				v[I] = str2:rep(V:len());
			end
			res[i] = table.concat(v," ");
		end
		res = table.concat(res,"\n");

		if all~=true then
			local s = strsub(str,1,1);
			if s=="\195" then
				s = strsub(str,1,2); -- utf8 special characters
			end
			res = s .. strsub(res,2,res:len());
		end

		--str = all and str2:rep(length) or strsub(str,1,1)..str2:rep(length-1);
		str = res;
	end
	return str;
end

local function memberInviteOrWhisperToon(self,info,button)
	local invite,tell,link,text;
	if IsAltKeyDown() then
		C_PartyInfo.InviteUnit(info.name);
	else
		SetItemRef("player:"..info.name, ("|Hplayer:%1$s|h[%1$s]|h"):format(info.name), "LeftButton");
	end
end

local pairsByField
do
	local function sortField(a,b)
		if a[2] and b[2] then
			return a[2]<b[2];
		end
		return false;
	end

	function pairsByField(t,field)
		local list,i={},0;
		for k,v in pairs(t)do
			tinsert(list,{k,v[field]});
		end
		table.sort(list,sortField);
		local function iter()
			i=i+1;
			if list[i] then
				return list[i][1],t[list[i][1]];
			end
		end
		return iter;
	end
end

local function broker_OnEnterClub(self,clubId)
	local tt = GetTooltip(self,clubId);
	if tt.lines~=nil then tt:Clear(); end

	local club = ns.clubs[clubId];
	local _,clubColor = ns.channelColor(clubId);
	clubColor = clubColor or "ff888888";

	local clubIcon = "";
	if club.iconId then
		clubIcon = "|T"..club.iconId..":0|t ";
	end

	tt:SetCell(tt:AddLine(),1,clubIcon..C(club.name or "?",clubColor),tt:GetHeaderFont(),"LEFT",0);
	tt:SetCell(tt:AddLine(),1,C(club.clubType==0 and COMMUNITIES_INVITATION_FRAME_TYPE or COMMUNITIES_INVITATION_FRAME_TYPE_CHARACTER,clubColor),"GameFontNormalSmall","LEFT",0);
	tt:AddSeparator(4,0,0,0,0);

	if CommunityInfoDB["Club-"..clubId]["motd"] and club.broadcast and club.broadcast:trim()~="" then
		tt:SetCell(tt:AddLine(), 1, C(GUILD_MOTD_LABEL,CBlue),nil,"LEFT",0);
		tt:AddSeparator();
		tt:SetCell(tt:AddLine(), 1, C(scm(strWrap(club.broadcast,80)),CYellow), nil, "LEFT", 0);
		tt:AddSeparator(4,0,0,0,0);
	end

	if CommunityInfoDB["Club-"..clubId]["desc"] and club.description and club.description:trim()~="" then
		tt:SetCell(tt:AddLine(), 1, C(DESCRIPTION,CBlue),nil,"LEFT",0);
		tt:AddSeparator();
		tt:SetCell(tt:AddLine(), 1, C(scm(strWrap(club.description,80)),CYellow), nil, "LEFT", 0);
		tt:AddSeparator(4,0,0,0,0);
	end

	if club.clubType==0 then
		tt:AddLine(
			C(NAME,CYellowLight),
			C(LABEL_NOTE,CYellowLight),
			C(RANK,CYellowLight)
		);
	elseif club.clubType==1 then
		tt:AddLine(
			C(LEVEL,CYellowLight),
			C(NAME,CYellowLight),
			C(RACE,CYellowLight),
			C(ZONE,CYellowLight),
			C(LABEL_NOTE,CYellowLight),
			C(RANK,CYellowLight)
		);
	end
	tt:AddSeparator();
	for memberId, memberInfo in pairsByField(club.members,"name")do -- TODO: replace "name" by variable
		if memberInfo.presence==3 then
			-- ignore offline
		elseif club.clubType==0 then
			tt:AddLine(
				C(scm(memberInfo.name or UNKNOWN),clubColor),
				C(scm(strCut(memberInfo.memberNote,18)),CGray),
				memberInfo.role and COMMUNITY_MEMBER_ROLE_NAMES[memberInfo.role] or ""
			);
		elseif club.clubType==1 then
			local name,realm = strsplit("-",memberInfo.name,2);
			realm = realm and C(" - "..realm,CYellow) or "";

			local raceInfo = C_CreatureInfo.GetRaceInfo(memberInfo.race);
			local info = C_Club.GetMemberInfo(clubId,memberId);
			-- Note: info vs memberInfo. presence variable can change without event from 1(on) to 3(off) because
			-- BattleNet option "As Offline" has effect on both. BNet Lounge and WoW Community.
			-- memberInfo come from event and hold presence=1 and info used for current zone.

			if memberInfo.presence==2 and info.presence==1 then
				memberInfo.presence=1
			end

			-- mobile icon
			local icon = "";
			if memberInfo.presence==2 then
				icon = "|T457650:0|t ";
			end

			local hidden = "";
			--[[
			if info.presence==0 or info.presence==3 then
				hidden = " (hidden)"; --L["PlayerMarkedAsOffline"];
			end
			--]]

			local l = tt:AddLine(
				memberInfo.level,
				icon .. C(scm(name or UNKNOWN),ns.class_color(memberInfo.classID)) .. realm,
				C(raceInfo and raceInfo.raceName or "",CGray),
				(info.zone or "")..hidden,
				C(scm(strCut(memberInfo.memberNote,18)),CGray),
				memberInfo.role and COMMUNITY_MEMBER_ROLE_NAMES[memberInfo.role] or ""
			);
			if memberInfo.isSelf then
				tt:SetLineColor(l, .5, .5, .5);
			elseif club.clubType==1 then -- Currently ivite and whisper are not possible for battlenet-lounge members
				tt:SetLineScript(l,"OnMouseUp",memberInviteOrWhisperToon,memberInfo);
			end
		end
	end

	if club.clubType==1 then
		tt:AddSeparator(4,0,0,0,0);
		tt:SetCell(tt:AddLine(),1,L["TooltipActionOnMember"] ..HEADER_COLON.." ".. C(L["MouseBtn"],CBlue).." || "..C(WHISPER,CGreen)   .." - ".. C(L["ModKeyA"].."+"..L["MouseBtn"],CBlue).." || "..C(TRAVEL_PASS_INVITE,CGreen),nil,"LEFT",0);
		tt:SetCell(tt:AddLine(),1,L["TooltipActionOnBroker"] ..HEADER_COLON.." ".. C(L["MouseBtn"],CCopper).." || "..C(L["OpenCommunity"],CGreen) .." - ".. C(L["ModKeyA"].."+"..L["MouseBtn"],CCopper).." || "..C(OPTIONS,CGreen),nil,"LEFT",0);
	end

	tt:Show();
end

local function broker_OnClickClub(self,button,clubId)
	local club = ns.clubs[clubId];
	if button=="LeftButton" then
		-- open community window
		local frame = CommunitiesFrame;
		if frame and frame:IsShown() and frame.selectedClubId==clubId then
			HideUIPanel(frame);
		elseif CommunitiesHyperlink and CommunitiesHyperlink.OnClickReference then
			CommunitiesHyperlink.OnClickReference(clubId)
		end
	else
		ns.Options_Toggle(clubId)
	end
end

function broker_OnLeave(self,clubId)
	local club = ns.clubs[clubId];
	if not club.tooltip then return end
	if not (self and MouseIsOver(self,0,-3)) and not (club.clubType==1 and MouseIsOver(club.tooltip,3)) then
		club.tooltip:SetScript("OnLeave",nil);
		LQT:Release(club.tooltip);
		club.tooltip = nil;
	elseif MouseIsOver(club.tooltip,3) then
		C_Timer.After(0.5,function()
			broker_OnLeave(self,clubId)
		end);
	end
end

function ns.Broker_Update(clubId,field)
	local club,data = ns.clubs[clubId];
	if field == "icon" then
		data = club.iconId;
	elseif field=="text" then
		ns.clubs("updateCounter",clubId);
		local color,hexColor = ns.channelColor(clubId);
		data = patternMembers:format(CGreen,club.numOnline or 0,hexColor,club.numMembers or 0);
	end
	if data then
		(LDB:GetDataObjectByName(club.ldbName) or {})[field] = data;
	end
end

function ns.Broker_ToggleMinimap(clubId,forceShow)
	local club,show = ns.clubs[clubId];
	if type(forceShow)=="boolean" then
		show = forceShow;
	else
		show = not CommunityInfoDB[club.key].minimap.hide;
	end
	CommunityInfoDB[club.key].minimap.hide = not show;
	LDBI:Refresh(club.ldbName);
end

function ns.Broker_UpdateDirty(flag)
	for clubId,club in ns.clubs() do
		if flag then
			club.dirty = true;
		elseif club.dirty then
			ns.Broker_Update(clubId,"icon");
			ns.Broker_Update(clubId,"text");
			club.dirty = nil;
		end
	end
end

function ns.Broker_Register(clubId)
	local club = ns.clubs[clubId];
	if club==nil then return end
	club.ldbName = addon.."-"..club.key;
	if club.ldbObject==nil then
		club.ldbObject = LDB:NewDataObject(club.ldbName,{
			type      = "data source",
			icon      = 134400,
			iconCoors = club.clubType==0 and {0,1,0,1} or {0.05,0.95,0.05,0.95},
			label     = club.name,
			text      = club.name,
			OnEnter   = function(self)
				broker_OnEnterClub(self,club.clubId);
			end,
			OnLeave   = function(self)
				broker_OnLeave(self,club.clubId);
			end,
			OnClick   = function(self,button)
				broker_OnClickClub(self,button,club.clubId);
			end,
		});

		if LDBI then
			LDBI:Register(club.ldbName, club.ldbObject, CommunityInfoDB[club.key].minimap);
		end
	end
	club.dirty=nil;
end
