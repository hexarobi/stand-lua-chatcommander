-- ChatCommander Vehicle Utils

local vehicle_utils = {}

local constants = require("chat_commander/constants")
local cc_utils = require("chat_commander/utils")
local config = require("chat_commander/config")
local inspect = require("inspect")

local function show_busyspinner(text)
    HUD.BEGIN_TEXT_COMMAND_BUSYSPINNER_ON("STRING")
    HUD.ADD_TEXT_COMPONENT_SUBSTRING_PLAYER_NAME(text)
    HUD.END_TEXT_COMMAND_BUSYSPINNER_ON(2)
end

-- From Jackz Vehicle Options script
-- Gets the player's vehicle, attempts to request control. Returns 0 if unable to get control
vehicle_utils.get_player_vehicle_in_control = function(pid, opts)
    if not opts then opts = {} end
    local my_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()) -- Needed to turn off spectating while getting control
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)

    -- Calculate how far away from target
    local pos1 = ENTITY.GET_ENTITY_COORDS(target_ped)
    local pos2 = ENTITY.GET_ENTITY_COORDS(my_ped)
    local dist = SYSTEM.VDIST2(pos1.x, pos1.y, 0, pos2.x, pos2.y, 0)

    local was_spectating = NETWORK.NETWORK_IS_IN_SPECTATOR_MODE() -- Needed to toggle it back on if currently spectating
    -- If they out of range (value may need tweaking), auto spectate.
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, true)
    if opts and opts.near_only and vehicle == 0 then
        return 0
    end
    if vehicle == 0 and target_ped ~= my_ped and dist > 740000 and not was_spectating then
        if not config.auto_spectate_far_away_players then
            cc_utils.help_message(pid, "Sorry you are too far away right now, please try again later")
            return
        end
        util.toast("Player is too far, auto-spectating for upto 3s.")
        show_busyspinner("Player is too far, auto-spectating for upto 3s.")
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(true, target_ped)
        -- To prevent a hard 3s loop, we keep waiting upto 3s or until vehicle is acquired
        local loop = (opts and opts.loops ~= nil) and opts.loops or 30 -- 3000 / 100
        while vehicle == 0 and loop > 0 do
            util.yield(100)
            vehicle = PED.GET_VEHICLE_PED_IS_IN(target_ped, true)
            loop = loop - 1
        end
        HUD.BUSYSPINNER_OFF()
    end

    if vehicle > 0 and opts.no_control ~= false then
        if NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(vehicle) then
            return vehicle
        end
        -- Loop until we get control
        local netid = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(vehicle)
        local has_control_ent = false
        local loops = 15
        NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netid, true)

        -- Attempts 15 times, with 8ms per attempt
        while not has_control_ent do
            has_control_ent = NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
            loops = loops - 1
            -- wait for control
            util.yield(15)
            if loops <= 0 then
                break
            end
        end
    end

    if not was_spectating then
        NETWORK.NETWORK_SET_IN_SPECTATOR_MODE(false, target_ped)
    end
    return vehicle
end

---
--- Request Control
---

vehicle_utils.request_control_once = function(entity)
    if not NETWORK.NETWORK_IS_IN_SESSION() then
        return true
    end
    local netId = NETWORK.NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
    NETWORK.SET_NETWORK_ID_CAN_MIGRATE(netId, true)
    return NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
end

vehicle_utils.request_control = function(entity, timeout)
    if not ENTITY.DOES_ENTITY_EXIST(entity) then
        return false
    end
    local end_time = util.current_time_millis() + (timeout or 500)
    repeat util.yield_once() until vehicle_utils.request_control_once(entity) or util.current_time_millis() >= end_time
    return vehicle_utils.request_control_once(entity)
end

---
--- Teleport
---

