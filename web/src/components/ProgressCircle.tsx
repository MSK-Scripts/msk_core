import { useEffect, useRef, useState } from 'react'
import type { CSSProperties } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import type { ProgressCircleStartMessage } from '../types'

const RADIUS = 42
const CIRCUMFERENCE = 2 * Math.PI * RADIUS

interface CircleState {
  text: string
  color: string
  time: number
  runId: number
  position: 'middle' | 'bottom'
}

export default function ProgressCircle() {
  const [circle, setCircle] = useState<CircleState | null>(null)
  const [percent, setPercent] = useState(0)

  const timeout = useRef<number | null>(null)
  const interval = useRef<number | null>(null)
  const runId = useRef(0)

  const clearTimers = () => {
    if (timeout.current !== null) {
      window.clearTimeout(timeout.current)
      timeout.current = null
    }
    if (interval.current !== null) {
      window.clearInterval(interval.current)
      interval.current = null
    }
  }

  useEffect(() => clearTimers, [])

  useNuiEvent<ProgressCircleStartMessage>('progressCircleStart', (data) => {
    clearTimers()

    const id = ++runId.current
    const luaId = data.id
    const time = data.time || 1000
    const started = Date.now()

    setCircle({
      text: data.text || '',
      color: data.color || '#00e676',
      time,
      runId: id,
      position: data.position === 'bottom' ? 'bottom' : 'middle',
    })
    setPercent(0)

    interval.current = window.setInterval(() => {
      setPercent(Math.min(100, Math.floor(((Date.now() - started) / time) * 100)))
    }, 100)

    timeout.current = window.setTimeout(() => {
      clearTimers()
      setCircle(null)
      // Die id aus Lua geht zurück, damit nur dieser Durchlauf beendet wird.
      void fetchNui('progressEnd', { id: luaId })
    }, time)
  })

  // The stop action is shared with the bar, which already reports progressEnd.
  useNuiEvent('progressBarStop', () => {
    if (!circle) return
    clearTimers()
    setCircle(null)
  })

  if (!circle) return null

  const ringStyle = {
    strokeDashoffset: CIRCUMFERENCE,
    animation: `msk-circle-fill ${circle.time / 1000}s linear forwards`,
    filter: `drop-shadow(0 0 0.6vh ${circle.color})`,
    '--msk-circle': `${CIRCUMFERENCE}`,
  } as CSSProperties

  return (
    <div
      className={`pointer-events-none absolute left-1/2 flex -translate-x-1/2 flex-col items-center gap-[1.2vh] ${
        circle.position === 'bottom' ? 'top-[74%]' : 'top-1/2 -translate-y-1/2'
      }`}
    >
      <div className="relative h-[11vh] w-[11vh]">
        <svg viewBox="0 0 100 100" className="h-full w-full -rotate-90">
          <circle cx={50} cy={50} r={RADIUS} fill="rgba(19, 19, 23, 0.9)" stroke="rgba(255, 255, 255, 0.08)" strokeWidth={6} />
          <circle
            key={circle.runId}
            cx={50}
            cy={50}
            r={RADIUS}
            fill="none"
            stroke={circle.color}
            strokeWidth={6}
            strokeLinecap="round"
            strokeDasharray={CIRCUMFERENCE}
            style={ringStyle}
          />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center font-mono text-[1.8vh] font-bold text-text-primary">
          {percent}%
        </div>
      </div>

      {circle.text && (
        <div
          className="font-mono text-[1.4vh] font-bold uppercase tracking-[0.15vh] text-text-primary"
          style={{ textShadow: '0 0 0.8vh rgba(0,0,0,0.9)' }}
        >
          {circle.text}
        </div>
      )}
    </div>
  )
}
