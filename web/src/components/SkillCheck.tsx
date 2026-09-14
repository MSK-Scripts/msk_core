import { useEffect, useRef, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import type { StartSkillcheckMessage } from '../types'

const RADIUS = 40
const CIRCUMFERENCE = 2 * Math.PI * RADIUS

// Base speed of the marker in degrees per millisecond (300° per second).
const BASE_SPEED = 0.3

interface Check extends StartSkillcheckMessage {
  id: number
  zoneStart: number
}

let counter = 0

export default function SkillCheck() {
  const [check, setCheck] = useState<Check | null>(null)
  const [angle, setAngle] = useState(0)

  const angleRef = useRef(0)
  const doneRef = useRef(false)

  useNuiEvent<StartSkillcheckMessage>('startSkillcheck', (data) => {
    // The zone never starts in the first quarter, so there is always a moment
    // to see the key before the marker reaches it.
    const zoneStart = 90 + Math.random() * (270 - data.areaSize)
    angleRef.current = 0
    doneRef.current = false
    setAngle(0)
    setCheck({ ...data, id: ++counter, zoneStart })
  })

  useNuiEvent('cancelSkillcheck', () => {
    doneRef.current = true
    setCheck(null)
  })

  useEffect(() => {
    if (!check) return

    let frame = 0
    const started = performance.now()
    const zoneEnd = check.zoneStart + check.areaSize

    const finish = (success: boolean) => {
      if (doneRef.current) return
      doneRef.current = true
      cancelAnimationFrame(frame)
      setCheck(null)
      void fetchNui('skillcheckResult', { success })
    }

    const tick = (now: number) => {
      const current = (now - started) * BASE_SPEED * check.speed
      angleRef.current = current
      setAngle(current)

      if (current > zoneEnd) {
        finish(false)
        return
      }

      frame = requestAnimationFrame(tick)
    }

    const onKey = (e: KeyboardEvent) => {
      if (e.repeat) return
      const current = angleRef.current
      const inside = current >= check.zoneStart && current <= zoneEnd
      finish(inside && e.key.toLowerCase() === check.key)
    }

    frame = requestAnimationFrame(tick)
    window.addEventListener('keydown', onKey)

    return () => {
      cancelAnimationFrame(frame)
      window.removeEventListener('keydown', onKey)
    }
  }, [check])

  if (!check) return null

  const zoneLength = (CIRCUMFERENCE * check.areaSize) / 360

  return (
    <div className="pointer-events-none absolute left-1/2 top-[72%] flex -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-[1vh]">
      <div className="relative h-[13vh] w-[13vh]" style={{ animation: 'msk-zoom-in 0.2s cubic-bezier(0.22,1,0.36,1)' }}>
        <svg viewBox="0 0 100 100" className="h-full w-full">
          <circle cx={50} cy={50} r={RADIUS} fill="rgba(19, 19, 23, 0.9)" stroke="rgba(255, 255, 255, 0.1)" strokeWidth={5} />
          <circle
            cx={50}
            cy={50}
            r={RADIUS}
            fill="none"
            stroke="var(--color-accent)"
            strokeWidth={5}
            strokeDasharray={`${zoneLength} ${CIRCUMFERENCE}`}
            transform={`rotate(${check.zoneStart - 90} 50 50)`}
            style={{ filter: 'drop-shadow(0 0 0.5vh rgba(0, 230, 118, 0.8))' }}
          />
          <g transform={`rotate(${angle} 50 50)`}>
            <line x1={50} y1={3} x2={50} y2={17} stroke="#f0ede8" strokeWidth={2.4} strokeLinecap="round" />
          </g>
        </svg>

        <div className="absolute inset-0 flex items-center justify-center">
          <span className="flex h-[4.4vh] w-[4.4vh] items-center justify-center rounded-sm border border-accent/40 bg-accent/10 font-mono text-[2vh] font-bold uppercase text-accent">
            {check.key}
          </span>
        </div>
      </div>

      {check.rounds > 1 && (
        <span className="font-mono text-[1.2vh] uppercase tracking-[0.15vh] text-text-secondary">
          {check.round}/{check.rounds}
        </span>
      )}
    </div>
  )
}
