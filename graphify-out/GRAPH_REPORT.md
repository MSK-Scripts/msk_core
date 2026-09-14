# Graph Report - msk_core  (2026-09-14)

## Corpus Check
- 141 files · ~160,299 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1283 nodes · 1987 edges · 116 communities (109 shown, 7 thin omitted)
- Extraction: 93% EXTRACTED · 7% INFERRED · 0% AMBIGUOUS · INFERRED: 142 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `498296c6`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- App.tsx
- MSK Core Shared Library
- devDependencies
- logging
- compilerOptions
- Vehicle/client.lua
- msk_core README Banner
- ErrorBoundary
- Menu/client.lua
- Incorrect-Input Error State
- Table/shared.lua
- Zones/client.lua
- MSK Core NUI Input Component
- MSK Core NUI Input Component
- Numpad Component (msk_core NUI)
- Masked Input Mode (Dot Placeholders)
- 3x4 Numeric Key Grid (1-9, 0)
- types.ts
- Request/client.lua
- MSK Core Progressbar NUI Component
- CodeQL analysis workflow
- Context/client.lua
- Notify/client.lua
- Notify/server.lua
- Notify NUI Component
- TextUI NUI Component
- Coords/client.lua
- Cache/shared.lua
- Points/client.lua
- Scaleform/client.lua
- Progress/client.lua
- String/shared.lua
- Contributor Covenant Code of Conduct
- Entities/client.lua
- Society/server.lua
- TextUI/client.lua
- Vector/shared.lua
- Pull Request template
- import.lua
- Check/server.lua
- Command/client.lua
- Entities/server.lua
- Input/client.lua
- Math/shared.lua
- Numpad/client.lua
- Offline/server.lua
- TextUI/server.lua
- ContextMenu.tsx
- InputDialog.tsx
- Numpad/server.lua
- Progress/server.lua
- esx/server.lua
- Array/shared.lua
- qbcore/server.lua
- Player/server.lua
- Cron/server.lua
- Selector/shared.lua
- Radial/client.lua
- qbox/server.lua
- GNU General Public License v3.0 text
- core_inventory.lua
- jaksam_inventory.lua
- ox_inventory.lua
- Timer/shared.lua
- default.lua
- Locale/shared.lua
- NotifyStack.tsx
- bridge/server.lua
- Print/shared.lua
- VehicleStore/server.lua
- Marker/client.lua
- Class/shared.lua
- Grid/shared.lua
- Settings/client.lua
- Keybind/client.lua
- Logger/server.lua
- RadialMenu.tsx
- Controls/client.lua
- Anim/client.lua
- Skillcheck/client.lua
- Hook/shared.lua
- VehicleProperties/client.lua
- Alert/client.lua
- Events/server.lua

## God Nodes (most connected - your core abstractions)
1. `useNuiEvent()` - 28 edges
2. `fetchNui()` - 24 edges
3. `compilerOptions` - 17 edges
4. `parseColorCodes()` - 16 edges
5. `assertList()` - 15 edges
6. `logging()` - 13 edges
7. `faClass()` - 13 edges
8. `raw()` - 12 edges
9. `ready()` - 12 edges
10. `playSound()` - 11 edges

## Surprising Connections (you probably didn't know these)
- `MSK.AddPrincipal()` --calls--> `logging()`  [INFERRED]
  modules/Ace/server.lua → init/shared.lua
- `MSK.RemovePrincipal()` --calls--> `logging()`  [INFERRED]
  modules/Ace/server.lua → init/shared.lua
- `MSK.Cron.Create()` --calls--> `logging()`  [INFERRED]
  modules/Cron/server.lua → init/shared.lua
- `Framework-agnostic code rule (route through bridge/)` --conceptually_related_to--> `Framework Bridge (ESX / QBCore / ox_core / STANDALONE)`  [INFERRED]
  .github/CONTRIBUTING.md → Readme.md
