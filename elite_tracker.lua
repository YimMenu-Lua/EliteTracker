local elite_tracker_tab    = gui.get_tab("Elite Tracker")
local elite_objectives_tab = elite_tracker_tab:add_tab("Elite Objectives")

local HEIST_TYPES = {
	OG_HEISTS      = 0,
	DOOMSDAY_HEIST = 1,
	CASINO_HEIST   = 2,
	PERICO_HEIST   = 3
}

local global_one              = 4718592
local global_one_offset       = 127178
local global_two              = 2684504
local global_three            = 2685444
local global_three_offset_one = 6489
local global_three_offset_two = 6487

local mission_controller_local_one                        = 19746
local mission_controller_local_two                        = 28365
local mission_controller_local_three                      = 28365
local mission_controller_2020_local_one                   = 53558
local mission_controller_2020_local_two                   = 50150
local mission_controller_2020_local_two_offset_one        = 1495
local mission_controller_2020_local_two_offset_two        = 1492
local mission_controller_2020_local_three                 = 62290
local mission_controller_2020_local_three_offset_one_size = 275
local mission_controller_2020_local_three_offset_two      = 237

local selected_heist  = HEIST_TYPES.OG_HEISTS
local view_objectives = false

local has_quick_restarted = 0
local elite_time          = 0
local has_failed_hack     = 0
local kills               = 0
local headshots           = 0
local deaths              = 0
local vehicle_damage      = 0
local rashkovsky_damage   = 0
local noose_called        = 0
local h4_elite_time       = 0
local h4_has_failed_hack  = 0
local h4_deaths           = 0
local h4_bag_size         = 0
local h4_grabbed_cash     = 0
local h4_elite            = false
local og_elites           = {}
local h2_elites           = {}
local ch_elites           = {}

local function has_bit_set(address, pos)
    return (address & (1 << pos)) ~= 0
end

local function format_int(number)
    local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
    int = int:reverse():gsub("(%d%d%d)", "%1,")
    return minus .. int:reverse():gsub("^,", "") .. fraction
end

local function format_milliseconds(ms)
    local total_seconds = math.floor(ms / 1000)
    local hours         = math.floor(total_seconds / 3600)
    local minutes       = math.floor((total_seconds % 3600) / 60)
    local seconds       = total_seconds % 60
    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function add_text_component_long_string(text)
    local max_str_component_length = 99
    for i = 1, #text, max_str_component_length do
        local str_comp = string.sub(text, i, i + max_str_component_length - 1)
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(str_comp)
    end
end

local function get_net_difference(timeb)
    if NETWORK.NETWORK_IS_GAME_IN_PROGRESS() then
        return NETWORK.GET_TIME_DIFFERENCE(NETWORK.GET_NETWORK_TIME(), timeb)
    end
    return NETWORK.GET_TIME_DIFFERENCE(MISC.GET_GAME_TIMER(), timeb)
end

local function draw_text(text)
    HUD.BEGIN_TEXT_COMMAND_DISPLAY_TEXT(string.len(text) < 99 and "STRING" or "jamyfafi")
    if string.len(text) < 99 then
        HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    else
        add_text_component_long_string(text)
    end
    HUD.SET_TEXT_RENDER_ID(1)
    HUD.SET_TEXT_OUTLINE()
    HUD.SET_TEXT_WRAP(0.0, 0.975)
    HUD.SET_TEXT_RIGHT_JUSTIFY(true)
    HUD.SET_TEXT_SCALE(0, 0.5)
    HUD.SET_TEXT_FONT(4)
    HUD.SET_TEXT_COLOUR(255, 255, 255, 240)
    HUD.END_TEXT_COMMAND_DISPLAY_TEXT(0.0, 0.2, 0)
end

local function og_is_active()
    local root_content_ids = {
        tunables.get_int("ROOT_ID_HASH_THE_FLECCA_JOB"),
        tunables.get_int("ROOT_ID_HASH_THE_PRISON_BREAK"),
        tunables.get_int("ROOT_ID_HASH_THE_HUMANE_LABS_RAID"),
        tunables.get_int("ROOT_ID_HASH_SERIES_A_FUNDING"),
        tunables.get_int("ROOT_ID_HASH_THE_PACIFIC_STANDARD_JOB")
    }
    for _, id in ipairs(root_content_ids) do
        if globals.get_int(global_one + global_one_offset) == id then
            return true
        end
    end
    return false	
