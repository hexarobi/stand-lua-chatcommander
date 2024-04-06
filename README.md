# ChatCommander
A Lua Script for Stand to enable chat commands

![ChatCommander Logo](https://i.imgur.com/TO6rdtv.png)

# Features 

- Vehicle spawner that works with normal vehicle names (Ex: "!elegy retro custom"), and several common aliases (!op2)
- Vehicle spawner tunes max performance options, but randomizes other options to avoid always spawning the same look
- Vehicle spawner default limits to 1 spawn per player (configurable) to avoid lobby vehicle spam
- Vehicle spawner blocks large vehicles unless in appropriate location (airport)
- Built in !help system for browsing commands
- Passthrough commands for allowing any Stand command as a chat command
- AFK mode to keep finding a live lobby, optionally while rigging casino
- Auto-Announcements to explain basic commands, roulette (if afk in casino) and car gifting
- Modular file structure, each chat command is a file so easy to edit existing commands or add your own new ones

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
