# Contributing to MSK Core

Thanks for taking the time to contribute. MSK Core is the shared library behind
every MSK Scripts resource, so changes here can affect a lot of downstream
scripts. This guide explains how to report issues, suggest features, and open
pull requests.

## Ways to contribute

* **Report a bug** using the bug report issue template.
* **Request a feature** using the feature request issue template.
* **Improve the docs** at [docu.msk-scripts.de](https://docu.msk-scripts.de/docs/msk_core/).
* **Open a pull request** with a fix or a new module.

If you just have a question or want to discuss an idea first, join the
[MSK Scripts Discord](https://discord.gg/5hHSBRHvJE).

## Before you start

* **Lua 5.4** is required. Every resource that imports the core sets
  `lua54 'yes'`.
* MSK Core supports **ESX, QBCore, ox_core and STANDALONE** through a bridge
  layer. Keep new code framework-agnostic and route framework-specific logic
  through the existing bridge in `bridge/`.
* Server-side validation is mandatory for anything triggered from the client.
  Never trust client input.

## Project layout

```
msk_core/
├── bridge/        framework and inventory detection (AUTO)
├── init/          boot loader, registers exports
├── inventories/   inventory bridges
├── modules/       one folder per module (shared/client/server as needed)
├── import.lua     builds the global MSK table (lazy loading)
└── web/           React + Vite + TypeScript NUI (build committed to web/dist)
```

New helper functions belong in an existing module under `modules/`, or in a new
module folder if the topic does not fit. Expose every function both as
`MSK.Function(...)` and as `exports.msk_core:Function(...)`.

## Working on the NUI

The NUI lives in `web/` (React + Vite + TypeScript + Tailwind v4). The built
`web/dist` is committed so the server never needs npm.

```bash
cd web
npm install
npm run dev     # browser dev with the DevPanel
npm run build   # rebuild web/dist, commit it after UI changes
```

After any UI change, run `npm run build` and commit the updated `web/dist`.

## Pull request checklist

1. Fork the repo and create a branch from `main`.
2. Keep your change focused. One feature or fix per pull request.
3. Match the existing code style (naming, indentation, comment density).
4. Test on at least one framework, ideally ESX or QBCore, plus STANDALONE where
   it applies.
5. If you changed the NUI, rebuild and commit `web/dist`.
6. Update `CHANGELOGS.md` and the documentation if behavior, exports, or config
   changed.
7. Fill out the pull request template.

## Reporting security issues

Please do not open public issues for security vulnerabilities. See
[SECURITY.md](SECURITY.md) for how to report them privately.

## License

By contributing, you agree that your contributions will be licensed under the
project's **LGPL-3.0-or-later** license. See [LICENSE](../LICENSE).
