-- CeoPay

local cc_utils = require("chat_commander/utils")

return {
    command="ceopay",
    group="player",
    help="Adds the full armament of weapons to your player. Most will go away after a restart.",
    execute=function(pid, commands)
        local enabled_string = cc_utils.get_on_off_string(commands[2])
        menu.trigger_commands("ceopay " .. players.get_name(pid) .. " " .. enabled_string)
        cc_utils.help_message(pid, "CEOPay " .. enabled_string .. ". Remember, you must be a member (not CEO) of an org to get paid. For invite try !vip")
    end
}
