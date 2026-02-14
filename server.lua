local players = {}
local calls = {}
local nextCallId = 1

local inventoryChecker = nil

local function notify(src, message)
    TriggerClientEvent('funk_system:notify', src, message)
end

local function normalizeService(service)
    if not service then return nil end
    return tostring(service):lower()
end

local function setPlayerDefaults(src)
    players[src] = players[src] or {}
    players[src].service = players[src].service or 'civilian'
    players[src].radioChannel = players[src].radioChannel or nil
    players[src].devices = players[src].devices or {
        radio = Config.DefaultDevices.radio,
        pager = Config.DefaultDevices.pager
    }
end

local function hasDevice(src, deviceName)
    setPlayerDefaults(src)

    if Config.DeviceMode == 'inventory' and inventoryChecker then
        local has = inventoryChecker(src, deviceName)
        return has == true
    end

    return players[src].devices[deviceName] == true
end

local function isServiceAllowedForChannel(service, channelData)
    if not channelData.allowedServices then
        return true
    end

    for _, allowedService in ipairs(channelData.allowedServices) do
        if allowedService == service then
            return true
        end
    end

    return false
end

local function collectRecipientsForEmergency(fromService)
    local recipients = {}

    for _, center in ipairs(Config.DispatchCenters) do
        local inCenter = false
        for _, service in ipairs(center.services) do
            if service == fromService then
                inCenter = true
                break
            end
        end

        if inCenter then
            for _, service in ipairs(center.services) do
                recipients[service] = true
            end
            return recipients
        end
    end

    for _, service in ipairs(Config.DefaultEmergencyServices) do
        recipients[service] = true
    end

    return recipients
end

local function getPlayerService(src)
    setPlayerDefaults(src)
    return players[src].service
end

