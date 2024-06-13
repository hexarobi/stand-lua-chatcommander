-- ChatCommander
-- by Hexarobi

local SCRIPT_VERSION = "0.17.1"

---
--- Auto Updater
---

local auto_update_config = {
    source_url="https://raw.githubusercontent.com/hexarobi/stand-lua-chatcommander/main/ChatCommander.lua",
    script_relpath=SCRIPT_RELPATH,
    project_url="https://github.com/hexarobi/stand-lua-chatcommander",
    branch="main",
    dependencies={
        "lib/chat_commander/config.lua",
        "lib/chat_commander/constants.lua",
        "lib/chat_commander/item_browser.lua",
        "lib/chat_commander/user_database.lua",
        "lib/chat_commander/utils.lua",
        "lib/chat_commander/vehicle_utils.lua",
        "lib/file_database.lua",
        -- ChatCommands
        "lib/ChatCommands/other/event.lua",
        "lib/ChatCommands/other/kick.lua",
        "lib/ChatCommands/other/newlobby.lua",
        "lib/ChatCommands/other/ping.lua",
        "lib/ChatCommands/other/roulette.lua",
        "lib/ChatCommands/other/blackjack.lua",
        -- Player
        "lib/ChatCommands/player/allguns.lua",
        "lib/ChatCommands/player/ammo.lua",
        "lib/ChatCommands/player/autoheal.lua",
        "lib/ChatCommands/player/bail.lua",
        "lib/ChatCommands/player/casino.lua",
        "lib/ChatCommands/player/ceopay.lua",
        "lib/ChatCommands/player/cleanup.lua",
        "lib/ChatCommands/player/collectibles.lua",
        "lib/ChatCommands/player/escape.lua",
        "lib/ChatCommands/player/levelup.lua",
        "lib/ChatCommands/player/parachute.lua",
        "lib/ChatCommands/player/stuntjump.lua",
        "lib/ChatCommands/player/teleport.lua",
        "lib/ChatCommands/player/unstick.lua",
        "lib/ChatCommands/player/vip.lua",
        "lib/ChatCommands/player/wanted.lua",
        -- Vehicles
        "lib/ChatCommands/vehicle/copy.lua",
        "lib/ChatCommands/vehicle/deletevehicle.lua",
        "lib/ChatCommands/vehicle/fast.lua",
        "lib/ChatCommands/vehicle/fav.lua",
        "lib/ChatCommands/vehicle/gift.lua",
        "lib/ChatCommands/vehicle/headlights.lua",
        "lib/ChatCommands/vehicle/horn.lua",
        "lib/ChatCommands/vehicle/livery.lua",
        "lib/ChatCommands/vehicle/mods.lua",
        "lib/ChatCommands/vehicle/modsmax.lua",
        "lib/ChatCommands/vehicle/neonlights.lua",
        "lib/ChatCommands/vehicle/paint.lua",
        "lib/ChatCommands/vehicle/plate.lua",
        "lib/ChatCommands/vehicle/platetype.lua",
        "lib/ChatCommands/vehicle/repair.lua",
        "lib/ChatCommands/vehicle/shuffle.lua",
        "lib/ChatCommands/vehicle/spawn.lua",
        "lib/ChatCommands/vehicle/tires.lua",
        "lib/ChatCommands/vehicle/tiresmoke.lua",
        "lib/ChatCommands/vehicle/tune.lua",
        "lib/ChatCommands/vehicle/wash.lua",
        "lib/ChatCommands/vehicle/wheelcolor.lua",
        "lib/ChatCommands/vehicle/wheels.lua",
        "lib/ChatCommands/vehicle/windowtint.lua",
    },
}

-- If loading from Stand repository, then rely on it for updates and skip auto-updater
local is_from_repository = false

util.ensure_package_is_installed('lua/auto-updater')
local auto_updater = require('auto-updater')
if auto_updater == true and not is_from_repository then
    auto_updater.run_auto_update(auto_update_config)
end

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
local preferences = {
    blessed_players={},
    passthrough_commands={},
}

---
--- Dependencies
---

