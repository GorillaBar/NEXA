MySQL = module("modules/MySQL")

Proxy = module("lib/Proxy")
Tunnel = module("lib/Tunnel")
Lang = module("lib/Lang")
Debug = module("lib/Debug")

local config = module("cfg/base")
local version = module("version")


local verify_card = {
    ["type"] = "AdaptiveCard",
    ["$schema"] = "http://adaptivecards.io/schemas/adaptive-card.json",
    ["version"] = "1.3",
    ["backgroundImage"] = {
        ["url"] = "https://i.imgur.com/fy20wFK.png",
    },
    ["body"] = {
        {
            ["type"] = "TextBlock",
            ["text"] = "Welcome to nexa, to join our server please verify your discord account by following the steps below.",
            ["wrap"] = true,
            ["weight"] = "Bolder"
        },
        {
            ["type"] = "Container",
            ["items"] = {
                {
                    ["type"] = "TextBlock",
                    ["text"] = "1. Join the nexa discord (discord.gg/nexa)",
                    ["wrap"] = true,
                },
                {
                    ["type"] = "TextBlock",
                    ["text"] = "2. Type the following command",
                    ["wrap"] = true,
                },
                {
                    ["type"] = "TextBlock",
                    ["color"] = "Attention",
                    ["text"] = "3. !verify NULL",
                    ["wrap"] = true,
                }
            }
        },
        {
            ["type"] = "ActionSet",
            ["actions"] = {
                {
                    ["type"] = "Action.OpenUrl",
                    ["title"] = "Join Discord",
                    ["url"] = "https://discord.gg/nexa"
                },
                {
                    ["type"] = "Action.Submit",
                    ["id"] = "enter",
                    ["title"] = "Enter nexa",
                }
            }
        },
    }
}

Debug.active = config.debug
nexa = {}
Proxy.addInterface("nexa",nexa)

tnexa = {}
Tunnel.bindInterface("nexa",tnexa) -- listening for client tunnel

-- load language 
local dict = module("cfg/lang/"..config.lang) or {}
nexa.lang = Lang.new(dict)

-- init
nexaclient = Tunnel.getInterface("nexa","nexa") -- server -> client tunnel

