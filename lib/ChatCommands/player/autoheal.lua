-- AutoHeal

local cc_utils = require("chat_commander/utils")

return {
    command="autoheal",
    group="player",
    help="Refills health to full several times per second. Does not protect against instant-kills like explosions.",
    execute=function(pid, commands)
        local enabled_string = cc_utils.get_on_off_string((commands and commands[2]) or "on")
        menu.trigger_commands("autoheal " .. players.get_name(pid) .. " " .. enabled_string)
        cc_utils.help_message(pid, "Autoheal " .. enabled_string)
    end
}
