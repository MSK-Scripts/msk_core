# Changelog

All notable changes to msk_core are documented in this file.

## [4.0.0] - 2026-09-09

A rewrite of the framework bridge, plus the bug hunt that came with reading
every module again. **This release is not backwards compatible**, see the
migration notes at the end.

### Added

- **Qbox is a framework of its own now.** Until 4.0.0 a Qbox server ended up in
  the QBCore branch, because `qbx_core/fxmanifest.lua` declares
  `provide 'qb-core'` and the detection asked `GetResourceState('qb-core')`.
  That worked by accident and cost the one thing Qbox has and QBCore does not:
  multijob. `PlayerData.jobs` is a `table<string, integer>`, and the qb
  compatibility layer flattens it to a single job.

  Detection now asks for each framework under its own resource name and checks
  `qbx_core` first. A `provide` hit is a fallback, never a detection: FiveM
  changed how provided names answer resource-state lookups twice during 2026
  (builds b90 and b95), and for two weeks `GetResourceState` returned `missing`
  for a provided name without a single line of script code having changed.

- **One player shape on every framework.** `MSK.GetPlayer(id)` returns the same
  fields whether ESX, QBCore or Qbox is running: `source`, `identifier`,
  `license`, `name`, `firstName`, `lastName`, `dob`, `sex`, `phone`, `group`,
  `job`, `jobs`, `gang`, `gangs`, `money`, `metadata`, `position`. `job` and
  `gang` always look the same too: `name`, `label`, `grade`, `gradeName`,
  `gradeLabel`, `salary`, `isBoss`, `onDuty`.

  `jobs` and `gangs` are filled on every framework. On Qbox that is the real
  multijob map, on ESX and QBCore it holds the single job the player has, so
  consumer code can read `player.jobs` without asking which framework it is on.

- **`MSK.GetPlayer` takes whatever you have.** A server id, an identifier or
  citizenid, or a table (`{ source = }`, `{ identifier = }`, `{ citizenid = }`,
  `{ phone = }`, `{ userId = }`). Passing a plain number used to raise
  "attempt to index a number value".

- **The player object has methods again, and this time they arrive.** `SetJob`,
  `SetDuty`, `AddJob`, `RemoveJob`, `HasJob`, `AddMoney`, `RemoveMoney`,
  `GetMoney`, `SetMoney`, `GetMeta`, `SetMeta`, `AddItem`, `RemoveItem`,
  `HasItem`, `CanCarryItem`, `Notify`, `Kick`, `Save`, `Refresh` and more. See
  the migration notes for why they did not before.

- `MSK.GetPlayerJobs`, `MSK.GetPlayerGang` and, on the client,
  `MSK.GetPlayerData`, `MSK.IsPlayerLoaded`, `MSK.GetPlayerJob`,
  `MSK.GetPlayerGang`, `MSK.GetPlayerJobs`.

- **`MSK.IsPlayerDead()`** as a function of its own, including the visn_are and
  osp_ambulance special cases. It used to sit on the client player object where
  consumers could not reach it.

- **Company accounts follow the banking resource, not the framework.**
  `MSK.Society` now detects Renewed-Banking, qb-banking, qb-management or
  esx_addonaccount. Before this it branched on the framework, so a Qbox server
  got a hard 0 back no matter what was installed. `MSK.Society.GetProvider()`
  reports which one was found.

- `MSK.Offline` and `MSK.GetModelFromPlate` know the Qbox tables.

- **`MSK.GetJobs()` and `MSK.GetGangs()`**, client and server. Every framework
  keeps its list somewhere else: ESX behind `ESX.GetJobs()`, QBCore in
  `QBCore.Shared.Jobs`, Qbox behind its own export. A script that only wanted to
  fill a dropdown had to know all three and usually covered two. Both return
  `table<string, { name, label, grades }>`, with the grades normalised to a list
  sorted by grade number: `{ grade, name, label, salary, isBoss }`.
  `MSK.GetGangs()` is empty on ESX, which has no gangs. On the client both are a
  callback round trip, so call them from inside a thread.

