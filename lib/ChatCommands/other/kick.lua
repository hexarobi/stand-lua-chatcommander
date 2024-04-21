-- Kick

local cc_utils = require("chat_commander/utils")

return {
    command="kick",
    additional_commands={"bb"},
    help="Activate smart kick on a given user",
    group="other",
    authorized_for={ me=true, blessed=true, },
    execute=function(pid, commands, chat_command)
        cc_utils.help_message(pid, "Attempting to kick player "..commands[2])
        menu.trigger_commands("kick " .. commands[2])
    end
}