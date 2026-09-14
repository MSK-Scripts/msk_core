import { useState } from 'react'
import './mock'
import type { ContextOption, MenuItem, NotifyPosition, NuiMessage } from '../types'

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

  // Settings-Demo: Position der Notifications durchschalten
  const [posIndex, setPosIndex] = useState(0)
  const [sound, setSound] = useState(true)
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

      <Section title="Notify options">
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'notify',
              id: 'garage_full',
              title: 'Garage',
              message: `Garage voll (${new Date().toLocaleTimeString()})`,
              type: NOTIFY_TYPES.error,
              time: 6000,
              icon: 'warehouse',
            })
          }
        >
          same id
        </button>
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'notify',
              message: 'Ohne Titel, mit ~y~Shake~s~-Icon',
              type: NOTIFY_TYPES.warning,
              time: 5000,
              icon: 'bell',
              iconAnimation: 'shake',
            })
          }
        >
          no title
        </button>
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'notify',
              title: 'Unten rechts',
              message: 'Position aus dem Script, ohne Balken und ohne Sound',
              type: NOTIFY_TYPES.info,
              time: 5000,
              position: 'bottom-right',
              showDuration: false,
              sound: false,
            })
          }
        >
          bottom-right
        </button>
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

      <Section title="Input Dialog">
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'openInputDialog',
              header: 'Fahrzeug registrieren',
              allowCancel: true,
              size: 'md',
              rows: [
                { index: 1, type: 'input', label: 'Kennzeichen', placeholder: 'MSK 123', icon: 'id-card', required: true, maxLength: 8 },
                { index: 2, type: 'number', label: 'Preis', min: 1, max: 100000, description: 'Zwischen 1 und 100.000' },
                { index: 3, type: 'select', label: 'Garage', options: [{ value: 'pillbox', label: 'Pillbox' }, { value: 'sandy', label: 'Sandy Shores' }] },
                { index: 4, type: 'multi-select', label: 'Extras', options: [{ value: 1, label: 'Neon' }, { value: 2, label: 'Turbo' }, { value: 3, label: 'Xenon' }] },
                { index: 5, type: 'slider', label: 'Tankfüllung', min: 0, max: 100, default: 60 },
                { index: 6, type: 'color', label: 'Farbe', default: '#00e676' },
                { index: 7, type: 'date-range', label: 'Versicherung' },
                { index: 8, type: 'time', label: 'Abholung' },
                { index: 9, type: 'textarea', label: 'Notiz' },
                { index: 10, type: 'checkbox', label: 'Versichert', required: true },
              ],
            })
          }
        >
          all types
        </button>
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'openInputDialog',
              header: 'Name',
              allowCancel: false,
              size: 'sm',
              rows: [{ index: 1, type: 'input', label: 'Vorname', required: true }],
            })
          }
        >
          small
        </button>
        <button className={btn} onClick={() => send({ action: 'closeInputDialog' })}>
          close
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
            send({
              action: 'openNumpad',
              id: 1,
              mode: 'code',
              length: 4,
              masked: false,
              title: 'Tresor',
              labels: { enter: 'Code eingeben', wrong: 'Falscher Code', attempts: 'Versuche übrig' },
            })
          }
        >
          code 4
        </button>
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'openNumpad',
              id: 2,
              mode: 'input',
              length: 6,
              masked: true,
              labels: { enter: 'Enter PIN', wrong: 'Incorrect', attempts: 'Attempts left' },
            })
          }
        >
          input 6 masked
        </button>
      </Section>

      <Section title="TextUI">
        <button
          className={btn}
          onClick={() => send({ action: 'textUI', show: true, key: 'E', text: 'Press ~g~E~s~ to interact' })}
        >
          show
        </button>
        <button
          className={btn}
          onClick={() =>
            send({ action: 'textUI', show: true, key: 'E', text: `Update ${new Date().toLocaleTimeString()}` })
          }
        >
          update
        </button>
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'textUI',
              show: true,
              key: false,
              text: 'Ohne Taste, Icon links',
              icon: 'warehouse',
              iconAnimation: 'bounce',
              position: 'left-center',
            })
          }
        >
          icon left
        </button>
        <button
          className={btn}
          onClick={() =>
            send({ action: 'textUI', show: true, key: 'G', text: 'Oben', color: '#75d6ff', icon: 'car', position: 'top-center' })
          }
        >
          top
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

      <Section title="Progress Circle">
        <button
          className={btn}
          onClick={() =>
            send({ action: 'progressCircleStart', time: 5000, text: 'Lockpicking...', color: '#00e676', position: 'middle' })
          }
        >
          middle 5s
        </button>
        <button
          className={btn}
          onClick={() =>
            send({ action: 'progressCircleStart', time: 3000, text: 'Eating', color: '#75d6ff', position: 'bottom' })
          }
        >
          bottom 3s
        </button>
        <button className={btn} onClick={() => send({ action: 'progressBarStop' })}>
          stop
        </button>
      </Section>

      <Section title="Alert">
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'openAlert',
              header: 'Fahrzeug verkaufen',
              content: 'Willst du deinen ~g~Sultan~s~ wirklich verkaufen?\nDer Preis beträgt ~y~$12.000~s~.',
              cancel: true,
              labels: { confirm: 'Verkaufen', cancel: 'Behalten' },
            })
          }
        >
          confirm
        </button>
        <button
          className={btn}
          onClick={() =>
            send({ action: 'openAlert', header: 'Hinweis', content: 'Nur ein Button.', cancel: false, centered: true, size: 'sm' })
          }
        >
          notice
        </button>
        <button className={btn} onClick={() => send({ action: 'closeAlert' })}>
          close
        </button>
      </Section>

      <Section title="Radial">
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'openRadial',
              hasBack: false,
              items: [
                { index: 1, label: 'Vehicle', icon: 'car', hasMenu: true },
                { index: 2, label: 'Phone', icon: 'mobile-screen' },
                { index: 3, label: 'Emotes', icon: 'face-smile' },
                { index: 4, label: 'Billing', icon: 'file-invoice-dollar' },
                { index: 5, label: 'Clothing', icon: 'shirt' },
              ],
            })
          }
        >
          open
        </button>
        <button
          className={btn}
          onClick={() =>
            send({
              action: 'openRadial',
              hasBack: true,
              title: 'Vehicle',
              items: Array.from({ length: 11 }, (_, i) => ({ index: i + 1, label: `Option ${i + 1}`, icon: 'gear' })),
            })
          }
        >
          11 items
        </button>
        <button className={btn} onClick={() => send({ action: 'closeRadial' })}>
          close
        </button>
      </Section>

      <Section title="Skillcheck">
        <button
          className={btn}
          onClick={() => send({ action: 'startSkillcheck', areaSize: 50, speed: 1, key: 'e', round: 1, rounds: 1 })}
        >
          easy
        </button>
        <button
          className={btn}
          onClick={() => send({ action: 'startSkillcheck', areaSize: 25, speed: 1.75, key: 'w', round: 2, rounds: 3 })}
        >
          hard
        </button>
        <button className={btn} onClick={() => send({ action: 'cancelSkillcheck' })}>
          cancel
        </button>
      </Section>

      <Section title="Settings">
        <button
          className={btn}
          onClick={() => {
            const next = (posIndex + 1) % NOTIFY_POSITIONS.length
            setPosIndex(next)
            send({ action: 'settings', notifyPosition: NOTIFY_POSITIONS[next], notifySound: sound })
          }}
        >
          pos: {NOTIFY_POSITIONS[posIndex]}
        </button>
        <button
          className={btn}
          onClick={() => {
            setSound(!sound)
            send({ action: 'settings', notifyPosition: NOTIFY_POSITIONS[posIndex], notifySound: !sound })
          }}
        >
          sound: {sound ? 'on' : 'off'}
        </button>
      </Section>
    </div>
  )
}

const NOTIFY_POSITIONS: NotifyPosition[] = [
  'top-left',
  'top',
  'top-right',
  'center-right',
  'bottom-right',
  'bottom',
  'bottom-left',
  'center-left',
]

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-1">
      <div className="text-[10px] uppercase tracking-wider text-text-muted">{title}</div>
      <div className="flex flex-wrap gap-1">{children}</div>
    </div>
  )
}
