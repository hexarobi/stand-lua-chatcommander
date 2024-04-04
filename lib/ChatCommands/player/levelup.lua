-- LevelUp

local cc_utils = require("chat_commander/utils")

local config = {
    limit_levels=true,
}

return {
    command="levelup",
    additional_commands={"level"},
    group="player",
    help="Adds RP until you reach target level, default to +10 levels. Max of 120",
    execute=function(pid, commands)
        local start_rank = players.get_rank(pid)
        local target_rank = tonumber(commands[2])
        if target_rank == nil then target_rank = start_rank + 10 end
        if config.limit_levels then
            if target_rank > 120 then target_rank = 120 end
            if start_rank >= 120 then
                cc_utils.help_message(pid, "All level-based unlocks are available at 120. Cannot level you up any further.")
            end
        end
        if start_rank < target_rank then
            cc_utils.help_message(pid, "Attempting to level you up to rank "..target_rank)
            while (players.get_name(pid) ~= "undiscoveredplayer"
                    and players.get_rank(pid) ~= nil
                    and players.get_rank(pid) < target_rank) do
                menu.trigger_commands("rp" .. players.get_name(pid))
                util.yield(3000)
            end
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
