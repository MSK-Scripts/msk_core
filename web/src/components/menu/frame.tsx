import type { ReactNode } from 'react'

// Wandelt einen Icon-String in eine FontAwesome-Klasse um.
// "car" -> "fas fa-car"; vollstaendige Angaben ("fas fa-car", "fa-brands fa-...")
// werden unveraendert uebernommen.
export function faClass(icon?: string): string | undefined {
  if (!icon) return undefined
  const s = icon.trim()
  if (s === '') return undefined
  if (s.includes(' ') || s.includes('fa-')) return s
  return `fas fa-${s}`
}

const POSITIONS: Record<string, string> = {
  center: 'items-center justify-center',
  right: 'items-center justify-end pr-[3vh]',
  left: 'items-center justify-start pl-[3vh]',
  top: 'items-start justify-center pt-[3vh]',
  bottom: 'items-end justify-center pb-[3vh]',
  'top-right': 'items-start justify-end pt-[3vh] pr-[3vh]',
  'top-left': 'items-start justify-start pt-[3vh] pl-[3vh]',
  'bottom-right': 'items-end justify-end pb-[3vh] pr-[3vh]',
  'bottom-left': 'items-end justify-start pb-[3vh] pl-[3vh]',
}

export function positionClass(position?: string): string {
  return POSITIONS[position ?? 'center'] ?? POSITIONS.center
}

// Aeusserer Rahmen + Panel im MSK-Look (identisch zur Panel-Optik von Input/TextUI).
export function MenuShell({
  position,
  children,
}: {
  position?: string
  children: ReactNode
}) {
  return (
    <div className={`pointer-events-none absolute inset-0 flex ${positionClass(position)} font-body`}>
      <div
        className="pointer-events-auto flex w-[34vh] max-w-[92vw] flex-col overflow-hidden rounded-lg border border-border bg-panel/95 shadow-msk backdrop-blur-md"
        style={{ animation: 'msk-menu-in 0.22s cubic-bezier(0.22,1,0.36,1)' }}
      >
        {children}
      </div>
    </div>
  )
}

function IconBtn({ icon, onClick }: { icon: string; onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex h-[3.4vh] w-[3.4vh] shrink-0 items-center justify-center rounded-sm text-text-muted transition-colors hover:bg-input hover:text-text-primary"
    >
      <i className={`fas ${icon} text-[1.7vh]`} />
    </button>
  )
}

export function MenuHeader({
  title,
  counter,
  onBack,
  onClose,
}: {
  title: string
  counter?: string
  onBack?: () => void
  onClose?: () => void
}) {
  return (
    <div className="flex items-center gap-[1vh] border-b border-border px-[1.2vh] py-[1.2vh]">
      {onBack ? <IconBtn icon="fa-arrow-left" onClick={onBack} /> : <span className="h-[3.4vh] w-[3.4vh] shrink-0" />}
      <div className="flex flex-1 items-center justify-center gap-[0.8vh] overflow-hidden">
        <span className="truncate font-head text-[1.9vh] font-semibold text-text-primary">{title}</span>
        {counter ? (
          <span className="shrink-0 font-mono text-[1.2vh] tracking-[0.06em] text-text-muted">{counter}</span>
        ) : null}
      </div>
      {onClose ? <IconBtn icon="fa-xmark" onClick={onClose} /> : <span className="h-[3.4vh] w-[3.4vh] shrink-0" />}
    </div>
  )
}

export function EmptyRow({ label }: { label: string }) {
  return (
    <div className="rounded-sm border border-dashed border-border px-[1.4vh] py-[2vh] text-center font-body text-[1.5vh] text-text-muted">
      {label}
    </div>
  )
}
