import { useSyncExternalStore } from 'react'
import type { NotifyPosition } from '../types'

/**
 * Player settings the NUI needs (sent from modules/Settings/client.lua).
 * A tiny external store: components read it with useSettings(), event
 * handlers that must not re-subscribe read it with getSettings().
 */
export interface NuiSettings {
  // '' = Automatisch: die Position aus dem Script, sonst oben links
  notifyPosition: NotifyPosition | ''
  notifySound: boolean
}

let current: NuiSettings = {
  notifyPosition: '',
  notifySound: true,
}

const listeners = new Set<() => void>()

export function setSettings(next: Partial<NuiSettings>) {
  current = { ...current, ...next }
  listeners.forEach((listener) => listener())
}

export function getSettings(): NuiSettings {
  return current
}

function subscribe(listener: () => void) {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}

export function useSettings(): NuiSettings {
  return useSyncExternalStore(subscribe, getSettings)
}