local constants = require("chat_commander/constants")
local utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local config = require("chat_commander/config")
local item_browser = require("chat_commander/item_browser")
local user_db = require("chat_commander/user_database")

util.ensure_package_is_installed('lua/inspect')
local inspect = require("inspect")

util.require_natives("3095a")

-- Constructor lib is required for some commands, so install it from repo if its not already
util.ensure_package_is_installed('lua/Constructor')

local debug_log = utils.debug_log

local function error_msg(msg)
    util.toast("Error: "..msg, TOAST_ALL)
end

---
--- Preferences
---

local PREFS_FOLDER = filesystem.resources_dir().."ChatCommander"
filesystem.mkdirs(PREFS_FOLDER)
local PREFS_FILE = PREFS_FOLDER.."/preferences.json"

local function clean_prefs(real_preferences)
    local cleaned_prefs = {}
    for key, value in real_preferences do
        if type(value) == "table" then
            cleaned_prefs[key] = clean_prefs(value)
        elseif type(value) == "string" or type(value) == "number" or type(value) == "boolean" then
            cleaned_prefs[key] = value
        else
            debug_log("Skipped saving preference "..key.." due to invalid type")
        end
    end
    return cleaned_prefs
end

local function apply_default_preferences(prefs)
    if prefs.blessed_players == nil then prefs.blessed_players = {} end
    if prefs.passthrough_commands == nil then prefs.passthrough_commands = {} end
end

local function save_prefs()
    local file = io.open(PREFS_FILE, "wb")
    if file == nil then util.toast("Error opening file for writing: "..PREFS_FILE, TOAST_ALL) return end
    local cleaned_prefs = clean_prefs(preferences)
    local encoded_prefs = soup.json.encode(cleaned_prefs)
    if not encoded_prefs or encoded_prefs == "" then
        util.toast("Failed to encode preferences")
    else
        file:write(encoded_prefs)
    end
    file:close()
end

local function load_prefs()
    local file = io.open(PREFS_FILE)
    if file then
        local prefs_raw = file:read()
        file:close()
        if prefs_raw == nil then prefs_raw = "{}" end
        preferences = soup.json.decode(prefs_raw)
        --status, preferences = pcall(soup.json.decode, prefs_raw)
        --if not status and type(preferences) == "string" then
        --    preferences = DEFAULT_PREFERENCES
        --end
        --util.toast("Loaded prefs file "..inspect(preferences), TOAST_ALL)
    else
        save_prefs()
        --util.toast("Created new prefs file "..inspect(PREFS_FILE), TOAST_ALL)
    end
    apply_default_preferences(preferences)
    config.blessed_players = preferences.blessed_players
    return preferences
end

load_prefs()

local function add_blessed_player(player_name)
    if player_name == "" then return end
    util.toast("Adding blessed player "..inspect(player_name), TOAST_ALL)
    for _, player in preferences.blessed_players do
        if player == player_name then
            util.toast("Player already blessed")
            return
        end
    end
    table.insert(preferences.blessed_players, player_name)
end

local function save_user_command(pid, command)
    local user_data = user_db.load_user(pid)
    if user_data.command_counters[command] == nil then user_data.command_counters[command] = 0 end
    user_data.command_counters[command] = user_data.command_counters[command] + 1
    user_db.save_user(pid, user_data)
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
    return command
end

cc.refresh_commands_from_files = function(directory, path)
    if path == nil then path = "" end
    for _, filepath in ipairs(filesystem.list_files(directory)) do
        if filesystem.is_dir(filepath) then
            local _2, dirname = string.match(filepath, "(.-)([^\\/]-%.?)$")
            cc.refresh_commands_from_files(filepath, path.."/"..dirname)
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
    -- If authorized_for isn't set at all, then default all to on
    if chat_command.authorized_for == nil then
        chat_command.authorized_for = {
            me = true,
            friends = true,
            everyone = true,
            blessed = true,
        }
    end
    -- If authorized_for is set, but certain keys are not, then default missing keys to off
    if chat_command.authorized_for.me == nil then chat_command.authorized_for.me = false end
    if chat_command.authorized_for.friends == nil then chat_command.authorized_for.friends = false end
    if chat_command.authorized_for.everyone == nil then chat_command.authorized_for.everyone = false end
    if chat_command.authorized_for.blessed == nil then chat_command.authorized_for.blessed = false end
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