- `Supported frameworks (ESX, QBCore, ox_core, STANDALONE)` --conceptually_related_to--> `Framework Bridge (ESX / QBCore / ox_core / STANDALONE)`  [INFERRED]
  .github/ISSUE_TEMPLATE/bug_report.yml → Readme.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Input dialog composed of header, text field and submit button** — _assets_input_small_header_section, _assets_input_small_text_field, _assets_input_small_submit_button, _assets_input_small_input_component [EXTRACTED 1.00]
- **Header, Textarea and Submit Button Compose the Input Dialog** — _assets_input_large_header_accent_divider, _assets_input_large_large_textarea_variant, _assets_input_large_submit_button, _assets_input_large_centered_modal_panel [EXTRACTED 1.00]
- **Menu subsystem: both menus, their live update path and the namespaced API** — changelogs_context_menu, changelogs_menu, changelogs_live_menu_updates, changelogs_namespaced_menu_api, changelogs_menu_internal_navigation_leak [EXTRACTED 1.00]
- **Banner text stack communicating what msk_core is** — _assets_msk_core_banner_eyebrow_core_framework, _assets_msk_core_banner_wordmark, _assets_msk_core_banner_tagline, _assets_msk_core_banner_tech_chips [EXTRACTED 1.00]
- **NUI resilience: nil-safe parsing, per-component boundaries and the crash loop rule** — changelogs_colorcode_parser_nil_fix, changelogs_error_boundary, changelogs_crash_loop_threshold, readme_nui [EXTRACTED 1.00]
- **Bottom Action Row: Backspace, Zero, Confirm** — _assets_numpad_numbers_backspace_key, _assets_numpad_numbers_confirm_key, _assets_numpad_numbers_key_grid [EXTRACTED 1.00]
- **Plate lookup flow: server-side search, DB model resolution and plate normalization** — changelogs_getvehiclefromplate, changelogs_getmodelfromplate, changelogs_plate_normalization, readme_framework_bridge [EXTRACTED 1.00]
- **Privacy-Oriented Input Design (Masking plus Count Feedback)** — _assets_numpad_masked_masked_input_mode, _assets_numpad_masked_shoulder_surfing_rationale, _assets_numpad_masked_progress_feedback_rationale [INFERRED 0.75]
- **MSK Design Language Applied to Numpad** — _assets_numpad_msk_dark_theme, _assets_numpad_color_coded_actions_rationale, _assets_numpad_component, _assets_numpad_keypad_grid [INFERRED 0.75]
- **CI and release automation pipeline** — _github_workflows_codeql_codeql_workflow, _github_workflows_web_build_nui_build_workflow, _github_workflows_release_release_workflow, _github_dependabot_dependabot_config [INFERRED 0.85]
- **Framework and inventory abstraction contract for contributions** — readme_framework_bridge, readme_inventory_bridge, _github_contributing_framework_agnostic_rule, _github_contributing_dual_api_rule, _github_issue_template_bug_report_framework_dropdown [INFERRED 0.85]
- **Dark Panel, Green Accent and Uppercase Monospace Type Implement the MSK Design Language** — _assets_input_large_msk_design_language, _assets_input_large_header_accent_divider, _assets_input_large_submit_button, _assets_input_large_centered_modal_panel [INFERRED 0.85]
- **Previous MSK Core banner visual identity system** — _assets_msk_core_banner_old, _assets_msk_core_banner_old_wordmark, _assets_msk_core_banner_old_dark_green_palette, _assets_msk_core_banner_old_ui_card_mockups, _assets_msk_core_banner_old_tagline [INFERRED 0.85]
- **MSK Scripts visual identity expressed by the banner** — _assets_msk_core_banner_m_monogram, _assets_msk_core_banner_wordmark, _assets_msk_core_banner_dark_green_palette, _assets_msk_core_banner_typography_system, _assets_msk_core_banner_split_layout [INFERRED 0.85]
- **MSK Progressbar Visual Language** — _assets_progressbar_component, _assets_progressbar_skewed_bar_geometry, _assets_progressbar_accent_green_fill, _assets_progressbar_uppercase_mono_label, _assets_progressbar_dark_panel_theme [INFERRED 0.85]
- **MSK visual identity applied across input dialog elements** — _assets_input_small_msk_design_tokens, _assets_input_small_monospace_uppercase_labels, _assets_input_small_header_section, _assets_input_small_submit_button [INFERRED 0.85]
- **Toast Anatomy: Typed Header, Color-Coded Body, Timer Bar** — _assets_notify_icon_header, _assets_notify_color_codes, _assets_notify_progress_bar, _assets_notify_types [INFERRED 0.85]
- **Numpad Error Feedback System** — _assets_numpad_incorrect_error_state, _assets_numpad_incorrect_display_field, _assets_numpad_incorrect_semantic_color_coding, _assets_numpad_incorrect_inline_feedback_pattern [INFERRED 0.85]
- **Numpad Input Controls** — _assets_numpad_incorrect_keypad_grid, _assets_numpad_incorrect_backspace_key, _assets_numpad_incorrect_confirm_key, _assets_numpad_incorrect_retry_affordance [INFERRED 0.85]
- **Masked PIN Entry Flow (Keys, Masked Display, Confirm/Backspace)** — _assets_numpad_masked_key_grid, _assets_numpad_masked_display_field, _assets_numpad_masked_action_keys, _assets_numpad_masked_masked_input_mode [INFERRED 0.85]
- **Numpad PIN Entry Flow (display, digits, confirm/backspace)** — _assets_numpad_code_display, _assets_numpad_keypad_grid, _assets_numpad_action_keys, _assets_numpad_component [INFERRED 0.85]
- **TextUI Visual Composition (panel, keycap, label, tokens)** — _assets_textui_component, _assets_textui_keycap_badge, _assets_textui_prompt_label, _assets_textui_msk_design_tokens [INFERRED 0.85]

