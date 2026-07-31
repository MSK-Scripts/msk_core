import { useNuiEvent } from './hooks/useNuiEvent'
import type { CopyCoordsMessage } from './types'
import NotifyStack from './components/NotifyStack'
import Input from './components/Input'
import Progressbar from './components/Progressbar'
import Numpad from './components/Numpad'
import TextUI from './components/TextUI'
import ContextMenu from './components/ContextMenu'
import ListMenu from './components/ListMenu'
import ErrorBoundary from './components/ErrorBoundary'
import DevPanel from './dev/DevPanel'

function CoordsHandler() {
  useNuiEvent<CopyCoordsMessage>('copyCoords', (data) => {
    const value = data.value
    if (navigator.clipboard?.writeText) {
      void navigator.clipboard.writeText(value).catch(() => copyFallback(value))
    } else {
      copyFallback(value)
    }
  })
  return null
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

// Each component gets its OWN boundary, never one around all of them: a crash
// must only take out the component it happened in. See ErrorBoundary.tsx.
export default function App() {
  return (
    <>
      <ErrorBoundary name="NotifyStack">
        <NotifyStack />
      </ErrorBoundary>
      <ErrorBoundary name="Input">
        <Input />
      </ErrorBoundary>
      <ErrorBoundary name="Progressbar">
        <Progressbar />
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
      <ErrorBoundary name="CoordsHandler">
        <CoordsHandler />
      </ErrorBoundary>
      {import.meta.env.DEV && <DevPanel />}
    </>
  )
}
