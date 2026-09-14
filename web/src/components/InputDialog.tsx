import { useEffect, useRef, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import { parseColorCodes } from '../lib/colorCodes'
import { faClass } from './menu/frame'
import type { InputDialogRow, OpenInputDialogMessage } from '../types'

// select speichert den Index der Option (als String), multi-select eine Liste
// von Indizes. So bleiben Zahlen- und String-Werte der Optionen unverfälscht.
type FieldValue = string | boolean | number[] | [string, string]

const WIDTH = {
  sm: 'w-[38vh]',
  md: 'w-[48vh]',
  lg: 'w-[62vh]',
}

const FIELD =
  'h-[4vh] w-full rounded-sm border border-border bg-input px-[1.4vh] font-body text-[1.45vh] text-text-primary outline-none transition-colors placeholder:text-text-muted focus:border-accent/60 disabled:cursor-not-allowed disabled:opacity-50'

const isBlank = (text: string) => text.trim() === ''

function initialValue(row: InputDialogRow): FieldValue {
  const options = row.options ?? []

  switch (row.type) {
    case 'checkbox':
      return row.default === true
    case 'select': {
      const index = options.findIndex((o) => o.value === row.default)
      return index >= 0 ? String(index) : ''
    }
    case 'multi-select': {
      const defaults = Array.isArray(row.default) ? row.default : []
      return options.map((o, i) => (defaults.includes(o.value) ? i : -1)).filter((i) => i >= 0)
    }
    case 'date-range':
      return Array.isArray(row.default) && row.default.length === 2
        ? [String(row.default[0]), String(row.default[1])]
        : ['', '']
    case 'slider':
      return String(row.default ?? row.min ?? 0)
    default:
      return row.default === undefined || row.default === null ? '' : String(row.default)
  }
}

// Spiegelt InputDialog.Validate aus modules/Input/shared.lua.
function validate(row: InputDialogRow, value: FieldValue): string | null {
  if (row.disabled) return null

  switch (row.type) {
    case 'checkbox':
      return row.required && value !== true ? 'Required' : null

    case 'multi-select':
      return row.required && (value as number[]).length === 0 ? 'Select at least one option' : null

    case 'date-range': {
      const [from, to] = value as [string, string]
      if (!from && !to) return row.required ? 'Required' : null
      if (!from || !to) return 'Select a start and an end date'
      if (from > to) return 'The start date is after the end date'
      if (typeof row.min === 'string' && from < row.min) return `Not before ${row.min}`
      if (typeof row.max === 'string' && to > row.max) return `Not after ${row.max}`
      return null
    }

    default: {
      const text = value as string
      if (isBlank(text)) return row.required ? 'Required' : null

      if (row.type === 'number' || row.type === 'slider') {
        const number = Number(text)
        if (Number.isNaN(number)) return 'Not a number'
        if (typeof row.min === 'number' && number < row.min) return `At least ${row.min}`
        if (typeof row.max === 'number' && number > row.max) return `At most ${row.max}`
      }

      if ((row.type === 'input' || row.type === 'textarea') && row.maxLength && text.length > row.maxLength) {
        return `At most ${row.maxLength} characters`
      }

      if (row.type === 'color' && !/^#[0-9a-f]{6}([0-9a-f]{2})?$/i.test(text)) return 'Invalid color'

      if (row.type === 'date') {
        if (typeof row.min === 'string' && text < row.min) return `Not before ${row.min}`
        if (typeof row.max === 'string' && text > row.max) return `Not after ${row.max}`
      }

      return null
    }
  }
}

// Wert, wie er an Lua geht. undefined = leeres optionales Feld.
function toPayload(row: InputDialogRow, value: FieldValue): unknown {
  const options = row.options ?? []

  switch (row.type) {
    case 'checkbox':
      return value === true
    case 'select':
      return value === '' ? undefined : options[Number(value)]?.value
    case 'multi-select': {
      const list = (value as number[]).map((i) => options[i]?.value)
      return list.length > 0 ? list : undefined
    }
    case 'date-range': {
      const [from, to] = value as [string, string]
      return from && to ? [from, to] : undefined
    }
    case 'number':
    case 'slider':
      return isBlank(value as string) ? undefined : Number(value)
    default:
      return isBlank(value as string) ? undefined : value
  }
}

export default function InputDialog() {
  const [dialog, setDialog] = useState<OpenInputDialogMessage | null>(null)
  const [values, setValues] = useState<Record<number, FieldValue>>({})
  const [errors, setErrors] = useState<Record<number, string>>({})
  const bodyRef = useRef<HTMLDivElement>(null)

  useNuiEvent<OpenInputDialogMessage>('openInputDialog', (data) => {
    const initial: Record<number, FieldValue> = {}
    data.rows.forEach((row) => {
      initial[row.index] = initialValue(row)
    })
    setValues(initial)
    setErrors({})
    setDialog(data)
  })

  useNuiEvent('closeInputDialog', () => setDialog(null))

  useEffect(() => {
    if (!dialog) return
    const t = window.setTimeout(() => {
      bodyRef.current
        ?.querySelector<HTMLElement>('input:not([disabled]), textarea:not([disabled]), select:not([disabled])')
        ?.focus()
    }, 30)
    return () => window.clearTimeout(t)
  }, [dialog])

  const cancel = () => {
    if (!dialog?.allowCancel) return
    setDialog(null)
    void fetchNui('inputDialogCancel')
  }

  const submit = () => {
    if (!dialog) return

    const nextErrors: Record<number, string> = {}
    const payload: Record<string, unknown> = {}

    for (const row of dialog.rows) {
      const value = values[row.index]
      const error = validate(row, value)

      if (error) {
        nextErrors[row.index] = error
      } else if (!row.disabled) {
        const converted = toPayload(row, value)
        if (converted !== undefined) payload[String(row.index)] = converted
      }
    }

    setErrors(nextErrors)
    if (Object.keys(nextErrors).length > 0) return

    setDialog(null)
    void fetchNui('inputDialogSubmit', { values: payload })
  }

  useEffect(() => {
    if (!dialog) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') cancel()
      if (e.key === 'Enter' && !(e.target instanceof HTMLTextAreaElement)) {
        e.preventDefault()
        submit()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dialog, values])

  if (!dialog) return null

  const setValue = (index: number, value: FieldValue) => {
    setValues((prev) => ({ ...prev, [index]: value }))
    setErrors((prev) => {
      if (!(index in prev)) return prev
      const next = { ...prev }
      delete next[index]
      return next
    })
  }

  return (
    <div className="absolute inset-0 bg-black/45" style={{ animation: 'msk-fade-in 0.2s ease-out' }}>
      <div
        className={`absolute left-1/2 top-1/2 ${WIDTH[dialog.size] ?? WIDTH.md} -translate-x-1/2 -translate-y-1/2 overflow-hidden rounded-lg border border-border bg-panel/95 shadow-msk backdrop-blur-md`}
        style={{ animation: 'msk-zoom-in 0.24s cubic-bezier(0.22,1,0.36,1)', colorScheme: 'dark' }}
      >
        <div className="border-b border-border bg-white/[0.03] px-[2vh] py-[1.6vh] text-center">
          <span className="font-mono text-[1.5vh] font-bold uppercase tracking-[0.25vh] text-text-primary">
            {parseColorCodes(dialog.header)}
          </span>
          <div
            className="mx-auto mt-[0.8vh] h-[0.2vh] w-[40%]"
            style={{ background: 'linear-gradient(to right, transparent, var(--color-border-accent), transparent)' }}
          />
        </div>

        <div ref={bodyRef} className="flex max-h-[62vh] flex-col gap-[1.6vh] overflow-y-auto px-[2vh] py-[2vh]">
          {dialog.rows.map((row) => (
            <Field
              key={row.index}
              row={row}
              value={values[row.index]}
              error={errors[row.index]}
              onChange={(value) => setValue(row.index, value)}
            />
          ))}
        </div>

        <div className="flex gap-[1vh] border-t border-border px-[2vh] py-[1.6vh]">
          {dialog.allowCancel && (
            <button
              onClick={cancel}
              className="flex h-[4.2vh] flex-1 items-center justify-center gap-[0.8vh] rounded-sm border border-border bg-input font-mono text-[1.3vh] font-bold uppercase tracking-[0.2vh] text-text-secondary transition-all hover:border-white/20 hover:text-text-primary active:translate-y-[0.2vh]"
            >
              <i className="fas fa-xmark" />
              {dialog.labels?.cancel || 'Cancel'}
            </button>
          )}
          <button
            onClick={submit}
            className="flex h-[4.2vh] flex-1 items-center justify-center gap-[0.8vh] rounded-sm border border-accent/30 bg-accent/10 font-mono text-[1.3vh] font-bold uppercase tracking-[0.2vh] text-accent transition-all hover:border-accent/60 hover:bg-accent/20 active:translate-y-[0.2vh]"
          >
            <i className="fas fa-check" />
            {dialog.labels?.confirm || 'Confirm'}
          </button>
        </div>
      </div>
    </div>
  )
}

interface FieldProps {
  row: InputDialogRow
  value: FieldValue
  error?: string
  onChange: (value: FieldValue) => void
}

function Field({ row, value, error, onChange }: FieldProps) {
  const icon = faClass(row.icon)
  const options = row.options ?? []

  const label =
    row.type === 'checkbox' ? null : (
      <div className="mb-[0.6vh] flex items-center gap-[0.7vh]">
        {icon && <i className={`${icon} text-[1.4vh] text-accent`} />}
        {row.label && (
          <span className="font-mono text-[1.2vh] font-bold uppercase tracking-[0.12vh] text-text-secondary">
            {parseColorCodes(row.label)}
          </span>
        )}
        {row.required && <span className="font-mono text-[1.2vh] text-notify-error">*</span>}
      </div>
    )

  let control: React.ReactNode

  switch (row.type) {
    case 'textarea':
      control = (
        <textarea
          className={`${FIELD} h-[10vh] py-[1vh]`}
          placeholder={row.placeholder}
          disabled={row.disabled}
          maxLength={row.maxLength}
          spellCheck={false}
          value={value as string}
          onChange={(e) => onChange(e.target.value)}
        />
      )
      break

    case 'number':
      control = (
        <input
          type="number"
          className={FIELD}
          placeholder={row.placeholder}
          disabled={row.disabled}
          min={row.min as number | undefined}
          max={row.max as number | undefined}
          step={row.step ?? 'any'}
          value={value as string}
          onChange={(e) => onChange(e.target.value)}
        />
      )
      break

    case 'checkbox': {
      const checked = value === true
      control = (
        <button
          type="button"
          disabled={row.disabled}
          onClick={() => onChange(!checked)}
          className="flex items-center gap-[1vh] text-left disabled:cursor-not-allowed disabled:opacity-50"
        >
          <span
            className={`flex h-[2.2vh] w-[2.2vh] shrink-0 items-center justify-center rounded-[0.4vh] border transition-colors ${
              checked ? 'border-accent bg-accent/20 text-accent' : 'border-border bg-input text-transparent'
            }`}
          >
            <i className="fas fa-check text-[1.2vh]" />
          </span>
          {icon && <i className={`${icon} text-[1.4vh] text-accent`} />}
          <span className="font-body text-[1.45vh] text-text-primary">
            {row.label ? parseColorCodes(row.label) : null}
            {row.required && <span className="ml-[0.4vh] text-notify-error">*</span>}
          </span>
        </button>
      )
      break
    }

    case 'select':
      control = (
        <select
          className={FIELD}
          disabled={row.disabled}
          value={value as string}
          onChange={(e) => onChange(e.target.value)}
        >
          <option value="">{row.placeholder || 'Select...'}</option>
          {options.map((option, i) => (
            <option key={i} value={String(i)}>
              {option.label}
            </option>
          ))}
        </select>
      )
      break

    case 'multi-select': {
      const selected = value as number[]
      control = (
        <div className="flex flex-wrap gap-[0.7vh]">
          {options.map((option, i) => {
            const active = selected.includes(i)
            return (
              <button
                key={i}
                type="button"
                disabled={row.disabled}
                onClick={() => onChange(active ? selected.filter((s) => s !== i) : [...selected, i])}
                className={`rounded-sm border px-[1.1vh] py-[0.6vh] font-body text-[1.3vh] transition-colors disabled:cursor-not-allowed disabled:opacity-50 ${
                  active
                    ? 'border-accent/60 bg-accent/15 text-accent'
                    : 'border-border bg-input text-text-secondary hover:border-white/20'
                }`}
              >
                {active && <i className="fas fa-check mr-[0.5vh] text-[1.1vh]" />}
                {option.label}
              </button>
            )
          })}
        </div>
      )
      break
    }

    case 'slider': {
      const min = typeof row.min === 'number' ? row.min : 0
      const max = typeof row.max === 'number' ? row.max : 100
      control = (
        <div className="flex items-center gap-[1.2vh]">
          <input
            type="range"
            className="h-[0.6vh] flex-1 cursor-pointer disabled:cursor-not-allowed disabled:opacity-50"
            style={{ accentColor: 'var(--color-accent)' }}
            disabled={row.disabled}
            min={min}
            max={max}
            step={row.step ?? 1}
            value={value as string}
            onChange={(e) => onChange(e.target.value)}
          />
          <span className="w-[5vh] text-right font-mono text-[1.35vh] text-text-primary">{value as string}</span>
        </div>
      )
      break
    }

    case 'color': {
      const text = value as string
      const valid = /^#[0-9a-f]{6}/i.test(text)
      control = (
        <div className="flex gap-[1vh]">
          <input
            type="color"
            className="h-[4vh] w-[5vh] shrink-0 cursor-pointer rounded-sm border border-border bg-input p-[0.3vh] disabled:cursor-not-allowed disabled:opacity-50"
            disabled={row.disabled}
            value={valid ? text.slice(0, 7) : '#000000'}
            onChange={(e) => onChange(e.target.value)}
          />
          <input
            className={`${FIELD} font-mono`}
            placeholder={row.placeholder || '#00e676'}
            disabled={row.disabled}
            spellCheck={false}
            value={text}
            onChange={(e) => onChange(e.target.value)}
          />
        </div>
      )
      break
    }

    case 'date':
      control = (
        <input
          type="date"
          className={FIELD}
          disabled={row.disabled}
          min={row.min as string | undefined}
          max={row.max as string | undefined}
          value={value as string}
          onChange={(e) => onChange(e.target.value)}
        />
      )
      break

    case 'date-range': {
      const [from, to] = value as [string, string]
      control = (
        <div className="flex items-center gap-[1vh]">
          <input
            type="date"
            className={FIELD}
            disabled={row.disabled}
            min={row.min as string | undefined}
            max={to || (row.max as string | undefined)}
            value={from}
            onChange={(e) => onChange([e.target.value, to])}
          />
          <i className="fas fa-arrow-right text-[1.2vh] text-text-muted" />
          <input
            type="date"
            className={FIELD}
            disabled={row.disabled}
            min={from || (row.min as string | undefined)}
            max={row.max as string | undefined}
            value={to}
            onChange={(e) => onChange([from, e.target.value])}
          />
        </div>
      )
      break
    }

    case 'time':
      control = (
        <input
          type="time"
          className={FIELD}
          disabled={row.disabled}
          value={value as string}
          onChange={(e) => onChange(e.target.value)}
        />
      )
      break

    default:
      control = (
        <input
          type={row.password ? 'password' : 'text'}
          className={FIELD}
          placeholder={row.placeholder}
          disabled={row.disabled}
          maxLength={row.maxLength}
          spellCheck={false}
          value={value as string}
          onChange={(e) => onChange(e.target.value)}
        />
      )
  }

  return (
    <div>
      {label}
      {control}
      {row.description && (
        <div className="mt-[0.5vh] font-body text-[1.2vh] leading-[1.4] text-text-muted">
          {parseColorCodes(row.description)}
        </div>
      )}
      {error && (
        <div className="mt-[0.5vh] flex items-center gap-[0.5vh] font-body text-[1.2vh] text-notify-error">
          <i className="fas fa-circle-exclamation" />
          {error}
        </div>
      )}
    </div>
  )
}