vehicle_utils.teleport_vehicle_to_coords = function(vehicle, position)
    vehicle_utils.request_control(vehicle)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, true)
    ENTITY.FREEZE_ENTITY_POSITION(vehicle, false)
    ENTITY.SET_ENTITY_COORDS(vehicle, position.x, position.y, position.z)
    if position.h ~= nil then
        ENTITY.SET_ENTITY_HEADING(vehicle, position.h)
    end
end

---
--- Spawn Vehicle
---

vehicle_utils.spawn_shuffled_vehicle_for_player = function(pid, vehicle_model_name)
    --cc_utils.debug_log("Spawning vehicle "..vehicle_model_name)
    -- If vehicle model is nil or empty, or is a group name, then get a random vehicle model
    local new_vehicle_model_name = vehicle_utils.get_random_vehicle_model(vehicle_model_name)
    if new_vehicle_model_name then
        vehicle_model_name = new_vehicle_model_name
    end
    -- If vehicle model is an alias, get the real model name
    vehicle_model_name = vehicle_utils.apply_vehicle_model_name_shortcuts(vehicle_model_name)
    -- Validate user is allowed to spawn this vehicle
    if vehicle_utils.is_user_allowed_to_spawn_vehicle(pid, vehicle_model_name) then
        local vehicle = vehicle_utils.spawn_vehicle_for_player(pid, vehicle_model_name)
        if vehicle then
            vehicle_utils.set_all_mods_to_random(vehicle)
            vehicle_utils.randomize_livery(vehicle)
            vehicle_utils.set_performance_tuning_max(vehicle)
            vehicle_utils.set_plate_for_player(vehicle, pid)
            -- Assume deathbike is spawned for selling, so max its mods
            if string.find(vehicle_model_name, "deathbike") then
                vehicle_utils.set_all_mods_to_max(vehicle)
            end
            return vehicle
        end
    end
end

local players_spawned_vehicles = {}

local function get_player_spawned_vehicles(pid)
    for _, player_spawned_vehicles in pairs(players_spawned_vehicles) do
        if player_spawned_vehicles.pid == pid then
            return player_spawned_vehicles
        end
    end
    local new_player_spawned_vehicles = {pid=pid, vehicles={}}
    table.insert(players_spawned_vehicles, new_player_spawned_vehicles)
    return new_player_spawned_vehicles
end

local next_delete_old_vehicles_tick_time = util.current_time_millis() + config.delete_old_vehicles_tick_handler_delay
vehicle_utils.delete_old_vehicles_tick = function()
    if util.current_time_millis() > next_delete_old_vehicles_tick_time then
        next_delete_old_vehicles_tick_time = util.current_time_millis() + config.delete_old_vehicles_tick_handler_delay
        for _, player_spawned_vehicles in pairs(players_spawned_vehicles) do
            cc_utils.array_remove(player_spawned_vehicles.vehicles, function(t, i)
                local player_spawned_vehicle = t[i]
                if player_spawned_vehicle.is_deletable then
                    if player_spawned_vehicle.delete_counter == nil then player_spawned_vehicle.delete_counter = 0 end
                    if ENTITY.DOES_ENTITY_EXIST(player_spawned_vehicle.handle) then
                        entities.delete_by_handle(player_spawned_vehicle.handle)
                        player_spawned_vehicle.delete_counter = 0
                    else
                        player_spawned_vehicle.delete_counter = player_spawned_vehicle.delete_counter + 1
                    end
                    if player_spawned_vehicle.delete_counter > 5 then
                        return false
                    end
                end
                return true
            end)
        end
    end
end

vehicle_utils.despawn_for_player = function(pid)
    local player_spawned_vehicles = get_player_spawned_vehicles(pid)
    for index, player_spawned_vehicle in ipairs(cc_utils.array_reverse(player_spawned_vehicles.vehicles)) do
        if index >= config.num_allowed_spawned_vehicles_per_player then
            player_spawned_vehicle.is_deletable = true
        end
    end
end

vehicle_utils.spawn_for_player = function(pid, vehicle)
    local player_spawned_vehicles = get_player_spawned_vehicles(pid)
    table.insert(player_spawned_vehicles.vehicles, {handle=vehicle})
