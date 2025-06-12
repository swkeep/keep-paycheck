local function initialize()
  local queries = {
    [[
CREATE TABLE IF NOT EXISTS `keep_paycheck_account` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(255) NOT NULL,
  `money` BIGINT DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_citizenid` (`identifier`)
) ENGINE = InnoDB AUTO_INCREMENT = 1 DEFAULT CHARSET = utf8mb4;
         ]],
    [[
CREATE TABLE IF NOT EXISTS `keep_paycheck_logs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `account_id` INT UNSIGNED NOT NULL,
  `state` TINYINT(1) DEFAULT 0,
  `amount` INT DEFAULT 0,
  `metadata` TEXT NOT NULL,
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY (`account_id`),
  CONSTRAINT `fk_paycheck_logs_account` FOREIGN KEY (`account_id`) REFERENCES `keep_paycheck_account`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB AUTO_INCREMENT = 1 DEFAULT CHARSET = utf8mb4;
         ]]
  }

  for _, query in ipairs(queries) do
    local affectedRows = MySQL.query.await(query, {})
    if affectedRows then
      print("^2keep-paycheck -> Database table initialized.^0")
    else
      print("^1keep-paycheck -> Failed to initialize the database table.^0")
    end
  end
end

CreateThread(initialize)