local function getPlayersByServices(serviceSet)
    local list = {}
    for src, data in pairs(players) do
        if serviceSet[data.service] then
            list[#list + 1] = src
        end
    end
    return list
end

local function createCall(src, message)
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local fromService = getPlayerService(src)
    local recipients = collectRecipientsForEmergency(fromService)

    local call = {
        id = nextCallId,
        from = src,
        fromName = GetPlayerName(src),
        fromService = fromService,
        message = message,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        timestamp = os.time(),
        acceptedBy = nil
    }

    nextCallId = nextCallId + 1
    calls[#calls + 1] = call

    local targetPlayers = getPlayersByServices(recipients)
    for _, targetSrc in ipairs(targetPlayers) do
        if hasDevice(targetSrc, 'pager') then
            TriggerClientEvent('funk_system:newCall', targetSrc, call)
        end
    end

    notify(src, ('Notruf #%s wurde erstellt.'):format(call.id))
end

local function findCallById(callId)
    for _, call in ipairs(calls) do
        if call.id == callId then
            return call
        end
    end
    return nil
end

RegisterNetEvent('funk_system:sendRadioMessage', function(text)
    local src = source
    setPlayerDefaults(src)

    if not hasDevice(src, 'radio') then
        notify(src, 'Du hast kein Funkgerät.')
        return
    end

    local channel = players[src].radioChannel
    if not channel then
        notify(src, 'Du bist auf keinem Funkkanal.')
        return
    end

    text = tostring(text or '')
    if text == '' then
        return
    end

    for targetSrc, data in pairs(players) do
        if data.radioChannel == channel and hasDevice(targetSrc, 'radio') then
            TriggerClientEvent('funk_system:radioMessage', targetSrc, {
                channel = channel,
                sender = GetPlayerName(src),
                senderId = src,
                text = text
            })
        end
    end
end)

RegisterCommand(Config.Commands.setService, function(src, args)
    if src == 0 then
        print('Dieser Command ist nur Ingame verfügbar.')
        return
    end

    local wanted = normalizeService(args[1])
    if not wanted or not Config.Services[wanted] then
        notify(src, 'Unbekannter Dienst. Bitte Config.Services prüfen.')
        return
    end

    setPlayerDefaults(src)
    players[src].service = wanted
    notify(src, ('Dienst gesetzt: %s'):format(Config.Services[wanted].label or wanted))
end)

RegisterCommand(Config.Commands.joinRadio, function(src, args)
    if src == 0 then return end
    setPlayerDefaults(src)

    if not hasDevice(src, 'radio') then
        notify(src, 'Du hast kein Funkgerät.')
        return
    end

    local channel = tonumber(args[1])
    if not channel or not Config.RadioChannels[channel] then
        notify(src, 'Ungültiger Funkkanal.')
        return
    end

    local service = getPlayerService(src)
    local channelData = Config.RadioChannels[channel]

    if not isServiceAllowedForChannel(service, channelData) then
        notify(src, 'Du hast keinen Zugriff auf diesen Funkkanal.')
        return
    end

    players[src].radioChannel = channel
    notify(src, ('Du bist nun auf Kanal %s (%s).'):format(channel, channelData.label))
end)

RegisterCommand(Config.Commands.leaveRadio, function(src)
    if src == 0 then return end
    setPlayerDefaults(src)
    players[src].radioChannel = nil
    notify(src, 'Funkkanal verlassen.')
end)

RegisterCommand(Config.Commands.radioSend, function(src, args)
    if src == 0 then return end
    local text = table.concat(args, ' ')
    TriggerEvent('funk_system:sendRadioMessage', text)
end)

RegisterCommand(Config.Commands.emergency, function(src, args)
    if src == 0 then return end
    local message = table.concat(args, ' ')
    if message == '' then
        notify(src, 'Nutzung: /' .. Config.Commands.emergency .. ' <Nachricht>')
        return
    end

    createCall(src, message)
end)

RegisterCommand(Config.Commands.listCalls, function(src)
    if src == 0 then return end
    if not hasDevice(src, 'pager') then
        notify(src, 'Du hast keinen Melder.')
        return
    end

    TriggerClientEvent('funk_system:callList', src, calls)
end)

RegisterCommand(Config.Commands.acceptCall, function(src, args)
    if src == 0 then return end
    local callId = tonumber(args[1])
    if not callId then
        notify(src, 'Nutzung: /' .. Config.Commands.acceptCall .. ' <ID>')
        return
    end

    local call = findCallById(callId)
    if not call then
        notify(src, 'Einsatz nicht gefunden.')
        return
    end

    call.acceptedBy = src
    notify(src, ('Du hast Einsatz #%s übernommen.'):format(call.id))
    if call.from then
        notify(call.from, ('Dein Notruf #%s wurde angenommen von %s.'):format(call.id, GetPlayerName(src)))
    end
end)

RegisterCommand(Config.Commands.toggleDevice, function(src, args)
    if src == 0 then return end
    if Config.DeviceMode ~= 'virtual' then
        notify(src, 'Geräte können nur im virtual-Modus umgeschaltet werden.')
        return
    end

    local device = tostring(args[1] or ''):lower()
    local mode = tostring(args[2] or ''):lower()

    if (device ~= 'radio' and device ~= 'pager') or (mode ~= 'on' and mode ~= 'off') then
        notify(src, 'Nutzung: /' .. Config.Commands.toggleDevice .. ' radio|pager on|off')
        return
    end

    setPlayerDefaults(src)
    players[src].devices[device] = (mode == 'on')
    notify(src, ('%s %s.'):format(device == 'radio' and 'Funkgerät' or 'Melder', mode == 'on' and 'aktiviert' or 'deaktiviert'))
end)

AddEventHandler('playerDropped', function()
    players[source] = nil
end)

AddEventHandler('playerJoining', function()
    setPlayerDefaults(source)
end)

exports('setInventoryChecker', function(cb)
    inventoryChecker = cb
end)
