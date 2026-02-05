# gldnrmz-greenskeeper

A standalone FiveM resource for city worker/golf course cleaning jobs. Designed for server owners and developers seeking a simple, optimized, and configurable job script.

## 📦 Features
- Standalone, no framework dependency
- Optimized for performance and reliability
- Configurable boss location, scenarios, payout, and vehicle
- Uses ox_lib for shared functionality
- Blip and target integration for job interaction
- Exploit protection and server-side validation
- Easy to extend for custom logic

## ⚙️ Requirements
- [ox_lib](https://github.com/overextended/ox_lib) (required)
- No framework required (QBCore/ESX/ox not needed)
- Optional: [community_bridge] for extended features (target, notify, vehicle key, fuel)

## 🚀 Installation
1. Download and place `gldnrmz-greenskeeper` in your resources folder.
2. Ensure [ox_lib](https://github.com/overextended/ox_lib) is installed and started before this resource.
3. Add to your `server.cfg`:
   ```
   ensure ox_lib
   ensure community_bridge
   ensure gldnrmz-greenskeeper
   ```
4. Restart your server.

## 🛠️ Configuration
- Main config: `config.lua` (client) and `sv_config.lua` (server)
- Example (`config.lua`):
  ```lua
  return {
      BossModel = `s_m_m_gardener_01`,
      BossCoords = vector4(-1355.38, 124.55, 55.24, 6.04),
      Scenario = {
          'WORLD_HUMAN_DRUG_FIELD_WORKERS_RAKE',
          'WORLD_HUMAN_DRUG_FIELD_WORKERS_WEEDING',
          'WORLD_HUMAN_GARDENER_LEAF_BLOWER',
      },
  }
  ```
- Example (`sv_config.lua`):
  ```lua
  return {
      Timeout = 10000,
      Account = 'cash',
      Payout = {min = 600, max = 800},
      Locations = {
          vector3(-1288.19, 149.57, 58.46),
          -- ... more locations ...
      },
      Vehicle = `caddy`,
      VehicleSpawn = vector4(-1349.54, 126.09, 55.68, 275.48),
  }
  ```

## 📘 Advanced Configuration
| Field         | Type      | Description                                 |
|-------------- |---------- |---------------------------------------------|
| BossModel     | hash      | Ped model for boss NPC                      |
| BossCoords    | vector4   | Location and heading for boss               |
| Scenario      | table     | List of scenarios for job tasks             |
| Timeout       | number    | Delay before next job task (ms)             |
| Account       | string    | Payment account (e.g., 'cash')              |
| Payout        | table     | Min/max payout per job                      |
| Locations     | table     | Delivery/cleaning locations                 |
| Vehicle       | hash      | Work vehicle model                          |
| VehicleSpawn  | vector4   | Spawn location for work vehicle             |

- All config values are validated on resource start.
- Use realistic coordinates and models for best results.

## ❗ Troubleshooting
- **Job not starting:** Ensure ox_lib and community_bridge are started first.
- **No blip or target:** Check for missing dependencies and correct config values.
- **Vehicle not spawning:** Validate vehicle model and spawn coordinates.
- **Exploit detected:** Server will drop players for invalid actions.
- **Debugging:** Enable debug prints in scripts for more info.

## 📄 License / Usage Rules
- No selling, reselling, or commercial use
- Do not remove author credit
- Modifications allowed for personal/server use only
- Redistribution only with full credit

## 🙏 Credit
- [ox_lib](https://github.com/overextended/ox_lib) by overextended
- [community_bridge] by respective authors
- Script by Randolio

## 📝 License Footer
Attribution required. Do not redistribute without credit. Commercial use is strictly prohibited.
