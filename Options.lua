
local addon,ns = ...;
local L,C = ns.L,WrapTextInColorCode;
local faction = UnitFactionGroup("player");
local AC = LibStub("AceConfig-3.0");
local ACD = LibStub("AceConfigDialog-3.0");
local clubChatValues,generalDefaults,clubDefaults = {
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
}

local function GetCommunityNameAndType(info)
	local key,clubKey,clubId,club,name = info[#info];
	for i=1, 4 do
		clubkey = info[#info-i];
		if clubkey and clubkey:find("^Club%-") then
			clubId = tonumber(clubkey:match("^Club%-(%d+)")) or 0;
			club = ns.clubs[clubId];
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
	local icon = "|Tinterface\\friendsframe\\Battlenet-" .. (club.clubType==0 and "Battleneticon" or "WoWicon") .. ":16:16:0:-1:64:64:6:58:6:58|t ";
	local factionIcon = club.clubType~=0 and " |TInterface\\PVPFrame\\PVP-Currency-"..faction..":16:16:-2:-1:16:16:0:16:0:16|t" or "";
	local name = C(club.name,hex);
	if key=="label" then
		return icon .. name .. factionIcon;
	end
	return icon .. name .. factionIcon .. "\n" .. clubType;
end

local function opt(info,value,...)
	local key = info[#info];
	if #info>1 then
		key = info[#info-1].."-"..key;
	end
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
		CommunityInfoDB[club.."-"..key] = value
		return;
	elseif key=="minimap" then
		return not CommunityInfoDB[club.."-"..key].hide;
	end
	return CommunityInfoDB[club.."-"..key];
end

local options = {
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
			args = {}
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
		}
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
	if club.clubId>0 then
		local clubKey = clubKey.."-";
		for optKey,value in pairs(clubDefaults)do
			local t = type(value);
			if type(CommunityInfoDB[clubKey..optKey])~=t then
				CommunityInfoDB[clubKey..optKey] = (t=="table" and CopyTable(value)) or value;
			end
		end
	end
	if options.args.communities.args[clubKey] then
		return;
	end
	options.args.communities.args[clubKey] = CopyTable(comTpl);
	if club.clubType~=0 then
		options.args.communities.args[clubKey].order = 50;
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
	AC:RegisterOptionsTable(addon, options);
	ACD:AddToBlizOptions(addon);
end
