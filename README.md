# ChatCommander
A Lua Script for Stand to enable chat commands

![ChatCommander Logo](https://i.imgur.com/TO6rdtv.png)

# Install

Copy all files into `Stand/Lua Scripts`

# Run

Goto `Stand>Lua Scripts>ChatCommander>Run Script`

# Chat Commands

You can view all chat commands in-game using the !help command.

# Adding new Chat Commands

Add new chat command .lua files in `Stand/Lua Scripts/lib/ChatCommands` organized by group folders.

Each command requires a `command` name to trigger it, but all other fields are optional.
 
- `execute` function to actually do something when the command is triggered, passed `pid` and `commands` list
- `help` list of strings to display to the user as help for the command
- `additional_commands` list of strings to allow as aliases for the main command
