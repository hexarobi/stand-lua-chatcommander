-- Ping Chat Command
-- Example ChatCommander-Compatible ChatCommand

local cc_utils = require("chat_commander/utils")

return {
    name="Ping",                                    -- Internal name (Optional) Defaults to filename
    command="ping",                                 -- Chat command (Optional) Defaults to filename
    additional_commands={"ping2"},                  -- Additional chat commands (Optional) Defaults to empty list
    group="other",
    help="Check if chat commands are enabled.",     -- Help Text (Optional) Defaults to nil
    execute=function(pid)                           -- Executable function (Required)
        cc_utils.help_message(pid, "Pong! Your chat message was heard.")
    end
}
