# Dependencies

- qb-input or [ox_lib](#)
- [qb-target](https://github.com/BerkieBb/qb-target) or [ox_target](#)
- [qb-menu](#) or [ox_lib](#) or [keep-menu](https://github.com/swkeep/keep-menu)

# Preview

[![Preview Video](https://img.youtube.com/vi/1MbqnIDTAO0/0.jpg)](https://youtu.be/1MbqnIDTAO0)

## Installation

### For qb-core

1. Edit `qb-core/server/functions.lua`  
   *(Make sure you have a backup of this file first)*

2. Replace the code in `PaycheckInterval()` with:

```lua
function PaycheckInterval()
    local pay_check_society = QBCore.Config.Money.PayCheckSociety

    if GetResourceState('keep-paycheck') == "started" and type(exports['keep-paycheck'].QbcorePaycheckHandler) == 'function' then
        exports['keep-paycheck']:QbcorePaycheckHandler(QBCore.Players, QBShared.Jobs, pay_check_society)
    else
        warn("keep-paycheck is not started!")
    end
    SetTimeout(QBCore.Config.Money.PayCheckTimeOut * (60 * 1000), PaycheckInterval)
end
```

### For ESX

1. Uncomment ox_lib from `fxmanifest.lua`:

    ```lua
    shared_scripts {
        "@ox_lib/init.lua", --- this line 
        'locale/locale.lua',
        'locale/en.lua',
        'shared.config.lua',
    }
    ```

2. Set the following values to `ox_lib`:
   - `Config.menu`
   - `Config.input`

3. Set the Config.target_system to `ox_target`

4. Edit `es_extended/server/modules/paycheck.lua` *(Make sure you have a backup of this file first)*

5. Replace the code in `StartPayCheck()` with:

```lua
function StartPayCheck()
    CreateThread(function()
        while true do
            Wait(Config.PaycheckInterval)

            local society_payouts = Config.EnableSocietyPayouts
            local Offduty_multiplier = Config.OffDutyPaycheckMultiplier

            if GetResourceState('keep-paycheck') == "started" and type(exports['keep-paycheck'].ESXPaycheckHandler) == 'function' then
                exports['keep-paycheck']:ESXPaycheckHandler(ESX.Players, society_payouts, Offduty_multiplier)
            else
                warn("keep-paycheck is not started!")
            end
        end
    end)
end

```