cc.is_user_allowed_to_issue_chat_command = function(pid, commands, chat_command)
    local rockstar_id = players.get_rockstar_id(pid)
    if user_command_log[rockstar_id] == nil then user_command_log[rockstar_id] = {} end

    local new_user_log = build_new_user_log(user_command_log[rockstar_id])
    if #new_user_log > (config.user_max_commands_per_time) and
            not (pid == players.user() and config.is_player_allowed_to_bypass_commands_limit) then
        utils.help_message(pid, "Please slow down your commands.")
        return false
    end

    if not utils.is_player_authorized(pid) then
        debug_log("User not authorized "..pid)
        return false
    end

    if not utils.is_player_authorized_for_chat_command(pid, chat_command) then
        debug_log("User not authorized for command "..pid.." "..chat_command.command)
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
    if config.disable_builtin_chat_commands ~= true then return end
    for _, builtin_chat_commands_path in pairs(builtin_chat_commands_paths) do
        local command_ref = menu.ref_by_path(builtin_chat_commands_path)
        if command_ref.value then
            util.toast("Disabling built-in chat command option: "..builtin_chat_commands_path, TOAST_ALL)
            command_ref.value = false
        end
    end
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
    PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 201, 1)
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

local function force_rig_blackjack()
    local rig_blackjack_menu = menu.ref_by_path("Online>Quick Progress>Casino>Always Win Blackjack")
    if menu.is_ref_valid(rig_blackjack_menu) then
        if not rig_blackjack_menu.value then
            rig_blackjack_menu.value = true
        end
    else
        util.toast("Failed to get command ref to rig blackjack", TOAST_ALL)
    end
end

local function afk_casino_tick()
    if not config.afk_in_casino then return end
    if not utils.is_player_in_casino(players.user()) then
        enter_casino()
    else
        force_roulette_area()
        force_rig_roulette()
        force_rig_blackjack()
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
--- Announcements
---

local announcements = {
    {
        name="Basic Commands",
        messages={
            "Chat commands are now enabled for you! Spawn any vehicle with !name (Ex: !deluxo !op2 !raiju) "..
            "Keep them with !gift Lose cops with !bail Heal with !autoheal Teleport with !tp Get RP with !levelup "..
            "Get more help with !help"
        },
    },
    {
        name="Casino Money",
        messages={"For anyone that wants money, casino roulette is now rigged to always land on 1. Max bet and win 330k per spin. Blackjack is also rigged. For VIP access say !vip For more details say !roulette or !blackjack"},
        validator=function()
            return config.afk_mode and utils.is_player_in_casino(players.user())
        end
    },
    {
        name="How to Gift",
        messages={
            "To keep spawned cars, start with a basic 10 car garage (!tp giftgarage) and fill it with any free car from phone, return your personal vehicle to garage, then use !gift",
        }
    }
}

local function announce(announcement)
    if not announcement.is_enabled then return end
    if announcement.validator and type(announcement.validator) == "function" then
        if not announcement.validator() then
            --util.toast("Skipping invalid announcement: "..announcement.name)
            return
        end
    end
    if state.next_announcement_time ~= nil and (util.current_time_millis() < state.next_announcement_time) then
        util.toast("Skipping flood delayed announcement: "..announcement.name)
        return
    end
    state.next_announcement_time = util.current_time_millis() + config.announce_flood_delay
    announcement.next_announcement_time = util.current_time_millis() + (config.announce_delay * 60000)
    for _, message in pairs(announcement.messages) do
        chat.send_message(utils.replace_command_character(message), false, true, true)
        util.yield(config.announce_flood_delay)
    end
end

