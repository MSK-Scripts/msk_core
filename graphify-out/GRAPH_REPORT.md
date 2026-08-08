# Graph Report - msk_core  (2026-08-08)

## Corpus Check
- 100 files · ~99,749 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 606 nodes · 790 edges · 84 communities (76 shown, 8 thin omitted)
- Extraction: 85% EXTRACTED · 15% INFERRED · 0% AMBIGUOUS · INFERRED: 117 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `30415f42`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- types.ts
- MSK Core Shared Library
- devDependencies
- Ace/server.lua
- compilerOptions
- Vehicle/client.lua
- msk_core README Banner
- ErrorBoundary
- Menu/client.lua
- Incorrect-Input Error State
- Ban/server.lua
- MSK Core NUI Input Component
- MSK Core NUI Input Component
- Numpad Component (msk_core NUI)
- Masked Input Mode (Dot Placeholders)
- 3x4 Numeric Key Grid (1-9, 0)
- GenerateCallbackHandlerKey
- Request/client.lua
- MSK Core Progressbar NUI Component
- CodeQL analysis workflow
- Context/client.lua
- Notify NUI Component
- TextUI NUI Component
- Coords/client.lua
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
- DisconnectLogger/client.lua
- GNU General Public License v3.0 text

## God Nodes (most connected - your core abstractions)
1. `useNuiEvent()` - 17 edges
2. `compilerOptions` - 17 edges
3. `fetchNui()` - 12 edges
4. `logging()` - 10 edges
5. `msk_core README Banner` - 10 edges
6. `ErrorBoundary` - 9 edges
7. `parseColorCodes()` - 9 edges
8. `playSound()` - 9 edges
9. `MSK Core Shared Library` - 8 edges
10. `MSK Core NUI Input Component` - 7 edges

## Surprising Connections (you probably didn't know these)
- `MSK.AddPrincipal()` --calls--> `logging()`  [INFERRED]
  modules/Ace/server.lua → init/shared.lua
- `MSK.RemovePrincipal()` --calls--> `logging()`  [INFERRED]
  modules/Ace/server.lua → init/shared.lua
- `MSK.BanPlayer()` --calls--> `logging()`  [INFERRED]
  modules/Ban/server.lua → init/shared.lua
- `MSK.UnbanPlayer()` --calls--> `logging()`  [INFERRED]
  modules/Ban/server.lua → init/shared.lua
- `Framework-agnostic code rule (route through bridge/)` --conceptually_related_to--> `Framework Bridge (ESX / QBCore / ox_core / STANDALONE)`  [INFERRED]
  .github/CONTRIBUTING.md → Readme.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Menu subsystem: both menus, their live update path and the namespaced API** — changelogs_context_menu, changelogs_menu, changelogs_live_menu_updates, changelogs_namespaced_menu_api, changelogs_menu_internal_navigation_leak [EXTRACTED 1.00]
