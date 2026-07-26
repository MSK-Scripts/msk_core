# Graph Report - .  (2026-07-26)

## Corpus Check
- 119 files · ~62,723 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 566 nodes · 720 edges · 80 communities (73 shown, 7 thin omitted)
- Extraction: 86% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 97 edges (avg confidence: 0.84)
- Token cost: 862,311 input · 0 output

## Community Hubs (Navigation)
- React NUI Components
- Repo Governance and CI
- NUI Dependency Manifest
- Core Boot and Ace Permissions
- TypeScript Build Config
- Ban System and Webhooks
- Keyboard List Menu
- Numpad Error State
- Input Dialog Small
- Vehicle Helpers Client
- Input Dialog Large
- MSK Brand Identity
- Numpad Component
- Numpad Masked Input
- Numpad Keypad Layout
- Callback System
- Asset Request Helpers
- Progressbar UI Design
- Context Menu Client
- Notify UI Design
- TextUI Hint Design
- Coordinate Display Client
- Points System
- Scaleform Client
- Progressbar Client
- String Helpers
- Entity Helpers Client
- Society Accounts
- TextUI Client
- Vector Helpers
- Module Loader
- Version and Dependency Check
- Commands Client
- Entity Helpers Server
- Coords Draw Loop

## God Nodes (most connected - your core abstractions)
1. `useNuiEvent()` - 17 edges
2. `compilerOptions` - 17 edges
3. `fetchNui()` - 10 edges
4. `parseColorCodes()` - 9 edges
5. `playSound()` - 9 edges
6. `logging()` - 8 edges
7. `MSK Core README Banner` - 8 edges
8. `MSK Core Readme` - 7 edges
9. `MSK Core NUI Input Component` - 7 edges
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
- `MSK.AddAce()` --calls--> `logging()`  [INFERRED]
  modules/Ace/server.lua → init/shared.lua

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **GitHub community health file set** — _github_code_of_conduct_contributor_covenant, _github_contributing_contribution_guide, _github_security_security_policy, _github_pull_request_template_pr_template, _github_issue_template_bug_report_bug_report_form, _github_issue_template_feature_request_feature_request_form, _github_issue_template_config_issue_config [EXTRACTED 1.00]
- **CI and release automation pipeline** — _github_workflows_codeql_codeql_workflow, _github_workflows_web_build_nui_build_workflow, _github_workflows_release_release_workflow, _github_dependabot_dependabot_config, changelogs_changelog [INFERRED 0.85]
- **Framework and inventory abstraction contract for contributions** — readme_framework_bridge, readme_inventory_bridge, _github_contributing_framework_agnostic_rule, _github_contributing_dual_api_rule, _github_issue_template_bug_report_framework_dropdown [INFERRED 0.85]
- **Toast Anatomy: Typed Header, Color-Coded Body, Timer Bar** — _assets_notify_icon_header, _assets_notify_color_codes, _assets_notify_progress_bar, _assets_notify_types [INFERRED 0.85]
- **Header, Textarea and Submit Button Compose the Input Dialog** — _assets_input_large_header_accent_divider, _assets_input_large_large_textarea_variant, _assets_input_large_submit_button, _assets_input_large_centered_modal_panel [EXTRACTED 1.00]
- **Dark Panel, Green Accent and Uppercase Monospace Type Implement the MSK Design Language** — _assets_input_large_msk_design_language, _assets_input_large_header_accent_divider, _assets_input_large_submit_button, _assets_input_large_centered_modal_panel [INFERRED 0.85]
- **Input dialog composed of header, text field and submit button** — _assets_input_small_header_section, _assets_input_small_text_field, _assets_input_small_submit_button, _assets_input_small_input_component [EXTRACTED 1.00]
- **MSK visual identity applied across input dialog elements** — _assets_input_small_msk_design_tokens, _assets_input_small_monospace_uppercase_labels, _assets_input_small_header_section, _assets_input_small_submit_button [INFERRED 0.85]
- **MSK Core banner brand system (wordmark, palette, typography, visual style)** — _assets_msk_core_banner_wordmark, _assets_msk_core_banner_palette, _assets_msk_core_banner_typography, _assets_msk_core_banner_visual_style [INFERRED 0.85]
- **Banner composition: centered wordmark and tagline flanked by two mock UI cards** — _assets_msk_core_banner_wordmark, _assets_msk_core_banner_tagline, _assets_msk_core_banner_card_script_overview, _assets_msk_core_banner_card_integration_examples [EXTRACTED 1.00]
- **Numpad PIN Entry Flow (display, digits, confirm/backspace)** — _assets_numpad_code_display, _assets_numpad_keypad_grid, _assets_numpad_action_keys, _assets_numpad_component [INFERRED 0.85]
- **MSK Design Language Applied to Numpad** — _assets_numpad_msk_dark_theme, _assets_numpad_color_coded_actions_rationale, _assets_numpad_component, _assets_numpad_keypad_grid [INFERRED 0.75]
- **Numpad Error Feedback System** — _assets_numpad_incorrect_error_state, _assets_numpad_incorrect_display_field, _assets_numpad_incorrect_semantic_color_coding, _assets_numpad_incorrect_inline_feedback_pattern [INFERRED 0.85]
- **Numpad Input Controls** — _assets_numpad_incorrect_keypad_grid, _assets_numpad_incorrect_backspace_key, _assets_numpad_incorrect_confirm_key, _assets_numpad_incorrect_retry_affordance [INFERRED 0.85]
- **Masked PIN Entry Flow (Keys, Masked Display, Confirm/Backspace)** — _assets_numpad_masked_key_grid, _assets_numpad_masked_display_field, _assets_numpad_masked_action_keys, _assets_numpad_masked_masked_input_mode [INFERRED 0.85]
- **Privacy-Oriented Input Design (Masking plus Count Feedback)** — _assets_numpad_masked_masked_input_mode, _assets_numpad_masked_shoulder_surfing_rationale, _assets_numpad_masked_progress_feedback_rationale [INFERRED 0.75]
- **Bottom Action Row: Backspace, Zero, Confirm** — _assets_numpad_numbers_backspace_key, _assets_numpad_numbers_confirm_key, _assets_numpad_numbers_key_grid [EXTRACTED 1.00]
- **PIN Entry Flow: press digits, see display, confirm or delete** — _assets_numpad_numbers_display_field, _assets_numpad_numbers_key_grid, _assets_numpad_numbers_confirm_key, _assets_numpad_numbers_backspace_key [INFERRED 0.85]
- **MSK Progressbar Visual Language** — _assets_progressbar_component, _assets_progressbar_skewed_bar_geometry, _assets_progressbar_accent_green_fill, _assets_progressbar_uppercase_mono_label, _assets_progressbar_dark_panel_theme [INFERRED 0.85]
- **TextUI Visual Composition (panel, keycap, label, tokens)** — _assets_textui_component, _assets_textui_keycap_badge, _assets_textui_prompt_label, _assets_textui_msk_design_tokens [INFERRED 0.85]

