
local addon,ns = ...;
local L = ns.L;

local LDB = LibStub("LibDataBroker-1.1");
local LDBI = LibStub("LibDBIcon-1.0");
local LQT = LibStub("LibQTip-1.0");

local C = WrapTextInColorCode;
local CYellow,CYellowLight,CGreen,CBNet,CBlue,CGray = "ffffcc00","fffff569","ff00ff00","ff82c5ff","ff00aaff","ffaaaaaa";
local broker,patternToonMembers,patternBNetMembers = {},C("%s",CGreen)..C("/%s",CYellow),C("%s",CGreen)..C("/%s",CBNet);
local clubs,broker_OnLeave = {};

local COMMUNITY_MEMBER_ROLE_NAMES = {
	[Enum.ClubRoleIdentifier.Owner] = COMMUNITY_MEMBER_ROLE_NAME_OWNER,
	[Enum.ClubRoleIdentifier.Leader] = COMMUNITY_MEMBER_ROLE_NAME_LEADER,
	[Enum.ClubRoleIdentifier.Moderator] = COMMUNITY_MEMBER_ROLE_NAME_MODERATOR,
	[Enum.ClubRoleIdentifier.Member] = COMMUNITY_MEMBER_ROLE_NAME_MEMBER,
};

local function sortByName(a,b)
	return a.name<b.name;
end

local function MouseIsOver(region, topOffset, bottomOffset, leftOffset, rightOffset)
	if region and region.IsMouseOver then -- blizzard's own version does not check if region exists...
		return region:IsMouseOver(topOffset, bottomOffset, leftOffset, rightOffset);
	end
end

local function GetTooltip(parent,clubId)
	local club,ttColumns,ttAlign = ns.clubs[clubId],6,{"RIGHT", "LEFT", "LEFT", "LEFT","LEFT","LEFT"};
	if club.clubType==0 then
		ttColumns, ttAlign = 4, {"LEFT", "RIGHT", "LEFT", "LEFT","LEFT","LEFT"};
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

local function pairsClubs()
	local keys,i,iter,_ = {},0;
	for clubId,club in pairs(clubs) do
		if clubId~=0 then
			tinsert(keys,{clubId,name=club.info.name});
		end
	end
	table.sort(keys,sortByName);
	iter = function()
		i=i+1;
		if keys[i] then
			return clubs[keys[i][1]];
		end
	end
	return iter;
end

local function strCut(str,limit)
	if not str then return ""; end
	if str:len()>limit-3 then str = strsub(str,1,limit-3).."..." end
	return str;
end

local function strWrap(text, limit, insetCount, insetChr, insetLastChr)
	if not text then
		return "";
	end
	if text:match("\n") or text:match("%|n") then
		local txt = text:gsub("%|n","\n");
		local strings,tmp = {strsplit("\n",txt)},{};
		for i=1, #strings do
			tinsert(tmp,ns.strWrap(strings[i], limit, insetCount, insetChr, insetLastChr));
		end
		return tconcat(tmp,"\n");
	end
	if text:len()<=limit then
		return text;
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
	return table.concat(result,"|n"..inset)
end

local function memberInviteOrWhisperToon(self,info,button)
	local invite,tell,link,text;
	if IsAltKeyDown() then
		C_PartyInfo.InviteUnit(info.name);
	else
		SetItemRef("player:"..info.name, ("|Hplayer:%1$s|h[%1$s]|h"):format(info.name), "LeftButton");
	end
end

