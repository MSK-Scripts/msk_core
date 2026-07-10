import { useEffect, useRef, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import { playSound } from '../lib/sound'
import { parseColorCodes } from '../lib/colorCodes'
import type {
  ContextMetaItem,
  ContextOption,
  OpenContextMessage,
  UpdateContextMessage,
} from '../types'
import { EmptyRow, MenuHeader, MenuShell, faClass } from './menu/frame'

const clamp = (n: number) => Math.max(0, Math.min(100, n))

function firstSelectable(opts: ContextOption[], start: number, dir: number): number {
  if (opts.length === 0) return 0
  let i = start
  for (let n = 0; n < opts.length; n++) {
    if (i < 0) i = opts.length - 1
    else if (i >= opts.length) i = 0
    if (!opts[i].disabled && !opts[i].readOnly) return i
    i += dir
  }
  return Math.max(0, Math.min(start, opts.length - 1))
}

export default function ContextMenu() {
  const [state, setState] = useState<OpenContextMessage | null>(null)
  const [selected, setSelected] = useState(0)

  const stateRef = useRef<OpenContextMessage | null>(null)
  stateRef.current = state
  const selectedRef = useRef(0)
  selectedRef.current = selected

  useNuiEvent<OpenContextMessage>('openContext', (data) => {
    setState(data)
    setSelected(firstSelectable(data.options, 0, 1))
  })

  useNuiEvent<UpdateContextMessage>('updateContext', (data) => {
    setState((prev) => (prev ? { ...prev, options: data.options } : prev))
  })

  useNuiEvent('closeContext', () => setState(null))

  const select = (opt: ContextOption) => {
    if (opt.disabled || opt.readOnly) return
    playSound('click.mp3', 0.14)
    void fetchNui('contextSelect', { index: opt.index })
  }

  const back = () => {
    playSound('click.mp3', 0.14)
    void fetchNui('contextBack')
  }

  const close = () => {
    void fetchNui('closeContext')
  }

  useEffect(() => {
    if (!state) return
    const onKey = (e: KeyboardEvent) => {
      const s = stateRef.current
      if (!s) return
      const opts = s.options
      if (e.key === 'ArrowDown') {
        e.preventDefault()
        setSelected((i) => firstSelectable(opts, i + 1, 1))
      } else if (e.key === 'ArrowUp') {
        e.preventDefault()
        setSelected((i) => firstSelectable(opts, i - 1, -1))
      } else if (e.key === 'Enter' || e.key === 'ArrowRight') {
        const o = opts[selectedRef.current]
        if (o) select(o)
      } else if (e.key === 'Backspace') {
        if (s.hasBack) back()
      } else if (e.key === 'Escape') {
        if (s.canClose) close()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [state])

  if (!state) return null

  return (
    <MenuShell position={state.position}>
      <MenuHeader
        title={state.title}
        onBack={state.hasBack ? back : undefined}
        onClose={state.canClose ? close : undefined}
      />
      <div className="flex max-h-[62vh] flex-col gap-[0.8vh] overflow-y-auto p-[1vh]">
        {state.options.length === 0 ? (
          <EmptyRow label="—" />
        ) : (
          state.options.map((opt, i) => (
            <ContextRow
              key={opt.id ?? i}
              opt={opt}
              active={i === selected}
              onHover={() => {
                if (!opt.disabled && !opt.readOnly) setSelected(i)
              }}
              onClick={() => select(opt)}
            />
          ))
        )}
      </div>
    </MenuShell>
  )
}

function normalizeMeta(meta?: ContextMetaItem[] | Record<string, string>): ContextMetaItem[] {
  if (!meta) return []
  if (Array.isArray(meta)) return meta
  return Object.entries(meta).map(([label, value]) => ({ label, value: String(value) }))
}

function ContextRow({
  opt,
  active,
  onHover,
  onClick,
}: {
  opt: ContextOption
  active: boolean
  onHover: () => void
  onClick: () => void
}) {
  const clickable = !opt.disabled && !opt.readOnly
  const icon = faClass(opt.icon)
  const meta = normalizeMeta(opt.metadata)

  return (
    <div className="group relative">
      <button
        type="button"
        disabled={!clickable}
        onMouseEnter={onHover}
        onClick={onClick}
        className={`flex w-full items-center gap-[1.2vh] rounded-sm border px-[1.2vh] py-[1vh] text-left transition-colors ${
          opt.disabled
            ? 'cursor-not-allowed border-border bg-input opacity-40'
            : opt.readOnly
              ? 'cursor-default border-border bg-input'
              : active
                ? 'border-border-accent bg-accent/10'
                : 'border-border bg-input hover:border-border-accent hover:bg-white/5'
        }`}
      >
        {opt.image ? (
          <img src={opt.image} alt="" className="h-[3.6vh] w-[3.6vh] shrink-0 rounded-sm object-cover" />
        ) : icon ? (
          <i
            className={`${icon} shrink-0 text-[1.8vh]`}
            style={{ color: opt.iconColor || 'var(--color-accent)' }}
          />
        ) : null}

        <span className="flex min-w-0 flex-1 flex-col gap-[0.3vh]">
          <span className="truncate font-body text-[1.6vh] text-text-primary">{parseColorCodes(opt.title)}</span>
          {opt.description ? (
            <span className="truncate font-body text-[1.3vh] text-text-secondary">
              {parseColorCodes(opt.description)}
            </span>
          ) : null}
          {typeof opt.progress === 'number' ? (
            <span className="mt-[0.4vh] block h-[0.6vh] w-full overflow-hidden rounded-full bg-input">
              <span
                className="block h-full rounded-full"
                style={{ width: `${clamp(opt.progress)}%`, background: opt.colorScheme || 'var(--color-accent)' }}
              />
            </span>
          ) : null}
        </span>

        {opt.arrow ? <i className="fas fa-chevron-right shrink-0 text-[1.5vh] text-text-muted" /> : null}
      </button>

      {meta.length > 0 ? (
        <div className="pointer-events-none absolute right-full top-0 z-10 mr-[1vh] hidden w-[22vh] flex-col gap-[0.4vh] rounded-sm border border-border bg-panel/95 p-[1vh] shadow-msk backdrop-blur-md group-hover:flex">
          {meta.map((m, idx) => (
            <div key={idx} className="flex items-baseline justify-between gap-[1vh] text-[1.3vh]">
              <span className="font-mono uppercase tracking-[0.06em] text-text-muted">{m.label}</span>
              {m.value ? <span className="text-right text-text-primary">{m.value}</span> : null}
            </div>
          ))}
        </div>
      ) : null}
    </div>
  )
}
