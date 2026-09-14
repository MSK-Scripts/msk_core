import { useEffect } from 'react'
import { useNuiEvent } from './hooks/useNuiEvent'
import { fetchNui } from './lib/fetchNui'
import { setSettings } from './lib/settings'
import type { CopyCoordsMessage, SetClipboardMessage, SettingsMessage } from './types'
import NotifyStack from './components/NotifyStack'
import Input from './components/Input'
import InputDialog from './components/InputDialog'
import Progressbar from './components/Progressbar'
import ProgressCircle from './components/ProgressCircle'
import Numpad from './components/Numpad'
import TextUI from './components/TextUI'
import ContextMenu from './components/ContextMenu'
import ListMenu from './components/ListMenu'
import AlertDialog from './components/AlertDialog'
import RadialMenu from './components/RadialMenu'
import SkillCheck from './components/SkillCheck'
import ErrorBoundary from './components/ErrorBoundary'
import DevPanel from './dev/DevPanel'

function ClipboardHandler() {
  useNuiEvent<CopyCoordsMessage>('copyCoords', (data) => copyToClipboard(data.value))
  useNuiEvent<SetClipboardMessage>('setClipboard', (data) => copyToClipboard(data.value))
  return null
}

function copyToClipboard(value: string) {
  if (navigator.clipboard?.writeText) {
    void navigator.clipboard.writeText(value).catch(() => copyFallback(value))
  } else {
    copyFallback(value)
  }
}

function copyFallback(value: string) {
  const el = document.createElement('textarea')
  el.value = value
  el.style.position = 'fixed'
  el.style.opacity = '0'
  document.body.appendChild(el)
  el.select()
  try {
    document.execCommand('copy')
  } catch {
    /* no-op */
  }
  document.body.removeChild(el)
}

// Receives the player's settings. Lua only sends them once the NUI reported
// that it is ready, a SendNUIMessage before the page loaded would be lost.
function SettingsHandler() {
  useNuiEvent<SettingsMessage>('settings', (data) => {
    setSettings({ notifyPosition: data.notifyPosition, notifySound: data.notifySound })
  })

  useEffect(() => {
    void fetchNui('nuiReady')
  }, [])

  return null
}

// Each component gets its OWN boundary, never one around all of them: a crash
// must only take out the component it happened in. See ErrorBoundary.tsx.
export default function App() {
  return (
    <>
      <ErrorBoundary name="SettingsHandler">
        <SettingsHandler />
      </ErrorBoundary>
      <ErrorBoundary name="NotifyStack">
        <NotifyStack />
      </ErrorBoundary>
      <ErrorBoundary name="Input">
        <Input />
      </ErrorBoundary>
      <ErrorBoundary name="InputDialog">
        <InputDialog />
      </ErrorBoundary>
      <ErrorBoundary name="Progressbar">
        <Progressbar />
      </ErrorBoundary>
      <ErrorBoundary name="ProgressCircle">
        <ProgressCircle />
      </ErrorBoundary>
      <ErrorBoundary name="Numpad">
        <Numpad />
      </ErrorBoundary>
      <ErrorBoundary name="TextUI">
        <TextUI />
      </ErrorBoundary>
      <ErrorBoundary name="ContextMenu">
        <ContextMenu />
      </ErrorBoundary>
      <ErrorBoundary name="ListMenu">
        <ListMenu />
      </ErrorBoundary>
      <ErrorBoundary name="AlertDialog">
        <AlertDialog />
      </ErrorBoundary>
      <ErrorBoundary name="RadialMenu">
        <RadialMenu />
      </ErrorBoundary>
      <ErrorBoundary name="SkillCheck">
        <SkillCheck />
      </ErrorBoundary>
      <ErrorBoundary name="ClipboardHandler">
        <ClipboardHandler />
      </ErrorBoundary>
      {import.meta.env.DEV && <DevPanel />}
    </>
  )
}