## Communities (80 total, 7 thin omitted)

### Community 0 - "React NUI Components"
Cohesion: 0.06
Nodes (58): CoordsHandler(), copyFallback(), clamp(), ContextMenu(), ContextRow(), firstSelectable(), normalizeMeta(), Input() (+50 more)

### Community 1 - "Repo Governance and CI"
Cohesion: 0.05
Nodes (48): Contributor Covenant Code of Conduct, Community Impact Enforcement Ladder, MSK Scripts Discord (community and reporting channel), Committed web/dist build artifact policy, Contributing to MSK Core, Dual API exposure rule (MSK.Function and exports.msk_core:Function), Framework-agnostic code rule (route through bridge/), Lua 5.4 requirement (lua54 'yes') (+40 more)

### Community 2 - "NUI Dependency Manifest"
Cohesion: 0.05
Nodes (36): @fontsource/dm-sans, @fontsource/space-mono, @fontsource/syne, @fortawesome/fontawesome-free, react, react-dom, tailwindcss, @tailwindcss/vite (+28 more)

### Community 3 - "Core Boot and Ace Permissions"
Cohesion: 0.12
Nodes (16): logging(), mountCore(), registerExport(), allowAce(), checkParams(), MSK.AddAce(), MSK.AddPrincipal(), MSK.IsPrincipalAceAllowed() (+8 more)