end

local function h2_is_active()
    for i = 0, 15 do
        if globals.get_int(global_one + global_one_offset) == tunables.get_int("FHM_FLOW_ROOTCONTENT_ID_" .. i) then
            return true
        end
    end
    return false
end

local function ch_is_active()
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
    for _, id in ipairs(root_content_ids) do
        if globals.get_int(global_one + global_one_offset) == id then
            return true
        end
    end
    return false
end

local function h4_is_active()
    for i = 0, 10 do
        if globals.get_int(global_one + global_one_offset) == tunables.get_int("H4_ROOT_CONTENT_ID_" .. i) then
            return true
        end
    end
    return false
end

local function get_mission_time()
    local mission_time = get_net_difference(locals.get_int("fm_mission_controller", mission_controller_local_one + 985))
    if mission_time <= 0 then
        mission_time = get_net_difference(locals.get_int("fm_mission_controller", mission_controller_local_one + 985))
    end
    mission_time = mission_time + 10000
    if globals.get_int(global_two + 43 + 55) or globals.get_int(global_two + 43 + 56) then
        mission_time = mission_time + globals.get_int(global_three + global_three_offset_one)
    end
    return mission_time
end

local function h4_get_mission_time()
    local mission_time = 0
    if globals.get_int(global_two + 43 + 55) or globals.get_int(global_two + 43 + 56) then
        mission_time = locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_one + 1517 + 29)
        if locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_two + mission_controller_2020_local_two_offset_one) <= 0 then
            mission_time = mission_time + get_net_difference(locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_two + mission_controller_2020_local_two_offset_two))
        end
    else
        mission_time = locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_two + mission_controller_2020_local_two_offset_one)
        if mission_time <= 0 then
            mission_time = get_net_difference(locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_two + mission_controller_2020_local_two_offset_two))
        end
    end
    mission_time = mission_time + 10000
    return mission_time
end

local function is_elite_timer_paused()
    if selected_heist == HEIST_TYPES.PERICO_HEIST then
        return locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_two + mission_controller_2020_local_two_offset_two) == 0
    else
        return locals.get_int("fm_mission_controller", mission_controller_local_one + 985) == 0
    end
end

local function render_elite_objectives()
    local text = ""
    if selected_heist == HEIST_TYPES.OG_HEISTS then
        if og_is_active() then
            text = string.format(
                "TIME: %s~n~QUICK RESTARTED: %s~n~FAILED HACK: %s~n~DEATHS: %d~n~KILLS: %d~n~VEHICLE DAMAGE: %d%%~n~RASHKOVSKY DAMAGE: %d%%~n~NOOSE CALLED: %s",
                not is_elite_timer_paused() and elite_time or "PAUSED",
                has_quick_restarted ~= 0 and "YES" or "NO",
                has_failed_hack ~= 0 and "YES" or "NO",
                deaths,
                kills,
                vehicle_damage,
                rashkovsky_damage,
                noose_called ~= 0 and "YES" or "NO"
            )
        else
            text = "HEIST IS NOT ACTIVE."
        end
    elseif selected_heist == HEIST_TYPES.DOOMSDAY_HEIST then
        if h2_is_active() then
            text = string.format(
                "TIME: %s~n~QUICK RESTARTED: %s~n~FAILED HACK: %s~n~DEATHS: %d~n~KILLS: %d~n~HEADSHOTS: %d~n~VEHICLE DAMAGE: %d%%",
                not is_elite_timer_paused() and elite_time or "PAUSED",
                has_quick_restarted ~= 0 and "YES" or "NO",
                has_failed_hack ~= 0 and "YES" or "NO",
                deaths,
                kills,
                headshots,
                vehicle_damage
            )
        else
            text = "HEIST IS NOT ACTIVE."
        end
    elseif selected_heist == HEIST_TYPES.CASINO_HEIST then
        if ch_is_active() then
            text = string.format(
                "TIME: %s~n~QUICK RESTARTED: %s~n~FAILED HACK: %s~n~DEATHS: %d~n~HEADSHOTS: %d",
                not is_elite_timer_paused() and elite_time or "PAUSED",
                has_quick_restarted ~= 0 and "YES" or "NO",
                has_failed_hack ~= 0 and "YES" or "NO",
                deaths,
                headshots
            )
        else
            text = "HEIST IS NOT ACTIVE."
        end
    elseif selected_heist == HEIST_TYPES.PERICO_HEIST then
        if h4_is_active() then
            text = string.format(
                "TIME: %s~n~QUICK RESTARTED: %s~n~FAILED HACK: %s~n~DEATHS: %d~n~BAG: $%s (%d%%)",
                not is_elite_timer_paused() and h4_elite_time or "PAUSED",
                has_quick_restarted ~= 0 and "YES" or "NO",
                h4_has_failed_hack ~= 0 and "YES" or "NO",
                h4_deaths,
                h4_grabbed_cash,
                h4_bag_size
            )
        else
            text = "HEIST IS NOT ACTIVE."
        end
    end
    draw_text(text)