- **`MSK.VehicleStore`, one shape over the framework's owned-vehicle table.**
  `GetSchema`, `GetByPlate`, `CountByPlate`, `Insert`, `Update`, `Delete`,
  `ClearJob` and a paginated, filtered `Browse`. The tables differ by more than
  their names: ESX keeps every property as JSON in `owned_vehicles.vehicle`,
  QBCore and Qbox keep the spawn name in `player_vehicles.vehicle` and the
  properties in `mods`, so a name-to-name mapping is not enough. The two columns
  QBCore and Qbox do not have, `job` and `type`, are added on start with
  `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`, which leaves existing rows
  untouched.

  Vehicle properties are handed back in the format the running framework wrote
  them in. They are deliberately not unified, because every other garage on the
  server reads the same column.

- **`MSK.Offline.GetPlayerTable()`** returns the character table of the running
  framework together with its key column: `users` and `identifier` on ESX,
  `players` and `citizenid` on QBCore and Qbox. Scripts that hang their own
  column on that table were guessing `users`, which is right on one framework
  out of three.

- **`player.ClearInventory()`**, with a `clear` entry in every inventory
  adapter. It answers `nil` when the running inventory cannot empty itself,
  the same rule `CanCarryItem` follows.

### Changed

- **Framework and inventory are separate axes.** No framework bridge carries
  item code any more, and no inventory adapter carries framework code. All item
  handling lives in `inventories/server/*.lua`, including the new `default.lua`
  for the inventory built into the running framework. `FunctionOverride`, which
  glued item functions onto the player object after the fact, is gone.

- **`CanCarryItem` may answer `nil`.** `nil` means the running inventory cannot
  check that, which is not the same as `false`. The old code answered `true`
  without checking on QBCore and Qbox, and an item handed out on that promise
  ends up on the floor.

- **The client has no framework adapter any more.** The server normalises player
  data and sends it with every `msk_core:*` event, and `bridge/client.lua`
  receives it. One shape, one place. The client also cannot write player data
  back any more, which was an exploit path.

- `MSK.HasItem(playerId, item, count, metadata)` takes an optional minimum
  count. Passing metadata as the third argument still works.

- The bridge no longer writes to the framework's own objects. In 3.x
  `MSK.GetPlayer()` replaced `xPlayer.job` with the bridge's own shape, for
  every resource on the server, and set `label` to the technical job name.

### Fixed

- **The load and logout events never fired.** `bridge/*/server.lua` and
  `client.lua` registered handlers for `msk_core:playerLoaded`,
  `:playerLogout`, `:setJob` and `:setPlayerData`, but nothing in msk_core ever
  triggered them and no framework event was ever bound. `MSK.LoadedPlayers`
  stayed empty on every framework, client player data was only ever filled on a
  resource restart, and consumers waiting for a load event waited forever.

- **A single unban disabled the ban system.** `UnbanPlayer` set an array slot to
  `nil` instead of removing the entry, and `MSK.IsPlayerBanned` walks
  `1..#bannedPlayers`. The next player to connect hit that hole, the
  `playerConnecting` handler died before reaching its `CancelEvent()`, and every
  banned player could join again until the next restart. A ban row with an
  unreadable time value did the same.

- **Deleting a cron job disabled cron.** Same `nil`-in-an-array cause, same
  effect on the two tick loops. On top of that, `msk_core:createCron` was a net
  event, so any client could schedule jobs on the server, and a job created from
  a plain timestamp ended the scheduler on its first run.

- **Any client could read any player's data.** The `msk_core:getPlayerData`
  callback returned the complete player table for whatever id it was asked
  about: cash, bank, every metadata field, the licence. It now answers with
  identity and job for another player, and with everything only for the caller
  themselves. It was also registered twice, and the later registration silently
  replaced the other.

