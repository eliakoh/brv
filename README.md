# BATTLE ROYALE V

**WARNING**

This gametype was made for CitizenFX Server, the previous version of FX Server.

**IT IS NOT FULLY COMPATIBLE WITH FX SERVER**

## A Battle Royale gametype for FiveM

### Requirements

- **Apache / PHP / MySQL**
- **PHP-CRUD-API** (https://github.com/mevdschee/php-crud-api)

You only need the main file, you can download it here : https://raw.githubusercontent.com/mevdschee/php-crud-api/master/api.php

  :warning: ** Needs to be edited to be able to use emojis in database**
- Be sure to secure the script, so only your FiveM server can access `api.php`

**You are free to use any other database, but you will have to rewrite the provided Database class (`brv_main/classes/database.lua`).**

### Installation

- Clone the Git repository or extract the archive to `fx-server/server-data/resources/[battleroyalev]`

- The resource list of your `server.cfg` should be :
```
start mapmanager
start brv_chat
start spawnmanager
start brv_spawner
start hardcap
start rconlog
start baseevents
start brv_scoreboard
start brv_spawner
start brv_loading
start brv_menu
start brv_main
```

- Copy `brv_main/server/config.default.lua` to `brv_main/server/config.lua` and edit

- Copy `brv_main/client/config.default.lua` to `brv_main/client/config.lua` and edit

- Import the default SQL structure from `sql/battleroyalev.sql`

<!-- - Inserts data or disable whitelist -->

- Start the server

### Update

- Some fixes for FX Server compatibility
