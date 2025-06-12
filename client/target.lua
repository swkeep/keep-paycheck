local active_npcs = {}
local active_npc

function GetActiveNpc() return active_npc end

local function set_ped_variation(ped, variation)
     for component_id, var_data in pairs(variation) do
          if IsPedComponentVariationValid(ped, component_id, var_data.drawable_id, var_data.texture_id) then
               SetPedComponentVariation(ped, component_id, var_data.drawable_id, var_data.texture_id, 0)
          end
     end
end

local function spawn_npc(npc_data)
     if type(npc_data.model) == "string" then
          npc_data.model = GetHashKey(tostring(npc_data.model))
     end

     RequestModel(npc_data.model)
     while not HasModelLoaded(npc_data.model) do
          Wait(0)
     end

     local ped = CreatePed(1, npc_data.model, npc_data.coords, npc_data.networked or false, true)

     if npc_data.variant then
          set_ped_variation(ped, npc_data.variant)
     end

     if npc_data.freeze then
          FreezeEntityPosition(ped, true)
     end

     if npc_data.invincible then
          SetEntityInvincible(ped, true)
     end

     if npc_data.block_events then
          SetBlockingOfNonTemporaryEvents(ped, true)
     end

     if npc_data.anim_dict and npc_data.anim then
          RequestAnimDict(npc_data.anim_dict)
          while not HasAnimDictLoaded(npc_data.anim_dict) do
               Wait(0)
          end

          if type(npc_data.anim) == "table" then
               CreateThread(function()
                    while DoesEntityExist(ped) do
                         local anim = npc_data.anim[math.random(1, #npc_data.anim)]
                         ClearPedTasks(ped)
                         TaskPlayAnim(ped, npc_data.anim_dict, anim, 8.0, 0, -1, npc_data.flag or 1, 0, 0, 0, 0)
                         Wait(7000)
                    end
               end)
          else
               TaskPlayAnim(ped, npc_data.anim_dict, npc_data.anim, 8.0, 0, -1, npc_data.flag or 1, 0, 0, 0, 0)
          end
     end

     if npc_data.scenario then
          SetPedCanPlayAmbientAnims(ped, true)
          TaskStartScenarioInPlace(ped, npc_data.scenario, 0, true)
     end

     if npc_data.voice then
          SetAmbientVoiceName(ped, npc_data.voice_name or 'A_F_Y_BUSINESS_01_WHITE_FULL_01')
     end

     return ped
end

local function register_npc_zone(npc_id, npc_data)
     local box = npc_data.box
     if not box then return end

     local zone_name = "npc_zone_" .. npc_id
     local options = {}

     if Config.simple_paycheck then
          local simple_options = {
               {
                    label = Lang:t('menu.withdraw_menu.withdraw_all'),
                    icon = 'fa-solid fa-money-bill-transfer',
                    event = 'keep-paycheck:server:withdraw_all'
               },
               {
                    label = "Transaction History",
                    icon = 'fa-solid fa-clock-rotate-left',
                    event = 'keep-paycheck:server:get_logs'
               }
          }

          for _, opt in ipairs(simple_options) do
               options[#options + 1] = Config.target_system == 'ox_target' and {
                    name = zone_name .. '_' .. opt.label:gsub(' ', '_'):lower(),
                    label = opt.label,
                    icon = opt.icon,
                    onSelect = function() TriggerServerEvent(opt.event) end,
                    distance = 2.0
               } or {
                    label = opt.label,
                    icon = opt.icon,
                    action = function() TriggerServerEvent(opt.event) end
               }
          end
     else
          options[1] = Config.target_system == 'ox_target' and {
               name = zone_name,
               label = Lang:t('menu.qb_target_label'),
               icon = "fa-solid fa-credit-card",
               onSelect = function()
                    active_npc = active_npcs[npc_id]
                    TriggerEvent("keep-paycheck:menu:open_menu", npc_id)
               end,
               distance = 2.0
          } or {
               icon = "fa-solid fa-credit-card",
               label = Lang:t('menu.qb_target_label'),
               action = function()
                    active_npc = active_npcs[npc_id]
                    TriggerEvent("keep-paycheck:menu:open_menu", npc_id)
               end
          }
     end

     if Config.target_system == 'ox_target' then
          exports.ox_target:addBoxZone({
               coords = npc_data.coords,
               size = vec3(box.l, box.w, box.maxz_offset - box.minz_offset),
               rotation = box.heading,
               debug = false,
               options = options
          })
     else
          exports['qb-target']:AddBoxZone(
               zone_name,
               npc_data.coords,
               box.l,
               box.w,
               {
                    name = zone_name,
                    heading = box.heading,
                    debugPoly = false,
                    minZ = npc_data.coords.z + box.minz_offset,
                    maxZ = npc_data.coords.z + box.maxz_offset,
               },
               {
                    options = options,
                    distance = 2.0,
               }
          )
     end
end

local function remove_npc_zone(npc_id)
     if exports['qb-target'] then exports['qb-target']:RemoveZone("npc_zone_" .. npc_id) end
end

local function to_vec3(vec)
     if not vec then return nil end

     local x = vec.x or vec[1] or 0
     local y = vec.y or vec[2] or 0
     local z = vec.z or vec[3] or 0

     return vector3(x, y, z)
end

local function update_npc_spawns()
     local player_ped = PlayerPedId()
     local player_coords = GetEntityCoords(player_ped)
     local spawn_distance = Config.interaction.spawn_distance
     local despawn_distance = Config.interaction.despawn_distance

     for npc_id, npc_data in pairs(Config.interaction.npcs) do
          local distance = #(player_coords - to_vec3(npc_data.coords))
          if distance <= spawn_distance then
               if not active_npcs[npc_id] or not DoesEntityExist(active_npcs[npc_id]) then
                    local ped = spawn_npc(npc_data)
                    active_npcs[npc_id] = ped
                    register_npc_zone(npc_id, npc_data)
               end
          elseif distance > despawn_distance then
               if active_npcs[npc_id] and DoesEntityExist(active_npcs[npc_id]) then
                    DeleteEntity(active_npcs[npc_id])
                    remove_npc_zone(npc_id)
                    active_npcs[npc_id] = nil
               end
          end
     end
end

CreateThread(function()
     local function getValidValue(value, expectedType, defaultValue)
          return type(value) == expectedType and value or defaultValue
     end

     for _, npc in ipairs(Config.interaction.npcs) do
          local preset = npc.preset
          if preset then
               npc.flag = getValidValue(preset.flag, "number", 1)
               npc.model = getValidValue(preset.model, "string", "MP_F_ExecPA_01")
               npc.variant = getValidValue(preset.variant, "table", {})
               npc.voice = getValidValue(preset.voice, "string", "A_F_Y_BUSINESS_02_WHITE_FULL_01")
               npc.anim_dict = getValidValue(preset.anim_dict, "string", "anim@amb@board_room@stenographer@computer@")
               npc.anim = getValidValue(preset.anim, "table", {})
               npc.freeze = getValidValue(preset.freeze, "boolean", true)
               npc.invincible = getValidValue(preset.invincible, "boolean", true)
               npc.blockevents = getValidValue(preset.blockevents, "boolean", true)
          end
     end

     while true do
          update_npc_spawns()
          Wait(1000)
     end
end)

AddEventHandler('onResourceStop', function(resource_name)
     if resource_name ~= GetCurrentResourceName() then
          return
     end
     for npc_id, ped in pairs(active_npcs) do
          if DoesEntityExist(ped) then
               DeleteEntity(ped)
          end
          remove_npc_zone(npc_id)
     end
end)
