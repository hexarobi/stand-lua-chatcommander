-- Parachute

local cc_utils = require("chat_commander/utils")

return {
    command="parachute",
    group="player",
    help="Get a parachute",
    execute=function(pid, commands)
        menu.trigger_commands("paragive " .. players.get_name(pid))
        cc_utils.help_message(pid, "Added parachute")
    end
}