nexa.users = {} -- will store logged users (id) by first identifier
nexa.rusers = {} -- store the opposite of users
nexa.user_tables = {} -- user data tables (logger storage, saved to database)
nexa.user_tmp_tables = {} -- user tmp data tables (logger storage, not saved)
nexa.user_sources = {} -- user sources 
-- queries
Citizen.CreateThread(function()
    Wait(1000) -- Wait for GHMatti to Initialize
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_users(
    id INTEGER AUTO_INCREMENT,
    last_login VARCHAR(100),
    username VARCHAR(100),
    banned BOOLEAN,
    bantime VARCHAR(100) NOT NULL DEFAULT "",
    banreason VARCHAR(1000) NOT NULL DEFAULT "",
    banadmin VARCHAR(100) NOT NULL DEFAULT "",
    baninfo VARCHAR(2000) NOT NULL DEFAULT "",
    CONSTRAINT pk_user PRIMARY KEY(id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_user_ids (
    identifier VARCHAR(100) NOT NULL,
    user_id INTEGER,
    banned BOOLEAN,
    CONSTRAINT pk_user_ids PRIMARY KEY(identifier)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_user_tokens (
    token VARCHAR(200),
    user_id INTEGER,
    banned BOOLEAN NOT NULL DEFAULT 0,
    CONSTRAINT pk_user_tokens PRIMARY KEY(token)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_user_data(
    user_id INTEGER,
    dkey VARCHAR(100),
    dvalue TEXT,
    CONSTRAINT pk_user_data PRIMARY KEY(user_id,dkey),
    CONSTRAINT fk_user_data_users FOREIGN KEY(user_id) REFERENCES nexa_users(id) ON DELETE CASCADE
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_user_moneys(
    user_id INTEGER,
    wallet bigint,
    bank bigint,
    CONSTRAINT pk_user_moneys PRIMARY KEY(user_id),
    CONSTRAINT fk_user_moneys_users FOREIGN KEY(user_id) REFERENCES nexa_users(id) ON DELETE CASCADE
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_srv_data(
    dkey VARCHAR(100),
    dvalue TEXT,
    CONSTRAINT pk_srv_data PRIMARY KEY(dkey)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_user_vehicles(
    user_id INTEGER,
    vehicle VARCHAR(100),
    vehicle_plate varchar(255) NOT NULL,
    nitro INT(11) NOT NULL DEFAULT 0,
    rented BOOLEAN NOT NULL DEFAULT 0,
    rentedid varchar(200) NOT NULL DEFAULT '',
    rentedtime varchar(2048) NOT NULL DEFAULT '',
    locked BOOLEAN NOT NULL DEFAULT 0,
    fuel_level FLOAT NOT NULL DEFAULT 100,
    impounded BOOLEAN NOT NULL DEFAULT 0,
    impound_info varchar(2048) NOT NULL DEFAULT '',
    impound_time VARCHAR(100) NOT NULL DEFAULT '',
    CONSTRAINT pk_user_vehicles PRIMARY KEY(user_id,vehicle),
    CONSTRAINT fk_user_vehicles_users FOREIGN KEY(user_id) REFERENCES nexa_users(id) ON DELETE CASCADE
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_user_identities(
    user_id INTEGER,
    registration VARCHAR(100),
    phone VARCHAR(100),
    firstname VARCHAR(100),
    name VARCHAR(100),
    age INTEGER,
    CONSTRAINT pk_user_identities PRIMARY KEY(user_id),
    CONSTRAINT fk_user_identities_users FOREIGN KEY(user_id) REFERENCES nexa_users(id) ON DELETE CASCADE,
    INDEX(registration),
    INDEX(phone)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_warnings (
    warning_id INT AUTO_INCREMENT,
    user_id INT,
    warning_type VARCHAR(25),
    duration INT,
    admin VARCHAR(100),
    warning_date DATE,
    reason VARCHAR(2000),
    PRIMARY KEY (warning_id)
    )
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_gangs (
    gangname VARCHAR(255) NULL DEFAULT NULL,
    gangmembers VARCHAR(3000) NULL DEFAULT NULL,
    funds BIGINT NULL DEFAULT NULL,
    logs VARCHAR(65535) NULL DEFAULT NULL,
    webhook VARCHAR(255) NULL DEFAULT NULL,
    lockedfunds BOOLEAN NOT NULL DEFAULT 0,
    gangfit TEXT NULL DEFAULT NULL,
    gangdiscord TEXT NULL DEFAULT NULL,
    PRIMARY KEY (gangname)
    )
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_gang_users (
    user_id INT,
    gangname VARCHAR(255) NULL DEFAULT NULL,
    PRIMARY KEY (user_id)
    )
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_user_notes (
    user_id INT,
    info VARCHAR(500) NULL DEFAULT NULL,
    PRIMARY KEY (user_id)
    )
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_user_homes(
    user_id INTEGER,
    home VARCHAR(100),
    number INTEGER,
    rented BOOLEAN NOT NULL DEFAULT 0,
    rentedid varchar(200) NOT NULL DEFAULT '',
    rentedtime varchar(2048) NOT NULL DEFAULT '',
    CONSTRAINT pk_user_homes PRIMARY KEY(home),
    CONSTRAINT fk_user_homes_users FOREIGN KEY(user_id) REFERENCES nexa_users(id) ON DELETE CASCADE,
    UNIQUE(home,number)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_bans_offenses(
    UserID INTEGER AUTO_INCREMENT,
    Rules TEXT NULL DEFAULT NULL,
    points INT(10) NOT NULL DEFAULT 0,
    CONSTRAINT pk_user PRIMARY KEY(UserID)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_subscriptions(
    user_id INT(11),
    plathours FLOAT(10) NULL DEFAULT NULL,
    plushours FLOAT(10) NULL DEFAULT NULL,
    last_used VARCHAR(100) NOT NULL DEFAULT "",
    redeemed BOOLEAN NOT NULL DEFAULT 0,
    CONSTRAINT pk_user PRIMARY KEY(user_id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_casino_chips(
    user_id INT(11),
    chips bigint NOT NULL DEFAULT 0,
    casino_stats TEXT NULL DEFAULT NULL,
    CONSTRAINT pk_user PRIMARY KEY(user_id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_verification(
    user_id INT(11),
    code VARCHAR(100) NULL DEFAULT NULL,
    discord_id VARCHAR(100) NULL DEFAULT NULL,
    verified TINYINT NULL DEFAULT NULL,
    CONSTRAINT pk_user PRIMARY KEY(user_id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS phone_users_contacts (
    id int(11) NOT NULL AUTO_INCREMENT,
    identifier varchar(60) CHARACTER SET utf8mb4 DEFAULT NULL,
    number varchar(10) CHARACTER SET utf8mb4 DEFAULT NULL,
    display varchar(64) CHARACTER SET utf8mb4 NOT NULL DEFAULT '-1',
    PRIMARY KEY (id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS phone_messages (
    id int(11) NOT NULL AUTO_INCREMENT,
    transmitter varchar(10) NOT NULL,
    receiver varchar(10) NOT NULL,
    message varchar(255) NOT NULL DEFAULT '0',
    time timestamp NOT NULL DEFAULT current_timestamp(),
    isRead int(11) NOT NULL DEFAULT 0,
    owner int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS phone_calls (
    id int(11) NOT NULL AUTO_INCREMENT,
    owner varchar(10) NOT NULL COMMENT 'Num such owner',
    num varchar(10) NOT NULL COMMENT 'Reference number of the contact',
    incoming int(11) NOT NULL COMMENT 'Defined if we are at the origin of the calls',
    time timestamp NOT NULL DEFAULT current_timestamp(),
    accepts int(11) NOT NULL COMMENT 'Calls accept or not',
    PRIMARY KEY (id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS phone_app_chat (
    id int(11) NOT NULL AUTO_INCREMENT,
    channel varchar(20) NOT NULL,
    message varchar(255) NOT NULL,
    time timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS twitter_tweets (
    id int(11) NOT NULL AUTO_INCREMENT,
    authorId int(11) NOT NULL,
    realUser varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
    message varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL,
    time timestamp NOT NULL DEFAULT current_timestamp(),
    likes int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    KEY FK_twitter_tweets_twitter_accounts (authorId),
    CONSTRAINT FK_twitter_tweets_twitter_accounts FOREIGN KEY (authorId) REFERENCES twitter_accounts (id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS twitter_likes (
    id int(11) NOT NULL AUTO_INCREMENT,
    authorId int(11) DEFAULT NULL,
    tweetId int(11) DEFAULT NULL,
    PRIMARY KEY (id),
    KEY FK_twitter_likes_twitter_accounts (authorId),
    KEY FK_twitter_likes_twitter_tweets (tweetId),
    CONSTRAINT FK_twitter_likes_twitter_accounts FOREIGN KEY (authorId) REFERENCES twitter_accounts (id),
    CONSTRAINT FK_twitter_likes_twitter_tweets FOREIGN KEY (tweetId) REFERENCES twitter_tweets (id) ON DELETE CASCADE
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS twitter_accounts (
    id int(11) NOT NULL AUTO_INCREMENT,
    username varchar(50) CHARACTER SET utf8 NOT NULL DEFAULT '0',
    password varchar(50) COLLATE utf8mb4_bin NOT NULL DEFAULT '0',
    avatar_url varchar(255) COLLATE utf8mb4_bin DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY username (username)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_weapon_whitelists (
    user_id INT(11),
    weapon_info varchar(2048) DEFAULT '{}',
    PRIMARY KEY (user_id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_weapon_codes (
    user_id INT(11),
    spawncode varchar(2048) NOT NULL DEFAULT '',
    weapon_code int(11) NOT NULL DEFAULT 0,
    PRIMARY KEY (weapon_code)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_staff_tickets (
    user_id INT(11),
    ticket_count INT(11) NOT NULL DEFAULT 0,
    username VARCHAR(100) NOT NULL,
    PRIMARY KEY (user_id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_owned_plates (
    user_id INT(11),
    plate_text VARCHAR(255) NOT NULL,
    vehicle_used_on VARCHAR(25) NOT NULL,
    PRIMARY KEY (plate_text)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_store_data (
    uuid VARCHAR(255) NOT NULL,
    user_id INT(11) NOT NULL,
    store_item VARCHAR(255) NOT NULL,
    PRIMARY KEY (uuid)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_stats_data (
    user_id INT(11) NOT NULL,
    monthly_stats LONGTEXT NOT NULL,
    total_stats LONGTEXT NOT NULL,
    PRIMARY KEY (user_id)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_vehicle_mods (
    mod_uuid INT(11) NOT NULL AUTO_INCREMENT,
    user_id INT(11),
    spawncode VARCHAR(350),
    enabled BOOLEAN NOT NULL DEFAULT 1,
    savekey VARCHAR(350),
    `mod` VARCHAR(350),
    PRIMARY KEY (mod_uuid)
    );
    ]])
    MySQL.SingleQuery([[
    CREATE TABLE IF NOT EXISTS nexa_vehicle_stancer (
    stancer_uuid INT(11) NOT NULL AUTO_INCREMENT,
    user_id INT(11),
    spawncode VARCHAR(350),
    `mod` VARCHAR(100),
    value VARCHAR(100) NOT NULL DEFAULT "10",
    PRIMARY KEY (stancer_uuid)
    );
    ]])
    MySQL.SingleQuery("ALTER TABLE nexa_users ADD IF NOT EXISTS bantime varchar(100) NOT NULL DEFAULT '';")
    MySQL.SingleQuery("ALTER TABLE nexa_users ADD IF NOT EXISTS banreason varchar(100) NOT NULL DEFAULT '';")
    MySQL.SingleQuery("ALTER TABLE nexa_users ADD IF NOT EXISTS banadmin varchar(100) NOT NULL DEFAULT ''; ")
    MySQL.SingleQuery("ALTER TABLE nexa_user_vehicles ADD IF NOT EXISTS nitro INT(11) NOT NULL DEFAULT 0 AFTER vehicle_plate;")
    MySQL.SingleQuery("ALTER TABLE nexa_user_vehicles ADD IF NOT EXISTS rented BOOLEAN NOT NULL DEFAULT 0;")
    MySQL.SingleQuery("ALTER TABLE nexa_user_vehicles ADD IF NOT EXISTS rentedid varchar(200) NOT NULL DEFAULT '';")
    MySQL.SingleQuery("ALTER TABLE nexa_user_vehicles ADD IF NOT EXISTS rentedtime varchar(2048) NOT NULL DEFAULT '';")
end)

MySQL.createCommand("nexa/create_user","INSERT INTO nexa_users(banned) VALUES(false)")
MySQL.createCommand("nexa/add_identifier","INSERT INTO nexa_user_ids(identifier,user_id) VALUES(@identifier,@user_id)")
MySQL.createCommand("nexa/userid_byidentifier","SELECT user_id FROM nexa_user_ids WHERE identifier = @identifier")
MySQL.createCommand("nexa/identifier_all","SELECT * FROM nexa_user_ids WHERE identifier = @identifier")
MySQL.createCommand("nexa/select_identifier_byid_all","SELECT * FROM nexa_user_ids WHERE user_id = @id")

MySQL.createCommand("nexa/set_userdata","REPLACE INTO nexa_user_data(user_id,dkey,dvalue) VALUES(@user_id,@key,@value)")
MySQL.createCommand("nexa/get_userdata","SELECT dvalue FROM nexa_user_data WHERE user_id = @user_id AND dkey = @key")

MySQL.createCommand("nexa/set_srvdata","REPLACE INTO nexa_srv_data(dkey,dvalue) VALUES(@key,@value)")
MySQL.createCommand("nexa/get_srvdata","SELECT dvalue FROM nexa_srv_data WHERE dkey = @key")

MySQL.createCommand("nexa/get_banned","SELECT banned FROM nexa_users WHERE id = @user_id")
MySQL.createCommand("nexa/set_banned","UPDATE nexa_users SET banned = @banned, bantime = @bantime,  banreason = @banreason,  banadmin = @banadmin, baninfo = @baninfo WHERE id = @user_id")
MySQL.createCommand("nexa/set_identifierbanned","UPDATE nexa_user_ids SET banned = @banned WHERE identifier = @iden")
MySQL.createCommand("nexa/getbanreasontime", "SELECT * FROM nexa_users WHERE id = @user_id")

MySQL.createCommand("nexa/set_last_login","UPDATE nexa_users SET last_login = @last_login WHERE id = @user_id")
MySQL.createCommand("nexa/get_last_login","SELECT last_login FROM nexa_users WHERE id = @user_id")
MySQL.createCommand("nexa/setusername","UPDATE nexa_users SET username = @username WHERE id = @user_id")

--Token Banning 
MySQL.createCommand("nexa/add_token","INSERT INTO nexa_user_tokens(token,user_id) VALUES(@token,@user_id)")
MySQL.createCommand("nexa/check_token","SELECT user_id, banned FROM nexa_user_tokens WHERE token = @token")
MySQL.createCommand("nexa/check_token_userid","SELECT token FROM nexa_user_tokens WHERE user_id = @id")
MySQL.createCommand("nexa/ban_token","UPDATE nexa_user_tokens SET banned = @banned WHERE token = @token")
--Token Banning

-- removing anticheat ban entry
MySQL.createCommand("ac/delete_ban","DELETE FROM nexa_anticheat WHERE @user_id = user_id")


-- init tables


-- identification system

function nexa.getUserIdByIdentifiers(ids, cbr)
    local task = Task(cbr)
    if ids ~= nil and #ids then
        local i = 0
        local function search()
            i = i+1
            if i <= #ids then
                if (string.find(ids[i], "ip:") == nil) then
                    MySQL.query("nexa/userid_byidentifier", {identifier = ids[i]}, function(rows, affected)
                        if #rows > 0 then  -- found
                            task({rows[1].user_id})
                        else -- not found
                            search()
                        end
                    end)
                else
                    search()
                end
            else -- no ids found, create user
                MySQL.query("nexa/create_user", {}, function(rows, affected)
                    if rows.affectedRows > 0 then
                        local user_id = rows.insertId
                        -- add identifiers
                        for l,w in pairs(ids) do
                            if (string.find(w, "ip:") == nil) then
                                MySQL.execute("nexa/add_identifier", {user_id = user_id, identifier = w})
                            end
                        end
                        for k,v in pairs(nexa.getUsers()) do
                            nexaclient.notify(v, {'~g~You have received £25,000 as someone new has joined the server.'})
                            nexa.giveBankMoney(k, 25000)
                        end
                        task({user_id})
                    else
                        task()
                    end
                end)
            end
        end
        search()
    else
        task()
    end
end

function nexa.ReLoadChar(source)
    local name = GetPlayerName(source)
    local ids = GetPlayerIdentifiers(source)
    nexa.getUserIdByIdentifiers(ids, function(user_id)
        if user_id ~= nil then  
            nexa.StoreTokens(source, user_id) 
            if nexa.rusers[user_id] == nil then -- not present on the server, init
                nexa.users[ids[1]] = user_id
                nexa.rusers[user_id] = ids[1]
                nexa.user_tables[user_id] = {}
                nexa.user_tmp_tables[user_id] = {}
                nexa.user_sources[user_id] = source
                nexa.getUData(user_id, "nexa:datatable", function(sdata)
                    local data = json.decode(sdata)
                    if type(data) == "table" then nexa.user_tables[user_id] = data end
                    local tmpdata = nexa.getUserTmpTable(user_id)
                    nexa.getLastLogin(user_id, function(last_login)
                        tmpdata.last_login = last_login or ""
                        tmpdata.spawns = 0
                        local last_login_stamp = os.date("%d/%m/%Y at %X")
                        MySQL.execute("nexa/set_last_login", {user_id = user_id, last_login = last_login_stamp})
                        print("[nexa] "..name.." ^2joined^0 | (Perm ID = "..user_id..")")
                        TriggerEvent("nexa:playerJoin", user_id, source, name, tmpdata.last_login)
                    end)
                end)
            else -- already connected
                print("[nexa] "..name.." ^2re-joined^0 | (Perm ID = "..user_id..")")
                TriggerEvent("nexa:playerRejoin", user_id, source, name)
                local tmpdata = nexa.getUserTmpTable(user_id)
                tmpdata.spawns = 0
            end
        end
    end)
end

exports("nexabot", function(method_name, params, cb)
    if cb then 
        cb(nexa[method_name](table.unpack(params)))
    else 
        return nexa[method_name](table.unpack(params))
    end
end)

function nexa.notify(source, message)
    nexaclient.notify(source, {message})
end

function nexa.GetPlayerName(permid)
    if not tonumber(permid) then
        return "Unknown"
    end
    local source = nexa.getUserSource(permid)
    if source ~= nil and source ~= 0 then
        return tnexa.getDiscordName(source)
    else
        local name = exports['ghmattimysql']:executeSync("SELECT username FROM nexa_users WHERE id = @id", {id = permid})[1].username
        return name
    end
    return "Unknown"
end

function nexa.isBanned(user_id, cbr)
    local task = Task(cbr, {false})
    MySQL.query("nexa/get_banned", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            task({rows[1].banned})
        else
            task()
        end
    end)
end

function nexa.getLastLogin(user_id, cbr)
    local task = Task(cbr,{""})
    MySQL.query("nexa/get_last_login", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            task({rows[1].last_login})
        else
            task()
        end
    end)
end

function nexa.fetchBanReasonTime(user_id,cbr)
    MySQL.query("nexa/getbanreasontime", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then 
            cbr(rows[1].bantime, rows[1].banreason, rows[1].banadmin)
        end
    end)
end

function nexa.setUData(user_id,key,value)
    MySQL.execute("nexa/set_userdata", {user_id = user_id, key = key, value = value})
end

function nexa.getUData(user_id,key,cbr)
    local task = Task(cbr,{""})
    MySQL.query("nexa/get_userdata", {user_id = user_id, key = key}, function(rows, affected)
        if #rows > 0 then
            task({rows[1].dvalue})
        else
            task()
        end
    end)
end

function nexa.setSData(key,value)
    MySQL.execute("nexa/set_srvdata", {key = key, value = value})
end

function nexa.getSData(key, cbr)
    local task = Task(cbr,{""})
    MySQL.query("nexa/get_srvdata", {key = key}, function(rows, affected)
        if rows and #rows > 0 then
            task({rows[1].dvalue})
        else
            task()
        end
    end)
end

-- return user data table for nexa internal persistant connected user storage
function nexa.getUserDataTable(user_id)
    return nexa.user_tables[user_id]
end

function nexa.getUserTmpTable(user_id)
    return nexa.user_tmp_tables[user_id]
end

function nexa.getUserId(source)
    if source ~= nil then
        local ids = GetPlayerIdentifiers(source)
        if ids ~= nil and #ids > 0 then
            return nexa.users[ids[1]]
        end
    end
    return nil
end

-- return map of user_id -> player source
function nexa.getUsers()
    local users = {}
    for k,v in pairs(nexa.user_sources) do
        users[k] = v
    end
    return users
end

-- return source or nil
function nexa.getUserSource(user_id)
    return nexa.user_sources[user_id]
end

function nexa.IdentifierBanCheck(source,user_id,cb)
    for i,v in pairs(GetPlayerIdentifiers(source)) do 
        MySQL.query('nexa/identifier_all', {identifier = v}, function(rows)
            for i = 1,#rows do 
                if rows[i].banned then 
                    if user_id ~= rows[i].user_id then 
                        cb(true, rows[i].user_id, rows[i].identifier)
                    end 
                end
            end
        end)
    end
end

function nexa.BanIdentifiers(user_id, value)
    MySQL.query('nexa/select_identifier_byid_all', {id = user_id}, function(rows)
        for i = 1, #rows do 
            MySQL.execute("nexa/set_identifierbanned", {banned = value, iden = rows[i].identifier })
        end
    end)
end

function nexa.setBanned(user_id,banned,time,reason,admin,baninfo)
    if banned then 
        MySQL.execute("nexa/set_banned", {user_id = user_id, banned = banned, bantime = time, banreason = reason, banadmin = admin, baninfo = baninfo})
        nexa.BanIdentifiers(user_id, true)
        nexa.BanTokens(user_id, true) 
        nexa.BanSystemInfo(user_id, true)
    else 
        MySQL.execute("nexa/set_banned", {user_id = user_id, banned = banned, bantime = "", banreason =  "", banadmin =  "", baninfo = ""})
        nexa.BanIdentifiers(user_id, false)
        nexa.BanTokens(user_id, false) 
        nexa.BanSystemInfo(user_id, false)
        MySQL.execute("ac/delete_ban", {user_id = user_id})
    end 
end

function nexa.ban(adminsource,permid,time,reason,baninfo)
    local adminPermID = nexa.getUserId(adminsource)
    local getBannedPlayerSrc = nexa.getUserSource(tonumber(permid))
    if getBannedPlayerSrc then 
        local bannedPlayerName = tnexa.getDiscordName(getBannedPlayerSrc)
        if tonumber(time) then
            nexa.setBanned(permid,true,time,reason,tnexa.getDiscordName(adminsource),baninfo)
            nexa.kick(getBannedPlayerSrc,"[nexa] Ban expires in: "..calculateTimeRemaining(time).."\nYour ID is: "..permid.."\nReason: " .. reason .. "\nAppeal @ discord.gg/nexa") 
        else
            nexa.setBanned(permid,true,"perm",reason,tnexa.getDiscordName(adminsource),baninfo)
            nexa.kick(getBannedPlayerSrc,"[nexa] Permanent Ban\nYour ID is: "..permid.."\nReason: " .. reason .. "\nAppeal @ discord.gg/nexa") 
        end
        nexaclient.notify(adminsource,{"~g~Banned User ID "..permid..'('..bannedPlayerName..')'})
    else 
        if tonumber(time) then 
            nexa.setBanned(permid,true,time,reason,tnexa.getDiscordName(adminsource),baninfo)
        else 
            nexa.setBanned(permid,true,"perm",reason,tnexa.getDiscordName(adminsource),baninfo)
        end
        nexaclient.notify(adminsource,{"~g~Banned User ID "..permid})
    end
end

function nexa.banConsole(permid,time,reason)
    local adminPermID = "nexa"
    local getBannedPlayerSrc = nexa.getUserSource(tonumber(permid))
    if getBannedPlayerSrc then 
        if tonumber(time) then 
            local banTime = os.time()
            banTime = banTime  + (60 * 60 * tonumber(time))  
            nexa.setBanned(permid,true,banTime,reason, adminPermID)
            nexa.kick(getBannedPlayerSrc,"[nexa] Ban expires in "..calculateTimeRemaining(banTime).."\nYour ID is: "..permid.."\nReason: " .. reason .. "\nBanned by nexa \nAppeal @ discord.gg/nexa") 
        else 
            nexa.setBanned(permid,true,"perm",reason, adminPermID)
            nexa.kick(getBannedPlayerSrc,"[nexa] Permanent Ban\nYour ID is: "..permid.."\nReason: " .. reason .. "\nBanned by nexa \nAppeal @ discord.gg/nexa") 
        end
        print("Successfully banned Perm ID: " .. permid)
    else 
        if tonumber(time) then 
            local banTime = os.time()
            banTime = banTime  + (60 * 60 * tonumber(time))  
            nexa.setBanned(permid,true,banTime,reason, adminPermID)
        else 
            nexa.setBanned(permid,true,"perm",reason, adminPermID)
        end
        print("Successfully banned Perm ID: " .. permid)
    end
end

function nexa.banDiscord(permid,time,reason,adminPermID)
    local getBannedPlayerSrc = nexa.getUserSource(tonumber(permid))
    if tonumber(time) then 
        local banTime = os.time()
        banTime = banTime  + (60 * 60 * tonumber(time))  
        nexa.setBanned(permid,true,banTime,reason, adminPermID)
        if getBannedPlayerSrc then 
            nexa.kick(getBannedPlayerSrc,"[nexa] Ban expires in "..calculateTimeRemaining(banTime).."\nYour ID is: "..permid.."\nReason: " .. reason .. "\nAppeal @ discord.gg/nexa") 
        end
    else 
        nexa.setBanned(permid,true,"perm",reason,  adminPermID)
        if getBannedPlayerSrc then 
            nexa.kick(getBannedPlayerSrc,"[nexa] Permanent Ban\nYour ID is: "..permid.."\nReason: " .. reason .. "\nAppeal @ discord.gg/nexa") 
        end
    end
end

-- To use token banning you need the latest artifacts.
function nexa.StoreTokens(source, user_id) 
    if GetNumPlayerTokens then 
        local numtokens = GetNumPlayerTokens(source)
        for i = 1, numtokens do
            local token = GetPlayerToken(source, i)
            MySQL.query("nexa/check_token", {token = token}, function(rows)
                if token and rows and #rows <= 0 then 
                    MySQL.execute("nexa/add_token", {token = token, user_id = user_id})
                end        
            end)
        end
    end
end


function nexa.CheckTokens(source, user_id) 
    if GetNumPlayerTokens then 
        local banned = false;
        local numtokens = GetNumPlayerTokens(source)
        for i = 1, numtokens do
            local token = GetPlayerToken(source, i)
            local rows = MySQL.asyncQuery("nexa/check_token", {token = token, user_id = user_id})
                if #rows > 0 then 
                if rows[1].banned then 
                    return rows[1].banned, rows[1].user_id
                end
            end
        end
    else 
        return false; 
    end
end

function nexa.BanTokens(user_id, banned) 
    if GetNumPlayerTokens then 
        MySQL.query("nexa/check_token_userid", {id = user_id}, function(id)
            for i = 1, #id do 
                MySQL.execute("nexa/ban_token", {token = id[i].token, banned = banned})
            end
        end)
    end
end

function nexa.BanSystemInfo(user_id, banned) 
    exports["ghmattimysql"]:executeSync("UPDATE nexa_user_info SET banned = @banned WHERE user_id = @user_id", {banned = banned, user_id = user_id})
end


function nexa.kick(source,reason)
    DropPlayer(source,reason)
end

-- tasks

function task_save_datatables()
    TriggerEvent("nexa:save")
    Debug.pbegin("nexa save datatables")
    for k,v in pairs(nexa.user_tables) do
        nexa.setUData(k,"nexa:datatable",json.encode(v))
    end
    Debug.pend()
    SetTimeout(config.save_interval*1000, task_save_datatables)
end
task_save_datatables()

-- handlers

AddEventHandler("playerConnecting",function(name,setMessage,deferrals)
    deferrals.defer()
    local source = source
    Debug.pbegin("playerConnecting")
    local ids = GetPlayerIdentifiers(source)
    if ids ~= nil and #ids > 0 then
        deferrals.update("[nexa] Checking identifiers...")
        nexa.getUserIdByIdentifiers(ids, function(user_id)
            if user_id ~= nil then -- check user validity 
                if nexa.user_sources[user_id] ~= nil then deferrals.done("[nexa] You are already connected to the server.") return end
                deferrals.update("[nexa] Fetching Tokens...")
                nexa.StoreTokens(source, user_id) 
                deferrals.update("[nexa] Checking banned...")
                nexa.isBanned(user_id, function(banned)
                    if not banned then
                        local numtokens = GetNumPlayerTokens(source)
                        if numtokens == 0 then
                            deferrals.done("\n[nexa] Insufficient token count. Please restart FiveM and try again.")
                            return 
                        end
                        nexa.IdentifierBanCheck(source, user_id, function(status, id, bannedIdentifier)
                            if status then
                                deferrals.done("\n[nexa] Permanent Ban\nYour ID: "..user_id.."\nReason: Ban evading is not permitted.\nAppeal @ discord.gg/nexa")
                                nexa.setBanned(user_id,true,"perm",'Ban evading is not permitted.',"nexa")
                                tnexa.sendWebhook('ban-evaders', 'nexa Ban Evade Logs', "> Player Name: **"..name.."**\n> Player Current Perm ID: **"..user_id.."**\n> Player Banned PermID: **"..id.."**\n> Info: **Matched banned identifier: "..bannedIdentifier.."**")
                                return 
                            end
                        end)
                        Debug.pbegin("playerConnecting_delayed")
                        if nexa.rusers[user_id] == nil then -- not present on the server, init
                            ::try_verify::
                            local verified = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_verification WHERE user_id = @user_id", {user_id = user_id})
                            if #verified > 0 then 
                                if verified[1]["verified"] == 0 then
                                    local code = nil
                                    local data_code = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_verification WHERE user_id = @user_id", {user_id = user_id})
                                    code = data_code[1]["code"]
                                    if code == nil then
                                        code = math.random(100000, 999999)
                                    end
                                    ::regen_code::
                                    local checkCode = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_verification WHERE code = @code", {code = code})
                                    if checkCode ~= nil then
                                        if #checkCode > 0 then
                                            code = math.random(100000, 999999)
                                            goto regen_code
                                        end
                                    end
                                    exports["ghmattimysql"]:executeSync("UPDATE nexa_verification SET code = @code WHERE user_id = @user_id", {user_id = user_id, code = code})
                                    local function show_auth_card(code, deferrals, callback)
                                        verify_card["body"][2]["items"][3]["text"] = "3. !verify "..code
                                        deferrals.presentCard(verify_card, callback)
                                    end
                                    local function check_verified(data)
                                        local authenticated = false
                                        repeat
                                            if data.submitId == 'enter' then
                                                local data_verified = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_verification WHERE user_id = @user_id", {user_id = user_id})
                                                local verified_code = data_verified[1]["verified"]
                                                if verified_code == true or verified_code == 1 then
                                                    if nexa.CheckTokens(source, user_id) then 
                                                        deferrals.done("[nexa]: You are banned from this server, please do not try to evade your ban.")
                                                    end
                                                    nexa.users[ids[1]] = user_id
                                                    nexa.rusers[user_id] = ids[1]
                                                    nexa.user_tables[user_id] = {}
                                                    nexa.user_tmp_tables[user_id] = {}
                                                    --nexa.user_sources[user_id] = source
                                                    nexa.getUData(user_id, "nexa:datatable", function(sdata)
                                                        local data = json.decode(sdata)
                                                        if type(data) == "table" then
                                                            nexa.user_tables[user_id] = data
                                                        end
                                                        local tmpdata = nexa.getUserTmpTable(user_id)
                                                        nexa.getLastLogin(user_id, function(last_login)
                                                            tmpdata.last_login = last_login or ""
                                                            tmpdata.spawns = 0
                                                            local last_login_stamp = os.date("%d/%m/%Y at %X")
                                                            MySQL.execute("nexa/set_last_login", {user_id = user_id, last_login = last_login_stamp})
                                                            print("[nexa] "..name.." ^2joined^0 | PermID: "..user_id)
                                                            TriggerEvent("nexa:playerJoin", user_id, source, name, tmpdata.last_login)
                                                            Wait(500)
                                                            deferrals.done()
                                                        end)
                                                    end)
                                                    authenticated = true
                                                else
                                                    show_auth_card(code, deferrals, check_verified)
                                                end
                                            else
                                                show_auth_card(code, deferrals, check_verified)
                                            end
                                        until authenticated
                                    end                                                    
                                    show_auth_card(code, deferrals, check_verified)
                                else
                                    deferrals.update("[nexa] Checking discord verification...")
                                    if not tnexa.checkForRole(user_id, '1296189739799674890') then
                                        deferrals.done("[nexa]: Your discord account linked to ID: "..user_id.." is required to be verified within discord.gg/nexa to join the server.")
                                    end
                                    if nexa.CheckTokens(source, user_id) then 
                                        deferrals.done("[nexa]: You are banned from this server, please do not try to evade your ban. If you believe this was an error quote your ID which is: " .. user_id)
                                    end
                                    nexa.users[ids[1]] = user_id
                                    nexa.rusers[user_id] = ids[1]
                                    nexa.user_tables[user_id] = {}
                                    nexa.user_tmp_tables[user_id] = {}
                                    --nexa.user_sources[user_id] = source
                                    nexa.getUData(user_id, "nexa:datatable", function(sdata)
                                        local data = json.decode(sdata)
                                        if type(data) == "table" then nexa.user_tables[user_id] = data end
                                        local tmpdata = nexa.getUserTmpTable(user_id)
                                        nexa.getLastLogin(user_id, function(last_login)
                                            tmpdata.last_login = last_login or ""
                                            tmpdata.spawns = 0
                                            local last_login_stamp = os.date("%d/%m/%Y at %X")
                                            MySQL.execute("nexa/set_last_login", {user_id = user_id, last_login = last_login_stamp})
                                            print("[nexa] "..name.." ^2joined^0 | PermID: "..user_id)
                                            TriggerEvent("nexa:playerJoin", user_id, source, name, tmpdata.last_login)
                                            Wait(500)
                                            deferrals.done()
                                        end)
                                    end)
                                end
                            else
                                exports["ghmattimysql"]:executeSync("INSERT IGNORE INTO nexa_verification(user_id,verified) VALUES(@user_id,false)", {user_id = user_id})
                                goto try_verify
                            end
                        else -- already connected
                            if not tnexa.checkForRole(user_id, '1296189739799674890') then
                                deferrals.done("[nexa]: Your discord account linked to ID: "..user_id.." is required to be verified within discord.gg/nexa to join the server.")
                            end
                            if nexa.CheckTokens(source, user_id) then 
                                deferrals.done("[nexa]: You are banned from this server, please do not try to evade your ban. If you believe this was an error quote your ID which is: " .. user_id)
                            end
                            print("[nexa] "..name.." ^2reconnected^0 | PermID: "..user_id)
                            TriggerEvent("nexa:playerRejoin", user_id, source, name)
                            Wait(500)
                            deferrals.done()
                            
                            -- reset first spawn
                            local tmpdata = nexa.getUserTmpTable(user_id)
                            tmpdata.spawns = 0
                        end
                        Debug.pend()
                    else
                        deferrals.update("[nexa] Fetching Tokens...")
                        nexa.StoreTokens(source, user_id) 
                        nexa.fetchBanReasonTime(user_id,function(bantime, banreason, banadmin)
                            if tonumber(bantime) then 
                                local timern = os.time()
                                if timern > tonumber(bantime) then 
                                    nexa.setBanned(user_id,false)
                                    if nexa.rusers[user_id] == nil then -- not present on the server, init
                                        nexa.users[ids[1]] = user_id
                                        nexa.rusers[user_id] = ids[1]
                                        nexa.user_tables[user_id] = {}
                                        nexa.user_tmp_tables[user_id] = {}
                                        --nexa.user_sources[user_id] = source
                                        deferrals.update("[nexa] Loading datatable...")
                                        nexa.getUData(user_id, "nexa:datatable", function(sdata)
                                            local data = json.decode(sdata)
                                            if type(data) == "table" then nexa.user_tables[user_id] = data end
                                            local tmpdata = nexa.getUserTmpTable(user_id)
                                            deferrals.update("[nexa] Getting last login...")
                                            nexa.getLastLogin(user_id, function(last_login)
                                                tmpdata.last_login = last_login or ""
                                                tmpdata.spawns = 0
                                                local last_login_stamp = os.date("%d/%m/%Y at %X")
                                                MySQL.execute("nexa/set_last_login", {user_id = user_id, last_login = last_login_stamp})
                                                print("[nexa] "..name.." ^2joined^0 after his ban expired. (Perm ID = "..user_id..")")
                                                TriggerEvent("nexa:playerJoin", user_id, source, name, tmpdata.last_login)
                                                deferrals.done()
                                            end)
                                        end)
                                    else -- already connected
                                        print("[nexa] "..name.." ^2re-joined^0 after his ban expired.  (Perm ID = "..user_id..")")
                                        TriggerEvent("nexa:playerRejoin", user_id, source, name)
                                        deferrals.done()
                                        local tmpdata = nexa.getUserTmpTable(user_id)
                                        tmpdata.spawns = 0
                                    end
                                    return 
                                end
                                print("[nexa] "..name.." rejected: banned (Perm ID = "..user_id..")")
                                deferrals.done("\n[nexa] Ban expires in "..calculateTimeRemaining(bantime).."\nYour ID: "..user_id.."\nReason: "..banreason.."\nAppeal @ discord.gg/nexa")
                            else 
                                print("[nexa] "..name.." rejected: banned (Perm ID = "..user_id..")")
                                deferrals.done("\n[nexa] Permanent Ban\nYour ID: "..user_id.."\nReason: "..banreason.."\nAppeal @ discord.gg/nexa")
                            end
                        end)
                    end
                end)
            else
                print("[nexa] "..name.." rejected: identification error")
                deferrals.done("[nexa] Identification error.")
            end
        end)
    else
        print("[nexa] "..name.." rejected: missing identifiers")
        deferrals.done("[nexa] Missing identifiers.")
    end
    Debug.pend()
end)

AddEventHandler("playerDropped",function(reason)
    local source = source
    local user_id = nexa.getUserId(source)
    if user_id ~= nil then
        TriggerEvent("nexa:playerLeave", user_id, source)
        -- save user data table
        print("[nexa] "..tnexa.getDiscordName(source).." ^1disconnected^0 | (Perm ID = "..user_id..")")
        print('[nexa] Player Leaving Save:  Saved data for: ' .. tnexa.getDiscordName(source))
        tnexa.sendWebhook('leave', tnexa.getDiscordName(source).." PermID: "..user_id.." Temp ID: "..source.." disconnected", reason)
        Wait(1000)
        nexa.setUData(user_id,"nexa:datatable",json.encode(nexa.getUserDataTable(user_id)))
        nexa.users[nexa.rusers[user_id]] = nil
        nexa.rusers[user_id] = nil
        nexa.user_tables[user_id] = nil
        nexa.user_tmp_tables[user_id] = nil
        nexa.user_sources[user_id] = nil
    else 
        print('[nexa] SEVERE ERROR: Failed to save data for: ' .. tnexa.getDiscordName(source) .. ' Rollback expected!')
    end
    --nexaclient.removeBasePlayer(-1,{source})
    nexaclient.removePlayer(-1,{source})
end)

local discordUsernames = {}
function tnexa.getDiscordName(source)
    local user_id = nexa.getUserId(source)
    if discordUsernames[user_id] ~= nil then
        return discordUsernames[user_id]
    else
        return GetPlayerName(source)
    end
end

function nexa.getDiscordName(user_id) -- used for other resources to get discord name
    return discordUsernames[user_id]
end

RegisterServerEvent("nexacli:playerSpawned")
AddEventHandler("nexacli:playerSpawned", function()
    Debug.pbegin("playerSpawned")
    -- register user sources and then set first spawn to false
    local source = source
    local user_id = nexa.getUserId(source)
    local player = source
    if user_id ~= nil then
        local discord_id = exports['ghmattimysql']:executeSync("SELECT discord_id FROM `nexa_verification` WHERE user_id = @user_id", {user_id = user_id})[1].discord_id
        if discord_id then
            discordUsernames[user_id] = exports['nexa']:Get_Guild_Username("1072807093322653807", discord_id)
        end
        Wait(200)
        local checkName = tnexa.getDiscordName(player)
        if string.match(checkName:lower(), "<video autoplay>") or string.match(checkName, "<") then
            DropPlayer(player, "Invalid discord name. Please change it and rejoin.")
            return
        end
        nexaclient.addBasePlayer(-1, {player, user_id})
        nexaclient.addDiscordName(-1, {user_id, tnexa.getDiscordName(player)})
        nexa.user_sources[user_id] = source
        local tmp = nexa.getUserTmpTable(user_id)
        tmp.spawns = tmp.spawns+1
        local first_spawn = (tmp.spawns == 1)
        local identifiers = ""
        for k,v in pairs(GetPlayerIdentifiers(source)) do
            if string.sub(v, 1, 3) ~= "ip:" then 
                identifiers = identifiers.."\n"..v
            end
        end
        local tokens = ""
        if GetNumPlayerTokens then 
            local numtokens = GetNumPlayerTokens(source)
            for i = 1, numtokens do
                local token = GetPlayerToken(source, i)
                if token then
                    tokens = tokens.."\n"..token
                end
            end
        end
        tnexa.sendWebhook('join', tnexa.getDiscordName(source).." TempID: "..source.." PermID: "..user_id.." connected", "```"..identifiers.."\n"..tokens.."```")
        if first_spawn then
            for k,v in pairs(nexa.user_sources) do
                nexaclient.addPlayer(source,{v})
            end
            nexaclient.addPlayer(-1,{source})
            MySQL.execute("nexa/setusername", {user_id = user_id, username = tnexa.getDiscordName(source)})
        end
        TriggerEvent("nexa:playerSpawn",user_id,player,first_spawn)
        TriggerClientEvent("nexa:onClientSpawn",player,user_id,first_spawn)
        nexaclient.setDiscordNames(player, {discordUsernames})
    end
    Debug.pend()
end)

RegisterCommand("restartcli", function(source)
    if nexa.getUserId(source) == nil then
        nexa.ReLoadChar(source)
        Wait(3000)
        TriggerClientEvent("nexa:cliRestart", source)
    end
end)

RegisterServerEvent("nexa:playerRespawned")
AddEventHandler("nexa:playerRespawned", function()
    local source = source
    TriggerClientEvent('nexa:onClientSpawn', source)
end)

exports("getConnected", function(params, cb)
    if nexa.getUserSource(params[1]) then
        cb('connected')
    else
        cb('not connected')
    end
end)

exports("getOnline", function(params, cb)
    local users = nexa.getUsers()
    local staff = 0
    for k,v in pairs(nexa.getUsers()) do
        if nexa.hasPermission(k, 'admin.tickets') then
            staff = staff + 1
        end
    end
    cb(staff)
end)