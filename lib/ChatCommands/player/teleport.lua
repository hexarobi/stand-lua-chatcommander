-- Teleport

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

local config = {
    teleport_map = {
        ["8bit"] = { x = -623.96313, y = 278.97998, z = 81.24377 },
        airport = { x = -1087.7434, y = -3015.6057, z = 13.940606 },
        arena = { x = -381.53763, y = -1871.6571, z = 20.25674 },
        beach = { x = -1938.2361, y = -745.7929, z = 3.0065336 },
        carmeet = { x = 781.38837, y = -1893.78, z = 28.879707 },
        casino = { x = 922.69604, y = 47.10072, z = 81.10637 },
        chiliad = { x = 497.87296, y = 5594.12, z = 794.66626 },
        docks = { x = 816.03735, y = -2933.1458, z = 5.635548 },
        downtown = { x = 19.834902, y = -745.57104, z = 43.92299 },
        east = { x = 760.28656, y = -789.80023, z = 26.399529 },
        eclipse = { x = -775.03546, y = 297.41296, z = 85.46615 },
        giftgarage = { x = -1078.4542, y = -2229.311, z = 12.994034 },
        golf = { x = -1329.8248, y = -33.513905, z = 49.581203 },
        lakepicklenose = { x = 2587.2336, y = 6167.3735, z = 165.12334 },
        luxington = { x = 3071.25, y = -4729.30, z = 15.26 },
        mckenzie = { x = 2137.5266, y = 4799.469, z = 40.61362 },
        maze = { x = -75.15735, y = -818.50104, z = 326.1752 },
        observatory = { x = -408.3328, y = 1179.3496, z = 325.6197 },
        paleto = { x = -303.0619, y = 6247.989, z = 31.432796 },
        pier = { x = -1716.3751, y = -1090.788, z = 13.085348 },
        rex = { x = 2571.9, y = 2560.1484, z = 34.401012 },
        sandy = { x = 1756.956, y = 3270.2417, z = 40.565292 },
        simeons = { x = -73.73742, y = -1123.4886, z = 25.499369 },
        soccer = { x = 771.17, y = -232.47, z = 65.79 },
        southbeach = { x = -1116.8607, y = -1717.6504, z = 4.013644 },
        strip = { x = 118.78938, y = -1313.6859, z = 28.91388 },
        videogeddon = { x = 709.92834, y = -831.8337, z = 24.115917 },
        vinewood = { x = 226.5897, y = 209.1123, z = 105.52663 },
        west = { x = -1378.9878, y = -537.43, z = 30.134169 },
        zancudo = { x = -2285.87, y = 3124.1968, z = 32.81467 },
    },
    teleport_aliases = {
        base = "zancudo",
        dirtairport = "sandy",
        fort = "zancudo",
        lsia = "airport",
        sandyshores = "sandy",
        vanilla = "strip",
        video = "videogeddon",
    },
}

local function get_table_keys(tab)
    local keyset={}
    local n=0
    for k,v in pairs(tab) do
        n=n+1
        keyset[n]=k
    end
    table.sort(keyset)
    return keyset
end

local function teleport_player_to_coords(pid, x, y, z)
    --help_message(pid, "teleporting..")
    local old_x, old_y, old_z = players.get_waypoint(players.user())
    util.set_waypoint({x=x, y=y, z=z})
    menu.trigger_commands("wpsummon"..players.get_name(pid))
    if old_x ~= 0 or old_y ~= 0 then
        util.set_waypoint({x=old_x, y=old_y, z=old_z})
    else
        HUD.SET_WAYPOINT_OFF()
    end
end

return {
    command="teleport",
    additional_commands={"tp"},
    group="player",
    help="Teleport to a stunt jump location.",
    execute=function(pid, commands)
        local command = commands[2]
        if command == "list" then
            cc_utils.help_message(pid, "Teleport locations: "..table.concat(get_table_keys(config.teleport_map), ", "))
            return
        end
        local teleport_coords
        if command == nil then
            local x, y, z, b = players.get_waypoint(pid)
            if (x ~= 0.0 and y ~= 0.0) then
                teleport_coords = {x=x, y=y, z=z}
            end
        else
            local location = command
            if config.teleport_aliases[location] ~= nil then command = config.teleport_aliases[location] end
            if config.teleport_map[location] ~= nil then
                teleport_coords = config.teleport_map[location]
            else
                teleport_coords = cc_utils.find_coords_for_player_name(command)
            end
        end
        if teleport_coords == nil then
            cc_utils.help_message(pid, "To teleport, either select a waypoint, or include a location or player name. For a list of locations try !tp list")
            return
        end

        --teleport_player_to_coords(pid, teleport_coords.x, teleport_coords.y, teleport_coords.z)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle ~= nil and vehicle > 0 then
            vehicle_utils.teleport_vehicle_to_coords(vehicle, teleport_coords)
        else
            if config.allow_teleport_on_foot then
                teleport_player_to_coords(pid, teleport_coords.x, teleport_coords.y, teleport_coords.z)
            else
                cc_utils.help_message(pid, "You must be inside a vehicle to teleport")
                return
            end
        end

    end
}
