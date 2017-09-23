# BATTLE ROYALE V

## A Battle Royale gametype for FiveM

### Requirements

- **Apache / PHP / MySQL**
- **PHP-CRUD-API** (https://github.com/mevdschee/php-crud-api)

You only need the main file, you can download it here : https://raw.githubusercontent.com/mevdschee/php-crud-api/master/api.php

  ** :warning: Needs to be edited to be able to use emojis in database**
- Be sure to secure the script, so only your FiveM server can access `api.php`

**This is needed to be able to use MySQL async with FiveM. You are free to use any other database, but you will have to rewrite the provided Database class (`brv_main/classes/database.lua`).**

### Installation

- Clone the Git repository or extract the archive to `cfx-server/resources/[battleroyalev]`

- Add the following lines to your `AutoStartResources` :
```
  - brv_chat
  - brv_scoreboard
  - brv_spawner
  - brv_loading
  - brv_main
```

- Remove those :

```
  - chat
  - scoreboard
  - fivem
  - fivem-map-hipster / fivem-map-skater
```

- Copy `brv_main/server/config.default.lua` to `brv_main/server/config.lua` and edit

- Copy `brv_main/client/config.default.lua` to `brv_main/client/config.lua` and edit

- Import the default SQL structure from `sql/battleroyalev.sql`

<!-- - Inserts data or disable whitelist -->

- Start the server

### Update

- Added Discord URL at the top of the screen
- Edited */help* message
- Spectator mode now shows health of the current spectated player (**not tested**)
- Fix : Out-of-zone timer wasn't working with the last zone
- Possible fix : Added another check for ghost player as the first one doesn't seem to work