local function announcement_tick()
    if not config.is_auto_announcement_enabled then return end
    if state.next_announcement_tick_time == nil or util.current_time_millis() > state.next_announcement_tick_time then
        state.next_announcement_tick_time = util.current_time_millis() + config.announcement_tick_handler_delay
        for _, announcement in pairs(announcements) do
            if announcement.next_announcement_time == nil or util.current_time_millis() > announcement.next_announcement_time then
                announce(announcement)
            end
        end
    end
end

-- Init announcement delay
for _, announcement in pairs(announcements) do
    announcement.next_announcement_time = util.current_time_millis() + (config.announce_delay * 60000)
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

local function execute_chat_command(pid, commands, chat_command)
    if cc.is_user_allowed_to_issue_chat_command(pid, commands, chat_command) then
        --debug_log("Executing chat command function "..chat_command.name)
        save_user_command(pid, commands[1])
        return chat_command.execute(pid, commands, chat_command)
    end
end

chat.on_message(function(pid, reserved, message_text, is_team_chat, networked, is_auto)
    if is_auto then return end
    if utils.str_starts_with(message_text, utils.get_chat_control_character()) then
        --debug_log("Heard command: "..message_text)
        local commands = utils.strsplit(message_text:lower():sub(2))
        --debug_log("Command Keyword: "..tostring(commands[1]))
        cc.log_user_command(pid, commands)
        --debug_log("Checking against chat commands: "..inspect(cc.chat_commands))]
        for _, chat_command in cc.chat_commands do
            --debug_log("Checking chat command function "..chat_command.name)
            cc.attach_execute_to_passthrough_command(chat_command)
            if chat_command.is_enabled ~= false and is_command_matched(commands, chat_command) and chat_command.execute then
                execute_chat_command(pid, commands, chat_command)
                return
            end
        end
        -- Default command if no others apply
        if config.default_chat_command then
            table.insert(commands, 1, config.default_chat_command.command)
            if execute_chat_command(pid, commands, config.default_chat_command) then
                return
            end
        end
        if config.reply_to_unknown_commands then
            utils.help_message(pid, "Invalid command. Try !help")
        end
    end
end)

---
--- Load Chat Commands From Files
---

cc.refresh_commands_from_files(filesystem.scripts_dir()..config.chat_command_scripts_dir)
debug_log("Loaded "..cc.count_chat_commands().." chat commands")

if config.default_chat_command_name then
    config.default_chat_command = cc.find_chat_command(config.default_chat_command_name)
end
--debug_log("Default chat commands: "..inspect(config.default_chat_command))

---
--- PassThrough Commands
---

--local passthrough_commands = {
--    {
--        command="sprunk",
--        help="Spawns a sprunkified vehicle and some cans",
--        outbound_command_requires_player_name=true,
--        outbound_command="sprunk",
--    },
--    {
--        command="sprunkify",
--        help="Paints car green and more",
--        outbound_command_requires_player_name=true,
--        outbound_command="sprunkify",
--    },
--    {
--        command="sprunkrain",
--        help="Spawns some sprunk cans",
--        outbound_command_requires_player_name=true,
--        outbound_command="sprunkrain",
--    },
--    {
--        command="trivia",
--        help="Starts a game of trivia",
--        outbound_command="trivia",
--    },
--    {
--        command="casinotp",
--        additional_commands={"casino"},
--        outbound_command="casinotp",
--        outbound_command_requires_player_name=true,
--    },
--    {
--        command="collectibles",
--        additional_commands={"givecollectibles"},
--        outbound_command="givecollectibles",
--        outbound_command_requires_player_name=true,
--    },
--}

---
--- PassThrough Commands Handler
---

cc.add_passthrough_command = function(passthrough_command)
    if type(passthrough_command) ~= "table" then
        passthrough_command = {command=passthrough_command}
    end
    if passthrough_command.group == nil then
        passthrough_command.group = "other"
    end
    passthrough_command.override_action_command = "ccpassthrough"..passthrough_command.command  -- Prefix pass through commands for uniqueness to avoid loop
    cc.expand_chat_command_defaults(passthrough_command, passthrough_command.command, "ccpassthrough")
    return cc.add_chat_command(passthrough_command)