## Communities (116 total, 7 thin omitted)

### Community 0 - "App.tsx"
Cohesion: 0.11
Nodes (29): App(), ClipboardHandler(), copyFallback(), copyToClipboard(), AlertDialog(), WIDTH, ContextMenu(), firstSelectable() (+21 more)

### Community 1 - "MSK Core Shared Library"
Cohesion: 0.07
Nodes (40): Contributing to MSK Core, Framework-agnostic code rule (route through bridge/), Lua 5.4 requirement (lua54 'yes'), Bug Report issue form, Supported frameworks (ESX, QBCore, ox_core, STANDALONE), Supported inventory bridges (ox_inventory, core_inventory, jaksam_inventory, default, custom), Feature Request issue form, Private vulnerability disclosure process (+32 more)

### Community 2 - "devDependencies"
Cohesion: 0.05
Nodes (36): @fontsource/dm-sans, @fontsource/space-mono, @fontsource/syne, @fortawesome/fontawesome-free, react, react-dom, tailwindcss, @tailwindcss/vite (+28 more)

### Community 3 - "logging"
Cohesion: 0.06
Nodes (38): logging(), mountCore(), registerExport(), allowAce(), checkParams(), MSK.AddAce(), MSK.AddPrincipal(), MSK.AddRawAce() (+30 more)

### Community 4 - "compilerOptions"
Cohesion: 0.08
Nodes (23): DOM, DOM.Iterable, ES2020, src, vite.config.ts, compilerOptions, allowImportingTsExtensions, isolatedModules (+15 more)

### Community 5 - "Vehicle/client.lua"
Cohesion: 0.11
Nodes (11): MSK.GetModelFromPlate(), MSK.GetVehicleFromPlate(), MSK.GetVehicleLabel(), MSK.GetVehicleLabelFromModel(), MSK.GetVehicleWithPlate(), MSK.GetClosestVehicleWithPlate(), MSK.GetModelFromPlate(), MSK.GetVehicleFromPlate() (+3 more)

### Community 6 - "msk_core README Banner"
Cohesion: 0.17
Nodes (19): msk_core README Banner, MSK Scripts Brand Identity, Dark Green MSK Colour Palette, Eyebrow Label CORE FRAMEWORK, Framework Support Claim (ESX and QBCore), Gradient M Monogram Logo, MSK Core README Banner (previous version), Earlier Iteration of MSK Scripts Brand Identity (+11 more)