end

script.register_looped("Elite Tracker", function()
    og_elites[1]        = stats.get_packed_stat_bool(3765)
    og_elites[2]        = stats.get_packed_stat_bool(3766)
    og_elites[3]        = stats.get_packed_stat_bool(3767)
    og_elites[4]        = stats.get_packed_stat_bool(3768)
    og_elites[5]        = stats.get_packed_stat_bool(3769)
    h2_elites[1]        = stats.get_packed_stat_bool(18116)
    h2_elites[2]        = stats.get_packed_stat_bool(18117)
    h2_elites[3]        = stats.get_packed_stat_bool(18118)
    ch_elites[1]        = stats.get_packed_stat_bool(28194)
    ch_elites[2]        = stats.get_packed_stat_bool(28195)
    ch_elites[3]        = stats.get_packed_stat_bool(28196)
    h4_elite            = stats.get_bool("MPX_AWD_ELITE_THIEF")
	
    has_quick_restarted = globals.get_int(global_three + global_three_offset_two)
    kills               = locals.get_int("fm_mission_controller", mission_controller_local_one + 1725 + 1)
    headshots           = locals.get_int("fm_mission_controller", mission_controller_local_one + 1740 + 1)
    deaths              = locals.get_int("fm_mission_controller", mission_controller_local_one + 1730 + 1)
    has_failed_hack     = locals.get_int("fm_mission_controller", mission_controller_local_two + 3197)
    vehicle_damage      = locals.get_int("fm_mission_controller", mission_controller_local_three + 1231)
    rashkovsky_damage   = locals.get_int("fm_mission_controller", mission_controller_local_three + 1230)
    noose_called        = has_bit_set(locals.get_int("fm_mission_controller", mission_controller_local_one + 3), 11) and 1 or 0
    elite_time          = format_milliseconds(get_mission_time())
	
    h4_has_failed_hack  = locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_one + 1517 + 51)
    h4_deaths           = locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_one + 1517 + 36 + 1)
    h4_bag_size         = math.floor(locals.get_float("fm_mission_controller_2020", mission_controller_2020_local_three + (1 + (0 * mission_controller_2020_local_three_offset_one_size)) + mission_controller_2020_local_three_offset_two + 2) / SYSTEM.TO_FLOAT(tunables.get_int("HEIST_BAG_MAX_CAPACITY")) * 100.0)
    h4_grabbed_cash     = format_int(locals.get_int("fm_mission_controller_2020", mission_controller_2020_local_one + 1517 + 53))
    h4_elite_time       = format_milliseconds(h4_get_mission_time())

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
    selected_heist  = ImGui.Combo("Select Heist", selected_heist, { "OG Heists", "Doomsday Heist", "Diamond Casino Heist", "Cayo Perico Heist" }, 4)
    view_objectives = ImGui.Checkbox("View Objectives", view_objectives)
end)