end

cc.attach_execute_to_passthrough_command = function(passthrough_command)
    if passthrough_command.outbound_command ~= nil and passthrough_command.execute == nil then
        passthrough_command.execute = function(pid, commands)
            if passthrough_command.outbound_command_message then
                utils.help_message(pid, passthrough_command.outbound_command_message)
            end
            local command_string = (passthrough_command.outbound_command or passthrough_command.command)
            if pid ~= players.user() or passthrough_command.outbound_command_requires_player_name then
                command_string = command_string .. " " .. players.get_name(pid)
            end
            if commands and commands[2] ~= nil then
                command_string = command_string .. " " .. commands[2]
            end
            debug_log("Triggering passthrough command: "..command_string)
            menu.trigger_commands(command_string)
        end
    end
end

cc.refresh_passthrough_commands = function()
    for _, passthrough_command in preferences.passthrough_commands do
        cc.add_passthrough_command(passthrough_command)
    end
end

cc.refresh_passthrough_commands()

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

cc.add_construct_passthrough_command = function(passthrough_command)
    passthrough_command.group="constructs"
    return cc.add_passthrough_command(passthrough_command)
end

cc.refresh_construct_passthrough_commands = function()
    for _, spawnable_name in pairs(load_all_spawnable_names_from_dir(SPAWNABLE_DIR)) do
        cc.add_construct_passthrough_command(
            {
                command=spawnable_name,
                help="Spawn a "..spawnable_name,
                outbound_command=spawnable_name,
                outbound_command_requires_player_name=true,
            }
        )
    end
end

cc.refresh_construct_passthrough_commands()

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

local function get_unique_menu_id()
    --- Used for generating unique menu input command names
    if state.menu_counter == nil then state.menu_counter = 0 end
    state.menu_counter = state.menu_counter + 1
    return state.menu_counter
end

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
    if chat_command.menu ~= nil then
        return root_menu:link(chat_command.menu)
    end
    chat_command.menu = root_menu:list(chat_command.name, {}, get_menu_action_help(chat_command))
    chat_command.menu:divider(chat_command.name)
    chat_command.menu:action("Run", {chat_command.override_action_command or chat_command.name}, "Immediately trigger this command for yourself. Ignores all restrictions.", function(click_type, pid)
        if chat_command.execute ~= nil then
            return chat_command.execute(pid, {chat_command.name}, chat_command)
        end
    end)
    chat_command.menu:action("Help", {}, "Immediately trigger the help option for this command.", function(click_type, pid)
        if chat_command.help ~= nil then
            return utils.help_message(pid, chat_command.help)
        end
    end)
    if chat_command.is_enabled == nil then chat_command.is_enabled = true end
    chat_command.menu:toggle("Enabled", {}, "Is this command currently active and usable by other players", function(toggle)
        chat_command.is_enabled = toggle
    end, chat_command.is_enabled)

    chat_command.authorized_for_menu = chat_command.menu:list("Special Authorization For", {}, "To use this command a user must have general authorization, and be in at least one specially authorized group.")
    chat_command.authorized_for_menu:toggle("Me", {}, "Yourself", function(toggle)
        chat_command.authorized_for.me = toggle
    end, chat_command.authorized_for.me)
    chat_command.authorized_for_menu:toggle("Friends", {}, "People on your friends list", function(toggle)
        chat_command.authorized_for.friends = toggle
    end, chat_command.authorized_for.friends)
    chat_command.authorized_for_menu:toggle("Everyone", {}, "Everyone in the lobby", function(toggle)
        chat_command.authorized_for.everyone = toggle
    end, chat_command.authorized_for.everyone)
    chat_command.authorized_for_menu:toggle("Blessed", {}, "Players on your Blessed Players list", function(toggle)
        chat_command.authorized_for.blessed = toggle
    end, chat_command.authorized_for.blessed)

    if chat_command.config_menu ~= nil then
        chat_command.menu:divider("Config")
        chat_command.config_menu(chat_command.menu)
    end
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
        {name="Chat Commands", items=build_chat_command_items(), description="Browsable list of all chat commands you have installed"},
        add_chat_command_to_menu
    )