end

vehicle_utils.spawn_vehicle_for_player = function(pid, model_name, offset)
    if model_name == nil then return nil end
    local model = util.joaat(model_name)
    if STREAMING.IS_MODEL_VALID(model) and STREAMING.IS_MODEL_A_VEHICLE(model) then
        vehicle_utils.despawn_for_player(pid)
        vehicle_utils.load_hash(model)
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        if offset == nil then offset = {x=0, y=5.5, z=0.5} end
        local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(target_ped, offset.x, offset.y, offset.z)
        local heading = ENTITY.GET_ENTITY_HEADING(target_ped)
        local vehicle = entities.create_vehicle(model, pos, heading)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(model)
        vehicle_utils.spawn_for_player(pid, vehicle)
        cc_utils.help_message(pid, "Spawning "..model_name)
        return vehicle
    end
end

vehicle_utils.load_hash = function(hash)
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        util.yield()
    end
end

vehicle_utils.is_user_allowed_to_spawn_vehicle = function(pid, vehicle_model_name)
    local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if config.is_player_allowed_to_bypass_spawn_locations and target_ped == players.user_ped() then   -- The host user can spawn anything anywhere
        return true
    end
    --if cc_utils.is_in(vehicle_model_name, config.large_vehicles) and config.allowed_large_vehicles[vehicle_model_name] ~= true then
    --    return false
    --end
    if cc_utils.is_in(vehicle_model_name, config.airfield_only_spawns) then
        if not cc_utils.is_player_on_airfield(pid) then
            cc_utils.help_message(pid, "Cannot spawn vehicle outside of airport")
            return false
        end
    end
    if cc_utils.is_player_in_casino(pid) then
        return false
    end
    return true
end

--vehicle_utils.is_vehicle_allowed_at_position = function(pid, vehicle_model_name)
--    if cc_utils.is_in(vehicle_model_name, config.airfield_only_spawns) then
--        return utils.is_player_on_airfield(pid)
--    end
--    return true
--end

--- Vehicle Serialize / Deserialize

vehicle_utils.serialize_vehicle = function(vehicle)
    local car_data = {}

    return car_data
end

---
--- Random Vehicles
---

local function build_random_vehicles()
    local blocked_random_vehicles = {
        "kosatka", "cargoplane", "cargoplane2", "blimp", "blimp2", "blimp3", "alkonost",
        "armytrailer", "armytrailer2", "baletrailer", "boattrailer", "boattrailer2", "boattrailer3", "docktrailer",
        "freighttrailer", "graintrailer", "proptrailer", "raketrailer", "trailerlarge", "trailerlogs",
        "trailers", "trailers2", "trailers3", "trailers4", "trailers5", "trailersmall", "trailersmall2", "tvtrailer", "tvtrailer2",
        "coach",
    }
    vehicle_utils.random_vehicles = {
        all={},
        boat={},
        plane={},
        helicopter={},
        motorcycle={},
        cycle={},
        train={},
        car={},
    }
    for _, vehicle in util.get_vehicles() do
        if not cc_utils.is_in(vehicle, blocked_random_vehicles) then
            table.insert(vehicle_utils.random_vehicles.all, vehicle.name)
            if vehicle.class == util.joaat("plane") then
                table.insert(vehicle_utils.random_vehicles.plane, vehicle.name)
            elseif vehicle.class == util.joaat("helicopter") then
                table.insert(vehicle_utils.random_vehicles.helicopter, vehicle.name)
            elseif vehicle.class == util.joaat("boat") then
                table.insert(vehicle_utils.random_vehicles.boat, vehicle.name)
            elseif vehicle.class == util.joaat("motorcycle") then
                table.insert(vehicle_utils.random_vehicles.motorcycle, vehicle.name)
            elseif vehicle.class == util.joaat("cycle") then
                table.insert(vehicle_utils.random_vehicles.cycle, vehicle.name)
            elseif vehicle.class == util.joaat("rail") then
                table.insert(vehicle_utils.random_vehicles.train, vehicle.name)
            else
                table.insert(vehicle_utils.random_vehicles.car, vehicle.name)
            end
        end
    end
