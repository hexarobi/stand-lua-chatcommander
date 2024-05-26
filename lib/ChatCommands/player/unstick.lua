-- Unstick

local cc_utils = require("chat_commander/utils")

return {
    command="unstick",
    additional_commands={"unstuck"},
    group="player",
    help="Attempts to trigger location loading initialization. Useful when loading into casino etc just spins.",
    execute=function(pid)
        menu.trigger_commands("givesh " .. players.get_name(pid))
        cc_utils.help_message(pid, "Attempting to unstick your location loading screen.")
    end
}
