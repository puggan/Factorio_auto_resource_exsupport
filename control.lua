nofirstrun = true
onchangeyet = true
pause = true

local BUCKETS_COUNT = 10
local current_bucket_index = 1

local lastaddentityindex = {}
local entitieslist
local entitiesidx = {}
local reslist
local gui = {}
local furnace_type_index = 1

local Kchest = {
    ["wooden-chest"] = true,
    ["iron-chest"] = true,
    ["steel-chest"] = true,
    ["storage-tank"] = true,
    ["pumpjack"] = true,
}

local Kmachine = {}

local Kfurnace = {
    ["stone-furnace"] = true,
    ["steel-furnace"] = true,
    ["electric-furnace"] = true,
}

local storeLiquid = {}

local storeNormalItems = {}

local SiencePackNames = {
    "automation-science-pack",
    "logistic-science-pack",
    "military-science-pack",
    "chemical-science-pack",
    "production-science-pack",
    "utility-science-pack",
    "space-science-pack",
}

local _fuel = {}
local initfuel = { "coal", "solid-fuel" }
local _fuel_list = {
    ["flamethrower-turret"] = { { "light-oil", "heavy-oil", "crude-oil" } },
    ["boiler"] = { _fuel, { "water" } },
    ["burner-mining-drill"] = { _fuel },
    ["stone-furnace"] = { _fuel },
    ["steel-furnace"] = { _fuel },
    ["heat-exchanger"] = { { "water" } },
}
_fuel_list.__index = _fuel_list.prototype

local _ammo_list = {
    ["gun-turret"] = { { "piercing-rounds-magazine", "firearm-magazine" } },
    ["artillery-turret"] = { { "artillery-shell" } },
}

local ft_option = { "none", "iron", "copper", "steel", "stone-brick" }
local ft_src = {
    ["none"] = "",
    ["iron"] = "iron-ore",
    ["copper"] = "copper-ore",
    ["steel"] = "iron-plate",
    ["stone-brick"] = "stone",
}

function need_fuel(entity)
    return _fuel_list[entity.prototype.name] ~= nil
end

function need_ammo(entity)
    return _ammo_list[entity.prototype.name] ~= nil
end

function is_lab(entity)
    return entity.prototype.name == "lab"
end

function is_fluid(name)
    return game.fluid_prototypes[name] ~= nil
end

function is_furnace(entity)
    return Kfurnace[entity.prototype.name] ~= nil
end

function is_machine(entity)
    return Kmachine[entity.prototype.name] ~= nil
end

function is_chest(entity)
    return Kchest[entity.prototype.name] ~= nil
end

function is_accepted_type(entity)
    return is_machine(entity)
            or is_chest(entity)
            or need_fuel(entity)
            or is_lab(entity)
end

function init()
    local allItems = {}
    for _, item in pairs(game.item_prototypes) do
        allItems[#allItems + 1] = item.name
        if item.fuel_category == "chemical" then
            _fuel[#_fuel + 1] = item.name
        end
    end
    storeNormalItems = allItems
    for _, fluid in pairs(game.fluid_prototypes) do
        storeLiquid[#storeLiquid + 1] = fluid.name
    end
    for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "crafting-machine" } })) do
        if entity.burner_prototype ~= nil and
                _fuel_list[entity.name] == nil and
                entity.burner_prototype.fuel_categories["chemical"] then
            _fuel_list[entity.name] = { initfuel }
        end
        Kmachine[entity.name] = true
    end

    entitieslist = {}
    reslist = {}
    for playerId = 1,7 do
        entitieslist[playerId] = {}
        lastaddentityindex[playerId] = 1
        for bucketIndex = 1,BUCKETS_COUNT do
            entitieslist[playerId][bucketIndex] = {}
        end
        reslist[playerId] = {}
        local setMaxValues = function(items, newMaxValue)
            for _,itemKey in ipairs(items) do
                if reslist[playerId][itemKey] == nil then
                    reslist[playerId][itemKey] = { count = 0, max = newMaxValue }
                else
                    reslist[playerId][itemKey].max = newMaxValue
                end
            end
        end

        setMaxValues(storeLiquid, settings.global["max-liquid"].value)
        setMaxValues(storeNormalItems, settings.global["max-item"].value)
        global.ar = {
            entitieslist = entitieslist,
            reslist = reslist,
            entitiesidx = entitiesidx,
            lastaddentityindex = lastaddentityindex,
        }
    end