- **The client player mirror could die and freeze.** `getPlayerDeath()` went
  through `MSK.Call`, which raises on timeout rather than returning nil, so one
  slow answer from visn_are ended the thread and `ped`, `vehicle`, `seat` and
  `weapon` stayed at their last value for the rest of the session. `MSK.Call`
  now returns `nil` instead of raising, which is what its own comment always
  claimed it did.

- **`MSK.Player.serverId` could stay wrong for a whole session.**
  `GetPlayerServerId` answers `-1` until the session is up, and the value was
  read once at resource start and never corrected.

- **A closed input or numpad left its caller waiting forever.** Both build a
  promise for the blocking call and both cleared only the callback on close, so
  escape or a resource stop left the promise unresolved.

- **The menu stopped accepting keys.** `Menu.Show` calls `Menu.Hide`, `Hide`
  calls `onClose`, and if that callback yields, the input thread ends itself and
  clears the flag that would have let a new one start.

- **Callback timeouts.** All three call sites rejected a promise they never
  awaited, which FiveM reports as an unhandled rejection, and returned a silent
  `nil`. The request-id collision check compared a number against entries stored
  under a string key, so it could never match.

- **`sex` was inverted** on QBCore and Qbox: `gender == 1` was read as male,
  while the character creator writes 0 for male.

- **The client bridge for QBCore read a field that does not exist.** It asked
  for `self.PlayerData.citizenid` where `self` is already the PlayerData.

- `MSK.Timeout` tracked cancelled ids instead of pending ones, so a `Clear`
  after the callback had run left an entry nothing removed again.

- `Points.Remove(id)` called its handler without `self` and could not work at
  all. `Progress` stopped animations with `anim.clip`, a field that is never
  set. `Coords.Copy` indexed `MSK.Player[id]` unchecked. `Context` and `Menu`
  built inline ids from `GetGameTimer()` and never cleaned them up.
  `AdvancedNotification` turned an explicit `flash = false` back on.
  `Check.Dependency` compared against `nil` when the two versions had different
  numbers of parts, and the "should not be renamed" warning was printed even
  when the name was right. `MSK.AddWebhook` fired HTTP requests at an empty URL
  and said nothing.

### Removed

- **ox_core.** The branch carried no guarantee, was never finished (its
  `GetPlayerData` was an empty function) and is gone. `Config.Framework =
  'OXCore'` now stops with an explicit message instead of failing later.

### Migration

- **`MSK.GetPlayer()` returns the unified shape.** Field names changed:
  `grade_name` is `gradeName`, `grade_label` is `gradeLabel`, `grade_salary` is
  `salary`, `dateofbirth` is `dob`. `sex` is `'male'` or `'female'` on every
  framework. Money is `player.money.cash` / `.bank`, and `GetMoney('cash')`
  works everywhere.

- **The methods work in your resource now.** They are built by
  `modules/Player`, which `import.lua` compiles into the consumer. Before,
  msk_core built the object and handed it over an export, where functions do not
  survive: every method arrived as `nil` and only the data half was usable.
  Reaching them through `MSK.GetPlayer(...)` is unchanged.

- **`MSK.Bridge` is a real table in a consumer.** It used to fall through to the
  export proxy and become a function, so `MSK.Bridge.Framework.Type` raised
  "attempt to index a function value". Scripts carrying
  `if MSK.Bridge and MSK.Bridge.Framework and ...` now do what they always meant
  to.

- **Event payloads carry the unified shape.** `msk_core:playerLoaded` hands over
  a player table, `msk_core:setJob` a job table. Two events were added:
  `msk_core:setGang` and `msk_core:setDuty`.

- **`Config.Framework = 'OXCore'`** has to be changed to `'AUTO'` or a supported
  framework.

### Changed files

- `fxmanifest.lua` (version bump, explicit bridge file order)
- `config.lua`
- `aliases.lua`
- `init/shared.lua`
- `bridge/shared.lua`, `bridge/server.lua` (new), `bridge/client.lua` (new)
- `init/server.lua`
- `bridge/esx/server.lua`, `bridge/qbcore/server.lua`, `bridge/qbox/server.lua` (new)
- removed: `bridge/esx/client.lua`, `bridge/qbcore/client.lua`, `bridge/oxcore/`
- `inventories/server/default.lua` (new), `ox_inventory.lua`, `jaksam_inventory.lua`,
  `core_inventory.lua`, `custom.lua`, `hasitem_server.lua`, `registeritems.lua`
