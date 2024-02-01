elite_tracker_tab = gui.get_tab("Elite Tracker")

h2_tab = elite_tracker_tab:add_tab("The Doomsday Heist")
ch_tab = elite_tracker_tab:add_tab("The Diamond Casino Heist")
h4_tab = elite_tracker_tab:add_tab("The Cayo Perico Heist")

local og_elites = {}
local h2_elites = {}
local ch_elites = {}
local h4_elite

local has_quick_restarted
local has_got_detected

local elite_time
local has_failed_hack
local kills
local headshots
local deaths
local vehicle_damage

local h4_elite_time
local h4_has_failed_hack
local h4_deaths
local h4_bag_size
local h4_grabbed_cash

function has_bit_set(address, pos)
	return (address & (1 << pos)) ~= 0
end

function format_int(number)
  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
  int = int:reverse():gsub("(%d%d%d)", "%1,")
  return minus .. int:reverse():gsub("^,", "") .. fraction
end

function format_milliseconds(ms)
    local total_seconds = math.floor(ms / 1000)
    local hours = math.floor(total_seconds / 3600)
    local minutes = math.floor((total_seconds % 3600) / 60)
    local seconds = total_seconds % 60
    local formatted = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    
    return formatted
end

function get_net_difference(timeb)
    if NETWORK.NETWORK_IS_GAME_IN_PROGRESS() then
        return NETWORK.GET_TIME_DIFFERENCE(NETWORK.GET_NETWORK_TIME(), timeb)
    end

    return NETWORK.GET_TIME_DIFFERENCE(MISC.GET_GAME_TIMER(), timeb)
end

function get_mission_time()
	local mission_time = 0
	
	mission_time = get_net_difference(locals.get_int("fm_mission_controller", 19728 + 985))
	if mission_time <= 0 then
		mission_time = get_net_difference(locals.get_int("fm_mission_controller", 19728 + 985))
	end
	mission_time = mission_time + 10000
	if globals.get_int(2684312 + 43 + 55) or globals.get_int(2684312 + 43 + 56) then
		mission_time = mission_time + globals.get_int(2685249 + 6465)
	end
	
	return mission_time
end

function ch_is_active()
	local root_content_ids = {
		tunables.get_int("CICASINO_HEIST_MISSION_DIRECT_STAGE_1A"),
		tunables.get_int("CICASINO_HEIST_MISSION_DIRECT_STAGE_2A_CASINOFLOOR1"),
		tunables.get_int("CICASINO_HEIST_MISSION_DIRECT_STAGE_2A_CASINOFLOOR2"),
		tunables.get_int("CICASINO_HEIST_MISSION_DIRECT_STAGE_2B_ROOFTOP"),
		tunables.get_int("CICASINO_HEIST_MISSION_DIRECT_STAGE_2C_TUNNEL"),
		tunables.get_int("CICASINO_HEIST_MISSION_DIRECT_STAGE_3A"),
		tunables.get_int("CICASINO_HEIST_MISSION_DIRECT_STAGE_4A"),
		tunables.get_int("CICASINO_HEIST_MISSION_DIRECT_STAGE_5A"),
		tunables.get_int("CICASINO_HEIST_MISSION_STEALTH_STAGE_1A"),
		tunables.get_int("CICASINO_HEIST_MISSION_STEALTH_STAGE_2B_RAPPEL"),
		tunables.get_int("CICASINO_HEIST_MISSION_STEALTH_STAGE_2C_SIDE"),
		tunables.get_int("CICASINO_HEIST_MISSION_STEALTH_STAGE_3A"),
		tunables.get_int("CICASINO_HEIST_MISSION_STEALTH_STAGE_4A"),
		tunables.get_int("CICASINO_HEIST_MISSION_STEALTH_STAGE_5A"),
		tunables.get_int("CICASINO_HEIST_MISSION_SUBTERFUGE_STAGE_1A"),
		tunables.get_int("CICASINO_HEIST_MISSION_SUBTERFUGE_STAGE_2A"),
		tunables.get_int("CICASINO_HEIST_MISSION_SUBTERFUGE_STAGE_2B"),
		tunables.get_int("CICASINO_HEIST_MISSION_SUBTERFUGE_STAGE_3A"),
		tunables.get_int("CICASINO_HEIST_MISSION_SUBTERFUGE_STAGE_3B"),
		tunables.get_int("CICASINO_HEIST_MISSION_SUBTERFUGE_STAGE_4A"),
		tunables.get_int("CICASINO_HEIST_MISSION_SUBTERFUGE_STAGE_5A")
	}
	
	for i = 1, #root_content_ids do
		if globals.get_int(4718592 + 126144) == root_content_ids[i] then
			return true
		end
	end
	
	return false
