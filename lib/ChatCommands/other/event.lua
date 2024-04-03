-- Session Event

local cc_utils = require("chat_commander/utils")

local event_menus = {
    bizbattle="Online>Session>Session Scripts>Run Script>Freemode Activities>Business Battle 1",
    challenges="Online>Session>Session Scripts>Run Script>Freemode Activities>Challenges",
    checkpoints="Online>Session>Session Scripts>Run Script>Freemode Activities>Checkpoint Collection",
    damage="Online>Session>Session Scripts>Run Script>Freemode Activities>Criminal Damage",
    holdthewheel="Online>Session>Session Scripts>Run Script>Freemode Activities>Hold the Wheel",
}

return {
    command="event",
    group="other",
    help="Trigger a session event: bizbattle, challenges, checkpoints, damage, holdthewheel",
    execute=function(pid, commands)
        local event_name = commands[2]
        if event_name and event_menus[event_name] then
            local command_menu = menu.ref_by_path(event_menus[event_name])
            if not menu.is_ref_valid(command_menu) then error("Invalid event ref") end
            menu.trigger_command(command_menu)
            cc_utils.help_message(pid, "Triggered event: "..event_name)
        else
            cc_utils.help_message(pid, "Invalid event try: bizbattle, challenges, checkpoints, damage, holdthewheel")
        end
    end
}
