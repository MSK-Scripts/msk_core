import { useState } from 'react'
import { useNuiEvent } from '../hooks/useNuiEvent'
import { parseColorCodes } from '../lib/colorCodes'
import type { TextUiMessage } from '../types'

interface State {
  key: string
  text: string
  color: string
}

export default function TextUI() {
  const [data, setData] = useState<State | null>(null)

  useNuiEvent<TextUiMessage>('textUI', (msg) => {
    if (msg.show) {
      setData({
        key: msg.key || 'E',
        text: msg.text || '',
        color: msg.color || '#00e676',
      })
    } else {
      setData(null)
    }
  })

  if (!data) return null

  return (
    <div
      className="absolute bottom-[6vh] left-1/2 flex -translate-x-1/2 items-center gap-[1.4vh] rounded-lg border border-border bg-panel/95 px-[2vh] py-[1.4vh] shadow-msk backdrop-blur-md"
      style={{ animation: 'msk-slide-in 0.25s cubic-bezier(0.22,1,0.36,1)' }}
    >
      {/* Key-Box */}
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

      {/* Text */}
      <div className="font-body text-[1.8vh] font-medium text-text-primary">
        {parseColorCodes(data.text)}
      </div>
    </div>
  )
}