end

---
--- Menu
---

menus.root = menu.my_root()

---
--- Chat Commands Menu
---

add_chat_command_menus()

---
--- Passthrough Menu
---

menus.passthrough_commands = menu.my_root():list("Passthrough Commands", {}, "Allow other stand commands to be triggered via chat commands")
menus.add_passthrough_command = menus.passthrough_commands:text_input("Add Command", {"ccpassthruadd"}, "Add a new passthrough chat command. This can then be configured to trigger another existing Stand command.", function(value)
    local passthrough_command = cc.add_passthrough_command(value)
    cc.add_passthrough_command_menu(passthrough_command)
    table.insert(preferences.passthrough_commands, passthrough_command)
    save_prefs()
    menus.add_passthrough_command.value = ""
end, "")

cc.add_passthrough_command_menu = function(passthrough_command)
    local menu_id = get_unique_menu_id()
    passthrough_command.passthrough_menu = menus.passthrough_commands:list(passthrough_command.command or "unknown", {}, "")
    passthrough_command.passthrough_menu:text_input("Inbound Command", { "ccpassthruinbound"..menu_id}, "The chat command that triggers this action", function(value)
        passthrough_command.command = value
        save_prefs()
    end, passthrough_command.command or "")
    passthrough_command.passthrough_menu:text_input("Outbound Command", { "ccpassthruoutbound"..menu_id}, "The stand command that should be triggered by this action", function(value)
        passthrough_command.outbound_command = value
        save_prefs()
    end, passthrough_command.outbound_command or "")
    passthrough_command.passthrough_menu:text_input("Help Text", { "ccpassthruhelp"..menu_id}, "The help text for this action", function(value)
        passthrough_command.help = value
        save_prefs()
    end, passthrough_command.help or "")
    --passthrough_command.menu:text_input("Group", {"ccpassthrugroup"..menu_id}, "The group for this command. Default: other", function(value)
    --    passthrough_command.group = value
    --    save_prefs()
    --end, passthrough_command.group or "other")
    passthrough_command.passthrough_menu:toggle("Requires Player Name", {}, "Some Stand commands are player-specific. Check this box to automatically include the name of the player that issued the command.", function(value)
        passthrough_command.outbound_command_requires_player_name = value
        save_prefs()
    end, passthrough_command.outbound_command_requires_player_name)
    passthrough_command.passthrough_menu:action("Delete", {}, "Delete this passthrough command", function()
        cc.delete_passthrough_command(passthrough_command)
        save_prefs()
        menus.add_passthrough_command:focus()
    end)
    for _, main_menu_item in menu.get_children(passthrough_command.menu) do
        menu.link(passthrough_command.passthrough_menu, main_menu_item)
    end
end

cc.delete_passthrough_command = function(deleted_command)
    for key, passthrough_command in preferences.passthrough_commands do
        if passthrough_command.command == deleted_command.command then
            debug_log("Deleting passthrough command "..deleted_command.command)
            preferences.passthrough_commands[key] = nil
            if passthrough_command.menu:isValid() then
                menu.delete(passthrough_command.menu)
            end
        end
    end
end

cc.build_passthrough_menus = function()
    for _, passthrough_command in preferences.passthrough_commands do
        cc.add_passthrough_command_menu(passthrough_command)
    end
end
cc.build_passthrough_menus()

---
--- Announcements Menu
---

menus.announcements = menu.my_root():list("Announcements", {}, "Announcements system for letting others know about commands")
menus.announcements:action("Announce All", {"announce"}, "Immediately broadcast all relevant announcements", function()
    for _, announcement in ipairs(announcements) do
        announcement.next_announcement_time = nil
        announce(announcement)
    end
end)
menus.announcements:toggle("Auto-Announcements", {}, "Automatically broadcast relevant announcements on a repeating schedule.", function(toggle)
    config.is_auto_announcement_enabled = toggle
end, config.is_auto_announcement_enabled)
menus.announcements:slider("Announce Delay", {}, "Set the time interval for when announce will be triggered, in minutes", 30, 120, config.announce_delay, 15, function(value)
    config.announce_delay = value
end)

