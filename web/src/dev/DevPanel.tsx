import './mock'
import type { NuiMessage } from '../types'

// Feuert eine NUI-Nachricht, als käme sie von Lua (SendNUIMessage).
const send = (msg: NuiMessage) => window.postMessage(msg, '*')

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
                message: `Test-Notification vom Typ ~g~${key}~s~ mit ~y~Farbcode~s~.`,
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
            send({ action: 'openInput', header: 'Spielername', placeholder: 'Name eingeben…', field: false })
          }
        >
          small
        </button>
        <button
          className={btn}
          onClick={() =>
            send({ action: 'openInput', header: 'Nachricht', placeholder: 'Mehrzeilig…', field: true })
          }
        >
          big
        </button>
      </Section>

      <Section title="Progress">
        <button
          className={btn}
          onClick={() =>
            send({ action: 'progressBarStart', time: 5000, text: 'Durchsuche…', color: '#00e676' })
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
          masked
        </button>
      </Section>

      <Section title="TextUI">
        <button
          className={btn}
          onClick={() => send({ action: 'textUI', show: true, key: 'E', text: 'Drücke ~g~E~s~ zum Interagieren' })}
        >
          show
        </button>
        <button className={btn} onClick={() => send({ action: 'textUI', show: false })}>
          hide
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
