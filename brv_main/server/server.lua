--------------------------------------------------------------------------------
--                               BATTLE ROYALE V                              --
--                              Main server file                              --
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--                                 Variables                                  --
--------------------------------------------------------------------------------

local db = Database
local players = {}
local safeZonesCoords = {}
local isGameStarted = false
local nbAlivePlayers = 0
local pickupsSpawned = false
local gameId = 0
local sqlDateFormat = '%Y-%m-%d %H:%M:%S'
local radiuses = {
  40.0,
  300.0,
  700.0,
  1500.0,
  3000.0
}

--------------------------------------------------------------------------------
--                                  Events                                    --
--------------------------------------------------------------------------------

RegisterServerEvent('brv:playerFirstSpawned')
RegisterServerEvent('brv:saveCoords')
RegisterServerEvent('brv:dropPlayer')
RegisterServerEvent('brv:playerLoaded')
RegisterServerEvent('brv:playerDied')
RegisterServerEvent('brv:pickupCollected')
RegisterServerEvent('brv:dropWeapon')
RegisterServerEvent('brv:skinChanged')
RegisterServerEvent('brv:saveSkin')
RegisterServerEvent('brv:vote')
RegisterServerEvent('brv:showScoreboard')
RegisterServerEvent('brv:startGame')
RegisterServerEvent('brv:stopGame')
RegisterServerEvent('brv:stopGameClients')
RegisterServerEvent('brv:clientGameStarted')
RegisterServerEvent('baseevents:onPlayerDied')
RegisterServerEvent('baseevents:onPlayerKilled')

--------------------------------------------------------------------------------
--                            Global functions                                --
--------------------------------------------------------------------------------

-- Loads a player from database, based on the source
function loadPlayer(source)
  if players[source] == nil then
    local steamId = GetPlayerIdentifiers(source)[1]

    db:read('players', '', {'steamid,eq,' .. steamId}, '', function(data) -- , 'status,eq,1'
      if #data == 1 then
        local row = data[1]
        if row.status == 0 then
          print('Dropping player, banned : ' .. steamId .. ' (' .. source .. ')')
          TriggerEvent('brv:dropPlayer', source, 'You\'re banned !')
          return
        end
        players[source] = Player.new(row.id, steamId, row.name, row.role, row.skin, source)
        -- TODO : Put this in the Player class
        players[source].rank = 0
        players[source].kills = 0
        players[source].spawn = {}
        players[source].weapon = ''
        players[source].voted = false

        TriggerEvent('brv:playerLoaded', source, players[source])
        db:update('players', row.id, { last_login = os.date(sqlDateFormat) })
      else
        if conf.whitelist then
          print('Dropping player, not in whitelist : ' .. steamId .. ' (' .. source .. ')')
          TriggerEvent('brv:dropPlayer', source, 'You\'re not on the whitelist !')
          return
        else
          -- Insert data in DB and load player
          db:create('players', {steamid = steamId, role = 'player', name = GetPlayerName(source), created = os.date(sqlDateFormat), last_login = os.date(sqlDateFormat), status = 1}, function(id)
            players[source] = Player.new(id, steamId, GetPlayerName(source), 'player', '', source)
            players[source].rank = 0
            players[source].kills = 0
            players[source].spawn = {}
            players[source].weapon = ''
            players[source].voted = false

            TriggerEvent('brv:playerLoaded', source, players[source])
          end)
        end
      end

    end)
  end
end

-- Expose DB object
function getDatabase()
  return db
end

-- Expose all connected players
function getPlayers()
  return players
end

-- Returns a Player object based on the source if it exists
-- false otherwise
function getPlayer(source)
  if players[source] ~= nil then
    return players[source]
  end

  return false
end

function removePlayer(source, reason)
  if players[source] ~= nil then
    -- Player dropped during a game
    if isGameStarted and players[source].alive then
      players[source].alive = false
      nbAlivePlayers = nbAlivePlayers - 1
      updateAlivePlayers(-1)
      if nbAlivePlayers == 1 then
        TriggerEvent('brv:stopGame', true, false)
      end
    end

    sendSystemMessage(-1, players[source].name ..' left (' .. reason .. ')')

    players[source] = nil

    if count(players) == 0 then
      if isGameStarted then
          TriggerEvent('brv:stopGame', false, true)
      end
      -- no more players on server, reset some stuff ?
    end
  end
end

-- Returns a player's name based on the source if it exists
-- 'no one' otherwise
function getPlayerName(source)
  local player = getPlayer(source)
  if player then
    return player.name
  end
  return 'no one'
end

-- Returns a table containing all alive players
function getAlivePlayers()
  local alivePlayers = {}
  local index = 1

  for i, player in pairs(players) do
    if player.alive then
      alivePlayers[index] = player
      index = index +1
    end
  end

  return alivePlayers
end

function getVotes()
  local nb = 0
  for k,v in pairs(players) do
    if v.voted then
      nb = nb + 1
    end
  end

  return nb
end