end
build_random_vehicles()
--cc_utils.debug_log("Random vehicles: "..inspect(vehicle_utils.random_vehicles))

vehicle_utils.get_random_vehicle_model = function(category)
    if category == nil or category == "" then category = "car" end
    local vehicle_list = vehicle_utils.random_vehicles[category]
    if vehicle_list ~= nil then
        local vehicle = vehicle_list[math.random(#vehicle_list)]
        return vehicle
    end
end

vehicle_utils.apply_vehicle_model_name_shortcuts = function(vehicle_model_name)
    if constants.spawn_aliases[vehicle_model_name] then
        return constants.spawn_aliases[vehicle_model_name]
    end
    return vehicle_model_name
end

---
--- Vehicle Paint
---

vehicle_utils.get_vehicle_color_from_command = function(command)
    for _, vehicle_color in pairs(constants.VEHICLE_COLORS) do
        if vehicle_color.index == tonumber(command) or vehicle_color.name:lower() == command then
            return vehicle_color
        end
    end
end

vehicle_utils.set_extra_color = function(vehicle, pearl_color, wheel_color)
    local current_pearl_color = memory.alloc(8)
    local current_wheel_color = memory.alloc(8)
    VEHICLE.GET_VEHICLE_EXTRA_COLOURS(vehicle, current_pearl_color, current_wheel_color)
    pearl_color = vehicle_utils.get_vehicle_color_from_command(pearl_color)
    wheel_color = vehicle_utils.get_vehicle_color_from_command(wheel_color)
    if pearl_color == nil then pearl_color = {index=current_pearl_color} end
    if wheel_color == nil then wheel_color = {index=current_wheel_color} end
    VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vehicle, pearl_color.index, wheel_color.index)
end

vehicle_utils.apply_random_paint = function(vehicle_handle)
    -- Dont apply custom paint to emergency vehicles
    if VEHICLE.GET_VEHICLE_CLASS(vehicle_handle) == constants.VEHICLE_CLASSES.EMERGENCY then
        return
    end
    local main_color = vehicle_utils.get_random_vehicle_color()
    vehicle_utils.set_vehicle_colors(vehicle_handle, main_color, main_color)
end

local function dec_to_hex(input)
    return ('%X'):format(input)
end

vehicle_utils.color_rgb_to_hex = function(rgb_color)
    return dec_to_hex(rgb_color.r) .. dec_to_hex(rgb_color.g) .. dec_to_hex(rgb_color.b)
end

vehicle_utils.color_hex_to_rgb = function(hexcode)
    return {
        name="#"..hexcode,
        hex="#"..hexcode,
        r=tonumber(string.sub(hexcode, 1, 2),16),
        g=tonumber(string.sub(hexcode, 3, 4),16),
        b=tonumber(string.sub(hexcode, 5, 6),16)
    }
end

vehicle_utils.find_vehicle_color_by_name = function(color_name)
    if constants.VEHICLE_COLOR_ALIASES[color_name] ~= nil then
        color_name = constants.VEHICLE_COLOR_ALIASES[color_name]
    end
    for _, vehicle_color in constants.VEHICLE_COLORS do
        if vehicle_color.name:lower() == color_name:lower() or vehicle_color.index == tonumber(color_name) then
            return cc_utils.table_copy(vehicle_color)
        end
    end
end

vehicle_utils.get_command_color = function(command)
    if cc_utils.str_starts_with(command, "#") then
        return vehicle_utils.color_hex_to_rgb(command:sub(2))
    end
    return vehicle_utils.find_vehicle_color_by_name(command)
end

vehicle_utils.get_random_vehicle_color = function ()
    return cc_utils.table_copy(constants.VEHICLE_COLORS[math.random(1, #constants.VEHICLE_COLORS)])
end

vehicle_utils.set_vehicle_colors = function(vehicle, main_color, secondary_color)
    if main_color.index ~= nil and secondary_color and secondary_color.index ~= nil then
        cc_utils.debug_log("Painting vehicle stock color "..main_color.name)
        VEHICLE.CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle)
        VEHICLE.CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle)
        VEHICLE.SET_VEHICLE_COLOURS(vehicle, main_color.index, secondary_color.index)
    else
        if main_color.index ~= nil then
            cc_utils.debug_log("Painting vehicle color "..main_color.name)
            VEHICLE.SET_VEHICLE_MOD_COLOR_1(vehicle, main_color.paint_type, main_color.index, 0)
            VEHICLE.SET_VEHICLE_COLOURS(vehicle, main_color.index, main_color.index)
            VEHICLE.CLEAR_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle)
            VEHICLE.CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle)
        elseif main_color.r ~= nil then
            cc_utils.debug_log("Painting vehicle custom color "..main_color.hex)
            VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, main_color.r, main_color.g, main_color.b)
            VEHICLE.SET_VEHICLE_MOD_COLOR_1(vehicle, main_color.paint_type, 0, 0)
        end
        if secondary_color and secondary_color.index ~= nil then
            cc_utils.debug_log("Painting vehicle secondary color "..secondary_color.name)
            VEHICLE.SET_VEHICLE_MOD_COLOR_2(vehicle, secondary_color.paint_type, secondary_color.index, 0)
            VEHICLE.CLEAR_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle)
        elseif secondary_color and secondary_color.r ~= nil then
            cc_utils.debug_log("Painting vehicle secondary custom color "..secondary_color.hex)
            VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle, secondary_color.r, secondary_color.g, secondary_color.b)
            VEHICLE.SET_VEHICLE_MOD_COLOR_2(vehicle, secondary_color.paint_type, 0, 0)
        end
    end
