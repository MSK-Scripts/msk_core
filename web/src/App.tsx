import { useNuiEvent } from './hooks/useNuiEvent'
import type { CopyCoordsMessage } from './types'
import NotifyStack from './components/NotifyStack'
import Input from './components/Input'
import Progressbar from './components/Progressbar'
import Numpad from './components/Numpad'
import TextUI from './components/TextUI'
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

export default function App() {
  return (
    <>
      <NotifyStack />
      <Input />
      <Progressbar />
      <Numpad />
      <TextUI />
      <CoordsHandler />
      {import.meta.env.DEV && <DevPanel />}
    </>
  )
}
