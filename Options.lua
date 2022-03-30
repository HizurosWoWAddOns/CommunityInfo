
local addon,ns = ...;
local L,C = ns.L,WrapTextInColorCode;
local faction = UnitFactionGroup("player");
local AC = LibStub("AceConfig-3.0");
local ACD = LibStub("AceConfigDialog-3.0");
local ACR = LibStub("AceConfigRegistry-3.0");
local clubChatValues,generalDefaults,clubDefaults,options = {
	["0"] = ADDON_DISABLED,
	["1"] = GENERAL,
	["2"] = L["SelectedChatWindow"] -- Into same chat window like community chat messages
},{ -- generalDefaults
	addonloaded=true,
},{ -- clubDefaults
	minimap = {hide=true},
	msgTarget = "1",
	msgTargetChannel = false,
	notes = true,
	motd = true,
	desc = true,
	enableInOrExclude = 0,
}

local function GetCommunityNameAndType(info)
	local key,clubKey,clubId,club,name = info[#info];
	for i=0, 4 do
		if info[#info-i] and info[#info-i]:find("^Club%-") then
			clubId = tonumber(info[#info-i]:match("^Club%-(%d+)")) or 0;
			club = ns.clubs[clubId];
			clubKey = info[#info-i];
			break;
		end
	end
	if not (clubKey and clubId and club) then
		ns.debug(key,clubKey , clubId , club);
		return ""; -- failed
	end

	if key=="nameonly" then
		return club.name;
	end

	local color, hex = ns.channelColor(club.clubId);
	local clubType = C("("..(club.clubType==0 and COMMUNITIES_INVITATION_FRAME_TYPE or COMMUNITIES_INVITATION_FRAME_TYPE_CHARACTER)..")",hex); -- "ffaaaaaa"

	if key=="clubtype" then
		return clubType;
	end

	local factionIcon = club.clubType~=0 and " |TInterface\\PVPFrame\\PVP-Currency-"..faction..":16:16:-2:-1:16:16:0:16:0:16|t" or "";
	local clubIcon = ns.clubs[clubId].iconId or "";
	if clubIcon then
		clubIcon = "|T"..clubIcon..":0|t ";
	end
	local clubName = C(club.name,hex);
	if key=="label" then
		return clubIcon .. clubName .. factionIcon;
	end

	return clubIcon .. clubName .. factionIcon; -- .. "\n" .. clubType;
end

local function addMembers(info)
	if not info[#info] == "members" then return end
	local clubKey = info[#info-2];
	local clubId = tonumber(clubKey:match("(%d+)$"));
	local opt_members = options.args.communities.args[clubKey].args.notifications.args.members
	wipe(opt_members.args);

	local members = C_Club.GetClubMembers(clubId);
	for _,memberId in ipairs(members) do
		local info = C_Club.GetMemberInfo(clubId,memberId);
		if info and info.name and info.guid and info.isSelf==false then
			local id = "member-"..memberId;
			local classInfo = C_CreatureInfo.GetClassInfo(info.classID);
			local name, realm = strsplit("-",info.name);
			local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[classInfo.classFile];
			local _name = name;
			if color then
				_name = color:WrapTextInColorCode(name);
			end
			if realm then
				_name = _name .. C(" - "..realm,"ff888888");
			end
			opt_members.args[id] = {
				type = "toggle", order = info.classID,
				name = _name
			}
--@do-not-package@
		else
			ns.debug("no info for memberId",clubId,memberId);
--@end-do-not-package@
		end
	end
	return "";
end

local function hideMembers(info)
	if info[#info]~="members" then return false; end
	local clubKey = info[#info-2];
	if CommunityInfoDB[clubKey].enableInOrExclude == 0 then
		return true;
	end
	return false;
end

local function opt(info,value,...)
	local key = info[#info];
	if value~=nil then
		CommunityInfoDB[key] = value
		return;
	end
	return CommunityInfoDB[key];
end

local function comOpt(info,value)
	local key,club = info[#info],info[#info-1];
	if not club:find("^Club%-") then
		club = info[#info-2];
	end
	if value~=nil then
		if key=="minimap" then
			ns.Broker_ToggleMinimap(tonumber(club:match("(%d+)$")),value);
			return;
		end
		CommunityInfoDB[club][key] = value
		return;
	elseif key=="minimap" then
		return not CommunityInfoDB[club][key].hide;
	end
	return CommunityInfoDB[club][key];
end

local function membOpt(info,value)
	local member = info[#info];
	local clubKey = info[#info-3];
	local memberInfo = C_Club.GetMemberInfo(tonumber((clubKey:gsub("^Club%-",""))),tonumber((member:gsub("^member%-",""))));
	if value~=nil then
		CommunityInfoDB[clubKey][memberInfo.guid] = value or nil;
		return;
	end
	return CommunityInfoDB[clubKey][memberInfo.guid] or false;
end

options = {
	type = "group",
	name = addon,
	childGroups = "tab",
	get = opt, set = opt,
	args = {
		addonloaded = {
			type = "toggle", order = 1,
			name = L["AddOnLoaded"], -- AddOn loaded...
			desc = L["AddOnLoadedDesc"].."|n|n|cff44ff44"..L["AddOnLoadedDescAlt"].."|r", -- Display 'AddOn loaded...' message on login. Alternatively you can hold shift key on loading screen to display this message for this login only.
		},
		communities = {
			type = "group", order = 4,
			childGroups = "tree",
			name = COMMUNITIES,
			get = comOpt, set = comOpt,
			args = {
				NoCommunityFound = {
					type = "description", order = 0, fontSize = "large",
					name = L["NoCommunityFound"]
				}
			}
		},
	}
};

local comTpl = { -- community option table template
	type = "group", order = 100,
	name = GetCommunityNameAndType,
	args = {
		label = {
			type = "description", order = 0, fontSize = "large",
			name = GetCommunityNameAndType
		},
		clubtype = {
			type = "description", order = 1, fontSize = "medium",
			name = GetCommunityNameAndType
		},

		broker_tooltip = {
			type = "group", order = 2, inline = true,
			name = C(L["Broker & Tooltip"],"ffff8800"),
			args = {
				minimap = {
					type = "toggle", order = 2,
					name = L["MinimapButton"], -- Minimap button
					desc = L["MinimapButtonDesc"] -- Add community broker to minimap. Good for user without panel addons like titan panel, bazooka and co.
				},
				motd = {
					type = "toggle", order = 3,
					name = COMMUNITIES_SETTINGS_MOTD_LABEL,
					desc = L["MotdDesc"] -- Display community message of the day in tooltip
				},
				desc = {
					type = "toggle", order = 4,
					name = COMMUNITIES_SETTINGS_DESCRIPTION_LABEL,
					desc = L["DescDesc"] -- Display community description in tooltip
				},
			}
		},

		notifications = {
			type = "group", order = 3, inline = true,
			name = C(COMMUNITIES_NOTIFICATION_SETTINGS,"ffff8800"),
			args = {
				msgTarget = {
					type = "select", order = 1, width = "full",
					name = L["NotificationTarget"], -- Show notifications in:
					desc = L["NotificationTargetDesc"], -- Choose in which chat window the notifications should be displayed.
					values = clubChatValues
				},
				notes = {
					type = "toggle", order = 2,
					name = LABEL_NOTE,
					desc = L["NoteDesc"] -- Display member notes on notifigations
				},

				-- notification in channel color as option?
				--[[
				color_header = {
					type = "header", order = 3,
					name = L["TextColor"]
				},
				-- select values ( channel color, default color, custom color  )
				]]

				filter_header = {
					type = "header", order = 3,
					name = FILTER
				},

				enableInOrExclude = {
					type = "select", order = 4, width = "full",
					name = "", --"In- or exclude",
					values = {
						[0] = L["NotificationFilter0"],
						[1] = L["NotificationFilter1"],
						[2] = L["NotificationFilter2"]
					}
				},
				members = {
					type = "group", order = 5, inline = true,
					name = addMembers,
					hidden = hideMembers,
					get = membOpt,
					set = membOpt,
					args = {
						-- filled by function
					}
				}
			}
		},

	}
}

local function sortClubs(a,b)
	return a[1]<b[1];
end

local function Ace3NotifyChange()
	local index,tmp = 100,{};
	for k,v in pairs(options.args.communities.args) do
		if k~="NoCommunityFound" then
			local name = v.name({k,"nameonly"});
			tinsert(tmp,{name,v});
		end
	end
	table.sort(tmp,sortClubs);
	for k,v in pairs(tmp)do
		v[2].order = index;
		index = index + 1;
	end
	ACR:NotifyChange(addon);
end

function ns.Options_AddCommunity(clubId)
	local club,clubKey = ns.clubs[clubId],"Club-"..clubId;

	if club.clubType~=1 then
		return;
	end

	-- add community to option panel
	if not options.args.communities.args[clubKey] then
		options.args.communities.args[clubKey] = CopyTable(comTpl);
		options.args.communities.args.NoCommunityFound.hidden = true;
	end

	-- check community savedvariables
	if not CommunityInfoDB[clubKey] then
		CommunityInfoDB[clubKey] = CopyTable(clubDefaults);
	else
		for optKey,value in pairs(clubDefaults)do
			local t = type(value);
			if type(CommunityInfoDB[clubKey][optKey])~=t then
				CommunityInfoDB[clubKey][optKey] = (t=="table" and CopyTable(value)) or value;
			end
		end
	end
	Ace3NotifyChange()
end

function ns.Options_RemoveCommunity(clubId)
	if options.args.communities.args["Club-"..clubId] then
		options.args.communities.args["Club-"..clubId] = nil;
	end
	Ace3NotifyChange()
end

function ns.Options_Toggle()
end

function ns.Options_Register()
	if not CommunityInfoDB then
		CommunityInfoDB = {};
	end
	for k,v in pairs(generalDefaults) do
		if CommunityInfoDB[k]==nil then
			CommunityInfoDB[k] = type(v)=="table" and CopyTable(v) or v;
		end
	end
	-- remove old config entries
	for key,value in pairs(CommunityInfoDB)do
		local club, opts = key:match("^(Club%-%d+)%-(.+)$");
		if club and opts then
			if not CommunityInfoDB[club] then
				CommunityInfoDB[club] = CopyTable(clubDefaults);
			end
			CommunityInfoDB[club][opts] = value;
			CommunityInfoDB[key] = nil;
		end
	end
	AC:RegisterOptionsTable(addon, options);
	ACD:AddToBlizOptions(addon);
end