### Community 4 - "TypeScript Build Config"
Cohesion: 0.08
Nodes (23): DOM, DOM.Iterable, ES2020, src, vite.config.ts, compilerOptions, allowImportingTsExtensions, isolatedModules (+15 more)

### Community 5 - "Ban System and Webhooks"
Cohesion: 0.20
Nodes (10): banLog(), formatTime(), IsIdBanned(), IsTokenBanned(), IsTokenMatching(), MSK.BanPlayer(), MSK.IsPlayerBanned(), MSK.UnbanPlayer() (+2 more)

### Community 6 - "Keyboard List Menu"
Cohesion: 0.32
Nodes (12): firstSelectable(), Menu.Hide(), Menu.Register(), Menu.Show(), Menu.Update(), move(), normalizeItems(), refresh() (+4 more)

### Community 7 - "Numpad Error State"
Cohesion: 0.23
Nodes (12): Red Backspace Key, Green Confirm Key, Display Field Showing INCORRECT, Incorrect-Input Error State, Inline Feedback Instead of Separate Dialog, 3x4 Digit Keypad Grid, Monospace Uppercase Feedback Typography, MSK Dark Design Language (+4 more)

### Community 9 - "Input Dialog Small"
Cohesion: 0.33
Nodes (10): Rationale: compact dialog keeps game view unobstructed, Dialog Header with Accent Divider, MSK Core NUI Input Component, Monospace Uppercase Label Convention, MSK Dark Theme Design Tokens (green accent), Lua to NUI Input Contract (MSK.Input / SendNUIMessage), Input Dialog Screenshot (small variant), Input Size Variant (small) (+2 more)

### Community 11 - "Input Dialog Large"
Cohesion: 0.31
Nodes (9): Centered Modal Panel Layout, Uppercase Monospace Header with Green Accent Divider, MSK Core NUI Input Component, Large Multiline Textarea Input Variant, MSK Dark Design Language (Green Accent), MSK.Input Lua/NUI Message Contract, Placeholder Text Affordance ("Large text input..."), Input Dialog (Large Variant) Screenshot (+1 more)

