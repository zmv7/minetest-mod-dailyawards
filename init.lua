local s = minetest.get_mod_storage()
local INTERVAL = tonumber(minetest.settings:get("dailyawards_interval")) or 86400
local days_limit = tonumber(minetest.settings:get("dailyawards_dayslimit")) or 365

local awards = {
	"default:wood 4",
	"default:cobble 8",
	"default:steel_ingot 3",
	"default:mese_crystal_fragment",
	"default:mese_crystal",
	"default:mese_crystal 7",
	"default:mese",
	"default:mese 2",
	"default:diamond",
	"default:diamond 2",
	"default:diamond 4",
	"default:diamond 8",
	"default:diamondblock 2",
	"default:mese_crystal"
}

local function giveaward(name, day)
	local player = minetest.get_player_by_name(name)
	if not player then
		return
	end
	local award = awards[day] or awards[#awards].." "..day
	local inv = player:get_inventory()
	if inv and inv:room_for_item("main",award) then
		inv:add_item("main",award)
	else
		minetest.add_item(player:get_pos(),award)
	end
	minetest.chat_send_player(name,minetest.colorize("lime","You got an award for day "..day.."!"))
end

local function checkaward(name)
	local data = minetest.deserialize(s:get_string(name))
	if not data then
		giveaward(name,1)
		s:set_string(name,minetest.serialize({["lastaward"] = os.time(),["day"] = 1}))
		return true
	end
	if os.time() - data.lastaward > INTERVAL then
		if os.time() - data.lastaward < INTERVAL*2 then
			data.day = data.day + 1
			if data.day > days_limit then
				data.day = 1
			end
		else
			data.day = 1
		end
		giveaward(name,data.day)
		data.lastaward = os.time()
		s:set_string(name,minetest.serialize(data))
		return true
	end
	return
end

minetest.register_on_joinplayer(function(player)
	local name = player and player:get_player_name()
	if name and minetest.check_player_privs(name,{creative=true}) then
		return
	end
	checkaward(name)
end)
minetest.register_chatcommand("checkaward",{
  description = "Check daily award",
  privs = {interact=true},
  func = function(name, param)
	local player = minetest.get_player_by_name(name)
	if player then
		if checkaward(name) then
			return true
		end
	end
	return false, "No award avaiable now"
end})
