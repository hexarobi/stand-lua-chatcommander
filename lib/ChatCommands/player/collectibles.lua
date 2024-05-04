-- Collectibles

local cc_utils = require("chat_commander/utils")

return {
    command="collectibles",
    additional_commands={"givecollectibles", "collectables"},
    outbound_command="givecollectibles",
    outbound_command_requires_player_name=true,
    outbound_command_message="Attempting to give all collectibles (this will only work once per session)",
    group="player",
    help="Gives all available collectibles",
}
