-- Roulette

local cc_utils = require("chat_commander/utils")

return {
    command="roulette",
    help={
        "HOW TO PLAY RIGGED ROULETTE: Enter the casino (!casino) get chips from cashier then go to TABLE GAMES",
        "Find the HIGH LIMIT purple tables and take a seat at roulette. If you need VIP access join my org (!vip) or buy a penthouse.",
        "Press TAB, then click 1 and the `1st 12` space next to it until you cant bet anymore. If you win 330k you did it right.",
        "The ball will usually land on 1, but can sometimes come up 0. If this happens just bet 0 until it goes back to 1.",
        "You will get cut off for an hour after winning $4mil in a row, avoid this by placing a small losing bet for every $3mil won",
    },
    execute=function(pid, commands, chat_command)
        cc_utils.help_message(pid, chat_command.help)
    end
}