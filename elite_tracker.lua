elite_tracker_tab = gui.get_tab("Elite Tracker")

elite_objectives_tab = elite_tracker_tab:add_tab("Elite Objectives")

selected_heist = 0
view_objectives = false

local og_elites = {}
local h2_elites = {}
local ch_elites = {}
local h4_elite

local has_quick_restarted

local elite_time
local has_failed_hack
local kills
local headshots
local deaths
local vehicle_damage
local rashkovsky_damage
local noose_called
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

--https://github.com/itsjustcurtis/MenyooSP/blob/685cac407313ed92f1c6e23c4bb09dbcf78c0364/Solution/source/Natives/natives2.cpp#L62
function add_text_component_long_string(text)
    local max_str_component_length = 99
    for i = 1, #text, max_str_component_length do
        local str_comp = string.sub(text, i, i + max_str_component_length - 1)
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(str_comp)
    end
end

function get_net_difference(timeb)
    if NETWORK.NETWORK_IS_GAME_IN_PROGRESS() then
        return NETWORK.GET_TIME_DIFFERENCE(NETWORK.GET_NETWORK_TIME(), timeb)
    end

    return NETWORK.GET_TIME_DIFFERENCE(MISC.GET_GAME_TIMER(), timeb)
end

function draw_text(text)
    if string.len(text) < 99 then
		HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("STRING")
		HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
	else
		HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT("jamyfafi")
		add_text_component_long_string(text)
	end
    HUD.SET_TEXT_RENDER_ID(1)
    HUD.SET_TEXT_OUTLINE()
    HUD.SET_TEXT_WRAP(.0, 0.975)
    HUD.SET_TEXT_RIGHT_JUSTIFY(true)
    HUD.SET_TEXT_SCALE(0, .5)
    HUD.SET_TEXT_FONT(4)
    HUD.SET_TEXT_COLOUR(255, 255, 255, 240)
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(.0, .2, 0)
end

function og_is_active()
	for i = 1, 7 do
		if globals.get_int(4718592 + 126144) == tunables.get_int("WVM_FLOW_ROOTCONTENT_ID_" .. i) then
			return true
		end
	end
	
	return false
end

function h2_is_active()
	for i = 1, 15 do
		if globals.get_int(4718592 + 126144) == tunables.get_int("FHM_FLOW_ROOTCONTENT_ID_" .. i) then
			return true
		end
	end
	
	return false
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

function h4_is_active()
	for i = 0, 10 do
		if globals.get_int(4718592 + 126144) == tunables.get_int("H4_ROOT_CONTENT_ID_" .. i) then
			return true
		end
	end
	
	return false
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

function is_elite_timer_paused()
	if selected_event == 3 then
		return locals.get_int("fm_mission_controller_2020", 48513 + 1487) == 0
	else
		return locals.get_int("fm_mission_controller", 19728 + 985) == 0
	end
end

function render_elite_objectives()
	if selected_heist == 0 then
		if og_is_active() then
			draw_text("TIME: " .. (not is_elite_timer_paused() and elite_time or "PAUSED") .. "~n~QUICK RESTARTED: " .. (has_quick_restarted ~= 0 and "YES" or "NO") .. "~n~FAILED HACK: " .. (has_failed_hack ~= 0 and "YES" or "NO") .. "~n~DEATHS: " .. deaths .. "~n~KILLS: " .. kills .. "~n~VEHICLE DAMAGE: " .. vehicle_damage .. "%" .. "RASHKOVSKY DAMAGE: " .. rashkovsky_damage .. "%" .. "NOOSE CALLED: " .. noose_called ~= 0 and "YES" or "NO")
		else
			draw_text("HEIST IS NOT ACTIVE.")
		end	
	elseif selected_heist == 1 then
		if h2_is_active() then
			draw_text("TIME: " .. (not is_elite_timer_paused() and elite_time or "PAUSED") .. "~n~QUICK RESTARTED: " .. (has_quick_restarted ~= 0 and "YES" or "NO") .. "~n~FAILED HACK: " .. (has_failed_hack ~= 0 and "YES" or "NO") .. "~n~DEATHS: " .. deaths .. "~n~KILLS: " .. kills .. "~n~HEADSHOTS: " .. headshots .. "~n~VEHICLE DAMAGE: " .. vehicle_damage .. "%")
		else
			draw_text("HEIST IS NOT ACTIVE.")
		end	
	elseif selected_heist == 2 then
		if ch_is_active() then
			draw_text("TIME: " .. (not is_elite_timer_paused() and elite_time or "PAUSED") .. "~n~QUICK RESTARTED: " .. (has_quick_restarted ~= 0 and "YES" or "NO") .. "~n~FAILED HACK: " .. (has_failed_hack ~= 0 and "YES" or "NO") .. "~n~DEATHS: " .. deaths .. "~n~HEADSHOTS: " .. headshots)
		else
			draw_text("HEIST IS NOT ACTIVE.")
		end	
	elseif selected_heist == 3 then
		if h4_is_active() then
			draw_text("TIME: " .. (not is_elite_timer_paused() and h4_elite_time or "PAUSED") .. "~n~QUICK RESTARTED: " .. (has_quick_restarted ~= 0 and "YES" or "NO") .. "~n~FAILED HACK: " .. (h4_has_failed_hack ~= 0 and "YES" or "NO") .. "~n~DEATHS: " .. h4_deaths .. "~n~BAG: $" .. h4_grabbed_cash .. " (" .. h4_bag_size .. "%)")
		else
			draw_text("HEIST IS NOT ACTIVE.")
		end
	end
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
	h4_elite = stats.get_bool("MPX_AWD_ELITE_THIEF")
	has_quick_restarted = globals.get_int(2685249 + 6463)
	elite_time = format_milliseconds(get_mission_time())
	kills = locals.get_int("fm_mission_controller", 19728 + 1725 + 1)
	headshots = locals.get_int("fm_mission_controller", 19728 + 1740 + 1)
	deaths = locals.get_int("fm_mission_controller", 19728 + 1730 + 1)
	has_failed_hack = locals.get_int("fm_mission_controller", 28347 + 3197)
	vehicle_damage = locals.get_int("fm_mission_controller", 24562 + 1231)
	rashkovsky_damage = locals.get_int("fm_mission_controller", 24562 + 1230)
	noose_called = has_bit_set(locals.get_int("fm_mission_controller", 19728 + 3), 11) and 1 or 0
	h4_elite_time = format_milliseconds(h4_get_mission_time())
	h4_has_failed_hack = locals.get_int("fm_mission_controller_2020", 51882 + 1517 + 51)
	h4_deaths = locals.get_int("fm_mission_controller_2020", 51882 + 1517 + 36 + 1)
	h4_bag_size = math.floor(locals.get_float("fm_mission_controller_2020", 60496 + (1 + (0 * 261)) + 236 + 2) / SYSTEM.TO_FLOAT(tunables.get_int(1859395035)) * 100.0)
	h4_grabbed_cash = format_int(locals.get_int("fm_mission_controller_2020", 51882 + 1517 + 53))
	if view_objectives and not HUD.IS_HUD_COMPONENT_ACTIVE(19) then
		render_elite_objectives()
	end
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

elite_objectives_tab:add_imgui(function()
	selected_heist = ImGui.Combo("Select Heist", selected_heist, { "OG Heists", "Doomsday Heist", "Diamond Casino Heist", "Cayo Perico Heist" }, 4)
	view_objectives = ImGui.Checkbox("View Objectives", view_objectives)
end)