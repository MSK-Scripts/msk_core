# Changelog

All notable changes to msk_core are documented in this file.

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
