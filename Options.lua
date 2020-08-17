
local addon,ns = ...;
local L,C = ns.L,WrapTextInColorCode;
local faction = UnitFactionGroup("player");
local AC = LibStub("AceConfig-3.0");
local ACD = LibStub("AceConfigDialog-3.0");
local clubChatValues,generalDefaults,clubDefaults,options = {
	["0"] = ADDON_DISABLED,
	["1"] = GENERAL,
	["2"] = L["SelectedChatWindow"] -- Into same chat window like community chat messages
},{ -- generalDefaults
	addonloaded=true,
},{ -- clubDefaults
	minimap = {hide=true},
	msgTarget = "1",
	notes = true,
	motd = true,
	desc = true,
	enableInOrExclude = 0,
}

local function GetCommunityNameAndType(info)
	local key,clubKey,clubId,club,name = info[#info];
	for i=0, 4 do
		clubkey = info[#info-i];
		if clubkey and clubkey:find("^Club%-") then
			clubId = tonumber(clubkey:match("^Club%-(%d+)")) or 0;
			club = ns.clubs[clubId];
			clubKey = clubkey;
			break;
		end
	end
	if not (clubKey and clubId and club) then
		ns.debug(key,clubKey , clubId , club);
		return ""; -- failed
	end
	local clubType = C("("..(club.clubType==0 and COMMUNITIES_INVITATION_FRAME_TYPE or COMMUNITIES_INVITATION_FRAME_TYPE_CHARACTER)..")","ffaaaaaa");

	if key=="clubtype" then
		return clubType;
	end

	local color, hex = ns.channelColor(club.clubId);
	--local icon = "|Tinterface\\friendsframe\\Battlenet-" .. (club.clubType==0 and "Battleneticon" or "WoWicon") .. ":16:16:0:-1:64:64:6:58:6:58|t ";
	local factionIcon = club.clubType~=0 and " |TInterface\\PVPFrame\\PVP-Currency-"..faction..":16:16:-2:-1:16:16:0:16:0:16|t" or "";
	local name = C(club.name,hex);
	if key=="label" then
		return factionIcon .. name;
	end
	return factionIcon .. name -- .. "\n" .. clubType;
end

local function addMembers(info)
	if not info[#info] == "members" then return end
	local clubKey = info[#info-2];
	local clubId = tonumber(clubKey:match("(%d+)$"));
	ns.debug("addMembers",clubKey,clubId);
	local opt_members = options.args.communities.args[clubKey].args.include_exclude.args.members
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
	if value~=nil then
		if value == false then
			value = nil;
		end
		CommunityInfoDB[clubKey][member] = value;
		return;
	end
	return CommunityInfoDB[clubKey][member] or false;
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
			desc = L["AddOnLoadedDesc"], -- Display 'AddOn loaded...' message on login
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
				}
			}
		},

		include_exclude = {
			type = "group", order = 4, inline = true,
			name =  C(L["IncludeExclude"],"ffff8800"),
			args = {
				enableInOrExclude = {
					type = "select", order = 1, width = "full",
					name = "", --"In- or exclude",
					values = {
						[0] = ADDON_DISABLED,
						[1] = L["Include"],
						[2] = L["Exclude"]
					}
				},
				header = {
					type = "header", order = 2,
					name = MEMBERS
				},
				members = {
					type = "group", order = 3, inline = true,
					name = addMembers,
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

function ns.Options_ResetCommunities()
	for k in pairs(options.args.communities.args) do
		if k:find("^Club%-%d+$") then
			options.args.communities.args[k] = nil;
		end
	end
end

function ns.Options_AddCommunity(clubId)
	local club,clubKey = ns.clubs[clubId],"Club-"..clubId;

	if club.clubType~=1 then
		return;
	end

	-- add community to option panel
	if not options.args.communities.args[clubKey] then
		options.args.communities.args[clubKey] = CopyTable(comTpl);
		options.args.communities.args[clubKey].order = 50;
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