- **NUI resilience: nil-safe parsing, per-component boundaries and the crash loop rule** — changelogs_colorcode_parser_nil_fix, changelogs_error_boundary, changelogs_crash_loop_threshold, readme_nui [EXTRACTED 1.00]
- **Plate lookup flow: server-side search, DB model resolution and plate normalization** — changelogs_getvehiclefromplate, changelogs_getmodelfromplate, changelogs_plate_normalization, readme_framework_bridge [EXTRACTED 1.00]
- **MSK Scripts visual identity expressed by the banner** — _assets_msk_core_banner_m_monogram, _assets_msk_core_banner_wordmark, _assets_msk_core_banner_dark_green_palette, _assets_msk_core_banner_typography_system, _assets_msk_core_banner_split_layout [INFERRED 0.85]
- **Banner text stack communicating what msk_core is** — _assets_msk_core_banner_eyebrow_core_framework, _assets_msk_core_banner_wordmark, _assets_msk_core_banner_tagline, _assets_msk_core_banner_tech_chips [EXTRACTED 1.00]
- **Previous MSK Core banner visual identity system** — _assets_msk_core_banner_old, _assets_msk_core_banner_old_wordmark, _assets_msk_core_banner_old_dark_green_palette, _assets_msk_core_banner_old_ui_card_mockups, _assets_msk_core_banner_old_tagline [INFERRED 0.85]
- **CI and release automation pipeline** — _github_workflows_codeql_codeql_workflow, _github_workflows_web_build_nui_build_workflow, _github_workflows_release_release_workflow, _github_dependabot_dependabot_config [INFERRED 0.85]
- **Framework and inventory abstraction contract for contributions** — readme_framework_bridge, readme_inventory_bridge, _github_contributing_framework_agnostic_rule, _github_contributing_dual_api_rule, _github_issue_template_bug_report_framework_dropdown [INFERRED 0.85]
- **Toast Anatomy: Typed Header, Color-Coded Body, Timer Bar** — _assets_notify_icon_header, _assets_notify_color_codes, _assets_notify_progress_bar, _assets_notify_types [INFERRED 0.85]
- **Header, Textarea and Submit Button Compose the Input Dialog** — _assets_input_large_header_accent_divider, _assets_input_large_large_textarea_variant, _assets_input_large_submit_button, _assets_input_large_centered_modal_panel [EXTRACTED 1.00]
- **Dark Panel, Green Accent and Uppercase Monospace Type Implement the MSK Design Language** — _assets_input_large_msk_design_language, _assets_input_large_header_accent_divider, _assets_input_large_submit_button, _assets_input_large_centered_modal_panel [INFERRED 0.85]
- **Input dialog composed of header, text field and submit button** — _assets_input_small_header_section, _assets_input_small_text_field, _assets_input_small_submit_button, _assets_input_small_input_component [EXTRACTED 1.00]
- **MSK visual identity applied across input dialog elements** — _assets_input_small_msk_design_tokens, _assets_input_small_monospace_uppercase_labels, _assets_input_small_header_section, _assets_input_small_submit_button [INFERRED 0.85]
- **Numpad PIN Entry Flow (display, digits, confirm/backspace)** — _assets_numpad_code_display, _assets_numpad_keypad_grid, _assets_numpad_action_keys, _assets_numpad_component [INFERRED 0.85]
- **MSK Design Language Applied to Numpad** — _assets_numpad_msk_dark_theme, _assets_numpad_color_coded_actions_rationale, _assets_numpad_component, _assets_numpad_keypad_grid [INFERRED 0.75]
- **Numpad Error Feedback System** — _assets_numpad_incorrect_error_state, _assets_numpad_incorrect_display_field, _assets_numpad_incorrect_semantic_color_coding, _assets_numpad_incorrect_inline_feedback_pattern [INFERRED 0.85]
- **Numpad Input Controls** — _assets_numpad_incorrect_keypad_grid, _assets_numpad_incorrect_backspace_key, _assets_numpad_incorrect_confirm_key, _assets_numpad_incorrect_retry_affordance [INFERRED 0.85]
- **Masked PIN Entry Flow (Keys, Masked Display, Confirm/Backspace)** — _assets_numpad_masked_key_grid, _assets_numpad_masked_display_field, _assets_numpad_masked_action_keys, _assets_numpad_masked_masked_input_mode [INFERRED 0.85]
- **Privacy-Oriented Input Design (Masking plus Count Feedback)** — _assets_numpad_masked_masked_input_mode, _assets_numpad_masked_shoulder_surfing_rationale, _assets_numpad_masked_progress_feedback_rationale [INFERRED 0.75]
- **Bottom Action Row: Backspace, Zero, Confirm** — _assets_numpad_numbers_backspace_key, _assets_numpad_numbers_confirm_key, _assets_numpad_numbers_key_grid [EXTRACTED 1.00]
- **MSK Progressbar Visual Language** — _assets_progressbar_component, _assets_progressbar_skewed_bar_geometry, _assets_progressbar_accent_green_fill, _assets_progressbar_uppercase_mono_label, _assets_progressbar_dark_panel_theme [INFERRED 0.85]
- **TextUI Visual Composition (panel, keycap, label, tokens)** — _assets_textui_component, _assets_textui_keycap_badge, _assets_textui_prompt_label, _assets_textui_msk_design_tokens [INFERRED 0.85]

## Communities (84 total, 8 thin omitted)

### Community 0 - "types.ts"
Cohesion: 0.06
Nodes (61): App(), CoordsHandler(), copyFallback(), clamp(), ContextMenu(), ContextRow(), firstSelectable(), normalizeMeta() (+53 more)

### Community 1 - "MSK Core Shared Library"
Cohesion: 0.07
Nodes (40): Contributing to MSK Core, Framework-agnostic code rule (route through bridge/), Lua 5.4 requirement (lua54 'yes'), Bug Report issue form, Supported frameworks (ESX, QBCore, ox_core, STANDALONE), Supported inventory bridges (ox_inventory, core_inventory, jaksam_inventory, default, custom), Feature Request issue form, Private vulnerability disclosure process (+32 more)

