import { useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { parseColorCodes } from '../lib/colorCodes'
import { iconAnimationClass } from '../lib/iconAnimation'
import { faClass } from './menu/frame'
import type { TextUiMessage, TextUiPosition } from '../types'

interface State {
  key: string | false
  text: string
  color: string
  icon?: string
  iconColor?: string
  iconAnimation?: string
  position: TextUiPosition
}

const POSITION_CLASS: Record<TextUiPosition, string> = {
  'bottom-center': 'bottom-[6vh] left-1/2 -translate-x-1/2',
  'top-center': 'top-[6vh] left-1/2 -translate-x-1/2',
  'left-center': 'left-[2vh] top-1/2 -translate-y-1/2',
  'right-center': 'right-[2vh] top-1/2 -translate-y-1/2',
}

export default function TextUI() {
  const [data, setData] = useState<State | null>(null)

  useNuiEvent<TextUiMessage>('textUI', (msg) => {
    if (!msg.show) {
      setData(null)
      return
    }

    setData({
      key: msg.key === false ? false : msg.key || 'E',
      text: msg.text || '',
      color: msg.color || '#00e676',
      icon: msg.icon,
      iconColor: msg.iconColor,
      iconAnimation: msg.iconAnimation,
      position: msg.position && msg.position in POSITION_CLASS ? msg.position : 'bottom-center',
    })
  })

  if (!data) return null

  const icon = faClass(data.icon)

  return (
    // key = Position: nur ein Positionswechsel spielt die Einblendung neu ab,
    // ein reines Text-Update aktualisiert still.
    <div
      key={data.position}
      className={`absolute flex items-center gap-[1.4vh] rounded-lg border border-border bg-panel/95 px-[2vh] py-[1.4vh] shadow-msk backdrop-blur-md ${POSITION_CLASS[data.position]}`}
      style={{ animation: 'msk-zoom-in 0.25s cubic-bezier(0.22,1,0.36,1)' }}
    >
      {/* Key-Box */}
      {data.key !== false && (
        <div
          className="flex h-[4vh] min-w-[4vh] items-center justify-center rounded-sm px-[1vh] font-mono text-[2vh] font-bold uppercase text-bg"
          style={{
            background: data.color,
            boxShadow: `0 0.4vh 1.6vh -0.2vh ${data.color}`,
            animation: 'msk-pulse 2.4s ease-in-out infinite',
          }}
        >
          {data.key}
        </div>
      )}

      {/* Icon */}
      {icon && (
        <i
          className={`${icon} ${iconAnimationClass(data.iconAnimation)} text-[2vh]`}
          style={{ color: data.iconColor || data.color }}
        />
      )}

      {/* Text */}
      <div className="font-body text-[1.8vh] font-medium text-text-primary">
        {parseColorCodes(data.text)}
      </div>
    </div>
  )
}