end

local function get_color_command_message(color_command)
    if color_command.name then
        return color_command.name
    else
        return color_command.hex:lower()
    end
end

local function build_color_messages(main_color, secondary_color)
    if main_color == secondary_color then
        return get_color_command_message(main_color)
    else
        return get_color_command_message(main_color) .. " and " .. get_color_command_message(secondary_color)
    end
end

vehicle_utils.set_vehicle_paint = function(pid, vehicle, commands)
    local main_color
    local secondary_color
    local paint_type
    if commands and commands[2] then
        for i, command in ipairs(commands) do
            if not main_color then
                main_color = vehicle_utils.get_command_color(command)
                --if command_color then
                --    main_color = command_color
                ----    if command_color.a then
                ----        paint_type = get_paint_type(command_color.a)
                ----    end
                --end
            end
            if command == "and" and vehicle_utils.get_command_color(commands[i+1]) then
                secondary_color = vehicle_utils.get_command_color(commands[i+1])
            end
            --if command == "compliment" then
            --    secondary_color = colorsRGB.COMPLIMENT(main_color)
            --end
            local command_paint_type = constants.VEHICLE_PAINT_TYPES[command:upper()]
            if command_paint_type then
                paint_type = command_paint_type
            end
        end
        if not secondary_color then
            secondary_color = main_color
        end
        if not main_color then
            cc_utils.help_message(pid, "Paint color not found")
            return
        end
        cc_utils.help_message(pid, "Painting vehicle "..build_color_messages(main_color, secondary_color))
    else
        main_color = vehicle_utils.get_random_vehicle_color()
        cc_utils.help_message(pid, "Painting vehicle random color: "..main_color.name)
    end
    --if paint_type == nil then
    --    paint_type = main_color.paint_type
    --end
    vehicle_utils.set_vehicle_colors(vehicle, main_color, secondary_color)
    --VEHICLE.SET_VEHICLE_MOD(vehicle, constants.VEHICLE_MOD_TYPES.MOD_LIVERY, -1)
end

