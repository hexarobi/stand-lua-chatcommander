-- LevelUp

local cc_utils = require("chat_commander/utils")

local config = {
    limit_levels=true,
}
local active_players = {}

local function add_active_player(pid)
    active_players[players.get_name(pid)] = true
end

local function remove_active_player(pid)
    active_players[players.get_name(pid)] = false
end

local function is_player_active(pid)
    return active_players[players.get_name(pid)] == true
end

return {
    command="levelup",
    additional_commands={"level", "rp"},
    group="player",
    help="Adds RP until you reach target level, default to +10 levels. Max of 120",
    execute=function(pid, commands)
        local start_rank = players.get_rank(pid)
        if commands[2] == "off" or commands[2] == "stop" then
            remove_active_player(pid)
            cc_utils.help_message(pid, "Stopping levelup")
            return
        end
        local target_rank = tonumber(commands[2])
        if target_rank == nil then target_rank = start_rank + 10 end
        if config.limit_levels then
            if target_rank > 120 then target_rank = 120 end
            if start_rank >= 120 then
                cc_utils.help_message(pid, "All level-based unlocks are available at 120. Cannot level you up any further.")
            end
        end
        if start_rank < target_rank then
            cc_utils.help_message(pid, "Attempting to level you up to rank "..target_rank.." To stop say !levelup off")
            add_active_player(pid)
            while (is_player_active(pid)
                    and players.get_rank(pid) ~= nil
                    and players.get_rank(pid) < target_rank) do
                menu.trigger_commands("rp" .. players.get_name(pid))
                util.yield(3000)
            end
            remove_active_player(pid)
        else
            cc_utils.help_message(pid, "You are already above rank "..target_rank)
        end
    end,
    config_menu=function(menu_root)
        menu_root:toggle("Limit to level 120", {}, "", function(value)
            config.limit_levels = value
        end, config.limit_levels)
    end
}
