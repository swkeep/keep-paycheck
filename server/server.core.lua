local SQL = {
    UPDATE_MONEY = 'UPDATE `keep_paycheck_account` SET `money` = ? WHERE `identifier` = ?',
    INIT_ACCOUNT =
    'INSERT INTO keep_paycheck_account (identifier, money) VALUES (:identifier, :money) ON DUPLICATE KEY UPDATE money = :money',
    LOG_TRANSACTION = [[
        INSERT INTO keep_paycheck_logs (account_id, state, amount, metadata)
        SELECT id, :state, :amount, :metadata
        FROM keep_paycheck_account
        WHERE identifier = :identifier
    ]],
    GET_ACCOUNT = 'SELECT * FROM keep_paycheck_account WHERE identifier = ?',
    GET_MONEY = 'SELECT money FROM keep_paycheck_account WHERE identifier = ?',
    GET_LOGS =
    'SELECT state, amount, metadata, created FROM keep_paycheck_logs WHERE account_id IN (SELECT id FROM keep_paycheck_account WHERE identifier = ?) ORDER BY created DESC LIMIT 15'
}

local framework = GetFrameworkName()

local function log_transaction(identifier, state, amount, metadata)
    local data = {
        identifier = identifier,
        state = state,
        amount = amount,
        metadata = json.encode(metadata)
    }

    MySQL.Async.insert(SQL.LOG_TRANSACTION, data)
end

local function init_account(identifier, amount)
    local data = {
        identifier = identifier,
        money = amount
    }
    MySQL.Async.insert(SQL.INIT_ACCOUNT, data)
end

local function update_money(identifier, amount, cb)
    MySQL.Async.execute(SQL.UPDATE_MONEY, { amount, identifier }, cb)
end

local function withdraw_funds(player, identifier, account_data, amount)
    if type(account_data.money) ~= "number" then
        update_money(identifier, 0)
        return false, 'money type is not a number'
    end

    if account_data.money == 0 then
        return false, 'no money in account'
    end

    if account_data.money < 0 then
        update_money(identifier, 0)
        return false, 'negative money value'
    end

    local remaining = math.floor(account_data.money - amount)
    if remaining < 0 then
        return false, 'insufficient funds'
    end

    update_money(identifier, remaining, function(res)
        if res == 1 then
            AddMoneyToPlayer(player, 'cash', amount)
        else
            -- database probably failed! or disconnected
        end
    end)

    log_transaction(identifier, 0, amount, {
        desc = {
            type = 'to',
            source = {
                identifier = identifier,
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            }
        },
        account = {
            old_value = account_data.money,
            current_value = remaining
        }
    })
    return true, amount
end

local function addmoney_to_paycheck(identifier, amount, job)
    if type(amount) ~= "number" then return false end
    if not (amount >= 0 and amount <= math.maxinteger) then return false end
    local result = MySQL.single.await(SQL.GET_MONEY, { identifier })

    local player = GetPlayerObject(identifier)
    local old_money = result and result.money or 0
    local new_money = old_money + amount

    if result then
        update_money(identifier, new_money)
    else
        init_account(identifier, amount)
    end

    if player then
        local src = GetPlayerSource(player)
        ShowNotification(src, ('$%s was added to your paycheck. New Total: $%s'):format(amount, new_money),
            'success')
    end

    log_transaction(identifier, 1, amount, {
        desc = { type = 'from', source = { job = job or 'unknown' } },
        account = { old_value = old_money, current_value = new_money }
    })
end

RegisterNetEvent('keep-paycheck:server:get_account_info', function()
    local src = source
    local player = GetPlayerObject(src)
    if not player then return end
    local identifier = GetPlayerIdentifier(player)
    local result = MySQL.single.await(SQL.GET_ACCOUNT, { identifier })

    local data = { money = 0 }
    if not result then
        init_account(identifier, 0)
    else
        data.money = result.money
    end

    TriggerClientEvent('keep-paycheck:client:account_info_response', src, data)
end)

RegisterNetEvent('keep-paycheck:server:withdraw_all', function()
    local src = source
    local player = GetPlayerObject(src)
    if not player then return end
    local identifier = GetPlayerIdentifier(player)
    local result = MySQL.single.await(SQL.GET_ACCOUNT, { identifier })

    if not result then
        ShowNotification(src, "Account not found")
        return
    end

    local success, res = withdraw_funds(player, identifier, result, result.money)
    ShowNotification(src, res)

    if success then
        TriggerClientEvent('paycheck:client:withdraw_response', src)
    end
end)

