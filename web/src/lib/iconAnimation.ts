// Font-Awesome-Animationsklassen (in FA Free enthalten). Gemeinsam genutzt von
// NotifyStack und TextUI; die Namen spiegeln die erlaubten Werte in Lua.
export const ICON_ANIMATION_CLASS: Record<string, string> = {
  spin: 'fa-spin',
  spinPulse: 'fa-spin-pulse',
  spinReverse: 'fa-spin fa-spin-reverse',
  beat: 'fa-beat',
  beatFade: 'fa-beat-fade',
  bounce: 'fa-bounce',
  fade: 'fa-fade',
  flip: 'fa-flip',
  shake: 'fa-shake',
}

export function iconAnimationClass(animation?: string): string {
  return animation ? ICON_ANIMATION_CLASS[animation] ?? '' : ''
}
