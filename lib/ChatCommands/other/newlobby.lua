-- NewLobby

local cc_utils = require("chat_commander/utils")

return {
    command="newlobby",
    help="Send host to a new lobby",
    group="other",
    authorized_for={ me=true, blessed=true, },
    execute=function(pid, commands, chat_command)
        cc_utils.help_message(pid, "Sending to new lobby...")
        util.toast("Sending to new lobby. Triggered by "..players.get_name(pid), TOAST_ALL)
        menu.trigger_commands("gosolopub")
    end
}