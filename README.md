# Funk_system

Konfigurierbares FiveM-Resource für:

- **Funkkanäle** (beliebig erweiterbar)
- **Leitstellenlogik** (z. B. Feuerwehr + Rettungsdienst gemeinsam)
- **Funkgerät** und **Melder**
- **Notrufe** inkl. Einsatzannahme

## Installation

1. Ordner in `resources/[local]/funk_system` legen.
2. In der `server.cfg` eintragen:
   ```cfg
   ensure funk_system
   ```
3. Server starten.

## Konfiguration

Alle wichtigen Einstellungen sind in `config.lua`:

- `Config.RadioChannels`: Kanäle, Namen und erlaubte Dienste
- `Config.Services`: Dienste (frei erweiterbar)
- `Config.DispatchCenters`: gemeinsame Leitstellenlogik
- `Config.DefaultEmergencyServices`: Fallback-Empfänger für Notrufe
- `Config.DeviceMode`: `virtual` oder `inventory`

### Geräte-Modi

- `virtual`: Spielergeräte werden ohne Inventar verwaltet.
- `inventory`: eigenes Inventarsystem via Export anbinden.

#### Inventory-Integration (optional)

```lua
exports['funk_system']:setInventoryChecker(function(source, device)
    -- device ist "radio" oder "pager"
    -- return true/false
    return true
end)
```

## Commands (Standard)

- `/setdienst <service>` – Dienst setzen
- `/funk <kanal>` – Funkkanal beitreten
- `/funkleave` – Funkkanal verlassen
- `/funksay <text>` – Nachricht in aktuellem Kanal senden
- `/notruf <text>` – Notruf erstellen
- `/meldungen` – Einsätze auf dem Melder anzeigen
- `/einsatz <id>` – Einsatz übernehmen
- `/geraet radio|pager on|off` – nur im `virtual`-Modus

## Beispiel: Eigene Funkkanäle hinzufügen

```lua
Config.RadioChannels[10] = {
    label = 'Sondereinsatz',
    allowedServices = { 'police', 'dispatch_police' }
}
```

## Hinweise

- Das Script ist **framework-unabhängig** gehalten.
- Für produktive Nutzung solltest du Berechtigungen (ACE/Job-Checks) ergänzen.
- Wenn du Positionsmarker/Blips willst, kann das über ein separates NUI/Client-Modul erweitert werden.
