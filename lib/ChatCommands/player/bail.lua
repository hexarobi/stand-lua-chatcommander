-- Bail

local cc_utils = require("chat_commander/utils")

return {
    command="bail",
    additional_commands={"nocops"},
    group="player",
    help="Remove any wanted levels and keep them off.",
    execute=function(pid, commands)
        local enabled_string = cc_utils.get_on_off_string((commands and commands[2]) or "on")
        menu.trigger_commands("bail " .. players.get_name(pid) .. " " .. enabled_string)
        cc_utils.help_message(pid, "No-Cops " .. enabled_string)
    end
}