vehicle_utils.randomize_livery = function(vehicle)
    vehicle_utils.set_mod_to_random(vehicle, constants.VEHICLE_MOD_TYPES.MOD_LIVERY)
end

---
--- Performance
---

vehicle_utils.set_performance_tuning_max = function(vehicle)
    vehicle_utils.set_mod_to_max(vehicle, constants.VEHICLE_MOD_TYPES.MOD_ENGINE)
    vehicle_utils.set_mod_to_max(vehicle, constants.VEHICLE_MOD_TYPES.MOD_TRANSMISSION)
    vehicle_utils.set_mod_to_max(vehicle, constants.VEHICLE_MOD_TYPES.MOD_BRAKES)
    vehicle_utils.set_mod_to_max(vehicle, constants.VEHICLE_MOD_TYPES.MOD_ARMOR)
    vehicle_utils.set_mod_to_max(vehicle, constants.VEHICLE_MOD_TYPES.MOD_SPOILER)
    VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, constants.VEHICLE_MOD_TYPES.MOD_TURBO, true)
    -- If few roof options, assume its a weapon and max it
    if VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, constants.VEHICLE_MOD_TYPES.MOD_ROOF) < 5 then
        vehicle_utils.set_mod_to_max(vehicle, constants.VEHICLE_MOD_TYPES.MOD_ROOF)
    end
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false)
end

---
--- Vehicle Mods
---

vehicle_utils.set_mod = function(vehicle, mod_index, mod_value)
    if mod_value == nil then
        local max_mod_value = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, mod_index) - 1
        mod_value = math.random(-1, max_mod_value)
    end
    if mod_value ~= nil then
        entities.set_upgrade_value(vehicle, mod_index, tonumber(mod_value))
        return mod_value
    end
end

vehicle_utils.set_all_mods_to_random = function(vehicle)
    VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
    VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, math.random(-1, constants.VEHICLE_MAX_OPTIONS.WINDOW_TINTS))
    for mod_name, mod_number in pairs(constants.VEHICLE_MOD_TYPES) do
        -- Don't randomize performance, wheels, or livery
        if not (mod_number == constants.VEHICLE_MOD_TYPES.MOD_ARMOR
                or mod_number == constants.VEHICLE_MOD_TYPES.MOD_TRANSMISSION
                or mod_number == constants.VEHICLE_MOD_TYPES.MOD_ENGINE
                or mod_number == constants.VEHICLE_MOD_TYPES.MOD_BRAKES
                or mod_number == constants.VEHICLE_MOD_TYPES.MOD_FRONTWHEELS
                or mod_number == constants.VEHICLE_MOD_TYPES.MOD_BACKWHEELS
                or mod_number == constants.VEHICLE_MOD_TYPES.MOD_LIVERY
        ) then
            vehicle_utils.set_mod_to_random(vehicle, mod_number)
        end
    end
    for mod_number = 17, 22 do
        if not (mod_number == constants.VEHICLE_MOD_TYPES.MOD_TURBO) then
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, mod_number, math.random() > 0.5)
        end
    end
    VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle, math.random(-1, 12))
end

vehicle_utils.set_mod_to_max = function(vehicle, vehicle_mod)
    local max = entities.get_upgrade_max_value(vehicle, vehicle_mod)
    --util.log("Setting max mod "..vehicle_mod.." to "..max)
    entities.set_upgrade_value(vehicle, vehicle_mod, max)
end

vehicle_utils.set_mod_to_random = function(vehicle, vehicle_mod)
    local max = entities.get_upgrade_max_value(vehicle, vehicle_mod)
    if max > 0 then
        local rand_value = math.random(-1, max)
        entities.set_upgrade_value(vehicle, vehicle_mod, rand_value)
    end
end

vehicle_utils.set_all_mods_to_max = function(vehicle)
    --VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
    --VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, math.random(-1, constants.VEHICLE_MAX_OPTIONS.WINDOW_TINTS))
    for mod_name, mod_number in pairs(constants.VEHICLE_MOD_TYPES) do
        if mod_name ~= "MOD_LIVERY" then
            vehicle_utils.set_mod_to_max(vehicle, mod_number)
        end
    end
    for x = 17, 22 do
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, x, true)
    end
    VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false)
