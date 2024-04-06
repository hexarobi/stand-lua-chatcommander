-- Wanted

local cc_utils = require("chat_commander/utils")

return {
    command="wanted",
    group="player",
    help="Set current wanted level: 1 2 3 4 5",
    execute=function(pid, commands)
        local wanted_level = tonumber(commands[2])
        if wanted_level == nil then
            wanted_level = 0
        end
        menu.trigger_commands("pwanted " .. players.get_name(pid) .. " " .. wanted_level)
        cc_utils.help_message(pid, "Set wanted level to " .. wanted_level)
    end
}