menus.announcements:divider("Announcements")
for index, announcement in ipairs(announcements) do
    local menu_list = menus.announcements:list(announcement.name, {}, "")
    menu.action(menu_list, "Announce", {}, "Broadcast this announcement to the lobby", function()
        announcement.next_announcement_time = nil
        announce(announcement)
    end)
    if announcement.is_enabled == nil then announcement.is_enabled = true end
    menu.toggle(menu_list, "Enabled", {}, "If enabled, announcement will be repeated everytime the delay expires.", function(toggle)
        announcement.is_enabled = toggle
    end, announcement.is_enabled)
    if announcement.delay == nil then announcement.delay = config.announce_delay end
    --menu.slider(menu_list, "Delay", {}, "Time between repeats of this announcement, in minutes.", 15, 120, announcement.delay, 15, function(value)
    --    announcement.delay = value
    --end)
    for message_index, message in ipairs(announcement.messages) do
        menu.text_input(menu_list, "Message "..message_index, {"hexascripteditannouncement_"..index.."_"..message_index}, "Edit announcement content", function(value)
            announcement.messages[message_index] = value
        end, message)
    end
    --menu.readonly(menu_list, "Last Announced", announcement.last_announced or "Never")
end

---
--- Blessed Players
---

state.blessed_player_menus = {}
local function build_blessed_players_menu()
    utils.delete_menu_list(state.blessed_player_menus)
    for index, player in preferences.blessed_players do
        local player_menu = menus.blessed_players:list(player)
        player_menu:action("Remove", {}, "Removes the player from your blessed players list", function()
            for index2, blessed_player in preferences.blessed_players do
                if blessed_player == player then
                    preferences.blessed_players[index] = nil
                    save_prefs()
                    build_blessed_players_menu()
                end
            end
        end)
        table.insert(state.blessed_player_menus, player_menu)
    end
end

menus.blessed_players = menus.root:list("Blessed Players", {}, "Blessed players have elevated permissions for certain commands")
menus.add_blessed_player_by_name = menus.blessed_players:text_input("Add Player by Name", {"ccblessplayer"}, "Add a player to your blessed players list", function(player)
    add_blessed_player(player)
    save_prefs()
    build_blessed_players_menu()
    menus.add_blessed_player_by_name.value = ""
end, "")
menus.add_blessed_player_from_lobby_list = menus.blessed_players:list("Add Player from Lobby", {}, "Add a player to your blessed players list", function(player)
    -- Delete old menu items
    for _, old_menu_item in menu.get_children(menus.add_blessed_player_from_lobby_list) do
        if old_menu_item:isValid() then menu.delete(old_menu_item) end
    end
    menu.collect_garbage()
    -- Rebuild new menu items
    for _, pid in players.list(false) do
        local player_name = players.get_name(pid)
        menus.add_blessed_player_from_lobby_list:action(player_name, {}, "", function()
            menu.trigger_commands("ccblessplayer "..player_name)
            menus.add_blessed_player_from_lobby_list:focus()
        end)
    end
end)
menus.blessed_players:divider("Blessed Players")
build_blessed_players_menu()

---
--- AFK Options
---

menus.afk_options = menus.root:list("AFK Mode", {}, "Configuration options for AFK mode")
menus.afk_options:toggle("AFK Mode Enabled", {"afk"}, "When enabled, will attempt to keep you in an active lobby.", function(toggle)
    config.afk_mode = toggle
end, config.afk_mode)
menus.afk_options:list_select("AFK Lobby Type", {}, "When in AFK mode and alone in a lobby, what type of lobby should you switch to.", constants.lobby_modes, config.lobby_mode_index, function(index)
    config.lobby_mode_index = index
end)
menus.afk_options:toggle("AFK in Casino", {}, "Keep roulette rigged for others while AFK.", function(toggle)
    config.afk_in_casino = toggle
end, config.afk_in_casino)
menus.afk_options:slider("Min Players in Lobby", {}, "If in AFK mode, will try to stay in a lobby with at least this many players.", 0, 30, config.min_num_players, 1, function(val)
    config.min_num_players = val
end, config.min_num_players)

