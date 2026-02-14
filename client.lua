local function chat(prefix, message)
    TriggerEvent('chat:addMessage', {
        color = { 44, 172, 255 },
        multiline = false,
        args = { prefix, message }
    })
end

RegisterNetEvent('funk_system:notify', function(message)
    chat('Funk', message)
end)

RegisterNetEvent('funk_system:radioMessage', function(payload)
    chat(('Funk %s'):format(payload.channel), ('%s (%s): %s'):format(payload.sender, payload.senderId, payload.text))
end)

RegisterNetEvent('funk_system:newCall', function(call)
    local coords = call.coords
    chat('Melder', ('Neuer Einsatz #%s von %s: %s [%.1f %.1f %.1f]'):format(
        call.id,
        call.fromName,
        call.message,
        coords.x,
        coords.y,
        coords.z
    ))
end)

RegisterNetEvent('funk_system:callList', function(calls)
    if #calls == 0 then
        chat('Melder', 'Keine Einsätze vorhanden.')
        return
    end

    chat('Melder', '--- Offene Einsätze ---')
    for _, call in ipairs(calls) do
        local status = call.acceptedBy and ('angenommen von ID ' .. call.acceptedBy) or 'offen'
        chat('Melder', ('#%s | %s | %s'):format(call.id, call.message, status))
    end
end)
