import { useEffect, useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { fetchNui } from '../lib/fetchNui'
import { playSound } from '../lib/sound'
import { faClass } from './menu/frame'
import type { OpenRadialMessage, RadialItem } from '../types'

// Geometry in SVG units of a 200x200 viewBox.
const CENTER = 100
const OUTER = 96
const INNER = 34
const LABEL_RADIUS = (OUTER + INNER) / 2

// More than this many entries are split into pages; the last slice of every
// page then switches to the next one.
const PAGE_SIZE = 8

interface Slice {
  key: string
  label: string
  icon?: string
  iconColor?: string
  hasMenu?: boolean
  index?: number
  more?: boolean
}

function point(radius: number, angle: number): [number, number] {
  return [CENTER + radius * Math.cos(angle), CENTER + radius * Math.sin(angle)]
}

// Angle of the middle of slice `index`; slice 0 points straight up.
function middleAngle(index: number, count: number) {
  return -Math.PI / 2 + index * ((Math.PI * 2) / count)
}

function slicePath(index: number, count: number) {
  const step = (Math.PI * 2) / count
  const gap = 0.012
  const start = middleAngle(index, count) - step / 2 + gap
  const end = start + step - gap * 2
  const large = end - start > Math.PI ? 1 : 0

  const [ox1, oy1] = point(OUTER, start)
  const [ox2, oy2] = point(OUTER, end)
  const [ix1, iy1] = point(INNER, end)
  const [ix2, iy2] = point(INNER, start)

  return `M ${ox1} ${oy1} A ${OUTER} ${OUTER} 0 ${large} 1 ${ox2} ${oy2} L ${ix1} ${iy1} A ${INNER} ${INNER} 0 ${large} 0 ${ix2} ${iy2} Z`
}

// A single entry fills the whole ring. An arc cannot start and end on the same
// point, so the ring is two full circles cut out with evenodd.
const RING_PATH =
  `M ${CENTER - OUTER} ${CENTER} a ${OUTER} ${OUTER} 0 1 0 ${OUTER * 2} 0 a ${OUTER} ${OUTER} 0 1 0 ${-OUTER * 2} 0 ` +
  `M ${CENTER - INNER} ${CENTER} a ${INNER} ${INNER} 0 1 0 ${INNER * 2} 0 a ${INNER} ${INNER} 0 1 0 ${-INNER * 2} 0`

function buildPages(items: RadialItem[]): Slice[][] {
  const toSlice = (item: RadialItem): Slice => ({
    key: `item-${item.index}`,
    label: item.label,
    icon: item.icon,
    iconColor: item.iconColor,
    hasMenu: item.hasMenu,
    index: item.index,
  })

  if (items.length <= PAGE_SIZE) return [items.map(toSlice)]

  const perPage = PAGE_SIZE - 1
  const pages: Slice[][] = []

  for (let i = 0; i < items.length; i += perPage) {
    pages.push([
      ...items.slice(i, i + perPage).map(toSlice),
      { key: 'more', label: 'More', icon: 'ellipsis', more: true },
    ])
  }

  return pages
}

export default function RadialMenu() {
  const [menu, setMenu] = useState<OpenRadialMessage | null>(null)
  const [page, setPage] = useState(0)
  const [hovered, setHovered] = useState<string | null>(null)

  useNuiEvent<OpenRadialMessage>('openRadial', (data) => {
    setMenu(data)
    setPage(0)
    setHovered(null)
  })

  useNuiEvent('closeRadial', () => setMenu(null))

  useEffect(() => {
    if (!menu) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') void fetchNui('radialClose')
      if (e.key === 'Backspace') void fetchNui('radialBack')
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [menu])

  if (!menu) return null

  const pages = buildPages(menu.items)
  const slices = pages[Math.min(page, pages.length - 1)]
  const count = slices.length

  const select = (slice: Slice) => {
    playSound('click.mp3', 0.14)

    if (slice.more) {
      setPage((current) => (current + 1) % pages.length)
      return
    }

    void fetchNui('radialSelect', { index: slice.index })
  }

  const centerAction = () => void fetchNui(menu.hasBack ? 'radialBack' : 'radialClose')

  return (
    <div
      className="absolute left-1/2 top-1/2 h-[42vh] w-[42vh] -translate-x-1/2 -translate-y-1/2"
      style={{ animation: 'msk-zoom-in 0.22s cubic-bezier(0.22,1,0.36,1)' }}
      onContextMenu={(e) => {
        e.preventDefault()
        void fetchNui('radialBack')
      }}
    >
      <svg viewBox="0 0 200 200" className="h-full w-full overflow-visible">
        {slices.map((slice, i) => {
          const active = hovered === slice.key
          return (
            <path
              key={slice.key}
              d={count === 1 ? RING_PATH : slicePath(i, count)}
              fillRule="evenodd"
              fill={active ? 'rgba(0, 230, 118, 0.16)' : 'rgba(19, 19, 23, 0.92)'}
              stroke={active ? 'rgba(0, 230, 118, 0.6)' : 'rgba(255, 255, 255, 0.08)'}
              strokeWidth={0.6}
              className="cursor-pointer transition-colors duration-150"
              onMouseEnter={() => setHovered(slice.key)}
              onMouseLeave={() => setHovered((current) => (current === slice.key ? null : current))}
              onClick={() => select(slice)}
            />
          )
        })}

        <circle
          cx={CENTER}
          cy={CENTER}
          r={INNER - 3}
          fill="rgba(10, 11, 13, 0.95)"
          stroke="rgba(0, 230, 118, 0.35)"
          strokeWidth={0.6}
          className="cursor-pointer"
          onClick={centerAction}
        />
      </svg>

      {slices.map((slice, i) => {
        const [x, y] = point(LABEL_RADIUS, middleAngle(i, count))
        const active = hovered === slice.key

        return (
          <div
            key={`label-${slice.key}`}
            className="pointer-events-none absolute flex w-[9vh] -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-[0.5vh] text-center"
            style={{ left: `${x / 2}%`, top: `${y / 2}%` }}
          >
            {slice.icon && (
              <i
                className={`${faClass(slice.icon) ?? ''} text-[2.3vh] transition-colors`}
                style={{ color: active ? 'var(--color-accent)' : slice.iconColor || 'var(--color-text-secondary)' }}
              />
            )}
            <span
              className={`font-mono text-[1.05vh] font-bold uppercase leading-tight tracking-[0.1vh] ${
                active ? 'text-text-primary' : 'text-text-muted'
              }`}
            >
              {slice.label}
              {slice.hasMenu && <i className="fas fa-angle-right ml-[0.4vh]" />}
            </span>
          </div>
        )
      })}

      <div className="pointer-events-none absolute left-1/2 top-1/2 flex w-[12vh] -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-[0.4vh] text-center">
        <i className={`fas ${menu.hasBack ? 'fa-arrow-left' : 'fa-xmark'} text-[1.9vh] text-accent`} />
        <span className="font-mono text-[1vh] font-bold uppercase tracking-[0.15vh] text-text-secondary">
          {menu.title || (menu.hasBack ? 'Back' : 'Close')}
        </span>
        {pages.length > 1 && (
          <span className="font-mono text-[0.95vh] text-text-muted">
            {Math.min(page, pages.length - 1) + 1}/{pages.length}
          </span>
        )}
      </div>
    </div>
  )
}