local function broker_OnEnterClub(self,clubId)
	local club,tt = ns.clubs[clubId];
	local _,clubColor = ns.channelColor(clubId);
	clubColor = clubColor or "ff888888";
	local tt = GetTooltip(self,clubId);

	if tt.lines~=nil then tt:Clear(); end

	tt:SetCell(tt:AddLine(),1,C(club.name or "?",clubColor),tt:GetHeaderFont(),"LEFT",0);
	tt:SetCell(tt:AddLine(),1,C(club.clubType==0 and COMMUNITIES_INVITATION_FRAME_TYPE or COMMUNITIES_INVITATION_FRAME_TYPE_CHARACTER,clubColor),"GameFontNormalSmall","LEFT",0);
	tt:AddSeparator(4,0,0,0,0);

	local failed,members = {},{};
	for _,memberId in ipairs(C_Club.GetClubMembers(clubId)) do
		local info = C_Club.GetMemberInfo(clubId,memberId);
		if info and info.name and info.presence>0 then
			info.id = memberId;
			tinsert(members,info);
		else
			tinsert(failed,memberId);
		end
	end
	table.sort(members,sortByName);

	if CommunityInfoDB["Club-"..clubId.."-motd"] and club.broadcast and club.broadcast:trim()~="" then
		tt:SetCell(tt:AddLine(), 1, C(GUILD_MOTD_LABEL,CBlue),nil,"LEFT",0);
		tt:AddSeparator();
		tt:SetCell(tt:AddLine(), 1, C(strWrap(club.broadcast,80),CYellow), nil, "LEFT", 0);
		tt:AddSeparator(4,0,0,0,0);
	end

	if CommunityInfoDB["Club-"..clubId.."-desc"] and club.description and club.description:trim()~="" then
		tt:SetCell(tt:AddLine(), 1, C(DESCRIPTION,CBlue),nil,"LEFT",0);
		tt:AddSeparator();
		tt:SetCell(tt:AddLine(), 1, C(strWrap(club.description,80),CYellow), nil, "LEFT", 0);
		tt:AddSeparator(4,0,0,0,0);
	end

	if club.clubType==0 then
		tt:AddLine(
			--LEVEL,
			C(NAME,CYellowLight),
			--RACE,
			--ZONE,
			C(LABEL_NOTE,CYellowLight),
			C(RANK,CYellowLight)
		);
	else
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
	for index, memberInfo in pairs(members)do
		if memberInfo.presence==3 then
			-- ignore offline
		elseif club.clubType==0 then
			tt:AddLine(
				--memberInfo.level,
				C(memberInfo.name or UNKNOWN,clubColor),
				--memberInfo.race,
				--memberInfo.zone or "",
				C(strCut(memberInfo.memberNote,18),CGray),
				memberInfo.role and COMMUNITY_MEMBER_ROLE_NAMES[memberInfo.role] or ""
			);
		else
			local name,realm = strsplit("-",memberInfo.name,2);
			realm = realm and C(" - "..realm,CYellow) or "";
			local raceInfo = C_CreatureInfo.GetRaceInfo(memberInfo.race);

			local l = tt:AddLine(
				memberInfo.level,
				C(name or UNKNOWN,ns.class_color(memberInfo.classID)) .. realm,
				C(raceInfo and raceInfo.raceName or "",CGray),
				memberInfo.zone or "",
				C(strCut(memberInfo.memberNote,18),CGray),
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
		tt:SetCell(tt:AddLine(),1,C(L["MouseBtn"],CBlue).." || "..C(WHISPER,CGreen) .." - ".. C(L["ModKeyA"].."+"..L["MouseBtn"],CBlue).." || "..C(TRAVEL_PASS_INVITE,CGreen),nil,"LEFT",0);
	end

	tt:Show();
end

local function broker_OnClickClub(self,button,clubId)
	local club = ns.clubs[clubId];
	if button=="LeftButton" then
	else
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
		ns.updateOnline(clubId);
		ns.debug("<brokerUpdate>",clubId,field,club.online,club.numMembers);
		data = patternToonMembers:format(club.online or 0,club.numMembers or 0);
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
		show = not CommunityInfoDB[club.dbMinimap].hide;
	end
	CommunityInfoDB[club.dbMinimap].hide = not show;
	LDBI:Refresh(club.ldbName);
end

function ns.Broker_UpdateDirty(flag)
	for clubId,club in ns.clubs() do
		if flag then
			club.dirty = true;
		elseif club.dirty then
			local obj = (LDB:GetDataObjectByName(club.ldbName) or {});
			obj.text = "CLUB_NOT_FOUND";
			obj.icon = 134400;
		end
	end
end

function ns.Broker_Register(clubId)
	local club = ns.clubs[clubId];
	if club==nil then return end
	club.ldbName = addon.."-"..club.key;
	club.dbMinimap = "Club",club.key.."-minimap";
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
			LDBI:Register(club.ldbName, club.ldbObject, CommunityInfoDB[club.dbMinimap]);
		end
	end
	club.dirty=nil;
end
