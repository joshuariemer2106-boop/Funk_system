Config = {}

-- virtual: Geräte werden intern verwaltet (ohne Inventory-Framework)
-- inventory: Du lieferst per Export eine eigene Inventarprüfung
Config.DeviceMode = 'virtual'

Config.DefaultDevices = {
    radio = true,
    pager = true
}

-- Frei erweiterbare Funkkanäle
Config.RadioChannels = {
    [1] = {
        label = 'Polizei Einsatz',
        allowedServices = { 'police' }
    },
    [2] = {
        label = 'Feuerwehr / Rettungsdienst',
        allowedServices = { 'fire', 'ems' }
    },
    [3] = {
        label = 'Leitstelle Nord',
        allowedServices = { 'dispatch_fire_ems' }
    },
    [4] = {
        label = 'Leitstelle Polizei',
        allowedServices = { 'dispatch_police' }
    }
}

-- Dienste, die Server-Team beliebig anpassen/erweitern kann
Config.Services = {
    police = {
        label = 'Polizei',
        receivesEmergencyCalls = true
    },
    fire = {
        label = 'Feuerwehr',
        receivesEmergencyCalls = true
    },
    ems = {
        label = 'Rettungsdienst',
        receivesEmergencyCalls = true
    },
    dispatch_fire_ems = {
        label = 'Leitstelle Feuerwehr / Rettungsdienst',
        receivesEmergencyCalls = true
    },
    dispatch_police = {
        label = 'Leitstelle Polizei',
        receivesEmergencyCalls = true
    }
}

-- Welche Dienste dieselbe Leitstelle teilen
Config.DispatchCenters = {
    {
        id = 'fire_ems_shared',
        label = 'Leitstelle Feuerwehr + Rettungsdienst',
        services = { 'fire', 'ems', 'dispatch_fire_ems' }
    },
    {
        id = 'police_single',
        label = 'Leitstelle Polizei',
        services = { 'police', 'dispatch_police' }
    }
}

-- Services, die Notrufe empfangen sollen, wenn keine DispatchCenter-Regel matched
Config.DefaultEmergencyServices = { 'dispatch_fire_ems', 'dispatch_police' }

Config.Commands = {
    setService = 'setdienst',
    joinRadio = 'funk',
    leaveRadio = 'funkleave',
    radioSend = 'funksay',
    emergency = 'notruf',
    listCalls = 'meldungen',
    acceptCall = 'einsatz',
    toggleDevice = 'geraet'
}