end

function read_save()
    entitieslist = global.ar.entitieslist
    reslist = global.ar.reslist
    entitiesidx = global.ar.entitiesidx
    lastaddentityindex = global.ar.lastaddentityindex
    onchangeyet = true
    nofirstrun = true
    local setMaxValues = function(items, newMaxValue)
        for playerId = 1,7 do
            for _,itemKey in ipairs(items) do
                reslist[playerId][itemKey].max = newMaxValue
            end
        end
    end
    setMaxValues(storeLiquid, settings.global["max-liquid"].value)
    setMaxValues(storeNormalItems, settings.global["max-item"].value)
end

function onchange()
    local allItems = {}
    for _, item in pairs(game.item_prototypes) do
        allItems[#allItems + 1] = item.name
        if item.fuel_category == "chemical" then
            _fuel[#_fuel + 1] = item.name
        end
        for playerId = 1,7 do
            reslist[playerId][item.name].max = settings.global["max-item"].value
        end
    end
    storeNormalItems = allItems
    for _, fluid in pairs(game.fluid_prototypes) do
        storeLiquid[#storeLiquid + 1] = fluid.name
        for playerId = 1,7 do
            reslist[playerId][fluid.name].max = settings.global["max-liquid"].value
        end
    end
    for _, entity in pairs(game.get_filtered_entity_prototypes({ { filter = "crafting-machine" } })) do
        if entity.burner_prototype ~= nil and
                _fuel_list[entity.name] == nil and
                entity.burner_prototype.fuel_categories["chemical"] then
            _fuel_list[entity.name] = { initfuel }
        end
        Kmachine[entity.name] = true
    end
end

function entity_size_str(player)
    local str = ""
    for _,v in ipairs(entitieslist[player]) do
        str = str .. table_size(v) .. " "
    end
    return str
end

function print_inventory(entity)
    if entity == nil then
        return
    end

    local contentKeyValueString = function(inventory)
        if inventory == nil then
            return ""
        end
        local str = "slot " .. #inventory
        for key,value in pairs(inventory.get_contents()) do
            str = str .. " " .. key .. " " .. value
        end
        return str
    end

    game.print("-----")
    game.print("output " .. contentKeyValueString(entity.get_output_inventory()))
    -- game.print("module " .. contentKeyValueString(entity.get_module_inventory()))
    game.print("fuel " .. contentKeyValueString(entity.get_fuel_inventory()))
    game.print("burnt " .. contentKeyValueString(entity.get_burnt_result_inventory()))
    game.print("furnace_source " .. contentKeyValueString(entity.get_inventory(defines.inventory.furnace_source)))
    game.print("assembling_machine_input " .. contentKeyValueString(entity.get_inventory(defines.inventory.assembling_machine_input)))
    game.print("turretammo " .. contentKeyValueString(entity.get_inventory(defines.inventory.turret_ammo)))

    local keyValueString = function(table)
        if table == nil then
            return ""
        end
        local str = ""
        for key,value in pairs(table) do
            str = str .. " " .. key .. " " .. value
        end
        return str
    end

    game.print("fluid " .. keyValueString(entity.get_fluid_contents()))
end

function deposit_res(playerId, itemName, itemDepositCount)
    local obj = reslist[playerId][itemName]
    if obj == nil then
        -- item not tracked/stored
        return 0
    end
    if itemDepositCount <= 0 then
        return 0
    end
    obj.count = obj.count + itemDepositCount
    return itemDepositCount
end

function withdraw_res(playerId, itemName, itemWithdrawCount)
    local obj = reslist[playerId][itemName]
    if obj == nil then
        -- item not tracked/stored
        return 0
    end
    if itemWithdrawCount > obj.count then
        itemWithdrawCount = obj.count
    end
    if itemWithdrawCount <= 0 then
        return 0
    end
    obj.count = obj.count - itemWithdrawCount
    return itemWithdrawCount
end

function read_res(playerId, itemName)
    local obj = reslist[playerId][itemName]
    if obj == nil then
        -- item not tracked/stored
        return 0
    end
    return obj.count
end

function can_insert_res(playerId, itemName)
    local obj = reslist[playerId][itemName]
    if obj == nil then
        -- item not tracked/stored
        return 0
    end
    return obj.max - obj.count
end

function print_recipe(entity)
    local recipe = entity.get_recipe()
    if recipe == nil then
        return
    end

    local str = ""
    for _,ingredient in ipairs(recipe.ingredients) do
        str = str .. " " .. ingredient.name .. " " .. ingredient.amount
    end
    str = str .. " >>"
    for _,product in ipairs(recipe.products) do
        str = str .. " " .. product.name .. " " .. product.amount
    end
    game.print(entity.prototype.name .. " recipe " .. str)
end

function try_get_from_entity(playerId, entity, itemName, itemCount, inventory)
    local itemSpace = can_insert_res(playerId, itemName)
    if itemCount > itemSpace then
        itemCount = itemSpace
    end

    if itemCount < 1 then
        return 0
    end

    if is_fluid(itemName) then
        itemCount = entity.remove_fluid{ name = itemName, amount = itemCount }
    else
        itemCount = inventory.remove{ name = itemName, count = itemCount }
    end

    deposit_res(playerId, itemName, itemCount)

    return itemCount
end

function try_put_to_entity(playerId, entity, itemName, itemCount, inventory)
    local availableItems = read_res(playerId, itemName) - settings.global["min-item"].value

    if itemCount > availableItems then
        itemCount = availableItems
    end

    if itemCount < 1 then
        return 0
    end

    if is_fluid(itemName) then
        itemCount = entity.insert_fluid{ name = itemName, amount = itemCount }
    else
        itemCount = inventory.insert{ name = itemName, count = itemCount }
    end

    withdraw_res(playerId, itemName, itemCount)

    return itemCount
end

function read_entity(entity, itemName)
    if is_fluid(itemName) then
        return entity.get_fluid_count(itemName)
    else
        return entity.get_item_count(itemName)
    end
end

function do_chest(playerId, entity)
    if not is_chest(entity) then
        return false
    end
    local inventory = entity.get_output_inventory()
    if inventory ~= nil then
        -- k = prototype name v = number
        for itemName,itemCount in pairs(inventory.get_contents()) do
            try_get_from_entity(playerId, entity, itemName, itemCount, inventory)
        end
    end

    for fluidName,fluidCount in pairs(entity.get_fluid_contents()) do
        try_get_from_entity(playerId, entity, fluidName, fluidCount, inventory)
    end

    return true
end

function do_ammo(playerId, entity)
    if not need_ammo(entity) then
        return false
    end

    local inventory = entity.get_inventory(defines.inventory.fuel)
    local preferredAmmo = settings.global["preferred-ammo"].value
    local ammoCount = read_entity(entity, preferredAmmo)
    if ammoCount < settings.global["min-ammo"].value then
        local depositedAmmo = try_put_to_entity(playerId, entity, preferredAmmo, settings.global["min-ammo"].value - ammoCount, inventory)
        if depositedAmmo > 0 then
            return true
        end
    end

    for _,ammoSubList in pairs(_ammo_list[entity.prototype.name]) do
        for k2,ammoName in ipairs(ammoSubList) do
            ammoCount = read_entity(entity, ammoName)
            if ammoCount < settings.global["min-ammo"].value then
                local depositedAmmo = try_put_to_entity(playerId, entity, ammoName, settings.global["min-ammo"].value - ammoCount, inventory)
                if depositedAmmo > 0 then
                    return true
                end
            end
        end
    end

    return true
end

function do_fuel(playerId, entity)
    if not need_fuel(entity) then
        return false
    end

    if entity.burner ~= nil then
        local burntResultInventory = entity.get_inventory(defines.inventory.burnt_result)
        if burntResultInventory ~= nil and
                entity.burner.currently_burning ~= nil and
                entity.burner.currently_burning.burnt_result ~= nil then
            local burntResultName = entity.burner.currently_burning.burnt_result.name
            try_get_from_entity(
                playerId,
                entity,
                burntResultName,
                burntResultInventory.get_item_count(burntResultName),
                burntResultInventory
            )
        end

        if entity.burner.currently_burning ~= nil then
            local fuelName = entity.burner.currently_burning.name
            local fuelCount = read_entity(entity, entity.burner.currently_burning.name)
            local minAmount = settings.global["min-fuel"].value
            local maxAmount = settings.global["max-fuel"].value
            if fuelName == "water" then
                minAmount = 9999
                maxAmount = 9999
            end

            if fuelCount > maxAmount then
                try_get_from_entity(
                    playerId,
                    entity,
                    fuelName,
                    fuelCount - maxAmount,
                    entity.get_inventory(defines.inventory.fuel)
                )
            end

            if fuelCount >= minAmount then
                return
            end
        end
    end

    local inventory = entity.get_inventory(defines.inventory.fuel)
    local preferredFuel = settings.global["preferred-fuel"].value
    local preferredFuelCount = read_entity(entity, preferredFuel)
    if preferredFuelCount < settings.global["min-fuel"].value then
        local depositedFuel = try_put_to_entity(playerId, entity, preferredFuel, settings.global["min-fuel"].value - preferredFuelCount, inventory)
        if depositedFuel > 0 then
            return
        end
    end

    for _,fuelSubList in pairs(_fuel_list[entity.prototype.name]) do
        for _,fuelName in ipairs(fuelSubList) do
            local preferedAmount = settings.global["min-fuel"].value
            if fuelName == "water" then
                preferedAmount = 9999
            end

            local fuelCount = read_entity(entity, fuelName)
            local depositedFuel = try_put_to_entity(playerId, entity, fuelName, preferedAmount - fuelCount, inventory)
            if depositedFuel > 0 then
                return
            end
        end
    end

    return true
end

function do_lab(playerId, entity)
    if not is_lab(entity) then
        return false
    end

    local inv = entity.get_inventory(defines.inventory.lab_input)
    for i,siencePackName in ipairs(SiencePackNames) do
        if inv.get_item_count(siencePackName) < 1 then
            try_put_to_entity(playerId, entity, siencePackName, 1, inv)
        end
    end
    return true
end

function do_ssp(playerId, entity)
    try_get_from_entity(playerId, entity, "space-science-pack", 2000, entity.get_output_inventory())
end

function do_furnace(playerId, entityObj)
    local entity = entityObj.entity
    if not is_furnace(entity) then
        return false
    end

    -- get all output
    local inventory = entity.get_output_inventory()
    for itemName,itemCount in pairs(inventory.get_contents()) do
        try_get_from_entity(playerId, entity, itemName, itemCount, inventory)
    end

    -- decide what to burn based on current resource amount
    inventory = entity.get_inventory(defines.inventory.furnace_source)

    local insertFurnaceItems = function(itemName)
            local preferedAmount = 10
            local currentAmount = inventory.get_item_count()

            if currentAmount >= preferedAmount then
                return 0
            end

            return try_put_to_entity(playerId, entity, itemName, preferedAmount - currentAmount, inventory)
        end

    if inventory.is_empty() then
        if entityObj.furnace_source ~= nil then
            insertFurnaceItems(entityObj.furnace_source)
        end
        return
    end

    for itemName,_ in pairs(inventory.get_contents()) do
        insertFurnaceItems(itemName)
        entityObj.furnace_source = itemName
    end
end

function harvest_feed_entity(playerId, entityObj)
    if entityObj.entity.prototype.name == "rocket-silo" then
        do_ssp(playerId, entityObj.entity)
    end

    if do_chest(playerId, entityObj.entity) then
        return
    end

    if do_lab(playerId, entityObj.entity) then
        return
    end

    do_fuel(playerId, entityObj.entity)

    if do_furnace(playerId, entityObj) then
        return
    end

    if do_ammo(playerId, entityObj.entity) then
        return
    end

    if not is_machine(entityObj.entity) then
        return
    end

    local recipe = entityObj.entity.get_recipe()
    if recipe == nil then
        return
    end

    local inventory = entityObj.entity.get_output_inventory()
    for _,productItem in ipairs(recipe.products) do
        try_get_from_entity(playerId, entityObj.entity, productItem.name, 9999, inventory)
    end

    for _,ingredientItem in ipairs(recipe.ingredients) do
        inventory = entityObj.entity.get_inventory(defines.inventory.furnace_source)
        local ingredientAmount = read_entity(entityObj.entity, ingredientItem.name)
        local ingredientPreferedAmount = ingredientItem.amount / ( recipe.energy / entityObj.entity.crafting_speed ) * 2
        if ingredientPreferedAmount < ingredientItem.amount then
            ingredientPreferedAmount = ingredientItem.amount * 2
        end
        if ingredientAmount < ingredientPreferedAmount then
            try_put_to_entity(playerId, entityObj.entity, ingredientItem.name, ingredientPreferedAmount - ingredientAmount, inventory)
        end
    end
end

function harvest_feed(bucketIndex)
    for playerId,playerEntites in pairs(entitieslist) do
        for entityKey,entityObj in pairs(playerEntites[bucketIndex]) do
            if entityObj.entity == nil then
                game.print(" is nil")
            elseif not entityObj.entity.valid then
                playerEntites[bucketIndex][entityKey] = nil
            else
                harvest_feed_entity(playerId, entityObj)
            end
        end
    end
end

function ft_source()
    return ft_src[ft_option[furnace_type_index]]
end

function on_sel_change(event)
    if event.element.name == "gui_ft_setting" then
        furnace_type_index = event.element.selected_index
        game.get_player(event.player_index).gui.top["furnace_type"].caption = "FT=" .. ft_source()
    end
end

function on_gui_click(event)
    if is_fluid(event.element.name) then
        return
    end

    if event.element.name == "furnace_type" then
        if gui[event.player_index].ft == nil then
            gui[event.player_index].ft = game.get_player(event.player_index).gui.center.add{ type = "frame" }
            gui[event.player_index].ft.add{ type = "drop-down", items = ft_option, selected_index = furnace_type_index, name = "gui_ft_setting" }
        else
            gui[event.player_index].ft.destroy()
            gui[event.player_index].ft = nil
        end

        return
    end

    local itemCount = 1
    if defines.mouse_button_type.left == event.button then
        if event.shift then
            local p = game.item_prototypes[event.element.name]
            if p == nil or p.stack_size == nil then
                game.print(event.element.name .. " is nil")
            else
                itemCount = game.item_prototypes[event.element.name].stack_size
            end
        else
            itemCount = 1
        end
    end

    if defines.mouse_button_type.right == event.button then
        if event.shift then
            itemCount = game.item_prototypes[event.element.name].stack_size / 2
        else
            itemCount = 5
        end
    end

    if itemCount < 1 then
        itemCount = 1
    end

    itemCount = withdraw_res(event.player_index, event.element.name, itemCount)
    if itemCount > 0 then
        game.get_player(event.player_index).get_inventory(defines.inventory.character_main).insert{ name = event.element.name, count = itemCount }
    end
end

function create_gui(root, index)
    gui[index] = {
        restable = root.add{ type = "table", column_count = settings.global["item-columns"].value, name = "restable" },
        entityinfo = root.add{ type = "label", caption = "", name = "entityinfo" },
    }

    root.add{ type = "button", caption = "FT", name = "furnace_type" }

    for itemName,_ in pairs(reslist[index]) do
        local str = "item/" .. itemName
        if is_fluid(itemName) then
            str = "fluid/" .. itemName
        end
        gui[index].restable.add{ type = "sprite-button", sprite = str, name = itemName, visible = false }
    end
end

function show()
    for _,player in ipairs(game.connected_players) do
        local entityCaption = function()
            return "entity " .. entity_size_str(player.index)
        end

        local res = reslist[player.index]

        if player.gui.top["furnace_type"] == nil then
            create_gui(player.gui.top, player.index)
        end

        if gui[player.index] == nil then
            gui[player.index] = {
                restable = player.gui.top["restable"],
                entityinfo = player.gui.top["entityinfo"],
            }
        end

        for itemName,itemStorage in pairs(res) do
            local resourceListIcon = gui[player.index].restable[itemName]
            resourceListIcon.number = itemStorage.count
            resourceListIcon.tooltip = itemStorage.count
            if not is_fluid(itemName) then
                resourceListIcon.tooltip = resourceListIcon.tooltip .. itemName .. ". Click to get.[Left=1 Right=5 Shift+L=Stack Shift+R=Half stack]"
            end
            if itemStorage.count > 0 then
                resourceListIcon.visible = true
            end
        end

        gui[player.index].entityinfo.caption = entityCaption()

        if player.gui.top["furnace_type"] ~= nil then
            player.gui.top["furnace_type"].visible = settings.global["ft-button"].value;
            gui[player.index].entityinfo.visible = settings.global["ft-button"].value;
        end
    end
end

function new_entity(entity)
    if is_accepted_type(entity) == false then
       return
    end

    if entity.last_user == nil then
        game.print(entity.prototype.name .. " has no last_user")
        return
    end

    if entitiesidx[entity.unit_number] ~= nil then
        return
    end

    local playerId = entity.last_user.index
    local bucketIndex = lastaddentityindex[playerId];
    local entityObj = { entity = entity }

    local ftsrc = ft_source()
    if is_furnace(entity) and #ftsrc > 1 then
        entityObj.furnace_source = ftsrc
    end

    entitieslist[playerId][bucketIndex][entity.unit_number] = entityObj

    entitiesidx[entity.unit_number] = {
        playerid = playerId,
        idx = bucketIndex,
    }

    bucketIndex = bucketIndex + 1
    if bucketIndex > BUCKETS_COUNT then
        bucketIndex = 1
    end

    lastaddentityindex[playerId] = bucketIndex
end

function on_built_entity(event)
    new_entity(event.created_entity)
end

function on_entity_cloned(event)
    new_entity(event.destination)
end

function remove_entity(entity)
    local bucketIndexObj = entitiesidx[entity.unit_number]
    if bucketIndexObj == nil then
        if is_accepted_type(entity) == false then
            return
        end

        game.print("unknown entity " .. entity.prototype.name)
        return
    end

    local entityObj = entitieslist[bucketIndexObj.playerid][bucketIndexObj.idx][entity.unit_number]
    if entityObj == nil then
        game.print("invalid entity")
        return
    end

    entitieslist[bucketIndexObj.playerid][bucketIndexObj.idx][entity.unit_number] = nil
    entitiesidx[entity.unit_number] = nil
end

function on_entity_died (event)
    remove_entity(event.entity)
end

function on_player_mined_entity (event)
    remove_entity(event.entity)
end

script.on_event("autoresourceex-hide-restable", function(event)
    localplayer = game.players[event.player_index]
    if localplayer.gui.top.restable.visible == true then
        localplayer.gui.top.restable.visible = false
    else
        localplayer.gui.top.restable.visible = true
    end
end)

script.on_event("autoresourceex-run-onchange", function(event)
    onchange()
end)

script.on_event(defines.events.on_built_entity, on_built_entity)

script.on_event(defines.events.on_entity_cloned, on_entity_cloned)

script.on_event(defines.events.on_tick, function(event)
    if (event.tick%(5)) == 0 then
        harvest_feed(current_bucket_index)
        current_bucket_index = current_bucket_index + 1
        if current_bucket_index > BUCKETS_COUNT then
            current_bucket_index = 1
        end
    end
    if onchangeyet then
        onchange()
        onchangeyet = false
    end
    if (event.tick%(12)) == 0 then
        -- preffuel = settings.global["preferred-fuel"].value
        -- _fuel = {preffuel, preffuel}
        if pause then
            show()
        end
    end
end)

script.on_event(defines.events.on_gui_click, on_gui_click)

script.on_event(defines.events.on_gui_opened, function(event)
    if event.entity ~= nil then
        if event.entity.last_user == nil then
            event.entity.last_user = game.get_player(event.player_index)
        end
        new_entity(event.entity)
    end
end)

script.on_event(defines.events.on_gui_selection_state_changed, on_sel_change)

script.on_event(defines.events.on_entity_died, on_entity_died)

script.on_event(defines.events.on_player_mined_entity, on_player_mined_entity)

script.on_event(defines.events.on_robot_built_entity, function(event)
    new_entity(event.created_entity)
end)

script.on_event(defines.events.on_entity_cloned, function(event)
    new_entity(event.destination)
end)

script.on_event(defines.events.on_trigger_created_entity, function(event)
    new_entity(event.entity)
end)

script.on_event(defines.events.on_robot_mined_entity, function(event)
    remove_entity(event.entity)
end)

script.on_configuration_changed(onchange)

script.on_load(read_save)

script.on_init(init)