- `inventories/client/hasitem_client.lua`
- `modules/Bridge/shared.lua` (new)
- `modules/Player/server.lua`, `modules/Player/client.lua`
- `modules/VehicleStore/server.lua` (new)
- `modules/Ban/server.lua`, `modules/Cron/server.lua`, `modules/Check/server.lua`
- `modules/Callback/shared.lua`, `client.lua`, `server.lua`
- `modules/Society/server.lua`, `modules/Offline/server.lua`
- `modules/Command/server.lua`, `modules/Notify/client.lua`, `modules/Vehicle/server.lua`
- `modules/Timeout/shared.lua`, `modules/World/server.lua`, `modules/Coords/server.lua`
- `modules/Input/client.lua`, `modules/Numpad/client.lua`, `modules/Progress/client.lua`
- `modules/Points/client.lua`, `modules/Context/*.lua`, `modules/Menu/*.lua`

## [3.3.1] - 2026-08-08

### Fixed

- **`MSK.Call` failed on Linux servers.** Internally the core asked its module
  loader for `timeout`, but the folder is `modules/Timeout`. Windows filesystems
  ignore case, so this only ever surfaced on Linux, where the load returned
  nothing and every `MSK.Call` aborted with "requires the 'timeout' module (not
  yet ported)". The lookup now uses the real folder name. Scripts that reach
  `MSK.Call` through the module were never affected, only the core-internal
  path.

- The error message behind that lookup no longer claims the module is "not yet
  ported". `Timeout` has shipped since v3.0.0, so the old wording sent anyone
  hitting it looking for a missing feature instead of a failed load.

### Changed

- The eager-loading example in `import.lua` and the module examples in
  `init/shared.lua` used lowercase names that do not match any folder. They now
  show the real spelling and state that the name is case-sensitive on Linux.

- The version badge in `Readme.md` was still on 3.2.0.

### Changed files

- `fxmanifest.lua` (version bump)
- `init/shared.lua`
- `import.lua`
- `Readme.md`

## [3.3.0] - 2026-08-01

### Added

- **`MSK.AddRawAce` and `MSK.RemoveRawAce`, for ace objects that must not live
  under `command.`.** `MSK.AddAce` prefixes every ace with `command.`, which is
  right for commands but wrong for anything used as a permission object. Almost
  every server.cfg contains `add_ace group.admin command allow`, and ace objects
  are inherited by their children, so an object called `command.whatever` is
  handed to everyone holding `command`. The raw variants pass principal and ace
  through exactly as given, no prefixing and no principal normalisation, so
  `qbcore.admin` stays `qbcore.admin` instead of becoming `group.qbcore.admin`.

  They also solve something a consumer cannot solve on its own. FiveM checks
  `add_ace` against the resource that runs it, and `import.lua` compiles these
  modules **into** the consumer, so an `ExecuteCommand('add_ace ...')` written in
  a script runs as `resource.<that script>` and gets denied. Called from a
  consumer, `MSK.AddRawAce` bounces through msk_core's export, so the command runs
  as `resource.msk_core` and the single line you already have in your server.cfg
  covers every MSK script at once.

- **`MSK.CanAddAce()`** returns whether msk_core is currently allowed to run
  `add_ace`. Lets a script check up front instead of firing commands that get
  refused and fill the console with `Access denied for command add_ace`.

### Changed files

- `fxmanifest.lua` (version bump)
- `modules/Ace/server.lua`

## [3.2.0] - 2026-07-30

### Added

