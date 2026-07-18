# Pull Request

## Description

<!-- What does this PR change and why? -->

## Type of change

- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that changes existing behavior)
- [ ] Documentation update
- [ ] NUI change

## Related issues

<!-- Link any related issues, e.g. Closes #123 -->

## Testing

<!-- How did you test this? -->

- Framework(s) tested:
  - [ ] ESX
  - [ ] QBCore
  - [ ] ox_core
  - [ ] STANDALONE

## Checklist

- [ ] My code follows the style of the existing codebase
- [ ] The change is framework-agnostic, or framework-specific logic goes through the bridge
- [ ] Server-side validation is in place for anything triggered from the client
- [ ] Functions are exposed both as `MSK.Function(...)` and `exports.msk_core:Function(...)` where applicable
- [ ] I rebuilt and committed `web/dist` if the NUI changed
- [ ] I updated `CHANGELOGS.md` and the documentation if behavior, exports, or config changed
