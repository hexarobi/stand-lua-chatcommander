---
--- User Database
---

local db = require("file_database")
db.set_name("chat_commander")

local user_db = {}

user_db.load_user = function(pid)
    local player_name = players.get_name(pid)
    local user_data = db.load_data(player_name)
    return user_db.apply_default_user_data(user_data)
end

user_db.save_user = function(pid, user_data)
    user_data.updated_at = util.current_unix_time_seconds()
    db.save_data(players.get_name(pid), user_data)
end

user_db.apply_default_user_data = function(user_data)
    if user_data == nil then user_data = {} end
    if user_data.command_counters == nil then user_data.command_counters = {} end
    if user_data.prefs == nil then user_data.prefs = {} end
    if user_data.prefs.spawn_with_fav_paint == nil then user_data.prefs.spawn_with_fav_paint = false end
    if user_data.created_at == nil then user_data.created_at = util.current_unix_time_seconds() end
    return user_data
end

user_db.set_user_vehicle = function(pid, vehicle)
    local user_data = user_db.load_user(pid)
    user_data.saved_vehicle = vehicle
    user_db.save_user(pid, user_data)
end

user_db.get_user_vehicle = function(pid)
    local user_data = user_db.load_user(pid)
    return user_data.saved_vehicle
end

user_db.set_pref_spawn_with_fav_paint = function(pid, value)
    local user_data = user_db.load_user(pid)
    user_data.prefs.spawn_with_fav_paint = value
    user_db.save_user(pid, user_data)
end

user_db.get_pref_spawn_with_fav_paint = function(pid)
    local user_data = user_db.load_user(pid)
    return user_data.prefs.spawn_with_fav_paint
end

return user_db
