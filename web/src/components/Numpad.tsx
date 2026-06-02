import { useEffect, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import { playSound } from '../lib/sound'
import type { OpenNumpadMessage } from '../types'

type Status = 'idle' | 'typing' | 'wrong'

export default function Numpad() {
  const [open, setOpen] = useState(false)
  const [code, setCode] = useState('')
  const [length, setLength] = useState(4)
  const [show, setShow] = useState(true)
  const [enterCode, setEnterCode] = useState('Enter Code')
  const [wrongCode, setWrongCode] = useState('Incorrect')
  const [input, setInput] = useState('')
  const [status, setStatus] = useState<Status>('idle')

  useNuiEvent<OpenNumpadMessage>('openNumpad', (data) => {
    setCode(data.code)
    setLength(data.length)
    setShow(data.show)
    setEnterCode(data.EnterCode || 'Enter Code')
    setWrongCode(data.WrongCode || 'Incorrect')
    setInput('')
    setStatus('idle')
    setOpen(true)
  })

  useNuiEvent('closeNumpad', () => close(false))

  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close(true)
      else if (e.key >= '0' && e.key <= '9') addDigit(e.key)
      else if (e.key === 'Backspace') clear()
      else if (e.key === 'Enter') submit()
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, input, code])

  const close = (send: boolean) => {
    setOpen(false)
    setInput('')
    if (send) void fetchNui('closeNumpad')
  }

  const addDigit = (num: string) => {
    if (input.length >= length) return
    playSound('click.mp3', 0.14)
    setInput(input + num)
    setStatus('typing')
  }

  const clear = () => {
    playSound('click.mp3', 0.14)
    setInput('')
    setStatus('idle')
  }

  const submit = () => {
    if (input === code) {
      void fetchNui('submitNumpad')
      close(false)
    } else {
      setStatus('wrong')
      setInput('')
    }
  }

  if (!open) return null

  const displayContent = () => {
    if (status === 'wrong') return wrongCode
    if (status === 'idle' || input.length === 0) return enterCode
    if (show) return input
    return '•'.repeat(input.length)
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
      style={{ animation: 'msk-pop-in 0.28s cubic-bezier(0.22,1,0.36,1)' }}
    >
      {/* Display */}
      <div
        className="mb-[1.6vh] flex h-[7vh] w-full items-center justify-center rounded-sm border border-border bg-input font-mono text-[2.8vh] font-bold uppercase tracking-[0.3vh]"
        style={{ color: displayColor }}
      >
        {displayContent()}
      </div>

      {/* Ziffern */}
      <div className="grid grid-cols-3 gap-[1vh]">
        {keys.map((k) => (
          <NumButton key={k} onClick={() => addDigit(k)}>
            {k}
          </NumButton>
        ))}
        <NumButton variant="clear" onClick={clear}>
          <i className="fas fa-delete-left" />
        </NumButton>
        <NumButton onClick={() => addDigit('0')}>0</NumButton>
        <NumButton variant="submit" onClick={submit}>
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
}: {
  children: React.ReactNode
  onClick: () => void
  variant?: 'digit' | 'clear' | 'submit'
}) {
  const base =
    'flex h-[8vh] w-[8vh] items-center justify-center rounded-sm border font-mono text-[2.2vh] font-bold transition-all active:translate-y-[0.2vh]'
  const variants: Record<string, string> = {
    digit: 'border-border bg-input text-text-primary hover:border-white/20 hover:bg-white/[0.08]',
    clear:
      'border-notify-error/25 bg-notify-error/10 text-notify-error hover:bg-notify-error/20',
    submit:
      'border-accent/30 bg-accent/10 text-accent hover:border-accent/60 hover:bg-accent/20',
  }
  return (
    <button className={`${base} ${variants[variant]}`} onClick={onClick}>
      {children}
    </button>
  )
}