- **Find a spawned vehicle by its plate, without knowing where it is.**
  `MSK.GetVehicleFromPlate(plate)` returns the vehicle and its network id, on the
  client and on the server. The two functions that already existed,
  `MSK.GetVehicleWithPlate` and `MSK.GetClosestVehicleWithPlate`, both need a
  point and a radius, so a plate on its own was not enough to find anything.

  The search always runs on the server. A client asks over the callback API and
  gets the network id back, which it resolves locally. That way no client walks
  its own vehicle pool, and the answer covers every vehicle on the server
  instead of only the ones streamed in nearby. Because it is a callback round
  trip, the client side is blocking and has to be called from inside a thread.

  A network id without a local vehicle handle is a normal result and means the
  vehicle exists but is not streamed in for that client. There is nothing local
  to hand out in that case, the network id can still be passed around.

- **Read the model of a plate out of the database.**
  `MSK.GetModelFromPlate(plate)` returns the model hash, and the spawn name when
  the framework stores one. It reads the framework's vehicle table (`vehicle` in
  `owned_vehicles` on ESX, `vehicle` and `hash` in `player_vehicles` on QBCore),
  so it also answers while the vehicle is parked in a garage and does not exist
  in the world at all. Available on the client and on the server, and blocking
  on both, so call it from inside a thread. Other frameworks return `nil`.

- Plates are now compared after trimming **and** upper casing them, on both
  sides of every comparison. GTA hands plates back space padded, while a plate
  from a database, a command or a config is usually trimmed and not necessarily
  upper case, so the two never matched. Inner spaces are kept on purpose,
  `AB C123` and `ABC123` are two different plates. This applies to the two new
  functions, the existing `...WithPlate` functions are unchanged.

### Changed

- **Every NUI component now sits behind its own error boundary.** A single throw
  in one component used to unmount the entire interface, so notifications,
  input, numpad, progressbar, textui and both menus disappeared together until
  the resource was restarted. That is what a `nil` text in the color code parser
  caused in v3.1.0. Now only the component that actually failed goes away.

  A failed component reports to the client console with its name and stack
  instead of vanishing silently, and it comes back on the next NUI message. Only
  three failures within thirty seconds count as a crash loop and keep it hidden
  until the resource restarts, so a rare bad call does not disable a component
  for the rest of the session.

To update, replace `fxmanifest.lua`, `init/client.lua`, the `modules/Vehicle`
folder and `web/dist`.

### Changed files

- `fxmanifest.lua`
- `init/client.lua`
- `modules/Vehicle/shared.lua` (new)
- `modules/Vehicle/client.lua`
- `modules/Vehicle/server.lua`
- `web/src/App.tsx`
- `web/src/components/ErrorBoundary.tsx` (new)
- `web/dist/**` (rebuilt)
- `Readme.md`

## [3.1.2] - 2026-07-18

### Changed

- **NUI rebuilt on updated dependencies.** The web interface was rebuilt with
  React 19, Vite 8, TypeScript 7 and FontAwesome 7. There is no API or behavior
  change, the Lua side is untouched. FontAwesome 7 ships only woff2, so the
  unused `.ttf` font files were removed from `web/dist`.

### Repository

- Added continuous integration (CodeQL analysis for the NUI and a NUI build
  check), Dependabot for npm and GitHub Actions, an auto release workflow that
  tags and publishes a release from the matching CHANGELOGS.md section, and the
  standard community health files (Code of Conduct, Contributing, Security
  Policy, issue and pull request templates). These live in the repository only
  and are not part of the resource you upload to your server.

To update, replace `fxmanifest.lua` and `web/dist`. Pure NUI rebuild, no Lua or
API change.

### Changed files

- `fxmanifest.lua`
- `web/dist/**` (rebuilt, `.ttf` fonts removed)
- `web/src/hooks/useNuiEvent.ts`
- `web/package.json`
- `web/package-lock.json`
- `Readme.md`

## [3.1.1] - 2026-07-10

### Changed

