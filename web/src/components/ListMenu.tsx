import { useEffect, useRef, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { playSound } from '../lib/sound'
import { parseColorCodes } from '../lib/colorCodes'
import type { MenuItem, OpenMenuMessage, UpdateMenuMessage } from '../types'
import { EmptyRow, MenuHeader, MenuShell, faClass } from './menu/frame'

const clamp = (n: number) => Math.max(0, Math.min(100, n))

// Reine Render-Schicht: die gesamte Eingabe (Pfeiltasten) liest der Lua-Control-Loop,
// hier wird nur der von Lua gepushte State dargestellt.
export default function ListMenu() {
  const [state, setState] = useState<OpenMenuMessage | null>(null)
  const prevSelected = useRef<number | null>(null)
  const rowRefs = useRef<Record<number, HTMLDivElement | null>>({})

  useNuiEvent<OpenMenuMessage>('openMenu', (data) => {
    prevSelected.current = data.selected
    rowRefs.current = {}
    setState(data)
  })

  useNuiEvent<UpdateMenuMessage>('updateMenu', (data) => {
    setState((prev) => (prev ? { ...prev, selected: data.selected, items: data.items } : prev))
  })

  useNuiEvent('closeMenu', () => {
    setState(null)
    prevSelected.current = null
  })

  useEffect(() => {
    if (!state) return
    if (prevSelected.current !== null && prevSelected.current !== state.selected) {
      playSound('click.mp3', 0.14)
    }
    prevSelected.current = state.selected
    rowRefs.current[state.selected]?.scrollIntoView({ block: 'nearest' })
  }, [state])

  if (!state) return null
  const items = state.items

  return (
    <MenuShell position={state.position}>
      <MenuHeader
        title={state.title}
        counter={items.length ? `${state.selected}/${items.length}` : undefined}
      />
      <div className="flex max-h-[62vh] flex-col gap-[0.6vh] overflow-y-auto p-[1vh]">
        {items.length === 0 ? (
          <EmptyRow label="—" />
        ) : (
          items.map((item) => (
            <div
              key={item.id ?? item.index}
              ref={(el) => {
                rowRefs.current[item.index] = el
              }}
            >
              <MenuListRow item={item} active={item.index === state.selected} />
            </div>
          ))
        )}
      </div>
    </MenuShell>
  )
}

function MenuListRow({ item, active }: { item: MenuItem; active: boolean }) {
  const icon = faClass(item.icon)
  const value =
    item.values && item.valueIndex ? item.values[item.valueIndex - 1] : undefined

  return (
    <div
      className={`flex w-full items-center gap-[1.2vh] rounded-sm border px-[1.2vh] py-[1vh] transition-colors ${
        item.disabled
          ? 'border-border bg-input opacity-40'
          : active
            ? 'border-border-accent bg-accent/10'
            : 'border-border bg-input'
      }`}
    >
      {icon ? (
        <i
          className={`${icon} shrink-0 text-[1.8vh]`}
          style={{ color: item.iconColor || (active ? 'var(--color-accent)' : 'var(--color-text-secondary)') }}
        />
      ) : null}

      <span className="flex min-w-0 flex-1 flex-col gap-[0.3vh]">
        <span className="truncate font-body text-[1.6vh] text-text-primary">{parseColorCodes(item.label)}</span>
        {value?.description ? (
          <span className="truncate font-body text-[1.3vh] text-text-secondary">
            {parseColorCodes(value.description)}
          </span>
        ) : item.description ? (
          <span className="truncate font-body text-[1.3vh] text-text-secondary">
            {parseColorCodes(item.description)}
          </span>
        ) : null}
        {typeof item.progress === 'number' ? (
          <span className="mt-[0.4vh] block h-[0.6vh] w-full overflow-hidden rounded-full bg-input">
            <span
              className="block h-full rounded-full"
              style={{ width: `${clamp(item.progress)}%`, background: item.colorScheme || 'var(--color-accent)' }}
            />
          </span>
        ) : null}
      </span>

      {item.values ? (
        <span className="flex shrink-0 items-center gap-[0.8vh] font-mono text-[1.4vh] text-text-primary">
          <i className={`fas fa-chevron-left text-[1.2vh] ${active ? 'text-accent' : 'text-text-muted'}`} />
          <span className="min-w-[6vh] text-center uppercase tracking-[0.04em]">{value?.label ?? ''}</span>
          <i className={`fas fa-chevron-right text-[1.2vh] ${active ? 'text-accent' : 'text-text-muted'}`} />
        </span>
      ) : item.checked !== undefined ? (
        <span
          className={`flex h-[2.4vh] w-[2.4vh] shrink-0 items-center justify-center rounded-sm border ${
            item.checked ? 'border-accent bg-accent/20 text-accent' : 'border-border text-transparent'
          }`}
        >
          <i className="fas fa-check text-[1.3vh]" />
        </span>
      ) : null}
    </div>
  )
}