function vote(source)
  if players[source] ~= nil then
    players[source].voted = true
  end
end

-- isGameStarted ?
function getIsGameStarted()
  return isGameStarted
end

-- Update all clients with the new number of alive players
function updateAlivePlayers(source)
  local alivePlayers = {}
  local i = 1
  for k,v in pairs(players) do
    if v.alive then
      alivePlayers[i] = {
        id = v.id,
        name = v.name,
        source = v.source,
      }
      i = i + 1
    end
  end
  TriggerClientEvent('brv:updateAlivePlayers', source, alivePlayers)
end

-- "First" spawn
-- Is actually triggered every resource restart, because of gametype
AddEventHandler('brv:playerFirstSpawned', function()
  print('brv:playerFirstSpawned : ' .. source)
  loadPlayer(source)
  sendNotificationDetails(source, 'CHAR_ALL_PLAYERS_CONF', 'Battle Royale V', 'beta version', 'Welcome to the ~r~Battle Royale V~s~ !~n~Type ~b~/help~s~ for a list of commands.')
end)

AddEventHandler('brv:saveCoords', function(coords)
  db:create('coords', {x = coords.x, y = coords.y, z = coords.z}, function() end)
end)

AddEventHandler('brv:getPlayerData', function(source, event, data)
  if players[source] ~= nil then
    local playerData = {
      id = players[source].id,
      name = players[source].name,
      source = players[source].source,
      rank = players[source].rank,
      kills = players[source].kills,
      skin = players[source].skin,
      admin = players[source]:isAdmin(),
    }
    TriggerEvent(event, playerData, data)
  end
end)

AddEventHandler('brv:showScoreboard', function()
  local playersData = {}
  local globalData = {}

  for k,v in pairs(players) do
    if v.rank == nil then v.rank = 0 end
    if v.kills == nil then v.kills = 0 end

    playersData[k] = {
      name = v.name,
      source = v.source,
      rank = v.rank,
      kills = v.kills,
      admin = v:isAdmin(),
    }
  end

  local safeSource = source
  PerformHttpRequest(conf.stats_url,  function(err, text, headers)
    if text then
      globalData = json.decode(text)
      TriggerClientEvent('brv:showScoreboard', safeSource, {players = playersData, global = globalData, lastUpdated = headers['Last-Modified']})
    end
  end, 'GET', '')

end)

AddEventHandler('brv:playerLoaded', function(source, player)
  TriggerClientEvent('brv:playerLoaded', source, {id = player.id, name = player.name, skin = player.skin, source = player.source})
  sendSystemMessage(-1, player.name .. ' joined.')

  if not isGameStarted then
    local nbPlayers = count(players)
    if nbPlayers == conf.autostart then
      TriggerClientEvent('brv:restartGame', -1)
    else
      if nbPlayers < conf.autostart then
        TriggerClientEvent('brv:showNotification', -1, '~r~' .. (conf.autostart - nbPlayers) .. '~s~ more player(s) needed for autostart')
      end
    end
  else
    updateAlivePlayers(source)
    TriggerClientEvent('brv:setGameStarted', source)
  end

end)

AddEventHandler('brv:skinChanged', function(newSkin)
  local player = getPlayer(source)
  player.skin = newSkin
end)

AddEventHandler('brv:saveSkin', function()
  local player = getPlayer(source)
  getDatabase():update('players', player.id, {skin = player.skin}, function(data)
    sendSystemMessage(player.source, 'Skin saved (^4' .. player.skin .. '^2)')
  end)
end)

AddEventHandler('brv:vote', function()
  TriggerEvent('brv:voteServer', source)
end)

AddEventHandler('brv:voteServer', function(source)
  local player = getPlayer(source)
  if player.voted then
    sendSystemMessage(player.source, 'You already voted')
  elseif isGameStarted then
    sendSystemMessage(player.source, 'You can\'t vote during the Battle')
  else
    vote(player.source)
    sendSystemMessage(-1, '^5' .. player.name .. '^2 voted for the battle to begin')
    local nbPlayers = count(getPlayers())
    if nbPlayers > 1 and getVotes() > math.floor(nbPlayers / 2) then
      sendSystemMessage(-1, 'Battle will start soon thanks to the votes')
      TriggerClientEvent('brv:restartGame', -1)
    end
  end
end)

