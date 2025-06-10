local menu = {}

AddEventHandler('keep-paycheck:menu:open_menu', function()
     TriggerServerEvent("keep-paycheck:server:get_account_info")
end)

local function play_ambient_speech(word)
     if word == 'hi' then
          PlayPedAmbientSpeechNative(GetActiveNpc(), 'GENERIC_HI', 'Speech_Params_Force_Normal_Clear')
     elseif word == 'whatever' then
          PlayPedAmbientSpeechNative(GetActiveNpc(), 'GENERIC_WHATEVER', 'Speech_Params_Force_Frontend')
     elseif word == 'thanks' then
          PlayPedAmbientSpeechNative(GetActiveNpc(), 'GENERIC_THANKS', 'Speech_Params_Force_Shouted_Critical')
     end
end

local function format_int(number)
     local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
     int = int:reverse():gsub("(%d%d%d)", "%1,")
     return minus .. int:reverse():gsub("^,", "") .. fraction
end

local function withdraw_all(maximum)
     if maximum == 0 then
          ShowNotification(Lang:t('info.no_money_in_account'), "primary")
          return
     end
     TriggerServerEvent("keep-paycheck:server:withdraw_all")
end

local function withdraw_amount(maximum)
     if maximum == 0 then
          ShowNotification(Lang:t('info.no_money_in_account'), "primary")
          return
     end

     local input = exports['qb-input']:ShowInput({
          header = Lang:t('menu.withdraw_amount.header'),
          submitText = "Submit",
          inputs = {
               {
                    text = Lang:t('menu.withdraw_amount.textbox') .. maximum,
                    name = "amount",
                    type = "number",
                    isRequired = true
               }
          }
     })

     if input then
          if not input.amount then return end
          local amount = tonumber(input.amount)
          if type(amount) == "string" then
               ShowNotification(Lang:t('error.bad_input'), "error")
               return
          end
          if not (0 < amount) then
               ShowNotification(Lang:t('error.money_amount_more_than_zero'), "error")
               withdraw_amount(maximum)
               return
          end

          if amount > maximum then
               ShowNotification(Lang:t('error.can_not_withdraw_much') .. amount, "error")
               return
          end

          if not (amount <= maximum) and amount < math.maxinteger then
               ShowNotification(Lang:t('error.can_not_withdraw_much') .. amount, "error")
               withdraw_amount(maximum)
               return
          end

          TriggerServerEvent("keep-paycheck:server:withdraw_amount", input.amount)
     end
end

function menu.landing(data)
     if not data then
          ShowNotification(Lang:t('error.failed_to_open_menu'), "error")
          return
     end
     play_ambient_speech('hi')
     TriggerEvent('animations:client:EmoteCommandStart', { "wait10" })

     local money = string.format(Lang:t('menu.withdraw_menu.money_string'), format_int(data.money))
     local Menu = {
          {
               header = Lang:t('menu.withdraw_menu.header'),
               icon = 'fa-solid fa-credit-card',
               is_header = true,
               disabled = true
          },
          {
               header = Lang:t('menu.withdraw_menu.account_Information'),
               subheader = money,
               icon = 'fa-solid fa-hand-holding-dollar',
               submenu = false,
          },
          {
               header = Lang:t('menu.withdraw_menu.withdraw_all'),
               icon = 'fa-solid fa-money-bill-transfer',
               action = function()
                    TriggerEvent('animations:client:EmoteCommandStart', { "c" })
                    withdraw_all(data.money)
               end
          },
          {
               header = Lang:t('menu.withdraw_menu.withdraw_amount'),
               icon = 'fa-solid fa-arrow-up-wide-short',
               submenu = true,
               action = function()
                    TriggerEvent('animations:client:EmoteCommandStart', { "c" })
                    withdraw_amount(data.money)
               end
          },
          {
               header = Lang:t('menu.withdraw_menu.transaction_history'),
               icon = 'fa-solid fa-clock-rotate-left',
               submenu = true,
               action = function()
                    TriggerEvent('animations:client:EmoteCommandStart', { "c" })
                    TriggerServerEvent("keep-paycheck:server:get_logs")
               end
          },
          {
               header = Lang:t('menu.leave'),
               event = "keep-menu:closeMenu",
               leave = true
          }
     }

     exports['keep-menu']:createMenu(Menu)
end

local function generate_log_entry(transaction)
     local metadata = json.decode(transaction.metadata) or {}
     local account = metadata.account or { old_value = 0, current_value = 0 }
     local source = metadata.desc and metadata.desc.source or {}

     local header, icon
     if transaction.state then
          header = string.format(Lang:t('menu.logs_menu.recived'), format_int(transaction.amount))
          icon = "fa-solid fa-arrow-right-to-bracket"
     else
          header = string.format(Lang:t('menu.logs_menu.withdraw'), format_int(transaction.amount))
          icon = "fa-solid fa-arrow-right-from-bracket"
     end

     if source.name then
          header = header .. Lang:t('menu.logs_menu.to') .. source.name
     end
     if source.job then
          header = header .. Lang:t('menu.logs_menu.from') .. source.job
     end

     return {
          header = header,
          subheader = string.format(Lang:t('menu.logs_menu.before'), format_int(account.old_value)),
          footer = string.format(Lang:t('menu.logs_menu.after'), format_int(account.current_value)),
          icon = icon
     }
end

function menu.logs_menu(data)
     if data == nil then return end
     play_ambient_speech('whatever')

     local Menu = {
          {
               header = Lang:t('menu.logs_menu.paycheck_logs'),
               icon = 'fa-solid fa-list',
               is_header = true,
               disabled = true
          },
          {
               header = Lang:t('menu.leave'),
               event = "keep-menu:closeMenu",
               leave = true
          },
          {
               header = Lang:t('menu.back'),
               action = function()
                    TriggerServerEvent("keep-paycheck:server:get_account_info")
               end,
               back = true
          },
     }

     for _, transaction in pairs(data) do
          Menu[#Menu + 1] = generate_log_entry(transaction)
     end

     exports['keep-menu']:createMenu(Menu)
end

RegisterNetEvent("keep-paycheck:client:account_info_response", menu.landing)

RegisterNetEvent("paycheck:client:withdraw_response", function()
     play_ambient_speech('thanks')
     TriggerEvent('animations:client:EmoteCommandStart', { "ID" })
end)

RegisterNetEvent("paycheck:client:logs_response", menu.logs_menu)