RegisterNetEvent('keep-paycheck:server:withdraw_amount', function(amount)
    local src = source
    local player = GetPlayerObject(src)
    if not player then return end
    local identifier = GetPlayerIdentifier(player)
    local result = MySQL.single.await(SQL.GET_ACCOUNT, { identifier })

    if not result then
        ShowNotification(src, "Account not found")
        return
    end

    local success, res = withdraw_funds(player, identifier, result, amount)
    ShowNotification(src, res)

    if success then
        TriggerClientEvent('paycheck:client:withdraw_response', src)
    end
end)

RegisterNetEvent('keep-paycheck:server:get_logs', function()
    local src = source
    local player = GetPlayerObject(src)
    if not player then return end
    local identifier = GetPlayerIdentifier(player)

    local result = MySQL.Sync.fetchAll(SQL.GET_LOGS, { identifier })
    TriggerClientEvent('paycheck:client:logs_response', src, result)
end)

-- exports
exports('AddToPaycheck', addmoney_to_paycheck)
exports('AddMoneyToPayCheck', addmoney_to_paycheck)

AddEventHandler('keep-paycheck:server:AddMoneyToPayCheck', addmoney_to_paycheck)
AddEventHandler('keep-paycheck:server:AddToPayCheck', addmoney_to_paycheck)

local function get_qbcore_paycheck_data(player, jobs, society_payment)
    if framework ~= 'qb-core' then return nil end

    local player_job = player.PlayerData.job
    local job_name = player_job.name
    local job_grade = tostring(player_job.grade.level)
    local payment = jobs[job_name].grades[job_grade].payment or player_job.payment
    local should_pay = player_job and payment > 0 and (jobs[job_name].offDutyPay or player_job.onduty)

    return {
        should_pay = should_pay,
        amount = payment,
        job_name = job_name,
        society_payment = society_payment,
        source = player.PlayerData.source,
        identifier = player.PlayerData.citizenid
    }
end

-- move these in bridge
local function get_society_money_qbcore(job_name)
    if GetResourceState('qb-banking') == 'started' then
        return exports['qb-banking']:GetAccountBalance(job_name)
    elseif GetResourceState('qb-management') == 'started' then
        return exports['qb-management']:GetAccount(job_name)
    end

    return 0
end

local function remove_society_money_qbcore(job_name, amount)
    if GetResourceState('qb-banking') == 'started' then
        exports['qb-banking']:RemoveMoney(job_name, amount, 'Employee Paycheck')
    elseif GetResourceState('qb-management') == 'started' then
        exports['qb-management']:RemoveMoney(job_name, amount)
    end
end

local function get_esx_paycheck_data(xPlayer)
    if framework ~= 'esx' then return nil end

    return {
        should_pay = xPlayer.job.grade_salary > 0,
        amount = xPlayer.job.grade_salary,
        job_name = xPlayer.job.name,
        society_payment = Config.EnableSocietyPayouts,
        source = xPlayer.source,
        identifier = xPlayer.identifier
    }
end

local function handle_paycheck(identifier, amount, job_name, src, society_payment)
    if society_payment then
        local society_balance = 0

        if framework == 'qbcore' then
            society_balance = get_society_money_qbcore(job_name)
        elseif framework == 'esx' then
            -- -- ESX requires async handling
            -- get_society_money_esx(job_name, function(balance)
            --     society_balance = balance
            --     if society_balance >= amount then
            --         addmoney_to_paycheck(identifier, amount, job_name)
            --         remove_society_money_esx(job_name, amount)
            --         ShowNotification(source, ('Received paycheck: $%s'):format(amount))
            --     else
            --         ShowNotification(source, 'Company is too poor to pay you', 'error')
            --     end
            -- end)
            return
        end

        if society_balance >= amount then
            addmoney_to_paycheck(identifier, amount, job_name)
            if framework == 'qbcore' then
                remove_society_money_qbcore(job_name, amount)
            end
            ShowNotification(src, ('Received paycheck: $%s'):format(amount))
        else
            ShowNotification(src, 'Company is too poor to pay you', 'error')
        end
    else
        addmoney_to_paycheck(identifier, amount, job_name)
        ShowNotification(src, ('Received paycheck: $%s'):format(amount))
    end
end

local function qbcore_paycheck(players, jobs, pay_check_society)
    if not next(players) then return end

    for _, Player in pairs(players) do
        if Player then
            local paycheckData = get_qbcore_paycheck_data(Player, jobs, pay_check_society)
            if paycheckData and paycheckData.should_pay then
                handle_paycheck(
                    paycheckData.identifier,
                    paycheckData.amount,
                    paycheckData.job_name,
                    paycheckData.source,
                    paycheckData.society_payment
                )
            end
        end
    end
end

exports('QbcorePaycheckHandler', qbcore_paycheck)
