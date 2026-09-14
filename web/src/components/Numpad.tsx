import { useEffect, useRef, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import { playSound } from '../lib/sound'
import type { NumpadSubmitResult, OpenNumpadMessage } from '../types'

type Status = 'idle' | 'typing' | 'wrong' | 'checking'

// Die NUI kennt den Code nicht. Sie sammelt nur Ziffern und fragt Lua, ob sie
// stimmen; Lua (bzw. der Server) vergleicht und antwortet.
export default function Numpad() {
  const [numpad, setNumpad] = useState<OpenNumpadMessage | null>(null)
  const [input, setInput] = useState('')
  const [status, setStatus] = useState<Status>('idle')
  const [attemptsLeft, setAttemptsLeft] = useState<number | undefined>(undefined)

  // Die Eingabe liegt zusätzlich in einem Ref: der Tasten-Handler sieht den
  // State erst nach dem nächsten Render, zwei schnell getippte Ziffern hätten
  // sich sonst gegenseitig überschrieben.
  const inputRef = useRef('')
  const numpadRef = useRef<OpenNumpadMessage | null>(null)
  const checking = useRef(false)

  const updateInput = (next: string) => {
    inputRef.current = next
    setInput(next)
  }

  const updateNumpad = (next: OpenNumpadMessage | null) => {
    numpadRef.current = next
    setNumpad(next)
  }

  useNuiEvent<OpenNumpadMessage>('openNumpad', (data) => {
    checking.current = false
    updateNumpad(data)
    updateInput('')
    setStatus('idle')
    setAttemptsLeft(undefined)
  })

  useNuiEvent('closeNumpad', () => {
    checking.current = false
    updateNumpad(null)
    updateInput('')
  })

  const addDigit = (digit: string) => {
    const current = numpadRef.current
    if (!current || checking.current || inputRef.current.length >= current.length) return
    playSound('click.mp3', 0.14)
    updateInput(inputRef.current + digit)
    setStatus('typing')
  }

  // Backspace: eine Ziffer
  const removeDigit = () => {
    if (checking.current || inputRef.current === '') return
    playSound('click.mp3', 0.14)
    const next = inputRef.current.slice(0, -1)
    updateInput(next)
    setStatus(next ? 'typing' : 'idle')
  }

  // Roter Knopf: alles
  const clearAll = () => {
    if (checking.current) return
    playSound('click.mp3', 0.14)
    updateInput('')
    setStatus('idle')
  }

  const cancel = () => {
    if (!numpadRef.current) return
    updateNumpad(null)
    updateInput('')
    void fetchNui('closeNumpad')
  }

  const submit = async () => {
    const current = numpadRef.current
    const typed = inputRef.current
    if (!current || checking.current || typed === '') return

    checking.current = true
    setStatus('checking')

    const result = (await fetchNui<NumpadSubmitResult>('submitNumpad', { id: current.id, input: typed })) as
      | NumpadSubmitResult
      | undefined

    checking.current = false

    // Richtig oder gesperrt: Lua schließt das Numpad ohnehin.
    if (result?.ok || result?.locked) {
      updateNumpad(null)
      updateInput('')
      return
    }

    setAttemptsLeft(result?.attemptsLeft)
    setStatus('wrong')
    updateInput('')
  }

  useEffect(() => {
    if (!numpad) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') cancel()
      else if (e.key >= '0' && e.key <= '9') addDigit(e.key)
      else if (e.key === 'Backspace') removeDigit()
      else if (e.key === 'Enter') void submit()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // Die Handler lesen alles über Refs, ein Neuregistrieren pro Ziffer ist nicht nötig.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [numpad])

  if (!numpad) return null

  const { labels } = numpad

  const displayContent = () => {
    if (status === 'checking') return '• • •'
    if (status === 'wrong') return labels.wrong
    if (input.length === 0) return labels.enter
    return numpad.masked ? '•'.repeat(input.length) : input
  }

  const displayColor =
    status === 'wrong'
      ? 'var(--color-notify-error)'
      : status === 'typing'
        ? 'var(--color-text-primary)'
        : 'var(--color-text-muted)'

  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9']

  return (
    <div
      className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-lg border border-border bg-panel/95 p-[2vh] shadow-msk backdrop-blur-md"
      style={{ animation: 'msk-zoom-in 0.28s cubic-bezier(0.22,1,0.36,1)' }}
    >
      {numpad.title && (
        <div className="mb-[1.2vh] text-center font-mono text-[1.4vh] font-bold uppercase tracking-[0.25vh] text-text-secondary">
          {numpad.title}
        </div>
      )}

      {/* Display */}
      <div
        className="flex h-[7vh] w-full items-center justify-center rounded-sm border border-border bg-input font-mono text-[2.8vh] font-bold uppercase tracking-[0.3vh]"
        style={{ color: displayColor }}
      >
        {displayContent()}
      </div>

      {/* Fortschritt der Eingabe bzw. verbleibende Versuche */}
      <div className="mb-[1.4vh] mt-[0.8vh] flex h-[1.6vh] items-center justify-between font-mono text-[1.15vh] text-text-muted">
        <span>
          {input.length}/{numpad.length}
        </span>
        {attemptsLeft !== undefined && (
          <span className="text-notify-warning">
            {labels.attempts}: {attemptsLeft}
          </span>
        )}
      </div>

      {/* Ziffern */}
      <div className="grid grid-cols-3 gap-[1vh]">
        {keys.map((k) => (
          <NumButton key={k} onClick={() => addDigit(k)}>
            {k}
          </NumButton>
        ))}
        <NumButton variant="clear" onClick={clearAll}>
          <i className="fas fa-delete-left" />
        </NumButton>
        <NumButton onClick={() => addDigit('0')}>0</NumButton>
        <NumButton variant="submit" onClick={() => void submit()} disabled={input === ''}>
          <i className="fas fa-check" />
        </NumButton>
      </div>
    </div>
  )
}

function NumButton({
  children,
  onClick,
  variant = 'digit',
  disabled = false,
}: {
  children: React.ReactNode
  onClick: () => void
  variant?: 'digit' | 'clear' | 'submit'
  disabled?: boolean
}) {
  const base =
    'flex h-[8vh] w-[8vh] items-center justify-center rounded-sm border font-mono text-[2.2vh] font-bold transition-all active:translate-y-[0.2vh] disabled:cursor-not-allowed disabled:opacity-40'
  const variants: Record<string, string> = {
    digit: 'border-border bg-input text-text-primary hover:border-white/20 hover:bg-white/[0.08]',
    clear: 'border-notify-error/25 bg-notify-error/10 text-notify-error hover:bg-notify-error/20',
    submit: 'border-accent/30 bg-accent/10 text-accent hover:border-accent/60 hover:bg-accent/20',
  }
  return (
    <button className={`${base} ${variants[variant]}`} onClick={onClick} disabled={disabled}>
      {children}
    </button>
  )
}
