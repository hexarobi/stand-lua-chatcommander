-- ChatCommander-Compatible ChatCommand

local cc_utils = require("chat_commander/utils")

-- VIP func from pi_menu
--void func_7340(int iParam0, int iParam1, var uParam2, var uParam3, var uParam4, var uParam5, var uParam6) // Position - 0x2825DB
--{
--    struct<10> eventData;
--
--    eventData = -245642440;
--    eventData.f_1 = PLAYER::PLAYER_ID();
--    eventData.f_2 = iParam1;
--    eventData.f_3 = { uParam2 };
--    func_2139(&(eventData.f_8), &(eventData.f_9));
--
--    if (!(iParam0 == 0))
--    SCRIPT::SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, &eventData, 10, iParam0);
--
--    return;
--}

return {
    command="vip",
    group="player",
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