### Community 12 - "MSK Brand Identity"
Cohesion: 0.39
Nodes (9): MSK Core README Banner, MSK Scripts Brand Identity (dark-tech, green accent, developer-facing), INTEGRATION EXAMPLES Card (MSK.Register msk_core:GetPlayers, CORE READY, DOCUMENTATION), SCRIPT OVERVIEW Card (core_config.lua, locales.lua, loader.lua, player.lua, SHOW GUIDES), Dark Palette with MSK Green Accent (#00E676-like green on near-black), Tagline: core library for our resources, common utilities, Banner Typography: wide geometric sans wordmark, humanist sans body, monospace code, Dark Carbon-Fibre Backdrop with Floating UI Cards (+1 more)

### Community 13 - "Numpad Component"
Cohesion: 0.33
Nodes (9): Backspace and Confirm Action Keys, Code Display Field (ENTER CODE placeholder), Rationale: Color-Coded Destructive vs Confirm Actions, Numpad Component (msk_core NUI), 3x4 Digit Keypad Grid (0-9), Rationale: Mouse-Driven PIN Entry in Game NUI, MSK Dark Theme with Green Accent, MSK.Numpad Module (Lua API) (+1 more)

### Community 14 - "Numpad Masked Input"
Cohesion: 0.33
Nodes (9): Numpad Masked Input Screenshot, Backspace (Red) and Confirm (Green) Action Keys, Display Field Showing Four Filled Dots, 3x4 Digit Key Grid (1-9, 0), Masked Input Mode (Dot Placeholders), MSK Dark Theme with Green Accent, Numpad NUI Component, Rationale: Dots Give Digit-Count Feedback Without Revealing Values (+1 more)

### Community 15 - "Numpad Keypad Layout"
Cohesion: 0.31
Nodes (9): Numpad Numbers Screenshot, Physical ATM/Phone Keypad Metaphor, Red Backspace/Delete Key, Color-Coded Action Affordance (green = confirm, red = destructive), Green Confirm/Checkmark Key, PIN Display Field (monospace, shows entered digits), 3x4 Numeric Key Grid (1-9, 0), MSK Dark Theme Design Language (near-black panel, rounded tiles, green accent) (+1 more)

### Community 16 - "Callback System"
Cohesion: 0.25
Nodes (4): Callback.Trigger(), Callback.TriggerCallback(), Callback.Trigger(), GenerateCallbackHandlerKey()

### Community 17 - "Asset Request Helpers"
Cohesion: 0.36
Nodes (6): Request.AnimDict(), Request.AnimSet(), Request.Model(), Request.PtfxAsset(), Request.Streaming(), Request.TextureDict()

### Community 18 - "Progressbar UI Design"
Cohesion: 0.36
Nodes (8): Progressbar Screenshot (.assets/progressbar.png), MSK Accent Green Gradient Fill (#00E676), MSK Core Progressbar NUI Component, Dark Panel Theme with Subtle Border, Rationale: Glanceable In-Game HUD Feedback, React + Vite + Tailwind NUI Stack (web/), Skewed Parallelogram Bar Geometry, Uppercase Monospace Status Label ("SEARCHING...")

### Community 19 - "Context Menu Client"
Cohesion: 0.39
Nodes (5): Context.Register(), Context.Show(), Context.Update(), normalizeOptions(), serialize()

### Community 22 - "Notify UI Design"
Cohesion: 0.43
Nodes (7): Inline Color-Code Markup in Notification Text, Notify NUI Component, MSK Dark Panel Design Language, Icon Plus Monospace Uppercase Header Row, Auto-Dismiss Duration Progress Bar, Notify NUI Screenshot, Notification Type Variants (error, warning, success, info, general)

### Community 23 - "TextUI Hint Design"
Cohesion: 0.48
Nodes (7): TextUI Screenshot (.assets/textui.png), TextUI NUI Component, Rationale: Glanceable Non-Blocking On-Screen Hint, Keybind Affordance Pattern, Highlighted Keycap Badge Element, MSK Dark Panel + Green Accent Design Tokens, Prompt Label Text (Press E to interact)

### Community 26 - "Scaleform Client"
Cohesion: 0.57
Nodes (6): Scaleform.BreakingNews(), Scaleform.FreemodeMessage(), Scaleform.PopupWarning(), Scaleform.ScaleformAnnounce(), Scaleform.Show(), Scaleform.TrafficMovie()

### Community 27 - "Progressbar Client"
Cohesion: 0.60
Nodes (4): interrupted(), Progress.Start(), Progress.Stop(), setProgressData()

### Community 31 - "Entity Helpers Client"
Cohesion: 0.60
Nodes (3): getEntities(), MSK.GetClosestEntities(), MSK.GetClosestEntity()

### Community 33 - "Society Accounts"
Cohesion: 0.70
Nodes (4): esxShared(), Society.AddMoney(), Society.GetMoney(), Society.RemoveMoney()

### Community 34 - "TextUI Client"
Cohesion: 0.60
Nodes (3): TextUI.Hide(), TextUI.Show(), TextUI.ShowThread()

### Community 35 - "Vector Helpers"
Cohesion: 0.60
Nodes (3): getTableHeading(), Vector.CoordsToString(), Vector.TableToVector()

### Community 38 - "Module Loader"
Cohesion: 0.83
Nodes (3): compile(), mount(), resolve()

### Community 41 - "Entity Helpers Server"
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
- **72 isolated node(s):** `name`, `private`, `version`, `type`, `dev` (+67 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **7 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `Large Multiline Textarea Input Variant` and `Centered Modal Panel Layout`?**
  _Edge tagged AMBIGUOUS (relation: semantically_similar_to) - confidence is low._
- **What is the exact relationship between `MSK Core NUI Input Component` and `Rationale: compact dialog keeps game view unobstructed`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `Skewed Parallelogram Bar Geometry` and `Rationale: Glanceable In-Game HUD Feedback`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `logging()` connect `Core Boot and Ace Permissions` to `Ban System and Webhooks`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `name`, `private`, `version` to the rest of the system?**
  _72 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `React NUI Components` be split into smaller, more focused modules?**
  _Cohesion score 0.05822784810126582 - nodes in this community are weakly interconnected._
- **Should `Repo Governance and CI` be split into smaller, more focused modules?**
  _Cohesion score 0.051418439716312055 - nodes in this community are weakly interconnected._