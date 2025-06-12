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
        show_notification = function(message, notification_type)
            framework_object.Functions.Notify(message, notification_type)
        end,
    },
    ['es_extended'] = {
        show_notification = function(message, notification_type)
            framework_object.ShowNotification(message, notification_type)
        end,
    }
}

function GetFrameworkName() return framework_name end

function ShowNotification(message, notification_type)
    framework_funcs[framework_name].show_notification(message, notification_type)
end
