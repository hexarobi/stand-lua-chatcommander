-- StuntJumps

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

local stunt_jumps = {
    {"Stunt Jump 1", {x=-79.61, y=1642.58, z=265.76, h=296.27}},
    {"Stunt Jump 2", {x=-421.04, y=-986.78, z=36.61, h=168.77}},
    {"Stunt Jump 3", {x=592.59, y=4226.31, z=53.41, h=56.92}},
    {"Stunt Jump 4", {x=-305.57, y=6437.97, z=12.10, h=313.74}},
    {"Stunt Jump 5", {x=-898.36, y=4096.99, z=161.36, h=40.90}},
    {"Stunt Jump 6", {x=86.50, y=-1067.70, z=28.92, h=69.62}},
    {"Stunt Jump 7", {x=-354.72, y=-738.43, z=52.78, h=247.07}},
    {"Stunt Jump 8", {x=3.50, y=-557.91, z=37.10, h=76.54}},
    {"Stunt Jump 9", {x=-1486.95, y=-788.05, z=17.92, h=73.80}},
    {"Stunt Jump 10", {x=-141.18, y=-227.50, z=44.44, h=78.26}},
    {"Stunt Jump 11", {x=-1423.68, y=496.43, z=112.32, h=161.50}},
    {"Stunt Jump 12", {x=3239.63, y=5138.48, z=18.95, h=283.57}},
    {"Stunt Jump 13", {x=1675.37, y=2282.19, z=75.58, h=355.92}},
    {"Stunt Jump 14", {x=236.75, y=-596.44, z=42.19, h=254.52}},
    {"Stunt Jump 15", {x=-835.37, y=-837.88, z=18.88, h=107.12}},
    {"Stunt Jump 16", {x=408.42, y=-1142.51, z=28.85, h=116.19}},
    {"Stunt Jump 17", {x=370.77, y=-1689.73, z=47.74, h=320.08}},
    {"Stunt Jump 18", {x=-60.18, y=-740.33, z=43.67, h=249.86}},
    {"Stunt Jump 19", {x=53.67, y=6540.06, z=31.05, h=143.85}},
    {"Stunt Jump 20", {x=1768.86, y=2151.56, z=63.12, h=193.35}},
    {"Stunt Jump 21", {x=-1096.53, y=14.08, z=50.26, h=259.06}},
    {"Stunt Jump 22", {x=148.72, y=-2188.48, z=5.40, h=92.17}},
    {"Stunt Jump 23", {x=1729.32, y=3654.13, z=34.49, h=117.58}},
    {"Stunt Jump 24", {x=524.26, y=-508.63, z=44.62, h=204.41}},
    {"Stunt Jump 25", {x=377.29, y=-1315.57, z=42.99, h=229.42}},
    {"Stunt Jump 26", {x=-428.24, y=-1613.28, z=27.71, h=351.21}},
    {"Stunt Jump 27", {x=-898.51, y=-2663.56, z=13.17, h=148.16}},
    {"Stunt Jump 28", {x=-1949.11, y=-342.36, z=45.76, h=68.52}},
    {"Stunt Jump 29", {x=1711.29, y=3067.34, z=55.27, h=24.25}},
    {"Stunt Jump 30", {x=-575.65, y=-1468.38, z=8.78, h=257.07}},
    {"Stunt Jump 31", {x=867.02, y=-2910.68, z=5.34, h=92.67}},
    {"Stunt Jump 32", {x=2066.96, y=1879.55, z=92.42, h=60.64}},
    {"Stunt Jump 33", {x=611.07, y=-3011.26, z=5.48, h=278.13}},
    {"Stunt Jump 34", {x=122.62, y=-2900.32, z=5.44, h=9.06}},
    {"Stunt Jump 35", {x=108.25, y=-3160.98, z=5.44, h=179.20}},
    {"Stunt Jump 36", {x=116.78, y=-2874.02, z=5.44, h=184.57}},
    {"Stunt Jump 37", {x=120.10, y=-2831.54, z=5.44, h=312.07}},
    {"Stunt Jump 38", {x=176.78, y=-3047.88, z=5.21, h=7.95}},
    {"Stunt Jump 39", {x=301.09, y=-3089.09, z=5.34, h=9.64}},
    {"Stunt Jump 40", {x=305.17, y=-2637.17, z=5.44, h=269.87}},
    {"Stunt Jump 41", {x=-864.76, y=-2604.63, z=13.16, h=343.12}},
    {"Stunt Jump 42", {x=-973.71, y=-2458.70, z=13.19, h=161.62}},
    {"Stunt Jump 43", {x=-537.04, y=-1549.37, z=0.60, h=65.85}},
    {"Stunt Jump 44", {x=-579.41, y=-1084.90, z=21.77, h=77.37}},
    {"Stunt Jump 45", {x=-447.90, y=-1320.46, z=37.47, h=175.68}},
    {"Stunt Jump 46", {x=-443.08, y=-638.50, z=30.75, h=1.37}},
    {"Stunt Jump 47", {x=-569.75, y=-50.84, z=41.57, h=152.61}},
    {"Stunt Jump 48", {x=-689.08, y=-32.01, z=37.41, h=121.22}},
    {"Stunt Jump 49", {x=1534.34, y=-2179.11, z=76.81, h=125.39}},
    {"Stunt Jump 50", {x=316.42, y=-2548.64, z=5.14, h=294.68}}
}

return {
    command="stuntjump",
    group="player",
    help="Teleport to a stunt jump location.",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if not vehicle then
            cc_utils.help_message(pid, "Please enter a vehicle to use this command.")
        else
            local jump_index = commands[2]
            if jump_index == nil then
                jump_index = math.random(1, #stunt_jumps)
            end
            local stunt_jump = stunt_jumps[tonumber(jump_index)]
            if stunt_jump == nil then
                cc_utils.help_message(pid, "Invalid stunt jump")
            else
                vehicle_utils.teleport_vehicle_to_coords(vehicle, stunt_jump[2])
                cc_utils.help_message(pid, "Teleporting to stunt jump #"..jump_index)
            end
        end
    end
}