- **Both menus now use a namespaced API.** The documented way to reach them is
  `MSK.Context.Register`, `MSK.Context.Show`, `MSK.Context.Update`, `MSK.Context.Hide`,
  `MSK.Context.GetOpen` and the same set on `MSK.Menu`. This matches the rest of the
  library, where `MSK.Input.Open` and `MSK.Cron.Create` already work that way. Nothing
  breaks: the flat names from v3.1.0 (`MSK.RegisterContext`, `MSK.ShowMenu`,
  `MSK.UpdateContext` and so on) point at the same functions and stay supported, and the
  exports are unchanged (`exports.msk_core:RegisterContext(...)`).

- **`MSK.Menu.Hide` replaces `MSK.Menu.Close`** so it lines up with `MSK.Context.Hide`.
  `MSK.Menu.Close` remains as an alias.

### Fixed

- **The Menu module leaked its internal navigation onto the public table.** `MSK.Menu.Move`,
  `MSK.Menu.SideScroll` and `MSK.Menu.Select` were reachable inside msk_core but did not
  exist for consumer resources, so calling them from another script failed. They are
  module-internal now and no longer part of the public API.

Pure Lua change, the NUI is untouched. Only the two Menu files have to be replaced,
`web/dist` can stay as it is.

### Changed files

- `fxmanifest.lua`
- `modules/Menu/client.lua`
- `modules/Menu/server.lua`

## [3.1.0] - 2026-07-10

### Added

- **Context Menu.** A mouse driven menu with clickable options, sub menus and back
  navigation. A menu is registered once under an id and can then be opened as often as
  needed. Options support icons, descriptions, images, progress bars, hover metadata,
  `disabled` and `readOnly` rows, and can run a callback (`onSelect`), trigger a client
  or server event (`event` / `serverEvent`), or navigate into another registered menu
  (`menu`). While a context menu is open the NUI takes mouse focus, so the player stands
  still, which is intended because the mouse is needed to click.
  - Client: `MSK.RegisterContext`, `MSK.ShowContext`, `MSK.UpdateContext`,
    `MSK.HideContext`, `MSK.GetOpenContext`
  - Server: `MSK.ShowContext(playerId, idOrData)`, `MSK.HideContext(playerId)`

- **Menu.** A keyboard navigated list menu in the style of a classic NativeUI menu, with
  a highlighted row, side scroll values, checkboxes and progress bars. It deliberately
  does not take NUI focus. The arrow keys are read through the game controls and only
  those navigation controls are disabled, so the player can keep walking, driving and
  doing everything else while the menu is on screen. The complete state (selected row,
  current values, checkbox states) lives in Lua, so `onSelected`, `onSideScroll`,
  `onCheck` and `onClose` always receive the authoritative values.
  - Client: `MSK.RegisterMenu`, `MSK.ShowMenu`, `MSK.UpdateMenu`, `MSK.HideMenu`,
    `MSK.GetOpenMenu`
  - Server: `MSK.ShowMenu(playerId, idOrData)`, `MSK.HideMenu(playerId)`

- **Live updates for both menus.** `MSK.UpdateContext(contextId, dataId, updatedData)`
  and `MSK.UpdateMenu(menuId, dataId, updatedData)` address a single option through its
  `id` and merge the given fields into it, so only what actually changes is passed. If
  exactly that menu is currently open, the UI is refreshed live. This replaces the need
  to rebuild and reopen a whole menu just to move a progress bar, relabel a row or
  disable an option.

Both menus were written from scratch for msk_core and use the MSK design language (dark
panel, green accent, bundled FontAwesome icons), consistent with the rest of the NUI.

The NUI was rebuilt for this release, so `web/dist` has to be replaced together with the
Lua files.

### Fixed

- **A missing text could take down the whole NUI.** The color code parser called
  `String.slice` on whatever it was handed, so a single call with a `nil` text, for
  example `MSK.Notification('some text')` where the second parameter is the message and
  was left out, threw inside React. Because the NUI has no error boundary, that one throw
  unmounted every component at once: notifications, input, numpad, progressbar, textui and
  the new menus all disappeared until the resource was restarted. The parser now returns
  an empty result for `nil` and converts numbers to strings, so a bad call degrades to an
  empty label instead of killing the interface.

### Changed files

