import { useEffect, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import { parseColorCodes } from '../lib/colorCodes'
import type { OpenAlertMessage } from '../types'

const WIDTH = {
  sm: 'w-[36vh]',
  md: 'w-[48vh]',
  lg: 'w-[64vh]',
}

export default function AlertDialog() {
  const [alert, setAlert] = useState<OpenAlertMessage | null>(null)

  useNuiEvent<OpenAlertMessage>('openAlert', (data) => setAlert(data))
  useNuiEvent('closeAlert', () => setAlert(null))

  const respond = (result: 'confirm' | 'cancel') => {
    setAlert(null)
    void fetchNui('alertResult', { result })
  }

  // Enter confirms, Escape cancels (or confirms when there is no cancel button).
  useEffect(() => {
    if (!alert) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Enter') respond('confirm')
      if (e.key === 'Escape') respond(alert.cancel ? 'cancel' : 'confirm')
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [alert])

  if (!alert) return null

  const lines = (alert.content || '').split('\n')

  return (
    <div className="absolute inset-0 bg-black/45" style={{ animation: 'msk-fade-in 0.2s ease-out' }}>
      <div
        className={`absolute left-1/2 top-1/2 ${WIDTH[alert.size ?? 'md'] ?? WIDTH.md} -translate-x-1/2 -translate-y-1/2 overflow-hidden rounded-lg border border-border bg-panel/95 shadow-msk backdrop-blur-md`}
        style={{ animation: 'msk-zoom-in 0.24s cubic-bezier(0.22,1,0.36,1)' }}
      >
        {alert.header && (
          <div className="border-b border-border bg-white/[0.03] px-[2vh] py-[1.6vh] text-center">
            <span className="font-mono text-[1.5vh] font-bold uppercase tracking-[0.25vh] text-text-primary">
              {parseColorCodes(alert.header)}
            </span>
            <div
              className="mx-auto mt-[0.8vh] h-[0.2vh] w-[40%]"
              style={{
                background:
                  'linear-gradient(to right, transparent, var(--color-border-accent), transparent)',
              }}
            />
          </div>
        )}

        <div
          className={`flex flex-col gap-[0.6vh] px-[2.2vh] py-[2vh] font-body text-[1.5vh] leading-[1.55] text-text-secondary ${
            alert.centered ? 'text-center' : ''
          }`}
        >
          {lines.map((line, i) => (
            <p key={i} className="m-0 min-h-[1.5vh]">
              {parseColorCodes(line)}
            </p>
          ))}
        </div>

        <div className="flex gap-[1vh] border-t border-border px-[2vh] py-[1.6vh]">
          {alert.cancel && (
            <button
              onClick={() => respond('cancel')}
              className="flex h-[4.2vh] flex-1 items-center justify-center gap-[0.8vh] rounded-sm border border-border bg-input font-mono text-[1.3vh] font-bold uppercase tracking-[0.2vh] text-text-secondary transition-all hover:border-white/20 hover:text-text-primary active:translate-y-[0.2vh]"
            >
              <i className="fas fa-xmark" />
              {alert.labels?.cancel || 'Cancel'}
            </button>
          )}
          <button
            onClick={() => respond('confirm')}
            className="flex h-[4.2vh] flex-1 items-center justify-center gap-[0.8vh] rounded-sm border border-accent/30 bg-accent/10 font-mono text-[1.3vh] font-bold uppercase tracking-[0.2vh] text-accent transition-all hover:border-accent/60 hover:bg-accent/20 active:translate-y-[0.2vh]"
          >
            <i className="fas fa-check" />
            {alert.labels?.confirm || 'Confirm'}
          </button>
        </div>
      </div>
    </div>
  )
}