end

function h4_get_mission_time()
    local mission_time = 0

    if globals.get_int(2684312 + 43 + 55) or globals.get_int(2684312 + 43 + 56) then
        mission_time = locals.get_int("fm_mission_controller_2020", 51882 + 1517 + 29)
        if locals.get_int("fm_mission_controller_2020", 48513 + 1490) <= 0 then
            mission_time = mission_time + get_net_difference(locals.get_int("fm_mission_controller_2020", 48513 + 1487))
        end
    else
        mission_time = locals.get_int("fm_mission_controller_2020", 48513 + 1490)
        if mission_time <= 0 then
            mission_time = get_net_difference(locals.get_int("fm_mission_controller_2020", 48513 + 1487))
        end
    end

    mission_time = mission_time + 10000

    return mission_time
end

function h4_is_active()
	for i = 0, 10 do
		if globals.get_int(4718592 + 126144) == tunables.get_int("H4_ROOT_CONTENT_ID_" .. i) then
			return true
		end
	end
	
	return false
end

script.register_looped("Elite Tracker", function(script)
	og_elites[1] = stats.get_packed_stat_bool(3765)
	og_elites[2] = stats.get_packed_stat_bool(3766)
	og_elites[3] = stats.get_packed_stat_bool(3767)
	og_elites[4] = stats.get_packed_stat_bool(3768)
	og_elites[5] = stats.get_packed_stat_bool(3769)
	h2_elites[1] = stats.get_packed_stat_bool(18116)
	h2_elites[2] = stats.get_packed_stat_bool(18117)
	h2_elites[3] = stats.get_packed_stat_bool(18118)
	ch_elites[1] = stats.get_packed_stat_bool(28194)
	ch_elites[2] = stats.get_packed_stat_bool(28195)
	ch_elites[3] = stats.get_packed_stat_bool(28196)
	has_quick_restarted = globals.get_int(2685249 + 6463)
	if has_bit_set(locals.get_int("fm_mission_controller", 22942 + 1552 + 11), 1) then
		has_got_detected = true
	else
		has_got_detected = false
	end
	elite_time = format_milliseconds(get_mission_time())
	kills = locals.get_int("fm_mission_controller", 19728 + 1725 + 1)
	headshots = locals.get_int("fm_mission_controller", 19728 + 1740 + 1)
	deaths = locals.get_int("fm_mission_controller", 19728 + 1730 + 1)
	has_failed_hack = locals.get_int("fm_mission_controller", 28347 + 3197)
	vehicle_damage = locals.get_int("fm_mission_controller", 24562 + 1231)
	h4_elite = stats.get_bool("MPX_AWD_ELITE_THIEF")
	h4_elite_time = format_milliseconds(h4_get_mission_time())
	h4_has_failed_hack = locals.get_int("fm_mission_controller_2020", 51882 + 1517 + 51)
	h4_deaths = locals.get_int("fm_mission_controller_2020", 51882 + 1517 + 36 + 1)
	h4_bag_size = math.floor(locals.get_float("fm_mission_controller_2020", 60496 + (1 + (0 * 261)) + 236 + 2) / SYSTEM.TO_FLOAT(tunables.get_int(1859395035)) * 100.0)
	h4_grabbed_cash = locals.get_int("fm_mission_controller_2020", 51882 + 1517 + 53)
end)

