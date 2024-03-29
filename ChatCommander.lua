-- ChatCommander
-- by Hexarobi

local SCRIPT_VERSION = "0.1"

local chat_commander = {
    chat_commands = {},
}

-- Short name
local cc = chat_commander

local menus = {}

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

local function add_chat_commands_from_files(directory, path)
    if path == nil then path = "" end
    for _, filepath in ipairs(filesystem.list_files(directory)) do
        if filesystem.is_dir(filepath) then
            local _, dirname = string.match(filepath, "(.-)([^\\/]-%.?)$")
            add_chat_commands_from_files(filepath, path.."/"..dirname)
        else
            local _, filename, ext = string.match(filepath, "(.-)([^\\/]-%.?)[.]([^%.\\/]*)$")
            if ext == "lua" or ext == "pluto" then
                local command = require(config.chat_command_scripts_dir..path.."/"..filename)
                cc.expand_chat_command_defaults(command, filename, path)
                if cc.chat_commands[filename] ~= nil then
                    util.toast("Error loading chat command: "..path.."/"..filename..": Command name is already taken")
                else
                    cc.chat_commands[filename] = command
                end
            end
        end
    end
end

---
--- Chat Command Defaults
---

cc.expand_chat_command_defaults = function(chat_command, filename, path)
    chat_command.filename = filename
    chat_command.path = path
    if chat_command.name == nil then chat_command.name = chat_command.filename end
    if chat_command.command == nil then chat_command.command = chat_command.name end
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
    debug_log("Tracked command for "..players.get_name(pid).." "..#new_user_log)
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
--- Chat Handler
---

local function is_command_matched(commands, chat_command)
    --debug_log("Checking for '"..tostring(commands[1]).."' in allowed commands: "..inspect(chat_command.allowed_commands))
    if commands[1] == chat_command.command:lower() then
        return true
    end
    if chat_command.command_aliases then
        for _, command_alias in pairs(chat_command.command_aliases) do
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
                utils.debug_log("Default commands: "..inspect(commands))
                if cc.is_user_allowed_to_issue_chat_command(pid, commands) then
                    config.default_chat_command.execute(pid, commands)
                end
            end
        end
    end
end)

---
--- Menus
---

local function get_command_name(chat_command)
    if type(chat_command.command) == "table" then
        return chat_command.command[1]
    else
        return chat_command.command
    end
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
    debug_log("chat_commands_by_group "..inspect(chat_commands_by_group))

    local chat_command_items = {}
    for _, chat_command_group in chat_commands_by_group do
        table.insert(chat_command_items, chat_command_group)
    end
    sort_items_by_name(chat_command_items)
    debug_log("Sorted chat command items "..inspect(chat_command_items))
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
--- On Startup
---

add_chat_commands_from_files(filesystem.scripts_dir()..config.chat_command_scripts_dir)
debug_log("Loaded chat commands: "..inspect(cc.chat_commands))
add_chat_command_menus()

if config.default_chat_command_name then
    config.default_chat_command = cc.find_chat_command(config.default_chat_command_name)
end
--debug_log("Default chat commands: "..inspect(config.default_chat_command))
