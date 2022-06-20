# Dependencies

- [qb-target](https://github.com/BerkieBb/qb-target)
- [keep-menu](https://github.com/swkeep/keep-menu)

## Installation

## Step 0:

- import sql.sql in your database

## Step 1:

- change code in qb-core/server/functions.lua PaycheckInterval() to

```lua
function PaycheckInterval()
    if next(QBCore.Players) then
        for _, Player in pairs(QBCore.Players) do
            if Player then
                local payment = Player.PlayerData.job.payment
                local citizenid = Player.PlayerData.citizenid

                if Player.PlayerData.job and payment > 0 and (QBShared.Jobs[Player.PlayerData.job.name].offDutyPay or Player.PlayerData.job.onduty) then
                    if QBCore.Config.Money.PayCheckSociety then
                        local account = exports['qb-management']:GetAccount(Player.PlayerData.job.name)
                        if account ~= 0 then -- Checks if player is employed by a society
                            if account < payment then -- Checks if company has enough money to pay society
                                TriggerClientEvent('QBCore:Notify', Player.PlayerData.source, Lang:t('error.company_too_poor'), 'error')
                            else
                                TriggerEvent('keep-paycheck:server:AddMoneyToPayCheck', citizenid,payment,Player.PlayerData.job.name)
                                exports['qb-management']:RemoveMoney(Player.PlayerData.job.name, payment)
                            end
                        else
                            TriggerEvent('keep-paycheck:server:AddMoneyToPayCheck', citizenid,payment,Player.PlayerData.job.name)
                        end
                    else
                        TriggerEvent('keep-paycheck:server:AddMoneyToPayCheck', citizenid,payment,Player.PlayerData.job.name)
                    end
                end
            end
        end
    end
    SetTimeout(QBCore.Config.Money.PayCheckTimeOut * (60 * 1000), PaycheckInterval)
end
```
