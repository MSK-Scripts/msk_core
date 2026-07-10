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
 *
 * Robust gegen nil/Zahlen aus Lua: ein fehlender Text darf niemals die komplette
 * NUI killen (es gibt keine Error-Boundary, ein Throw hier nimmt alle Komponenten mit).
 */
export function parseColorCodes(input?: string | number | null): ReactNode[] {
  if (input === null || input === undefined) return []
  const text = typeof input === 'string' ? input : String(input)
  if (text === '') return []

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
  while ((match = TOKEN.exec(text)) !== null) {
    pushText(text.slice(lastIndex, match.index))
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
  pushText(text.slice(lastIndex))

  return nodes
}
