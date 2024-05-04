-- Item Browser
-- Library for adding a browseable and searchable menu in Stand for heirarchical data (like folders and files)

local browser = {}
browser.state = {
    search_menu_counter = 1
}
local max_search_results = 100

local function delete_menu_list(menu_list)
    if type(menu_list) ~= "table" then return end
    for k, h in pairs(menu_list) do
        if h:isValid() then
            menu.delete(h)
        end
        menu_list[k] = nil
    end
end

browser.table_copy = function(obj)
    if type(obj) ~= 'table' then return obj end
    local res = setmetatable({}, getmetatable(obj))
    for k, v in pairs(obj) do res[browser.table_copy(k)] = browser.table_copy(v) end
    return res
end

browser.search = function(search_params)
    if search_params.page_size == nil then search_params.page_size = max_search_results end
    if search_params.page_number == nil then search_params.page_number = 0 end
    if search_params.menus == nil then search_params.menus = {} end
    if search_params.results == nil then search_params.results = {} end
    local results = search_params.query_function(search_params)
    local more_results_available = false
    local first_result_index = (search_params.page_size*search_params.page_number)+1
    local last_result_index = search_params.page_size*(search_params.page_number+1)
    for i = first_result_index, last_result_index do
        if results[i] then
            local search_result_menu = search_params.add_item_menu_function(search_params, results[i])
            table.insert(search_params.results, search_result_menu)
        end
        more_results_available = (results[i+1] ~= nil)
    end
    if search_params.menus.search_add_more ~= nil and search_params.menus.search_add_more:isValid() then
        menu.delete(search_params.menus.search_add_more)
    end
    if more_results_available then
        search_params.menus.search_add_more = menu.action(search_params.menus.root, "[More]", {}, "", function()
            local more_search_params = search_params
            more_search_params.page_number = more_search_params.page_number + 1
            browser.search(more_search_params)
        end)
        table.insert(search_params.results, search_params.menus.search_add_more)
    end
end

browser.search_items = function(folder, query, results)
    if results == nil then results = {} end
    if #results > max_search_results then return results end
    for _, item in folder.items do
        if item.items ~= nil then
            browser.search_items(item, query, results)
        else
            if type(item.name) == "string" then
                if string.match(item.name:lower(), query:lower()) then
                    table.insert(results, item)
                end
            else
                util.log("Warning: Item skipped from search due to invalid name field of type "..type(item.name))
            end
        end
    end
    return results
end

browser.browse_item = function(parent_menu, this_item, add_item_menu_function, browse_params)
    if browse_params == nil then browse_params = {} end
    if this_item.items ~= nil then
        local menu_list = parent_menu:list(
                this_item.name.." ("..#this_item.items..")",
                {},
                this_item.description or ""
        )
        browser.state.search_menu_counter = browser.state.search_menu_counter + 1
        local search_command = "search"..browser.state.search_menu_counter
        local search_menu = menu_list:list("Search", {}, "Search this folder and sub-folders", function()
            menu.show_command_box(search_command.." ")
        end)
        search_menu:text_input("Search", {search_command}, "", function(query)
            delete_menu_list(browser.state.search_results_menus)
            browser.state.search_results_menus = {}
            browser.search({
                this_item=this_item,
                query=query,
                results=browser.state.search_results_menus,
                menus={
                    root=search_menu,
                },
                query_function=function(search_params)
                    if browse_params.query_function ~= nil then
                        return browse_params.query_function(search_params)
                    else
                        return browser.search_items(search_params.this_item, search_params.query)
                    end
                end,
                add_item_menu_function=function(search_params, item)
                    if add_item_menu_function ~= nil then
                        return add_item_menu_function(search_params.menus.root, item)
                    end
                end,
            })
        end)
        menu_list:divider("Browse")
        for _, item in pairs(this_item.items) do
            if type(item) == "table" then
                if item.items ~= nil then
                    browser.browse_item(menu_list, item, add_item_menu_function)
                else
                    if add_item_menu_function ~= nil then
                        add_item_menu_function(menu_list, item)
                    end
                end
            end
        end
        return menu_list
    end
end

return browser