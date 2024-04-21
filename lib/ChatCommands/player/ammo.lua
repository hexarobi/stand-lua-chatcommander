-- Ammo

local cc_utils = require("chat_commander/utils")

return {
    command="ammo",
    group="player",
    help="Add ammo for current weapon",
    execute=function(pid, commands)
        menu.trigger_commands("ammo" .. players.get_name(pid))
        cc_utils.help_message(pid, "Added ammo for current weapon")
    end
}
