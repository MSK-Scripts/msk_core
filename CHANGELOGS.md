# Changelog

All notable changes to msk_core are documented in this file.

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
