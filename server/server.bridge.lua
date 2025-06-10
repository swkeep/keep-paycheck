local framework_name
local framework_object

if GetResourceState('qb-core') == 'started' then
    framework_name = 'qb-core'
    framework_object = exports['qb-core']:GetCoreObject()
elseif GetResourceState('es_extended') == 'started' then
    framework_name = 'es_extended'
    framework_object = exports['es_extended']:getSharedObject()
end

local framework_funcs = {
    ['qb-core'] = {
        get_player = function(player_id)
            return framework_object.Functions.GetPlayer(player_id)
        end,
        show_notification = function(source, message, notification_type)
            TriggerClientEvent('QBCore:Notify', source, message, notification_type)
        end,
        get_player_identifier = function(player)
            return player.PlayerData.citizenid
        end,
        get_player_by_identifier = function(citizen_id)
            return framework_object.Functions.GetPlayerByCitizenId(citizen_id)
        end,
        get_source = function(player)
            return player and player.PlayerData.source
        end,
        get_character_name = function(player)
            return player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        end,
        add_money_to_player = function(player, account_type, amount)
            player.Functions.AddMoney(account_type, amount, "paycheck-withdraw")
        end
    },
    ['es_extended'] = {
        get_player = function(player_id)
            return framework_object.GetPlayerFromId(player_id)
        end,
        show_notification = function(source, message, notification_type)
            TriggerClientEvent('esx:showNotification', source, message, notification_type)
        end,
        get_player_identifier = function(player)
            return player.identifier
        end,
        get_player_by_identifier = function(identifier)
            return framework_object.GetPlayerFromIdentifier(identifier)
        end,
        get_source = function(player)
            return player and player.source
        end,
        get_character_name = function(player)
            return player.getName()
        end,
        add_money_to_player = function(player, account_type, amount)
            if account_type == 'cash' then account_type = 'money' end
            player.addAccountMoney(account_type, amount, "paycheck-withdraw")
        end
    }
}

function GetFrameworkName() return framework_name end

function GetPlayerObject(player_id)
    return framework_funcs[framework_name].get_player(player_id)
end

function GetPlayerIdentifier(player)
    return framework_funcs[framework_name].get_player_identifier(player)
end

function GetPlayerByIdentifier(identifier)
    return framework_funcs[framework_name].get_player_by_identifier(identifier)
end

function GetPlayerSource(player)
    return framework_funcs[framework_name].get_source(player)
end

function ShowNotification(source, message, notification_type)
    framework_funcs[framework_name].show_notification(source, message, notification_type)
end

function GetCharacterName(player)
    return framework_funcs[framework_name].get_character_name(player)
end

function AddMoneyToPlayer(player, account_type, amount)
    framework_funcs[framework_name].add_money_to_player(player, account_type, amount)
end
