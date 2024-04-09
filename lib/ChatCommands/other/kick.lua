-- Kick

local cc_utils = require("chat_commander/utils")

return {
    command="kick",
    additional_commands={"bb"},
    help="Activate smart kick on a given user",
    group="other",
    execute=function(pid, commands, chat_command)
        if cc_utils.is_player_blessed(pid) then
            cc_utils.help_message(pid, "Attempting to kick "..commands[2])
            menu.trigger_commands("kick " .. commands[2])
        end
    end
}