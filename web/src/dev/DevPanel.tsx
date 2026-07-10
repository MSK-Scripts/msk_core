import { useState } from 'react'
import './mock'
import type { ContextOption, MenuItem, NuiMessage } from '../types'

// Feuert eine NUI-Nachricht, als käme sie von Lua (SendNUIMessage).
const send = (msg: NuiMessage) => window.postMessage(msg, '*')

// ── Demo-Daten für Context/Menu ───────────────────────────────────
const contextOptions = (progress: number): ContextOption[] => [
  { index: 1, id: 'info', title: 'Fahrzeug ~g~Info~s~', description: 'Untermenü öffnen', icon: 'circle-info', arrow: true },
  { index: 2, id: 'repair', title: 'Reparieren', description: 'Zustand wiederherstellen', icon: 'wrench', progress, colorScheme: '#00e676' },
  { index: 3, id: 'locked', title: 'Gesperrt', description: 'Kein Zugriff', icon: 'lock', disabled: true },
  { index: 4, id: 'plate', title: 'Kennzeichen', icon: 'id-card', readOnly: true, metadata: [{ label: 'Plate', value: 'MSK 123' }, { label: 'Model', value: 'Sultan' }] },
]

const menuItems = (valueIndex: number, checked: boolean): MenuItem[] => [
  { index: 1, id: 'engine', label: 'Motor', description: 'Zustand', icon: 'gauge-high', progress: 82, colorScheme: '#00e676' },
  { index: 2, id: 'color', label: 'Farbe', icon: 'palette', values: [{ label: 'Schwarz' }, { label: 'Weiß' }, { label: 'MSK Grün' }], valueIndex },
  { index: 3, id: 'neon', label: 'Neon', icon: 'lightbulb', checked },
  { index: 4, id: 'locked', label: 'Deaktiviert', icon: 'ban', disabled: true },
]

const NOTIFY_TYPES = {
  general: { icon: 'fas fa-circle-info', color: '#f0ede8' },
  info: { icon: 'fas fa-circle-info', color: '#75d6ff' },
  success: { icon: 'fas fa-shield-check', color: '#00e676' },
  warning: { icon: 'fas fa-triangle-exclamation', color: '#facc15' },
  error: { icon: 'fas fa-circle-exclamation', color: '#f43f5e' },
}

export default function DevPanel() {
  const btn =
    'rounded-md border border-border bg-input px-2 py-1 text-[11px] font-medium text-text-primary transition-colors hover:border-accent/50 hover:bg-accent/10'

  // Lokaler Demo-State für das (Lua-getriebene) Menu, damit man im Browser
  // Navigation/Side-Scroll/Checkbox simulieren kann.
  const [mSel, setMSel] = useState(1)
  const [mVal, setMVal] = useState(1)
  const [mChk, setMChk] = useState(false)
  const pushMenu = (sel: number, val: number, chk: boolean) =>
    send({ action: 'updateMenu', selected: sel, items: menuItems(val, chk) })

  return (
    <div className="pointer-events-auto fixed right-3 top-3 z-[9999] flex w-[200px] flex-col gap-2 rounded-lg border border-border bg-panel/95 p-3 font-body text-text-secondary shadow-msk">
      <div className="font-mono text-[11px] uppercase tracking-widest text-accent">
        MSK Dev Panel
      </div>

      <Section title="Notify">
        {Object.entries(NOTIFY_TYPES).map(([key, type]) => (
          <button
            key={key}
            className={btn}
            onClick={() =>
              send({
                action: 'notify',
                title: key.toUpperCase(),
                message: `Test-Notification as type ~g~${key}~s~ with ~y~Color-Codes~s~.`,
                type,
                time: 5000,
              })
            }
          >
            {key}
          </button>
        ))}
      </Section>

      <Section title="Input">
        <button
          className={btn}
          onClick={() =>
            send({ action: 'openInput', header: 'Header', placeholder: 'Small text input...', field: false })
          }
        >
          small
        </button>
        <button
          className={btn}
          onClick={() =>
            send({ action: 'openInput', header: 'Header', placeholder: 'Large text input...', field: true })
          }
        >
          big
        </button>
      </Section>

      <Section title="Progress">
        <button
          className={btn}
          onClick={() =>
            send({ action: 'progressBarStart', time: 5000, text: 'Searching...', color: '#00e676' })
          }
        >
          start 5s
        </button>
        <button className={btn} onClick={() => send({ action: 'progressBarStop' })}>
          stop
        </button>
      </Section>

      <Section title="Numpad">
        <button
          className={btn}
          onClick={() =>
            send({ action: 'openNumpad', code: '1234', length: 4, show: true, EnterCode: 'Enter Code', WrongCode: 'Incorrect' })
          }
        >
          show 1234
        </button>
        <button
          className={btn}
          onClick={() =>
            send({ action: 'openNumpad', code: '4321', length: 4, show: false, EnterCode: 'Enter Code', WrongCode: 'Incorrect' })
          }
        >
          masked 4321
        </button>
      </Section>

      <Section title="TextUI">
        <button
          className={btn}
          onClick={() => send({ action: 'textUI', show: true, key: 'E', text: 'Press ~g~E~s~ to interact' })}
        >
          show
        </button>
        <button className={btn} onClick={() => send({ action: 'textUI', show: false })}>
          hide
        </button>
      </Section>

      <Section title="Context">
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'openContext',
              id: 'demo',
              title: 'Fahrzeug',
              options: contextOptions(45),
              canClose: true,
              position: 'center',
              hasBack: false,
            })
          }
        >
          open
        </button>
        <button className={btn} onClick={() => send({ action: 'updateContext', options: contextOptions(90) })}>
          update
        </button>
        <button className={btn} onClick={() => send({ action: 'closeContext' })}>
          close
        </button>
      </Section>

      <Section title="Menu">
        <button
          className={btn}
          onClick={() => {
            setMSel(1)
            setMVal(1)
            setMChk(false)
            send({ action: 'openMenu', id: 'demo', title: 'Optionen', position: 'top-left', selected: 1, items: menuItems(1, false) })
          }}
        >
          open
        </button>
        <button
          className={btn}
          onClick={() => {
            const next = (mSel % 4) + 1
            setMSel(next)
            pushMenu(next, mVal, mChk)
          }}
        >
          next
        </button>
        <button
          className={btn}
          onClick={() => {
            const next = (mVal % 3) + 1
            setMVal(next)
            pushMenu(mSel, next, mChk)
          }}
        >
          scroll
        </button>
        <button
          className={btn}
          onClick={() => {
            setMChk(!mChk)
            pushMenu(mSel, mVal, !mChk)
          }}
        >
          check
        </button>
        <button className={btn} onClick={() => send({ action: 'closeMenu' })}>
          close
        </button>
      </Section>
    </div>
  )
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1">
      <div className="text-[10px] uppercase tracking-wider text-text-muted">{title}</div>
      <div className="flex flex-wrap gap-1">{children}</div>
    </div>
  )
}
