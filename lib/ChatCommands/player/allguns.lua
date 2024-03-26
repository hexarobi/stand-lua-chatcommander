-- AllGuns

local cc_utils = require("chat_commander/utils")

return {
    command="allguns",
    group="player",
    help="Adds the full armament of weapons to your player. Most will go away after a restart.",
    execute=function(pid)
        menu.trigger_commands("arm" .. players.get_name(pid).."all")
        cc_utils.help_message(pid, "All guns acquired")
    end
}