elite_tracker_tab:add_imgui(function()
	ImGui.Text("Fleeca Job: " .. (og_elites[1] and "completed" or "not completed"))
	ImGui.Text("Prison Break: " .. (og_elites[2] and "completed" or "not completed"))
	ImGui.Text("Humane Labs Raid: " .. (og_elites[3] and "completed" or "not completed"))
	ImGui.Text("Series A Funding: " .. (og_elites[4] and "completed" or "not completed"))
	ImGui.Text("Pacific Standard Job: " .. (og_elites[5] and "completed" or "not completed"))
	ImGui.Separator()
	ImGui.Text("Data Breaches: " .. (h2_elites[1] and "completed" or "not completed"))
	ImGui.Text("Bogdan Problem: " .. (h2_elites[2] and "completed" or "not completed"))
	ImGui.Text("Doomsday Scenario: " .. (h2_elites[3] and "completed" or "not completed"))
	ImGui.Separator()
	ImGui.Text("Silent & Sneaky: " .. (ch_elites[1] and "completed" or "not completed"))
	ImGui.Text("Big Con: " .. (ch_elites[2] and "completed" or "not completed"))
	ImGui.Text("Aggressive: " .. (ch_elites[3] and "completed" or "not completed"))
	ImGui.Separator()
	ImGui.Text("Cayo Perico: " .. (h4_elite and "completed" or "not completed"))
end)

-- TO-DO: Add if doomsday heist active check and handle different time requirements
h2_tab:add_imgui(function()
	if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("fm_mission_controller")) ~= 0 then
		if locals.get_int("fm_mission_controller", 19728 + 985) ~= 0 then
			ImGui.Text("Timer: " .. elite_time .. " / 00:15:00")
		else
			ImGui.Text("Timer: paused")
		end
	else
		ImGui.Text("Timer: not started")
	end
	
	ImGui.Text("Quick Restarted: " .. (has_quick_restarted ~= 0 and "Yes" or "No"))
	ImGui.Text("Detected: " .. (has_got_detected and "Yes" or "No"))
	ImGui.Text("Failed Hack: " .. (has_failed_hack ~= 0 and "Yes" or "No"))
	ImGui.Text("Deaths: " .. deaths)
	ImGui.Text("Kills: " .. kills)
	ImGui.Text("Headshots: " .. headshots)
	ImGui.Text("Vehicle Damage: " .. vehicle_damage .. "%")
end)

ch_tab:add_imgui(function()
	if ch_is_active() then
		if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("fm_mission_controller")) ~= 0 then
			if locals.get_int("fm_mission_controller", 19728 + 985) ~= 0 then
				ImGui.Text("Timer: " .. elite_time .. " / 00:15:00")
			else
				ImGui.Text("Timer: paused")
			end
		else
			ImGui.Text("Timer: not started")
		end
		
		ImGui.Text("Quick Restarted: " .. (has_quick_restarted ~= 0 and "Yes" or "No"))
		ImGui.Text("Detected: " .. (has_got_detected and "Yes" or "No"))
		ImGui.Text("Failed Hack: " .. (has_failed_hack ~= 0 and "Yes" or "No"))
		ImGui.Text("Deaths: " .. deaths)
		ImGui.Text("Headshots: " .. headshots)
	else
		ImGui.Text("Heist is not active.")
	end
end)

h4_tab:add_imgui(function()
	if h4_is_active() then
		if SCRIPT.GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(joaat("fm_mission_controller_2020")) ~= 0 then
			if locals.get_int("fm_mission_controller_2020", 48513 + 1487) ~= 0 then
				ImGui.Text("Timer: " .. h4_elite_time .. " / 00:15:00")
			else
				ImGui.Text("Timer: paused")
			end
		else
			ImGui.Text("Timer: not started")
		end
		
		ImGui.Text("Quick Restarted: " .. (has_quick_restarted ~= 0 and "Yes" or "No"))
		ImGui.Text("Failed Hack: " .. (h4_has_failed_hack ~= 0 and "Yes" or "No"))		
		ImGui.Text("Deaths: " .. h4_deaths)	
		ImGui.Text("Bag: $" .. format_int(h4_grabbed_cash) .. " (" .. h4_bag_size .. "%)")
	else
		ImGui.Text("Heist is not active.")
	end
end)