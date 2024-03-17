-- ChatCommander Config

return {
    debug = true,
    chat_command_scripts_dir="lib/ChatCommands",
    chat_control_character_index=2,
    default_chat_command_name="spawn",
    -- User Command Log
    is_player_allowed_to_bypass_commands_limit = true,
    user_max_commands_per_time = 3,
    user_command_time = 30000,
    -- Spawns
    num_allowed_spawned_vehicles_per_player=1,
    delete_old_vehicles_tick_handler_delay=60000,
    large_vehicles = {
        "kosatka", "jet", "cargoplane", "cargoplane2", "tug", "alkonost", "titan", "volatol", "blimp", "blimp2", "blimp3",
    },
}