### Community 2 - "devDependencies"
Cohesion: 0.05
Nodes (36): @fontsource/dm-sans, @fontsource/space-mono, @fontsource/syne, @fortawesome/fontawesome-free, react, react-dom, tailwindcss, @tailwindcss/vite (+28 more)

### Community 3 - "Ace/server.lua"
Cohesion: 0.12
Nodes (19): logging(), mountCore(), registerExport(), allowAce(), checkParams(), MSK.AddAce(), MSK.AddPrincipal(), MSK.AddRawAce() (+11 more)

### Community 4 - "compilerOptions"
Cohesion: 0.08
Nodes (23): DOM, DOM.Iterable, ES2020, src, vite.config.ts, compilerOptions, allowImportingTsExtensions, isolatedModules (+15 more)

### Community 5 - "Vehicle/client.lua"
Cohesion: 0.11
Nodes (7): MSK.GetModelFromPlate(), MSK.GetVehicleFromPlate(), MSK.GetVehicleLabel(), MSK.GetVehicleLabelFromModel(), MSK.GetModelFromPlate(), MSK.GetVehicleFromPlate(), normalizePlate()

### Community 6 - "msk_core README Banner"
Cohesion: 0.17
Nodes (19): msk_core README Banner, MSK Scripts Brand Identity, Dark Green MSK Colour Palette, Eyebrow Label CORE FRAMEWORK, Framework Support Claim (ESX and QBCore), Gradient M Monogram Logo, MSK Core README Banner (previous version), Earlier Iteration of MSK Scripts Brand Identity (+11 more)

### Community 8 - "Menu/client.lua"
Cohesion: 0.32
Nodes (12): firstSelectable(), Menu.Hide(), Menu.Register(), Menu.Show(), Menu.Update(), move(), normalizeItems(), refresh() (+4 more)

### Community 9 - "Incorrect-Input Error State"
Cohesion: 0.23
Nodes (12): Red Backspace Key, Green Confirm Key, Display Field Showing INCORRECT, Incorrect-Input Error State, Inline Feedback Instead of Separate Dialog, 3x4 Digit Keypad Grid, Monospace Uppercase Feedback Typography, MSK Dark Design Language (+4 more)

### Community 11 - "Ban/server.lua"
Cohesion: 0.20
Nodes (10): banLog(), formatTime(), IsIdBanned(), IsTokenBanned(), IsTokenMatching(), MSK.BanPlayer(), MSK.IsPlayerBanned(), MSK.UnbanPlayer() (+2 more)

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

### Community 17 - "GenerateCallbackHandlerKey"
Cohesion: 0.25
Nodes (4): Callback.Trigger(), Callback.TriggerCallback(), Callback.Trigger(), GenerateCallbackHandlerKey()

### Community 18 - "Request/client.lua"
Cohesion: 0.36
Nodes (6): Request.AnimDict(), Request.AnimSet(), Request.Model(), Request.PtfxAsset(), Request.Streaming(), Request.TextureDict()