### Community 8 - "Menu/client.lua"
Cohesion: 0.29
Nodes (17): buildRuntime(), copy(), firstSelectable(), Menu.Hide(), Menu.Register(), Menu.SetOptions(), Menu.Show(), Menu.Update() (+9 more)

### Community 9 - "Incorrect-Input Error State"
Cohesion: 0.23
Nodes (12): Red Backspace Key, Green Confirm Key, Display Field Showing INCORRECT, Incorrect-Input Error State, Inline Feedback Instead of Separate Dialog, 3x4 Digit Keypad Grid, Monospace Uppercase Feedback Typography, MSK Dark Design Language (+4 more)

### Community 10 - "Table/shared.lua"
Cohesion: 0.10
Nodes (7): read(), Require.File(), Require.Json(), Require.Load(), Require.Unload(), resolve(), Table.Freeze()

### Community 11 - "Zones/client.lua"
Cohesion: 0.15
Nodes (16): drawQuad(), drawWalls(), drawZone(), pointInPolygon(), polyContains(), register(), safeCall(), startFrameLoop() (+8 more)

### Community 12 - "MSK Core NUI Input Component"
Cohesion: 0.33
Nodes (10): Rationale: compact dialog keeps game view unobstructed, Dialog Header with Accent Divider, MSK Core NUI Input Component, Monospace Uppercase Label Convention, MSK Dark Theme Design Tokens (green accent), Lua to NUI Input Contract (MSK.Input / SendNUIMessage), Input Dialog Screenshot (small variant), Input Size Variant (small) (+2 more)

### Community 13 - "MSK Core NUI Input Component"
Cohesion: 0.31
Nodes (9): Centered Modal Panel Layout, Uppercase Monospace Header with Green Accent Divider, MSK Core NUI Input Component, Large Multiline Textarea Input Variant, MSK Dark Design Language (Green Accent), MSK.Input Lua/NUI Message Contract, Placeholder Text Affordance ("Large text input..."), Input Dialog (Large Variant) Screenshot (+1 more)

### Community 14 - "Numpad Component (msk_core NUI)"
Cohesion: 0.33
Nodes (9): Backspace and Confirm Action Keys, Code Display Field (ENTER CODE placeholder), Rationale: Color-Coded Destructive vs Confirm Actions, Numpad Component (msk_core NUI), 3x4 Digit Keypad Grid (0-9), Rationale: Mouse-Driven PIN Entry in Game NUI, MSK Dark Theme with Green Accent, MSK.Numpad Module (Lua API) (+1 more)

### Community 15 - "Masked Input Mode (Dot Placeholders)"
Cohesion: 0.33
Nodes (9): Numpad Masked Input Screenshot, Backspace (Red) and Confirm (Green) Action Keys, Display Field Showing Four Filled Dots, 3x4 Digit Key Grid (1-9, 0), Masked Input Mode (Dot Placeholders), MSK Dark Theme with Green Accent, Numpad NUI Component, Rationale: Dots Give Digit-Count Feedback Without Revealing Values (+1 more)

### Community 16 - "3x4 Numeric Key Grid (1-9, 0)"
Cohesion: 0.31
Nodes (9): Numpad Numbers Screenshot, Physical ATM/Phone Keypad Metaphor, Red Backspace/Delete Key, Color-Coded Action Affordance (green = confirm, red = destructive), Green Confirm/Checkmark Key, PIN Display Field (monospace, shows entered digits), 3x4 Numeric Key Grid (1-9, 0), MSK Dark Theme Design Language (near-black panel, rounded tiles, green accent) (+1 more)

### Community 17 - "types.ts"
Cohesion: 0.07
Nodes (28): contextOptions(), DevPanel(), menuItems(), NOTIFY_POSITIONS, NOTIFY_TYPES, send(), CancelSkillcheckMessage, CloseAlertMessage (+20 more)

### Community 18 - "Request/client.lua"
Cohesion: 0.21
Nodes (12): awaitRaycast(), Request.AnimDict(), Request.AnimSet(), Request.CameraRaycast(), Request.Model(), Request.PtfxAsset(), Request.RaycastFromCoords(), Request.ReadRaycast() (+4 more)

