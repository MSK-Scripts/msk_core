import { useEffect, useRef, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { parseColorCodes } from '../lib/colorCodes'
import { playSound } from '../lib/sound'
import { getSettings, useSettings } from '../lib/settings'
import { iconAnimationClass } from '../lib/iconAnimation'
import { faClass } from './menu/frame'
import type { NotifyMessage, NotifyPosition } from '../types'

interface Note {
  uid: number
  id?: string
  title?: string
  message: string
  color: string
  icon: string
  iconColor?: string
  iconAnimation?: string
  time: number
  showDuration: boolean
  position?: NotifyPosition
  leaving: boolean
  // Wird bei einer Aktualisierung über dieselbe id hochgezählt, damit der
  // Fortschrittsbalken seine Animation neu startet.
  runId: number
}

// Unten wächst der Stapel nach oben (flex-col-reverse), damit die neueste
// Notification am Bildschirmrand steht.
const POSITION_CLASS: Record<NotifyPosition, string> = {
  'top-left': 'left-[2vh] top-[5vh] flex-col',
  top: 'left-1/2 top-[5vh] -translate-x-1/2 flex-col',
  'top-right': 'right-[2vh] top-[5vh] flex-col',
  'center-left': 'left-[2vh] top-1/2 -translate-y-1/2 flex-col',
  'center-right': 'right-[2vh] top-1/2 -translate-y-1/2 flex-col',
  'bottom-left': 'left-[2vh] bottom-[5vh] flex-col-reverse',
  bottom: 'left-1/2 bottom-[5vh] -translate-x-1/2 flex-col-reverse',
  'bottom-right': 'right-[2vh] bottom-[5vh] flex-col-reverse',
}

const POSITIONS = Object.keys(POSITION_CLASS) as NotifyPosition[]

let counter = 0

export default function NotifyStack() {
  const [notes, setNotes] = useState<Note[]>([])
  const timers = useRef(new Map<number, number>())
  const { notifyPosition } = useSettings()

  useEffect(() => {
    const active = timers.current
    return () => active.forEach((timer) => window.clearTimeout(timer))
  }, [])

  const schedule = (uid: number, time: number) => {
    const previous = timers.current.get(uid)
    if (previous !== undefined) window.clearTimeout(previous)

    const leave = window.setTimeout(() => {
      setNotes((prev) => prev.map((n) => (n.uid === uid ? { ...n, leaving: true } : n)))

      const remove = window.setTimeout(() => {
        timers.current.delete(uid)
        setNotes((prev) => prev.filter((n) => n.uid !== uid))
      }, 320)

      timers.current.set(uid, remove)
    }, time)

    timers.current.set(uid, leave)
  }

  useNuiEvent<NotifyMessage>('notify', (data) => {
    const fields = {
      id: data.id,
      title: data.title || undefined,
      message: data.message ?? '',
      color: data.type?.color || '#00e676',
      icon: faClass(data.icon) || data.type?.icon || 'fas fa-circle-info',
      iconColor: data.iconColor,
      iconAnimation: data.iconAnimation,
      time: data.time || 5000,
      showDuration: data.showDuration !== false,
      position: data.position,
    }

    if (data.sound !== false && getSettings().notifySound) {
      playSound('notification.mp3', 0.25)
    }

    // Gleiche id noch sichtbar: diese Notification aktualisieren und ihre Zeit
    // neu starten, statt eine zweite daneben zu stapeln.
    const existing = data.id ? notes.find((n) => n.id === data.id && !n.leaving) : undefined

    if (existing) {
      setNotes((prev) =>
        prev.map((n) => (n.uid === existing.uid ? { ...n, ...fields, runId: n.runId + 1, leaving: false } : n)),
      )
      schedule(existing.uid, fields.time)
      return
    }

    const uid = ++counter
    setNotes((prev) => [{ uid, ...fields, leaving: false, runId: 0 }, ...prev]) // neueste oben
    schedule(uid, fields.time)
  })

  // Die Einstellung des Spielers gewinnt, die Position aus dem Script greift nur
  // bei "Automatisch".
  const positionOf = (note: Note): NotifyPosition => notifyPosition || note.position || 'top-left'

  return (
    <>
      {POSITIONS.map((position) => {
        const group = notes.filter((note) => positionOf(note) === position)
        if (group.length === 0) return null

        const fromRight = position.endsWith('right')

        return (
          <div
            key={position}
            className={`pointer-events-none absolute flex w-[32vh] gap-[1.4vh] ${POSITION_CLASS[position]}`}
          >
            {group.map((note) => (
              <NoteCard key={note.uid} note={note} fromRight={fromRight} />
            ))}
          </div>
        )
      })}
    </>
  )
}

function NoteCard({ note, fromRight }: { note: Note; fromRight: boolean }) {
  const iconClass = `${note.icon} ${iconAnimationClass(note.iconAnimation)}`
  const iconColor = note.iconColor || note.color

  return (
    <div
      className="relative overflow-hidden rounded-sm border border-border bg-panel/95 shadow-msk backdrop-blur-sm"
      style={{
        animation: note.leaving
          ? `${fromRight ? 'msk-slide-out-right' : 'msk-slide-out'} 0.3s cubic-bezier(0.55,0,1,0.45) forwards`
          : `${fromRight ? 'msk-slide-in-right' : 'msk-slide-in'} 0.35s cubic-bezier(0.22,1,0.36,1)`,
      }}
    >
      {note.title ? (
        <>
          {/* Titel-Banner */}
          <div className="flex items-center gap-[0.8vh] border-b border-border bg-white/[0.03] px-[1.6vh] py-[1vh]">
            <i className={iconClass} style={{ color: iconColor, fontSize: '1.7vh' }} />
            <span
              className="font-mono text-[1.4vh] font-bold uppercase tracking-[0.12vh]"
              style={{ color: note.color }}
            >
              {parseColorCodes(note.title)}
            </span>
          </div>

          <div className="px-[1.6vh] py-[1.2vh] font-body text-[1.45vh] leading-[1.5] text-text-secondary">
            {parseColorCodes(note.message)}
          </div>
        </>
      ) : (
        // Ohne Titel: kompakt, Icon neben dem Text statt einer leeren Titelleiste.
        <div className="flex items-start gap-[1.1vh] px-[1.6vh] py-[1.2vh]">
          <i className={`${iconClass} mt-[0.2vh]`} style={{ color: iconColor, fontSize: '1.7vh' }} />
          <div className="font-body text-[1.45vh] leading-[1.5] text-text-secondary">
            {parseColorCodes(note.message)}
          </div>
        </div>
      )}

      {note.showDuration && (
        <div className="h-[0.4vh] w-full bg-black/40">
          <div
            key={note.runId}
            className="h-full"
            style={{
              background: note.color,
              boxShadow: `0 0 1vh ${note.color}`,
              animation: `msk-progress-deplete ${note.time / 1000}s linear forwards`,
            }}
          />
        </div>
      )}
    </div>
  )
}
