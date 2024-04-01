-- Bail

local cc_utils = require("chat_commander/utils")

return {
    command="allguns",
    group="player",
    help="Unlock all weapons",
    execute=function(pid, commands)
        menu.trigger_commands("arm" .. players.get_name(pid).."all")
        cc_utils.help_message(pid, "All weapons unlocked")
    end
}