--------------------------------------------------------------------------------
--                                START GAME                                  --
--------------------------------------------------------------------------------
AddEventHandler('brv:startGame', function()
  if isGameStarted then return end
  checkPlayers()

  isGameStarted = true
  local prevRad
  local randomLocation = getRandomLocation()

  safeZonesCoords = {
    {
      x = randomLocation.x,
      y = randomLocation.y,
      z = randomLocation.z,
      radius = radiuses[1]
    }
  }

  for i = 1, 4 do
    prevRad = radiuses[i]

    safeZonesCoords[i+1] = {
      x = safeZonesCoords[i].x + (math.random(prevRad - (20*i)) * (round(math.random()) * 2 - 1)),
      y = safeZonesCoords[i].y + (math.random(prevRad - (20*i)) * (round(math.random()) * 2 - 1)),
      z = safeZonesCoords[i].z,
      radius = radiuses[i+1],
    }
  end

  safeZonesCoords[5] = limitMap(safeZonesCoords[5])

  safeZonesCoords = table_reverse(safeZonesCoords)

  -- Sets all players alive, and init some other variables
  nbAlivePlayers = count(players)
  for i, player in pairs(players) do
    player.alive = true
    player.rank = 0
    player.kills = 0
    player.spawn = {}
    player.weapon = ''
    player.voted = false
  end

  -- Insert data in DB
  safeZonesJSON = json.encode(safeZonesCoords)

  db:create('games', {safezones = safeZonesJSON, created = os.date(sqlDateFormat)}, function(id)
    gameId = id
  end)

  local seed = math.random()

  TriggerClientEvent('brv:startGame', -1, nbAlivePlayers, safeZonesCoords)
  TriggerClientEvent('brv:createPickups', -1, seed)
end)

-- Remove a collected pickup to all other players
AddEventHandler('brv:pickupCollected', function(index)
  TriggerClientEvent('brv:removePickup', -1, index)
end)

-- Game has started for client, saves the spawning point and weapon
AddEventHandler('brv:clientGameStarted', function(stats)
  if players[source] ~= nil then
    players[source].spawn = stats.spawn
    players[source].weapon = stats.weapon
  end
end)

-- Stops the game
AddEventHandler('brv:stopGame', function(restart, noWin)
  -- Disable autorestart if nb players < autostart
  if count(players) < conf.autostart then restart = false end

  if not isGameStarted then
    TriggerClientEvent('brv:stopGame', -1, 'no one', restart)
    return false
  end
  -- Get the winner
  local alivePlayers = getAlivePlayers()
  local winner = { id = 0, name = 'no one' }
  if not noWin and count(alivePlayers) == 1 then
    winner = alivePlayers[1]
    winner.rank = 1
  end
  if conf.stats then
    for k,player in pairs(players) do
      if player.weapon ~= '' then
        db:create('players_stats', { pid = player.id, gid = gameId, spawn = json.encode(player.spawn), weapon = player.weapon, kills = player.kills, rank = player.rank}, function()
          print('Players stats saved')
        end)
      end
    end
  end
  -- Update database
  isGameStarted = false
  db:update('games', gameId, {finished = os.date(sqlDateFormat), wid = winner.id}, function()
    -- Send the event to the clients with the winner name
    if winner.id ~= 0 then
      TriggerClientEvent('brv:winnerScreen', winner.source, winner.rank, winner.kills, restart)
    else
      TriggerClientEvent('brv:stopGame', -1, winner.name, restart)
    end
  end)
end)

AddEventHandler('brv:stopGameClients', function(name, restart)
  TriggerClientEvent('brv:stopGame', -1, name, restart)
end)

AddEventHandler('brv:dropPlayer', function(source, reason)
  DropPlayer(source, reason)
end)

AddEventHandler('brv:playerDied', function(source, type, killer)
  local message = ''

  players[source].rank = nbAlivePlayers;
  TriggerClientEvent('brv:wastedScreen', source, players[source].rank, players[source].kills)

  nbAlivePlayers = nbAlivePlayers - 1
  players[source].alive = false
  updateAlivePlayers(-1)

  if source == killer then
    message = '~r~' .. getPlayerName(source) .. '~s~  killed himself'
  else
    if type == 'killed' and killer ~= nil and getPlayerName(killer) then
      message = '~r~' .. getPlayerName(source) .. '~s~  was killed by ~r~' .. getPlayerName(killer)
    else
      message = '~r~' .. getPlayerName(source) .. '~s~  was killed'
    end
  end
  sendNotification(-1, message)

  if not conf.debug and isGameStarted and nbAlivePlayers == 1 and count(players) > 1 then
    TriggerEvent('brv:stopGame', true, false)
  end
end)

AddEventHandler('brv:dropWeapon', function(pickupHash, location)
  TriggerClientEvent('brv:addPickup', -1, pickupHash, location)
end)

AddEventHandler('brv:sendToDiscord', function(name, message)
  if conf.discord_url == nil or conf.discord_url == '' then return false end

  PerformHttpRequest(conf.discord_url, function(err, text, headers) end, 'POST', json.encode({username = name, content = message}), { ['Content-Type'] = 'application/json' })
end)

AddEventHandler('playerDropped', function(reason)
  removePlayer(source, reason)
end)

AddEventHandler('baseevents:onPlayerDied', function(killedBy, coords)
  TriggerEvent('brv:playerDied', source, 'died', killedBy)
end)

AddEventHandler('baseevents:onPlayerKilled', function(killer, data)
  if players[killer] ~= nil then
    players[killer].kills = players[killer].kills + 1;
  end
  TriggerEvent('brv:playerDied', source, 'killed', killer)
end)