- `fxmanifest.lua`
- `init/client.lua`
- `init/server.lua`
- `modules/Context/client.lua`
- `modules/Context/server.lua`
- `modules/Menu/client.lua`
- `modules/Menu/server.lua`
- `web/src/App.tsx`
- `web/src/types.ts`
- `web/src/index.css`
- `web/src/lib/colorCodes.tsx`
- `web/src/components/ContextMenu.tsx`
- `web/src/components/ListMenu.tsx`
- `web/src/components/menu/frame.tsx`
- `web/src/dev/DevPanel.tsx`
- `web/dist/index.html`
- `web/dist/assets/index.js`
- `web/dist/assets/index.css`

## [3.0.1] - 2026-07-08

### Fixed

- **QBCore item functions were unreachable and crashed `MSK.GetPlayer()`.**
  On QBCore the player wrapper read the item helpers from `self.PlayerData.Functions`,
  which is `nil` (QBCore exposes them on `Player.Functions`). Any command or script
  that resolved a player and touched `AddItem`, `RemoveItem`, `HasItem` or `GetItem`
  crashed with `attempt to index a nil value (field 'Functions')`. They now read from
  `self.Functions`, consistent with the rest of the wrapper.

- **Eager loading a module could break other resources or duplicate effects.**
  Several modules registered shared, msk_core owned listeners (net events, callbacks,
  commands, background threads) unconditionally. When a consumer resource eager loaded
  such a module (for example `msk_core 'Notify'` in its `fxmanifest.lua`), a second copy
  of those listeners started inside the consumer and interfered server wide. Every
  affected module now guards its shared registrations so they run only inside msk_core,
  while consumers keep the full callable API through the export proxy. This makes every
  module safe to eager load. Affected modules and their symptom:
  - **Callback**: a second responder answered `callbackNotFound` for other resources'
    callbacks and broke them.
  - **Notify (client)**: notifications were shown twice, once per eager loading resource.
  - **Command (server)**: the `msk_core:doesPlayerExist` and `msk_core:getPlayerData`
    callbacks were re registered onto the core with a closure pointing back into the
    consumer, so they broke once that consumer stopped.
  - **Ace (server)**: the `msk_core:isAceAllowed` and `msk_core:isPrincipalAceAllowed`
    callbacks had the same problem.
  - **Entities (client)**: a second death detection handler reported every death twice.
  - **Vehicle (client)**: a second enter/exit thread reported every vehicle event twice.
  - **DisconnectLogger (client and server)**: disconnects were logged and drawn more
    than once.
  - **Ban (server)**: bans were enforced twice and the `/ban` and `/unban` commands were
    registered a second time.
  - **Cron (server)**: a second tick loop and `createCron` listener could run a cron job
    twice.

- **`MSK.Cron` was unusable from consumer resources.**
  The Cron module returned `true`, which the consumer loader cached over the `MSK.Cron`
  table, leaving only `MSK.CreateCron` and `MSK.DeleteCron` reachable. It now returns the
  `MSK.Cron` table, so `MSK.Cron.Create` and `MSK.Cron.Delete` work as documented.

### Changed files

- `bridge/qbcore/server.lua`
- `modules/Callback/shared.lua`
- `modules/Callback/client.lua`
- `modules/Callback/server.lua`
- `modules/Notify/client.lua`
- `modules/Command/server.lua`
- `modules/Ace/server.lua`
- `modules/Entities/client.lua`
- `modules/Vehicle/client.lua`
- `modules/DisconnectLogger/client.lua`
- `modules/DisconnectLogger/server.lua`
- `modules/Ban/server.lua`
- `modules/Cron/server.lua`
- `fxmanifest.lua`
- `Readme.md`

## [3.0.0]

Full rewrite. Framework and inventory bridge architecture (ESX, QBCore, ox_core,
STANDALONE), lazy loaded modules, and a new React + Vite + TypeScript NUI (Notify, Input,
Numpad, Progressbar, TextUI). Full API reference at
[docu.msk-scripts.de/docs/msk_core](https://docu.msk-scripts.de/docs/msk_core/).