---
--- Settings Menu
---

menus.settings = menu.my_root():list("Settings", {}, "Additional configuration options")

menus.authorized_for = menus.settings:list("General Authorization For", {}, "To use any command a user must have general authorization. This can optionally be further restricted on each command with special authorization.")
menus.authorized_for:toggle("Me", {}, "Yourself", function(toggle)
    config.authorized_for.me = toggle
end, config.authorized_for.me)
menus.authorized_for:toggle("Friends", {}, "People on your friends list", function(toggle)
    config.authorized_for.friends = toggle
end, config.authorized_for.friends)
menus.authorized_for:toggle("Everyone", {}, "Everyone in the lobby", function(toggle)
    config.authorized_for.everyone = toggle
end, config.authorized_for.everyone)
menus.authorized_for:toggle("Blessed", {}, "Players on your Blessed Players list", function(toggle)
    config.authorized_for.blessed = toggle
end, config.authorized_for.blessed)

menus.settings:list_select("Chat Control Character", {}, "Set the character that chat commands must begin with", constants.control_characters, config.chat_control_character_index, function(index)
    config.chat_control_character_index = index
end)
menus.settings:toggle("Disable Built-In Chat Commands", {}, "Stands built-in chat commands conflict with ChatCommander so they are normally disabled at startup.", function(toggle)
    config.disable_builtin_chat_commands = toggle
end, config.disable_builtin_chat_commands)
menus.settings:toggle("Auto-Spectate Far Away Players", {}, "If enabled, you will automatically spectate players who issue commands from far away. Without this far away players will get an error when issuing commands.", function(toggle)
    config.auto_spectate_far_away_players = toggle
end, config.auto_spectate_far_away_players)
menus.settings:slider("Num Spawns Allowed Per Player", {}, "The maximum number of vehicle spawns allowed per player. Once this number is reached, additional spawns will delete the oldest spawned vehicle.", 0, 5, config.num_allowed_spawned_vehicles_per_player, 1, function(value)
    config.num_allowed_spawned_vehicles_per_player = value
end)

menus.settings:divider("Replies")

menus.settings:list_select("Reply Prefix", {}, "Set the character that your replies will begin with", constants.reply_characters, config.reply_prefix_index, function(index)
    config.reply_prefix_index = index
end)
menus.settings:toggle("Reply to Unknown Commands", {}, "Unknown commands will return a warning reply, instead of just silence", function(toggle)
    config.reply_to_unknown_commands = toggle
end, config.reply_to_unknown_commands)
menus.settings:toggle("Reply Visible to All", {}, "Make replies visible to everyone instead of just to the player that entered the command", function(toggle)
    config.reply_visible_to_all = toggle
end, config.reply_visible_to_all)

---
--- About Menu
---

local script_meta_menu = menu.my_root():list("About ChatCommander", {}, "Information about the script itself")
script_meta_menu:divider("ChatCommander")
script_meta_menu:readonly("Version", SCRIPT_VERSION)
if auto_update_config and auto_updater then
    script_meta_menu:action("Check for Update", {}, "The script will automatically check for updates at most daily, but you can manually check using this option anytime.", function()
        auto_update_config.check_interval = 0
        if auto_updater.run_auto_update(auto_update_config) then
            util.toast("No updates found")
        end
    end)
end
script_meta_menu:hyperlink("Github Source", "https://github.com/hexarobi/stand-lua-chatcommander", "View source files on Github")
script_meta_menu:hyperlink("Discord", "https://discord.gg/RF4N7cKz", "Open Discord Server")

---
--- Post-Menu Startup
---

util.yield()
disable_builtin_chat_commands()

---
--- Tick Handlers
---

util.create_tick_handler(afk_mode_tick)
util.create_tick_handler(vehicle_utils.delete_old_vehicles_tick)
util.create_tick_handler(announcement_tick)
