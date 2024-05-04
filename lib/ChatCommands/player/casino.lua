-- Casino Teleport

local cc_utils = require("chat_commander/utils")

return {
    command="casino",
    additional_commands={"casinotp"},
    outbound_command="casinotp",
    outbound_command_requires_player_name=true,
    outbound_command_message="Teleporting to Casino",
    group="player",
    help="Teleports player into casino",
}