### Community 19 - "MSK Core Progressbar NUI Component"
Cohesion: 0.36
Nodes (8): Progressbar Screenshot (.assets/progressbar.png), MSK Accent Green Gradient Fill (#00E676), MSK Core Progressbar NUI Component, Dark Panel Theme with Subtle Border, Rationale: Glanceable In-Game HUD Feedback, React + Vite + Tailwind NUI Stack (web/), Skewed Parallelogram Bar Geometry, Uppercase Monospace Status Label ("SEARCHING...")

### Community 20 - "CodeQL analysis workflow"
Cohesion: 0.32
Nodes (8): Committed web/dist build artifact policy, Dependabot configuration, Weekly github-actions updates (ci commit prefix), Weekly npm updates for /web (react and build-tooling groups), CodeQL analysis workflow, Only the NUI is analyzable (Lua unsupported by CodeQL), NUI Build workflow (type-check and vite build), NUI HTML entry document (root div, /src/main.tsx module script)

### Community 21 - "Context/client.lua"
Cohesion: 0.39
Nodes (5): Context.Register(), Context.Show(), Context.Update(), normalizeOptions(), serialize()

### Community 24 - "Notify NUI Component"
Cohesion: 0.43
Nodes (7): Inline Color-Code Markup in Notification Text, Notify NUI Component, MSK Dark Panel Design Language, Icon Plus Monospace Uppercase Header Row, Auto-Dismiss Duration Progress Bar, Notify NUI Screenshot, Notification Type Variants (error, warning, success, info, general)

### Community 25 - "TextUI NUI Component"
Cohesion: 0.48
Nodes (7): TextUI Screenshot (.assets/textui.png), TextUI NUI Component, Rationale: Glanceable Non-Blocking On-Screen Hint, Keybind Affordance Pattern, Highlighted Keycap Badge Element, MSK Dark Panel + Green Accent Design Tokens, Prompt Label Text (Press E to interact)

### Community 29 - "Scaleform/client.lua"
Cohesion: 0.57
Nodes (6): Scaleform.BreakingNews(), Scaleform.FreemodeMessage(), Scaleform.PopupWarning(), Scaleform.ScaleformAnnounce(), Scaleform.Show(), Scaleform.TrafficMovie()

### Community 30 - "Progress/client.lua"
Cohesion: 0.60
Nodes (4): interrupted(), Progress.Start(), Progress.Stop(), setProgressData()

### Community 33 - "Contributor Covenant Code of Conduct"
Cohesion: 0.40
Nodes (5): Contributor Covenant Code of Conduct, Community Impact Enforcement Ladder, MSK Scripts Discord (community and reporting channel), Issue template config (blank issues disabled, Discord and Docs links), Support routing to Discord instead of issues

### Community 35 - "Entities/client.lua"
Cohesion: 0.60
Nodes (3): getEntities(), MSK.GetClosestEntities(), MSK.GetClosestEntity()

### Community 37 - "Society/server.lua"
Cohesion: 0.70
Nodes (4): esxShared(), Society.AddMoney(), Society.GetMoney(), Society.RemoveMoney()

### Community 38 - "TextUI/client.lua"
Cohesion: 0.60
Nodes (3): TextUI.Hide(), TextUI.Show(), TextUI.ShowThread()

### Community 39 - "Vector/shared.lua"
Cohesion: 0.60
Nodes (3): getTableHeading(), Vector.CoordsToString(), Vector.TableToVector()

### Community 41 - "Pull Request template"
Cohesion: 0.50
Nodes (4): Dual API exposure rule (MSK.Function and exports.msk_core:Function), Pull request checklist, Mandatory server-side validation of client input, Pull Request template

### Community 42 - "import.lua"
Cohesion: 0.83
Nodes (3): compile(), mount(), resolve()

### Community 45 - "Entities/server.lua"
Cohesion: 0.83
Nodes (3): getEntities(), MSK.GetClosestEntities(), MSK.GetClosestEntity()

## Ambiguous Edges - Review These
- `Large Multiline Textarea Input Variant` → `Centered Modal Panel Layout`  [AMBIGUOUS]
  .assets/input_large.png · relation: semantically_similar_to
- `MSK Core NUI Input Component` → `Rationale: compact dialog keeps game view unobstructed`  [AMBIGUOUS]
  .assets/input_small.png · relation: conceptually_related_to
- `Skewed Parallelogram Bar Geometry` → `Rationale: Glanceable In-Game HUD Feedback`  [AMBIGUOUS]
  .assets/progressbar.png · relation: conceptually_related_to

## Knowledge Gaps
- **80 isolated node(s):** `name`, `private`, `version`, `type`, `dev` (+75 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **8 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Large Multiline Textarea Input Variant` and `Centered Modal Panel Layout`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `MSK Core NUI Input Component` and `Rationale: compact dialog keeps game view unobstructed`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Skewed Parallelogram Bar Geometry` and `Rationale: Glanceable In-Game HUD Feedback`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `logging()` connect `Ace/server.lua` to `Ban/server.lua`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **Why does `ErrorBoundary` connect `ErrorBoundary` to `types.ts`?**
  _High betweenness centrality (0.003) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `logging()` (e.g. with `MSK.AddAce()` and `MSK.AddPrincipal()`) actually correct?**
  _`logging()` has 9 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `msk_core README Banner` (e.g. with `MSK Core README Banner (previous version)` and `Earlier Iteration of MSK Scripts Brand Identity`) actually correct?**
  _`msk_core README Banner` has 2 INFERRED edges - model-reasoned connections that need verification._