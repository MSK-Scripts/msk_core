import { useRef, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import type { ProgressStartMessage } from '../types'

interface BarState {
  text: string
  color: string
  time: number
  runId: number
  position: 'middle' | 'bottom'
}

export default function Progressbar() {
  const [bar, setBar] = useState<BarState | null>(null)
  const timeout = useRef<number | null>(null)
  const runId = useRef(0)

  const clearTimer = () => {
    if (timeout.current !== null) {
      window.clearTimeout(timeout.current)
      timeout.current = null
    }
  }

  useNuiEvent<ProgressStartMessage>('progressBarStart', (data) => {
    clearTimer()
    const id = ++runId.current
    const luaId = data.id

    setBar({
      text: data.text || '',
      color: data.color || '#00e676',
      time: data.time || 1000,
      runId: id,
      position: data.position === 'middle' ? 'middle' : 'bottom',
    })

    // Die id aus Lua geht zurück, damit nur dieser Durchlauf beendet wird.
    timeout.current = window.setTimeout(() => {
      setBar(null)
      void fetchNui('progressEnd', { id: luaId })
    }, data.time || 1000)
  })

  // Kein progressEnd beim Stop: Lua hat den Fortschritt dann schon selbst
  // beendet, und eine späte Meldung konnte den nächsten Fortschritt treffen.
  useNuiEvent('progressBarStop', () => {
    clearTimer()
    setBar(null)
  })

  if (!bar) return null

  return (
    <div
      className={`pointer-events-none absolute left-1/2 -translate-x-1/2 ${
        bar.position === 'middle' ? 'top-1/2 -translate-y-1/2' : 'top-[80%]'
      }`}
    >
      <div
        className="relative h-[4vh] w-[54vh] overflow-hidden rounded-sm border border-border bg-panel/90 shadow-msk"
        style={{ transform: 'skew(-20deg)' }}
      >
        {/* Füllung */}
        <div
          key={bar.runId}
          className="absolute inset-y-0 left-0"
          style={{
            background: `linear-gradient(90deg, ${bar.color}cc, ${bar.color})`,
            boxShadow: `0 0 2vh ${bar.color}`,
            animation: `msk-progress-fill ${bar.time / 1000}s linear forwards`,
          }}
        />
        {/* Text */}
        <div
          className="absolute inset-0 flex items-center justify-center font-mono text-[1.6vh] font-bold uppercase tracking-[0.15vh] text-text-primary"
          style={{ transform: 'skew(20deg)', textShadow: '0 0 0.8vh rgba(0,0,0,0.9)' }}
        >
          {bar.text}
        </div>
      </div>
    </div>
  )
}
