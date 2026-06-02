import type { ReactNode } from 'react'

// FiveM-Farbcodes — identisch zur colors-Map aus dem alten web/script.js.
const COLORS: Record<string, string> = {
  r: 'red',
  b: '#378cbf',
  g: 'green',
  lg: '#5eb131',
  y: 'yellow',
  p: 'purple',
  c: 'grey',
  m: '#212121',
  u: 'black',
  o: 'orange',
}

const TOKEN = /~([a-z]+)~/g

/**
 * Wandelt einen Text mit ~x~-Farbcodes in sichere React-Nodes um.
 * `~s~` setzt die Farbe zurück. Kein dangerouslySetInnerHTML -> XSS-sicher.
 */
export function parseColorCodes(input: string): ReactNode[] {
  const nodes: ReactNode[] = []
  let lastIndex = 0
  let currentColor: string | undefined
  let key = 0

  const pushText = (text: string) => {
    if (!text) return
    if (currentColor) {
      nodes.push(
        <span key={key++} style={{ color: currentColor }}>
          {text}
        </span>,
      )
    } else {
      nodes.push(<span key={key++}>{text}</span>)
    }
  }

  let match: RegExpExecArray | null
  TOKEN.lastIndex = 0
  while ((match = TOKEN.exec(input)) !== null) {
    pushText(input.slice(lastIndex, match.index))
    const code = match[1]
    if (code === 's') {
      currentColor = undefined
    } else if (code in COLORS) {
      currentColor = COLORS[code]
    } else {
      // Unbekanntes Token unverändert ausgeben
      pushText(match[0])
    }
    lastIndex = match.index + match[0].length
  }
  pushText(input.slice(lastIndex))

  return nodes
}
