-- ChatCommander
-- by Hexarobi

local SCRIPT_VERSION = "0.3"

-- Auto Updater from https://github.com/hexarobi/stand-lua-auto-updater
local status, auto_updater = pcall(require, "auto-updater")
if not status then
    if not async_http.have_access() then
        util.toast("Failed to install auto-updater. Internet access is disabled. To enable automatic updates, please stop the script then uncheck the `Disable Internet Access` option.")
    else
        local auto_update_complete = nil util.toast("Installing auto-updater...", TOAST_ALL)
        async_http.init("raw.githubusercontent.com", "/hexarobi/stand-lua-auto-updater/main/auto-updater.lua",
                function(raw_result, raw_headers, raw_status_code)
                    local function parse_auto_update_result(result, headers, status_code)
                        local error_prefix = "Error downloading auto-updater: "
                        if status_code ~= 200 then util.toast(error_prefix..status_code, TOAST_ALL) return false end
                        if not result or result == "" then util.toast(error_prefix.."Found empty file.", TOAST_ALL) return false end
                        filesystem.mkdir(filesystem.scripts_dir() .. "lib")
                        local file = io.open(filesystem.scripts_dir() .. "lib\\auto-updater.lua", "wb")
                        if file == nil then util.toast(error_prefix.."Could not open file for writing.", TOAST_ALL) return false end
                        file:write(result) file:close() util.toast("Successfully installed auto-updater lib", TOAST_ALL) return true
                    end
                    auto_update_complete = parse_auto_update_result(raw_result, raw_headers, raw_status_code)
                end, function() util.toast("Error downloading auto-updater lib. Update failed to download.", TOAST_ALL) end)
        async_http.dispatch() local i = 1 while (auto_update_complete == nil and i < 40) do util.yield(250) i = i + 1 end
        if auto_update_complete == nil then error("Error downloading auto-updater lib. HTTP Request timeout") end
        auto_updater = require("auto-updater")
    end
end
if auto_updater == true then error("Invalid auto-updater lib. Please delete your Stand/Lua Scripts/lib/auto-updater.lua and try again") end

---
--- Auto Updater
---

local auto_update_config = {
    source_url="https://raw.githubusercontent.com/hexarobi/stand-lua-chatcommander/main/ChatCommander.lua",
    script_relpath=SCRIPT_RELPATH,
    project_url="https://github.com/hexarobi/stand-lua-chatcommander",
}
auto_updater.run_auto_update(auto_update_config)

---
--- Chat Commander Vars
---

local chat_commander = {
    chat_commands = {},
}

-- Short name
local cc = chat_commander

local menus = {}
local state = {}

---
--- Dependencies

local constants = require("chat_commander/constants")
local utils = require("chat_commander/utils")
local config = require("chat_commander/config")
local inspect = require("inspect")
local item_browser = require("chat_commander/item_browser")

util.require_natives("3095a")

local debug_log = utils.debug_log

local function error_msg(msg)
    util.toast("Error: "..msg, TOAST_ALL)
end

---
--- ChatCommands File Loader
---

cc.count_table = function(tbl)
    local count = 0
    for _, item in tbl do
        count = count + 1
    end
    return count
end

cc.count_chat_commands = function()
    return cc.count_table(cc.chat_commands)
end

cc.add_chat_command = function(command)
    cc.expand_chat_command_defaults(command)
    if command.command and cc.chat_commands[command.command] ~= nil then
        util.toast("Error loading chat command: "..command.path.."/"..command.filename..": Command name is already taken")
    else
        cc.chat_commands[command.command] = command
        --debug_log("Added command "..command.command.." #"..cc.get_num_chat_commands())
    end
end

local function add_chat_commands_from_files(directory, path)
    if path == nil then path = "" end
    for _, filepath in ipairs(filesystem.list_files(directory)) do
        if filesystem.is_dir(filepath) then
            local _2, dirname = string.match(filepath, "(.-)([^\\/]-%.?)$")
            add_chat_commands_from_files(filepath, path.."/"..dirname)
        else
            local _3, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
            if ext == "lua" or ext == "pluto" then
                local command = require(config.chat_command_scripts_dir..path.."/"..filename)
                --debug_log("Loading command "..config.chat_command_scripts_dir..path.."/"..filename..": "..inspect(command))
                cc.expand_chat_command_defaults(command, filename, path)
                cc.add_chat_command(command)
            end
        end
    end
