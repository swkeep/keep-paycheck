# Dependencies

- [qb-target](https://github.com/BerkieBb/qb-target)
- [keep-menu](https://github.com/swkeep/keep-menu) *(recommended menu)*

# Preview

[![Preview Video](https://img.youtube.com/vi/1MbqnIDTAO0/0.jpg)](https://youtu.be/1MbqnIDTAO0)

## Step 1: Redirect qb-core's paychecks to script

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