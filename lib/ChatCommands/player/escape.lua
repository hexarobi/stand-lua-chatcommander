-- Escape

local cc_utils = require("chat_commander/utils")

return {
    command="escape",
    additional_commands={"tpme"},
    group="player",
    help="Teleport to nearby apartment. Good for force resetting your character when stuck somewhere on the map.",
    execute=function(pid)
        menu.trigger_commands("aptme " .. players.get_name(pid))
    end
}