### Community 19 - "MSK Core Progressbar NUI Component"
Cohesion: 0.36
Nodes (8): Progressbar Screenshot (.assets/progressbar.png), MSK Accent Green Gradient Fill (#00E676), MSK Core Progressbar NUI Component, Dark Panel Theme with Subtle Border, Rationale: Glanceable In-Game HUD Feedback, React + Vite + Tailwind NUI Stack (web/), Skewed Parallelogram Bar Geometry, Uppercase Monospace Status Label ("SEARCHING...")

### Community 20 - "CodeQL analysis workflow"
Cohesion: 0.32
Nodes (8): Committed web/dist build artifact policy, Dependabot configuration, Weekly github-actions updates (ci commit prefix), Weekly npm updates for /web (react and build-tooling groups), CodeQL analysis workflow, Only the NUI is analyzable (Lua unsupported by CodeQL), NUI Build workflow (type-check and vite build), NUI HTML entry document (root div, /src/main.tsx module script)

### Community 21 - "Context/client.lua"
Cohesion: 0.29
Nodes (12): Context.Hide(), Context.Register(), Context.Show(), Context.Update(), copy(), normalizeMetadata(), normalizeOptions(), register() (+4 more)

### Community 22 - "Notify/client.lua"
Cohesion: 0.13
Nodes (16): display(), drawDisplay(), MSK.Draw3DText(), MSK.Notification(), playGameSound(), show(), soundEnabled(), toData() (+8 more)

### Community 24 - "Notify NUI Component"
Cohesion: 0.43
Nodes (7): Inline Color-Code Markup in Notification Text, Notify NUI Component, MSK Dark Panel Design Language, Icon Plus Monospace Uppercase Header Row, Auto-Dismiss Duration Progress Bar, Notify NUI Screenshot, Notification Type Variants (error, warning, success, info, general)

### Community 25 - "TextUI NUI Component"
Cohesion: 0.48
Nodes (7): TextUI Screenshot (.assets/textui.png), TextUI NUI Component, Rationale: Glanceable Non-Blocking On-Screen Hint, Keybind Affordance Pattern, Highlighted Keycap Badge Element, MSK Dark Panel + Green Accent Design Tokens, Prompt Label Text (Press E to interact)

### Community 27 - "Cache/shared.lua"
Cohesion: 0.48
Nodes (5): Cache.Get(), Cache.Has(), Cache.Set(), isFresh(), store()

### Community 28 - "Points/client.lua"
Cohesion: 0.33
Nodes (5): ConvertCoords(), Points.Add(), Points.Remove(), RemovePoint(), runCallback()

### Community 29 - "Scaleform/client.lua"
Cohesion: 0.17
Nodes (14): announce(), ensureHandle(), Movie:Call(), Movie:CallWithReturn(), Movie:Draw(), Movie:Render(), Movie:SetRenderTarget(), pushArgument() (+6 more)

### Community 30 - "Progress/client.lua"
Cohesion: 0.26
Nodes (15): begin(), beginLegacy(), copy(), createProps(), deleteProps(), interrupted(), newState(), normalize() (+7 more)

### Community 32 - "String/shared.lua"
Cohesion: 0.32
Nodes (4): fillPattern(), String.RandomPattern(), String.Trim(), String.TrimLegacy()

### Community 33 - "Contributor Covenant Code of Conduct"
Cohesion: 0.40
Nodes (5): Contributor Covenant Code of Conduct, Community Impact Enforcement Ladder, MSK Scripts Discord (community and reporting channel), Issue template config (blank issues disabled, Discord and Docs links), Support routing to Discord instead of issues

### Community 35 - "Entities/client.lua"
Cohesion: 0.29
Nodes (11): getEntities(), MSK.GetClosestEntities(), MSK.GetClosestEntity(), MSK.GetClosestObject(), MSK.GetClosestPed(), MSK.GetNearbyObjects(), MSK.GetNearbyPeds(), MSK.GetNearbyPlayers() (+3 more)

### Community 37 - "Society/server.lua"
Cohesion: 0.48
Nodes (5): getProvider(), Society.AddMoney(), Society.GetMoney(), Society.GetProvider(), Society.RemoveMoney()

### Community 38 - "TextUI/client.lua"
Cohesion: 0.36
Nodes (9): display(), normalize(), sameAs(), showThreaded(), TextUI.Hide(), TextUI.Show(), TextUI.ShowThread(), toTable() (+1 more)

### Community 39 - "Vector/shared.lua"
Cohesion: 0.47
Nodes (3): getTableHeading(), Vector.CoordsToString(), Vector.TableToVector()

### Community 41 - "Pull Request template"
Cohesion: 0.50
Nodes (4): Dual API exposure rule (MSK.Function and exports.msk_core:Function), Pull request checklist, Mandatory server-side validation of client input, Pull Request template

### Community 42 - "import.lua"
Cohesion: 0.83
Nodes (3): compile(), mount(), resolve()

### Community 44 - "Command/client.lua"
Cohesion: 0.60
Nodes (3): copyProperties(), MSK.RegisterCommand(), RegisterHotkey()

### Community 45 - "Entities/server.lua"
Cohesion: 0.80
Nodes (4): getEntities(), MSK.GetClosestEntities(), MSK.GetClosestEntity(), resolveOrigin()

### Community 46 - "Input/client.lua"
Cohesion: 0.11
Nodes (13): Input.Close(), Input.CloseDialog(), Input.Dialog(), Input.Open(), openLegacy(), settle(), settleDialog(), warnDeprecated() (+5 more)

### Community 47 - "Math/shared.lua"
Cohesion: 0.20
Nodes (9): Math.Clamp(), Math.HexToRgb(), Math.InverseLerp(), Math.Lerp(), Math.NormalToRotation(), Math.Remap(), Math.ToRgba(), Math.ToScalars() (+1 more)

### Community 48 - "Numpad/client.lua"
Cohesion: 0.35
Nodes (9): begin(), failedValue(), finish(), labelsOf(), normalizeCode(), Numpad.Close(), Numpad.Input(), Numpad.Open() (+1 more)

### Community 49 - "Offline/server.lua"
Cohesion: 0.57
Nodes (5): isOnline(), Offline.AddBank(), Offline.GetBank(), Offline.RemoveBank(), onlineCall()

### Community 50 - "TextUI/server.lua"
Cohesion: 0.53
Nodes (4): TextUI.Show(), TextUI.ShowThread(), toTable(), warnDeprecated()

### Community 54 - "ContextMenu.tsx"
Cohesion: 0.17
Nodes (21): clamp(), ContextRow(), normalizeMeta(), Field(), clamp(), MenuListRow(), EmptyRow(), faClass() (+13 more)

### Community 55 - "InputDialog.tsx"
Cohesion: 0.29
Nodes (10): FieldProps, FieldValue, initialValue(), InputDialog(), isBlank(), toPayload(), validate(), WIDTH (+2 more)

### Community 57 - "Numpad/server.lua"
Cohesion: 0.47
Nodes (3): normalizeCode(), Numpad.Open(), warnDeprecated()

### Community 58 - "Progress/server.lua"
Cohesion: 0.53
Nodes (4): Progress.Circle(), Progress.Start(), start(), warnDeprecated()

### Community 59 - "esx/server.lua"
Cohesion: 0.09
Nodes (10): accountName(), Adapter.addJob(), Adapter.addMoney(), Adapter.getMoney(), Adapter.read(), Adapter.removeMoney(), Adapter.setJob(), Adapter.setMoney() (+2 more)

### Community 60 - "Array/shared.lua"
Cohesion: 0.22
Nodes (18): Array.Chunk(), Array.Concat(), Array.Every(), Array.Filter(), Array.Find(), Array.FindIndex(), Array.Flatten(), Array.ForEach() (+10 more)

### Community 61 - "qbcore/server.lua"
Cohesion: 0.09
Nodes (17): accountName(), Adapter.addGang(), Adapter.addJob(), Adapter.addMoney(), Adapter.getGangs(), Adapter.getJobs(), Adapter.getMoney(), Adapter.read() (+9 more)

### Community 63 - "Player/server.lua"
Cohesion: 0.14
Nodes (11): acceptCustom(), acceptVehicle(), build(), onPlayer(), Player.Get(), Player.GetAll(), Player.GetByCitizenId(), Player.GetByPhone() (+3 more)

### Community 65 - "Cron/server.lua"
Cohesion: 0.17
Nodes (19): createUniqueId(), dayMatches(), getTime(), matches(), minuteOf(), MSK.Cron.Create(), MSK.Cron.GetNextRun(), MSK.Cron.Schedule() (+11 more)

### Community 66 - "Selector/shared.lua"
Cohesion: 0.20
Nodes (12): copy(), entryValue(), entryWeight(), Pool:Pick(), Pool:PickMany(), Pool:Weighted(), Pool:WeightedMany(), requireSet() (+4 more)

### Community 67 - "Radial/client.lua"
Cohesion: 0.25
Nodes (12): currentItems(), normalize(), Radial.Add(), Radial.Clear(), Radial.Disable(), Radial.Hide(), Radial.Register(), Radial.Remove() (+4 more)

### Community 68 - "qbox/server.lua"
Cohesion: 0.07
Nodes (12): Adapter.getJobs(), accountName(), Adapter.addMoney(), Adapter.getGangs(), Adapter.getJobs(), Adapter.getMoney(), Adapter.read(), Adapter.removeMoney() (+4 more)

### Community 75 - "core_inventory.lua"
Cohesion: 0.42
Nodes (7): Inventory.addItem(), Inventory.canCarryItem(), Inventory.getInventory(), Inventory.getItem(), Inventory.removeItem(), inventoryName(), ready()

### Community 78 - "jaksam_inventory.lua"
Cohesion: 0.38
Nodes (9): Inventory.addItem(), Inventory.canCarryItem(), Inventory.canSwapItem(), Inventory.getInventory(), Inventory.getItem(), Inventory.removeItem(), Inventory.setMaxWeight(), normalise() (+1 more)

### Community 79 - "ox_inventory.lua"
Cohesion: 0.29
Nodes (12): Inventory.addItem(), Inventory.addWeapon(), Inventory.canCarryItem(), Inventory.canSwapItem(), Inventory.clear(), Inventory.getInventory(), Inventory.getItem(), Inventory.getWeapon() (+4 more)

### Community 85 - "Timer/shared.lua"
Cohesion: 0.21
Nodes (8): arm(), elapsedSinceStart(), Timer:GetTimeLeft(), Timer:Pause(), Timer:Restart(), Timer:Resume(), Timer:Start(), Timer:Stop()

### Community 86 - "default.lua"
Cohesion: 0.29
Nodes (12): Inventory.addItem(), Inventory.addWeapon(), Inventory.canCarryItem(), Inventory.canSwapItem(), Inventory.clear(), Inventory.getInventory(), Inventory.getItem(), Inventory.getWeapon() (+4 more)

### Community 87 - "Locale/shared.lua"
Cohesion: 0.27
Nodes (15): ensureLoaded(), flatten(), interpolate(), Locale.GetAll(), Locale.GetFrom(), Locale.GetLanguage(), Locale.Has(), Locale.Load() (+7 more)

### Community 88 - "NotifyStack.tsx"
Cohesion: 0.20
Nodes (14): SettingsHandler(), Note, NotifyStack(), POSITION_CLASS, POSITIONS, current, getSettings(), listeners (+6 more)

### Community 89 - "bridge/server.lua"
Cohesion: 0.26
Nodes (8): announceLoaded(), getPlayerData(), handlers.dutyChanged(), handlers.gangChanged(), handlers.jobChanged(), handlers.loaded(), playerCall(), resolveRaw()

### Community 90 - "Print/shared.lua"
Cohesion: 0.30
Nodes (10): currentLevel(), output(), Print.Debug(), Print.Error(), Print.GetLevel(), Print.Info(), Print.IsEnabled(), Print.Verbose() (+2 more)

### Community 91 - "VehicleStore/server.lua"
Cohesion: 0.21
Nodes (4): decode(), readRow(), VehicleStore.Browse(), VehicleStore.GetByPlate()

### Community 93 - "Marker/client.lua"
Cohesion: 0.35
Nodes (10): draw(), Instance:Draw(), Instance:GetDistance(), Instance:SetColor(), Instance:SetCoords(), Marker.Draw(), Marker.New(), prepare() (+2 more)

### Community 95 - "Class/shared.lua"
Cohesion: 0.40
Nodes (9): Base:Extend(), Base:IsA(), Base:New(), Class.IsClass(), Class.IsInstance(), Class.New(), construct(), define() (+1 more)

### Community 96 - "Grid/shared.lua"
Cohesion: 0.29
Nodes (5): bounds(), cellKey(), Grid:Add(), Grid:GetInRange(), Grid:GetNearby()

### Community 97 - "Settings/client.lua"
Cohesion: 0.33
Nodes (8): copy(), localeLabel(), positionLabel(), pushToNui(), Settings.Get(), Settings.GetAll(), Settings.Open(), Settings.Set()

### Community 99 - "Logger/server.lua"
Cohesion: 0.27
Nodes (14): base64(), encodable(), flush(), getPlayerInfo(), Logger.Log(), lokiEndpoint(), onResponse(), parseTags() (+6 more)

### Community 100 - "RadialMenu.tsx"
Cohesion: 0.18
Nodes (14): ListMenu(), Numpad(), Status, buildPages(), middleAngle(), point(), RadialMenu(), Slice (+6 more)

### Community 101 - "Controls/client.lua"
Cohesion: 0.39
Nodes (5): collect(), Controls.Clear(), Controls.Disable(), Controls.Enable(), start()

### Community 103 - "Anim/client.lua"
Cohesion: 0.52
Nodes (6): Anim.Clear(), Anim.IsPlaying(), Anim.Play(), Anim.Scenario(), Anim.Stop(), resolvePed()

### Community 104 - "Skillcheck/client.lua"
Cohesion: 0.43
Nodes (5): clamp(), settle(), Skillcheck.Cancel(), Skillcheck.Start(), toRound()

### Community 106 - "VehicleProperties/client.lua"
Cohesion: 0.43
Nodes (5): Props.Get(), Props.Set(), readDriftTyres(), readRgb(), rgb()

### Community 107 - "Alert/client.lua"
Cohesion: 0.60
Nodes (3): Alert.Close(), Alert.Show(), settle()

### Community 108 - "Events/server.lua"
Cohesion: 0.83
Nodes (3): Events.GetPlayersInRange(), Events.TriggerClients(), Events.TriggerClientsInRange()

## Ambiguous Edges - Review These
- `MSK Core NUI Input Component` → `Rationale: compact dialog keeps game view unobstructed`  [AMBIGUOUS]
  .assets/input_small.png · relation: conceptually_related_to
- `Centered Modal Panel Layout` → `Large Multiline Textarea Input Variant`  [AMBIGUOUS]
  .assets/input_large.png · relation: semantically_similar_to
- `Skewed Parallelogram Bar Geometry` → `Rationale: Glanceable In-Game HUD Feedback`  [AMBIGUOUS]
  .assets/progressbar.png · relation: conceptually_related_to

## Knowledge Gaps
- **96 isolated node(s):** `name`, `private`, `version`, `type`, `dev` (+91 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `MSK Core NUI Input Component` and `Rationale: compact dialog keeps game view unobstructed`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Centered Modal Panel Layout` and `Large Multiline Textarea Input Variant`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `Skewed Parallelogram Bar Geometry` and `Rationale: Glanceable In-Game HUD Feedback`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `MSK.Bridge.NormaliseGrades()` connect `qbox/server.lua` to `qbcore/server.lua`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **Why does `readDefinitions()` connect `qbcore/server.lua` to `qbox/server.lua`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **Why does `logging()` connect `logging` to `Cron/server.lua`?**
  _High betweenness centrality (0.002) - this node is a cross-community bridge._
- **What connects `name`, `private`, `version` to the rest of the system?**
  _96 weakly-connected nodes found - possible documentation gaps or missing edges._