end

vehicle_utils.set_all_mods_to_min = function(vehicle)
    --VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
    --VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, math.random(-1, constants.VEHICLE_MAX_OPTIONS.WINDOW_TINTS))
    for mod_name, mod_number in pairs(constants.VEHICLE_MOD_TYPES) do
        entities.set_upgrade_value(vehicle, mod_number, -1)
    end
    for x = 17, 22 do
        VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, x, false)
    end
end

---
--- Wheels
---

vehicle_utils.randomize_wheels = function(vehicle)
    vehicle_utils.set_wheels(vehicle)
end

vehicle_utils.set_wheels = function(vehicle, commands)
    local wheels = {
        name="",
        type=nil,
        kind=nil
    }
    if commands and commands[2] == "stock" and commands[3] == nil then
        commands[3] = "-1"
    end
    if commands and commands[2] then
        wheels.type = constants.VEHICLE_WHEEL_TYPES[commands[2]:upper()]
        if not wheels.type then
            return false
        end
    else
        wheels.type = math.random(-1, constants.VEHICLE_MAX_OPTIONS.WHEEL_TYPES)
    end
    wheels.max_kinds = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, constants.VEHICLE_MOD_TYPES.MOD_FRONTWHEELS) - 1
    if commands and commands[3] then
        wheels.kind = commands[3]
    else
        wheels.kind = math.random(-1, wheels.max_kinds)
    end
    wheels.name = wheels.type
    for wheel_type_name, wheel_type_number in pairs(constants.VEHICLE_WHEEL_TYPES) do
        if wheel_type_number == tonumber(wheels.type) then
            wheels.name = wheel_type_name
        end
    end
    VEHICLE.SET_VEHICLE_WHEEL_TYPE(vehicle, wheels.type)
    entities.set_upgrade_value(vehicle, constants.VEHICLE_MOD_TYPES.MOD_FRONTWHEELS, wheels.kind)
    entities.set_upgrade_value(vehicle, constants.VEHICLE_MOD_TYPES.MOD_BACKWHEELS, wheels.kind)
end

---
--- Nameplate
---

vehicle_utils.set_plate_type = function(pid, vehicle, plate_type_num)
    if type(plate_type_num) == "string" then
        plate_type_num = constants.VEHICLE_PLATE_TYPES[plate_type_num:upper()]
    end
    if plate_type_num == nil then
        plate_type_num = math.random(0, 5)
    end
    local plate_type_name = cc_utils.get_enum_value_name(constants.VEHICLE_PLATE_TYPES, plate_type_num)
    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT_INDEX(vehicle, plate_type_num)
    return plate_type_name
end

local function plateify_text(plate_text)
    if config.custom_plate_texts ~= nil and config.custom_plate_texts[plate_text] ~= nil then
        -- Custom overrides
        if type(config.custom_plate_texts[plate_text]) == "table" then
            local plates = config.custom_plate_texts[plate_text]
            plate_text = plates[math.random(1, #plates)]
        else
            plate_text = config.custom_plate_texts[plate_text]
        end
    end
    if string.len(plate_text) > 8 then
        -- Special characters
        plate_text = plate_text:gsub("[^A-Za-z0-9]", "")
    end
    if string.len(plate_text) > 8 then
        -- Ending numbers
        plate_text = plate_text:gsub("[0-9]+$", "")
    end
    if string.len(plate_text) > 8 then
        -- Vowels
        plate_text = plate_text:gsub("[AEIOUaeiou]", "")
    end
    plate_text = string.sub(plate_text, 1, 8)
    return plate_text
end

vehicle_utils.set_plate_for_player = function(vehicle, pid)
    VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, plateify_text(players.get_name(pid)))
end

return vehicle_utils
