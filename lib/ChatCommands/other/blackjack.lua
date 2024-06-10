-- Blackjack

local cc_utils = require("chat_commander/utils")

return {
    command="blackjack",
    group="other",
    help={
    "HOW TO PLAY RIGGED BLACKJACK: Enter the casino (!casino) and get chips from the cashier.",
    "Go to the HIGH LIMIT blackjack tables. If you need VIP access, join my org (!vip) or buy a penthouse.",
    "The dealer will always go bust. after they draw their first 2 cards. OPTIONAL FOR MORE WINNINGS: If your first 2 cards total less than 12, always double down. The dealer will bust, and you'll win. Remember, Ace can be either 11 or 1, your choice. If you need more help, google it :)",
    "You will get cut off for an hour after winning $4mil in a row, avoid this by placing a small losing bet for every $3mil won",
    },
    execute=function(pid, commands, chat_command)
        cc_utils.help_message(pid, chat_command.help)
    end
}