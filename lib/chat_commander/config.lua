-- ChatCommander Config

return {
    debug = true,
    chat_command_scripts_dir="lib/ChatCommands",
    chat_control_character_index=1,
    auto_spectate_far_away_players = true,
    default_chat_command_name="spawn",
    disable_builtin_chat_commands=true,
    -- User Command Log
    is_player_allowed_to_bypass_commands_limit = false,
    user_max_commands_per_time = 3,
    user_command_time = 30000,
    -- Spawns
    num_allowed_spawned_vehicles_per_player=1,
    delete_old_vehicles_tick_handler_delay=5000,
    large_vehicles = {
        "kosatka", "jet", "cargoplane", "cargoplane2", "tug", "alkonost", "titan", "volatol", "blimp", "blimp2", "blimp3",
    },
    -- AFK
    afk_mode = false,
    afk_in_casino = true,
    afk_tick_handler_delay = 5000,
    lobby_mode_index = 1,
    min_num_players = 3,
    -- Lobby Finder
    fresh_lobby_delay = 600000,
    min_num_players = 3,
    -- Announcements
    announce_delay = 60,
    announce_flood_delay = 5000,
    announcement_tick_handler_delay = 5000,
}
