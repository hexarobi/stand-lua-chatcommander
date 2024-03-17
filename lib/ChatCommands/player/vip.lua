-- ChatCommander-Compatible ChatCommand

local cc_utils = require("chat_commander/utils")

return {
    command="vip",
    help="Request an org invite, useful for ceopay or VIP at casino.",
    execute=function(pid)
        if players.get_org_type(players.user()) == -1 then
            menu.trigger_commands("ceostart")
            util.yield(100)
            if players.get_org_type(players.user()) == -1 then
                utils.help_message(pid, "Sorry, VIP is not available right now.")
            end
        end
        -- Thanks to Totaw Annihiwation for this script event! // Position - 0x2725D7
        util.trigger_script_event(1 << pid, {
            -245642440,
            players.user(),
            4,
            10000, -- wage?
            0,
            0,
            0,
            0,
            memory.read_int(memory.script_global(1916087 + 9)), -- f_8
            memory.read_int(memory.script_global(1916087 + 10)), -- f_9
        })
        cc_utils.help_message(pid, "Org invite sent. Please check your phone to accept invite.")
    end
}
