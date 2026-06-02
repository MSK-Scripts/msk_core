import { useEffect, useRef, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import type { OpenInputMessage } from '../types'

export default function Input() {
  const [open, setOpen] = useState(false)
  const [header, setHeader] = useState('')
  const [placeholder, setPlaceholder] = useState('')
  const [isField, setIsField] = useState(false)
  const [value, setValue] = useState('')
  const fieldRef = useRef<HTMLInputElement | HTMLTextAreaElement>(null)

  useNuiEvent<OpenInputMessage>('openInput', (data) => {
    setHeader(data.header || '')
    setPlaceholder(data.placeholder || '')
    setIsField(!!data.field)
    setValue('')
    setOpen(true)
  })

  useNuiEvent('closeInput', () => setOpen(false))

  // Fokus setzen, sobald geöffnet
  useEffect(() => {
    if (open) {
      const t = window.setTimeout(() => fieldRef.current?.focus(), 30)
      return () => window.clearTimeout(t)
    }
  }, [open])

  // ESC schließt mit send=true
  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close(true)
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open])

  const close = (send: boolean) => {
    setOpen(false)
    setValue('')
    if (send) void fetchNui('closeInput')
  }

  const submit = () => {
    void fetchNui('submitInput', { input: value })
    setOpen(false)
    setValue('')
    // Lua schließt zusätzlich via closeInput-Action
  }

  if (!open) return null

  return (
    <div
      className="absolute left-1/2 top-1/2 w-[46vh] -translate-x-1/2 -translate-y-1/2 overflow-hidden rounded-lg border border-border bg-panel/95 shadow-msk backdrop-blur-md"
      style={{ animation: 'msk-pop-in 0.28s cubic-bezier(0.22,1,0.36,1)' }}
    >
      {/* Header */}
      <div className="border-b border-border bg-white/[0.03] px-[2vh] py-[1.6vh] text-center">
        <span className="font-mono text-[1.5vh] font-bold uppercase tracking-[0.25vh] text-text-primary">
          {header}
        </span>
        <div
          className="mx-auto mt-[0.8vh] h-[0.2vh] w-[40%]"
          style={{
            background:
              'linear-gradient(to right, transparent, var(--color-border-accent), transparent)',
          }}
        />
      </div>

      {/* Body */}
      <div className="px-[2vh] py-[2vh]">
        {isField ? (
          <textarea
            ref={fieldRef as React.RefObject<HTMLTextAreaElement>}
            className="h-[12vh] w-full rounded-sm border border-border bg-input px-[1.6vh] py-[1.2vh] font-body text-[1.5vh] text-text-primary outline-none transition-colors placeholder:text-text-muted focus:border-accent/60"
            placeholder={placeholder}
            spellCheck={false}
            value={value}
            onChange={(e) => setValue(e.target.value)}
          />
        ) : (
          <input
            ref={fieldRef as React.RefObject<HTMLInputElement>}
            className="h-[4.4vh] w-full rounded-sm border border-border bg-input px-[1.6vh] text-center font-body text-[1.5vh] text-text-primary outline-none transition-colors placeholder:text-text-muted focus:border-accent/60"
            placeholder={placeholder}
            spellCheck={false}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') {
                e.preventDefault()
                submit()
              }
            }}
          />
        )}

        <button
          onClick={submit}
          className="group mt-[1.6vh] flex h-[4.4vh] w-full items-center justify-center gap-[0.8vh] rounded-sm border border-accent/30 bg-accent/10 font-mono text-[1.4vh] font-bold uppercase tracking-[0.2vh] text-accent transition-all hover:border-accent/60 hover:bg-accent/20 active:translate-y-[0.2vh]"
        >
          <i className="fas fa-check" />
          Submit
        </button>
      </div>
    </div>
  )
}