end

---
--- Chat Command Defaults
---

cc.expand_chat_command_defaults = function(chat_command, filename, path)
    if chat_command.command == nil then
        util.log("Cannot expand chat command without a command")
        return
    end
    if chat_command.filename == nil then chat_command.filename = filename or chat_command.command end
    if chat_command.path == nil then chat_command.path = path or "unknown" end
    if chat_command.name == nil then chat_command.name = chat_command.filename end
    chat_command.allowed_commands = { chat_command.command }
    if chat_command.additional_commands ~= nil then
        for _, allowed_command in chat_command.additional_commands do
            table.insert(chat_command.allowed_commands, allowed_command)
        end
    end
end

---
--- User Command Log
---

local user_command_log = {}

local function build_new_user_log(commands_log)
    local new_user_log = {}
    local expired_time = util.current_time_millis() - config.user_command_time
    for _, log_item in pairs(commands_log) do
        if log_item.time > expired_time then
            table.insert(new_user_log, log_item)
        end
    end
    return new_user_log
end

cc.log_user_command = function(pid, commands)
    local new_log_item = {
        time=util.current_time_millis(),
        commands=commands
    }
    local rockstar_id = players.get_rockstar_id(pid)
    if user_command_log[rockstar_id] == nil then user_command_log[rockstar_id] = {} end
    local new_user_log = build_new_user_log(user_command_log[rockstar_id])
    table.insert(new_user_log, new_log_item)
    user_command_log[rockstar_id] = new_user_log
    --debug_log("Tracked command for "..players.get_name(pid).." "..#new_user_log)
end

cc.is_user_allowed_to_issue_chat_command = function(pid, commands)
    local rockstar_id = players.get_rockstar_id(pid)
    if user_command_log[rockstar_id] == nil then user_command_log[rockstar_id] = {} end

    local new_user_log = build_new_user_log(user_command_log[rockstar_id])
    if #new_user_log > (config.user_max_commands_per_time) and
            not (pid == players.user() and config.is_player_allowed_to_bypass_commands_limit) then
        utils.help_message(pid, "Please slow down your commands.")
        return false
    end

    return true
end

---
--- Disable Built-In Chat Commands
---

local builtin_chat_commands_paths = {
    "Online>Chat>Commands>For Strangers>Enabled",
    "Online>Chat>Commands>For Team Chat>Enabled",
    "Online>Chat>Commands>For Crew Members>Enabled",
    "Online>Chat>Commands>For Friends>Enabled",
    "Online>Chat>Commands>Enabled For Me",
}

local function disable_builtin_chat_commands()
    for _, builtin_chat_commands_path in pairs(builtin_chat_commands_paths) do
        local command_ref = menu.ref_by_path(builtin_chat_commands_path)
        if command_ref.value then
            util.toast("Disabling built-in chat command option: "..builtin_chat_commands_path, TOAST_ALL)
            command_ref.value = false
        end
    end
end

if config.disable_builtin_chat_commands then
    disable_builtin_chat_commands()
end

---
--- Lobby Finder
---

local function is_lobby_empty()
    local players_list = players.list()
    local num_players = #players_list
    return num_players < config.min_num_players
end

local function should_find_new_lobby()
    if not NETWORK.NETWORK_IS_SESSION_STARTED() then
        return true
    end
    if util.current_time_millis() < state.lobby_created_at + config.fresh_lobby_delay then
        return false
    end
    return is_lobby_empty()
end

local function find_new_lobby()
    state.lobby_created_at = util.current_time_millis()
    util.toast("Finding new lobby...", TOAST_ALL)
    -- Enter key to dismiss any game alerts
    PAD.SET_CONTROL_VALUE_NEXT_FRAME(0, 201, 1)
    menu.trigger_commands(constants.lobby_mode_commands[config.lobby_mode_index][2])
end
state.lobby_created_at = util.current_time_millis()

local function enter_casino()
    if NETWORK.NETWORK_IS_SESSION_STARTED() then
        menu.trigger_commands("casinotp " .. players.get_name(players.user()))
    end
end

---
--- AFK Mode
---

local function force_mc()
    local org_type = players.get_org_type(players.user())
    if org_type == -1 then
        menu.trigger_commands("mcstart")
    elseif org_type == 0 then
        menu.trigger_commands("ceotomc")
    end
end

local function force_org()
    local org_type = players.get_org_type(players.user())
    if org_type == -1 then
        menu.trigger_commands("ceostart")
    elseif org_type == 1 then
        menu.trigger_commands("mctoceo")
    end
end

local function force_roulette_area()
    if not utils.is_player_within_dimensions(players.user(), {min={x=1130,y=240,z=-55},max={x=1150,y=270,z=-45}}) then
        ENTITY.SET_ENTITY_COORDS(players.user_ped(), 1138.828, 256.55817, -51.035732)
    end
end

local function force_rig_roulette()
    local rig_roulette_menu = menu.ref_by_path("Online>Quick Progress>Casino>Roulette Outcome")
    if menu.is_ref_valid(rig_roulette_menu) then
        if rig_roulette_menu.value ~= 1 then
            rig_roulette_menu.value = 1
        end
    else
        util.toast("Failed to get command ref to rig roulette", TOAST_ALL)
    end
end

local function afk_casino_tick()
    if not config.afk_in_casino then return end
    if not utils.is_player_in_casino(players.user()) then
        enter_casino()
    else
        force_roulette_area()
        force_rig_roulette()
        --util.request_script_host("casinoroulette")
    end
end

local function afk_mode_tick()
    if config.afk_mode then
        if state.next_afk_tick_time == nil or util.current_time_millis() > state.next_afk_tick_time then
            state.next_afk_tick_time = util.current_time_millis() + config.afk_tick_handler_delay
            force_mc()
            if should_find_new_lobby() then
                find_new_lobby()
            else
                afk_casino_tick()
            end
        end
    end
    return true
end

---
--- Chat Handler
---

local function is_command_matched(commands, chat_command)
    --debug_log("Checking for '"..tostring(commands[1]).."' in allowed commands: "..inspect(chat_command.allowed_commands))
    if commands[1] == chat_command.command:lower() then
        return true
    end
    if chat_command.allowed_commands then
        for _, command_alias in pairs(chat_command.allowed_commands) do
            if commands[1] == command_alias:lower() then
                return true
            end
        end
    end
    return false
end

cc.find_chat_command = function(raw_command)
    for _, chat_command in cc.chat_commands do
        if chat_command.command == raw_command:lower() then
            return chat_command
        end
    end
end

chat.on_message(function(pid, reserved, message_text, is_team_chat, networked, is_auto)
    if is_auto then return end
    if utils.str_starts_with(message_text, utils.get_chat_control_character()) then
        --debug_log("Heard command: "..message_text)
        local commands = utils.strsplit(message_text:lower():sub(2))
        --debug_log("Command Keyword: "..tostring(commands[1]))
        cc.log_user_command(pid, commands)
        if cc.is_user_allowed_to_issue_chat_command(pid, commands) then
            --debug_log("Checking against chat commands: "..inspect(cc.chat_commands))
            for _, chat_command in cc.chat_commands do
                --debug_log("Checking chat command function "..chat_command.name)
                if chat_command.is_enabled ~= false and is_command_matched(commands, chat_command) and chat_command.execute then
                    --debug_log("Calling chat command function "..chat_command.name)
                    chat_command.execute(pid, commands, chat_command)
                    --log_user_command(pid, chat_command)
                    return
                end
            end
            -- Default command if no others apply
            if config.default_chat_command then
                table.insert(commands, 1, config.default_chat_command.command)
                --utils.debug_log("Default commands: "..inspect(commands))
                if cc.is_user_allowed_to_issue_chat_command(pid, commands) then
                    config.default_chat_command.execute(pid, commands)
                end
            end
        end
    end
end)

---
--- Load Chat Commands From Files
---

add_chat_commands_from_files(filesystem.scripts_dir()..config.chat_command_scripts_dir)
debug_log("Loaded "..cc.count_chat_commands().." chat commands")

if config.default_chat_command_name then
    config.default_chat_command = cc.find_chat_command(config.default_chat_command_name)
end
--debug_log("Default chat commands: "..inspect(config.default_chat_command))

---
--- PassThrough Commands
---

local passthrough_commands = {
    {
        command="sprunk",
        help="Spawns a sprunkified vehicle and some cans",
        requires_player_name=true,
    },
    "sprunkify",
    "sprunkrain",
    "trivia",
    {
        command="casinotp",
        additional_commands={"casino"},
        outbound_command="casinotp",
        requires_player_name=true,
    },
    {
        command="collectibles",
        additional_commands={"givecollectibles"},
        outbound_command="givecollectibles",
        requires_player_name=true,
    },

}

---
--- Constructor Spawnable Constructs Passthrough Commands
---

local CONSTRUCTS_DIR = filesystem.stand_dir() .. 'Constructs\\'
local SPAWNABLE_DIR = CONSTRUCTS_DIR.."spawnable"

local function load_spawnable_names_from_dir(directory)
    local spawnable_names = {}
    for _, filepath in ipairs(filesystem.list_files(directory)) do
        if not filesystem.is_dir(filepath) then
            local index, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
            table.insert(spawnable_names, filename)
        end
    end
    return spawnable_names
end

local function load_all_spawnable_names_from_dir(directory)
    if not filesystem.exists(directory) then return {} end
    local spawnable_names = load_spawnable_names_from_dir(directory)
    for _, filepath in ipairs(filesystem.list_files(directory)) do
        if filesystem.is_dir(filepath) then
            for index, construct_plan_file in pairs(load_all_spawnable_names_from_dir(filepath)) do
                table.insert(spawnable_names, construct_plan_file)
            end
        end
    end
    return spawnable_names
end

local spawnable_names = load_all_spawnable_names_from_dir(SPAWNABLE_DIR)
for _, spawnable_name in pairs(spawnable_names) do
    table.insert(
        passthrough_commands,
        {
            command=spawnable_name,
            group="constructs",
            help="Spawn a "..spawnable_name,
            outbound_command=spawnable_name,
            requires_player_name=true,
        }
    )
end

---
--- PassThrough Commands Handler
---

for _, passthrough_command in passthrough_commands do
    if type(passthrough_command) ~= "table" then
        passthrough_command = {command=passthrough_command}
    end
    if passthrough_command.group == nil then
        passthrough_command.group = "other"
    end
    passthrough_command.override_action_command = "passthrough"..passthrough_command.command  -- Prefix pass through commands for uniqueness to avoid loop
    passthrough_command.execute = function(pid, commands)
        local command_string = (passthrough_command.outbound_command or passthrough_command.command)
        if pid ~= players.user() or passthrough_command.requires_player_name then
            command_string = command_string .. " " .. players.get_name(pid)
        end
        if commands and commands[2] ~= nil then
            command_string = command_string .. " " .. commands[2]
        end
        menu.trigger_commands(command_string)
    end
    cc.expand_chat_command_defaults(passthrough_command, passthrough_command.command, "passthrough")
    cc.add_chat_command(passthrough_command)
end

---
--- Help
---

cc.add_chat_command({
    command="help",
    additional_commands={"commands"},
    group="other",
    help={
        "Welcome! Please don't grief others. For help with a specific command (or group) say !help <command>",
        --"!spawn any vehicle by its name Ex: !deluxo !op2",
        --"To keep cars, first fill a 10-car garage up with free cars, then use !gift",
        --"More commands: !unstick !tpme !autoheal !bail !allguns !tp !repair !cleanup !paint !mods !wheels !shuffle !tune !fast",
    },
    execute=function(pid, commands, this_chat_command)
        local groups = {}
        local group_commands = {}
        if type(commands) == "table" then
            for _, chat_command in cc.chat_commands do
                if commands[2] == chat_command.command then
                    utils.help_message(pid, chat_command.help)
                    return
                elseif commands[2] == chat_command.group then
                    table.insert(group_commands, chat_command.command)
                end
                if not utils.is_in(chat_command.group, groups) then
                    table.insert(groups, chat_command.group)
                end
            end
        end
        if cc.count_table(group_commands) > 0 then
            utils.help_message(pid, commands[2]:upper().." commands: "..table.concat(group_commands, " "))
            return
        end
        -- Help's help message
        utils.help_message(pid, this_chat_command.help)
        utils.help_message(pid, "Command Groups: "..table.concat(groups, " "))
    end,
})

---
--- Chat Command Menu Functions
---

local function get_menu_action_help(chat_command_options)
    if chat_command_options.help == nil then
        return ""
    end
    if (type(chat_command_options.help) == "table") then
        return chat_command_options.help[1]
    end
    return chat_command_options.help
end

local function add_chat_command_to_menu(root_menu, chat_command)
    chat_command.menu = root_menu:list(chat_command.name, {}, get_menu_action_help(chat_command))
    chat_command.menu:divider(chat_command.name)
    chat_command.menu:action("Run", {chat_command.override_action_command or chat_command.name}, get_menu_action_help(chat_command), function(click_type, pid)
        if chat_command.func ~= nil then
            return chat_command.func(pid, {chat_command.name}, chat_command)
        end
    end)
    chat_command.menu:action("Help", {}, get_menu_action_help(chat_command), function(click_type, pid)
        if chat_command.help ~= nil then
            return utils.help_message(pid, chat_command.help)
        end
    end)
    --menu.list_select(menu_list, "Allowed", {}, "", config.allowed_options, chat_command.allowed, function(index)
    --    chat_command.allowed = index
    --end)
    if chat_command.is_enabled == nil then chat_command.is_enabled = true end
    chat_command.menu:toggle("Enabled", {}, "Is this command currently active and usable by other players", function(toggle)
        chat_command.is_enabled = toggle
    end, chat_command.is_enabled)
    return chat_command.menu
end

local function sort_items_by_name(items)
    table.sort(items, function(a, b)
        if a.name:lower() ~= b.name:lower() then
            return a.name:lower() < b.name:lower()
        end
    end)
    for _, item in items do
        if item.items ~= nil then
            sort_items_by_name(item.items)
        end
    end
end

local function build_chat_command_items()
    local chat_commands_by_group = {}
    for _, chat_command in cc.chat_commands do
        if chat_command.group == nil then chat_command.group = "ungrouped" end
        if chat_commands_by_group[chat_command.group] == nil then
            chat_commands_by_group[chat_command.group] = {
                name=chat_command.group,
                items={},
            }
        end
        table.insert(chat_commands_by_group[chat_command.group].items, chat_command)
    end
    --debug_log("chat_commands_by_group "..inspect(chat_commands_by_group))

    local chat_command_items = {}
    for _, chat_command_group in chat_commands_by_group do
        table.insert(chat_command_items, chat_command_group)
    end
    sort_items_by_name(chat_command_items)
    --debug_log("Sorted chat command items "..inspect(chat_command_items))
    return chat_command_items
end

local function add_chat_command_menus()
    item_browser.browse_item(
        menu.my_root(),
        {name="Chat Commands", items=build_chat_command_items()},
        add_chat_command_to_menu
    )
end

---
--- Menu
---

menu.toggle(menu.my_root(), "AFK Mode", {"afk"}, "When enabled, will attempt to keep you in an active lobby.", function(toggle)
    config.afk_mode = toggle
end, config.afk_mode)


---
--- Chat Commands Menu

add_chat_command_menus()

---
--- Settings Menu
---

menus.settings = menu.my_root():list("Settings")
menus.settings:list_select("Chat Control Character", {}, "Set the character that chat commands must begin with", constants.control_characters, config.chat_control_character_index, function(index)
    config.chat_control_character_index = index
end)
menus.settings:toggle("Disable Built-In Chat Commands", {}, "Stands built-in chat commands conflict with ChatCommander so they are normally disabled at startup.", function(toggle)
    config.disable_builtin_chat_commands = toggle
end, config.disable_builtin_chat_commands)
--menu.toggle(menu_options, "Allow by Default", {}, "Any commands with the `Default` op.", function(toggle)
--    config.allow_by_default = toggle
--end, config.allow_by_default)
menus.settings:toggle("Auto-Spectate Far Away Players", {}, "If enabled, you will automatically spectate players who issue commands from far away. Without this far away players will get an error when issuing commands.", function(toggle)
    config.auto_spectate_far_away_players = toggle
end, config.auto_spectate_far_away_players)
menus.settings:slider("Num Spawns Allowed Per Player", {}, "The maximum number of vehicle spawns allowed per player. Once this number is reached, additional spawns will delete the oldest spawned vehicle.", 0, 5, config.num_allowed_spawned_vehicles_per_player, 1, function(value)
    config.num_allowed_spawned_vehicles_per_player = value
end)
--menus.options_allowed_vehicles = menus.settings:list("Allowed Large Vehicles", {}, "Certain large vehicles are blocked by default to prevent lobby spam, but can be allowed here")
--if state.allowed_large_vehicles == nil then state.allowed_large_vehicles = {} end
--for _, large_vehicle in pairs(config.large_vehicles) do
--    menu.toggle(menus.options_allowed_vehicles, large_vehicle, {}, "", function(toggle)
--        state.allowed_large_vehicles[large_vehicle] = toggle
--    end, state.allowed_large_vehicles[large_vehicle])
--end

menus.settings:divider("AFK Options")
menus.settings:list_select("AFK Lobby Type", {}, "When in AFK mode and alone in a lobby, what type of lobby should you switch to.", constants.lobby_modes, config.lobby_mode_index, function(index)
    config.lobby_mode_index = index
end)
menus.settings:toggle("AFK in Casino", {}, "Keep roulette rigged for others while AFK.", function(toggle)
    config.afk_in_casino = toggle
end, config.afk_in_casino)
menus.settings:slider("Min Players in Lobby", {}, "If in AFK mode, will try to stay in a lobby with at least this many players.", 0, 30, config.min_num_players, 1, function(val)
    config.min_num_players = val
end, config.min_num_players)
menus.settings:divider("Announcement Options")
menus.settings:toggle("Auto-Announcements", {}, "While enabled announcements about available options will be sent to lobby chat on a regular cadence.", function(toggle)
    config.is_auto_announcement_enabled = toggle
end, config.is_auto_announcement_enabled)
menus.settings:slider("Announce Delay", {}, "Set the time interval for when announce will be triggered, in minutes", 30, 120, config.announce_delay, 15, function(value)
    config.announce_delay = value
end)


---
--- About Menu
---

local script_meta_menu = menu.my_root():list("About ChatCommander")
script_meta_menu:divider("ChatCommander")
script_meta_menu:readonly("Version", SCRIPT_VERSION)
--script_meta_menu:list_select("Release Branch", {}, "Switch from main to dev to get cutting edge updates, but also potentially more bugs.", AUTO_UPDATE_BRANCHES, SELECTED_BRANCH_INDEX, function(index, menu_name, previous_option, click_type)
--    if click_type ~= 0 then return end
--    auto_update_config.switch_to_branch = AUTO_UPDATE_BRANCHES[index][1]
--    auto_update_config.check_interval = 0
--    auto_updater.run_auto_update(auto_update_config)
--end)
--script_meta_menu:action("Check for Update", {}, "The script will automatically check for updates at most daily, but you can manually check using this option anytime.", function()
--    auto_update_config.check_interval = 0
--    if auto_updater.run_auto_update(auto_update_config) then
--        util.toast("No updates found")
--    end
--end)
script_meta_menu:hyperlink("Github Source", "https://github.com/hexarobi/stand-lua-chatcommander", "View source files on Github")
script_meta_menu:hyperlink("Discord", "https://discord.gg/RF4N7cKz", "Open Discord Server")

---
--- Tick Handlers
---

util.create_tick_handler(afk_mode_tick)
