import { useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { parseColorCodes } from '../lib/colorCodes'
import { playSound } from '../lib/sound'
import type { NotifyMessage } from '../types'

interface Note {
  id: number
  title: string
  message: string
  color: string
  icon: string
  time: number
  leaving: boolean
}

let counter = 0

export default function NotifyStack() {
  const [notes, setNotes] = useState<Note[]>([])

  useNuiEvent<NotifyMessage>('notify', (data) => {
    const id = ++counter
    const note: Note = {
      id,
      title: data.title,
      message: data.message,
      color: data.type?.color || '#00e676',
      icon: data.type?.icon || 'fas fa-circle-info',
      time: data.time || 5000,
      leaving: false,
    }

    setNotes((prev) => [note, ...prev]) // neueste oben
    playSound('notification.mp3', 0.25)

    // Auslauf-Animation starten, dann entfernen
    window.setTimeout(() => {
      setNotes((prev) => prev.map((n) => (n.id === id ? { ...n, leaving: true } : n)))
      window.setTimeout(() => {
        setNotes((prev) => prev.filter((n) => n.id !== id))
      }, 320)
    }, note.time)
  })

  return (
    <div className="pointer-events-none absolute left-[2vh] top-[5vh] flex w-[32vh] flex-col gap-[1.4vh]">
      {notes.map((note) => (
        <div
          key={note.id}
          className="relative overflow-hidden rounded-sm border border-border bg-panel/95 shadow-msk backdrop-blur-sm"
          style={{
            animation: note.leaving
              ? 'msk-slide-out 0.3s cubic-bezier(0.55,0,1,0.45) forwards'
              : 'msk-slide-in 0.35s cubic-bezier(0.22,1,0.36,1)',
            borderLeft: `0.3vh solid ${note.color}`,
          }}
        >
          {/* Titel-Banner */}
          <div className="flex items-center gap-[0.8vh] border-b border-border bg-white/[0.03] px-[1.6vh] py-[1vh]">
            <i className={note.icon} style={{ color: note.color, fontSize: '1.7vh' }} />
            <span
              className="font-mono text-[1.4vh] font-bold uppercase tracking-[0.12vh]"
              style={{ color: note.color }}
            >
              {note.title}
            </span>
          </div>

          {/* Text */}
          <div className="px-[1.6vh] py-[1.2vh] font-body text-[1.45vh] leading-[1.5] text-text-secondary">
            {parseColorCodes(note.message)}
          </div>

          {/* Progress */}
          <div className="h-[0.4vh] w-full bg-black/40">
            <div
              className="h-full"
              style={{
                background: note.color,
                boxShadow: `0 0 1vh ${note.color}`,
                animation: `msk-progress-deplete ${note.time / 1000}s linear forwards`,
              }}
            />
          </div>
        </div>
      ))}
    </div>
  )
}
