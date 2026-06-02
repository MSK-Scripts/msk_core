import { useEffect, useRef } from 'react'

/**
 * Registriert einen Listener für eine NUI-Action (window 'message').
 * Der Handler ist ref-stabil, sodass aktuelle Closures ohne Re-Subscribe greifen.
 */
export function useNuiEvent<T = unknown>(
  action: string,
  handler: (data: T) => void,
): void {
  const saved = useRef(handler)
  saved.current = handler

  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const data = event.data
      if (data && data.action === action) {
        saved.current(data as T)
      }
    }
    window.addEventListener('message', listener)
    return () => window.removeEventListener('message', listener)
  }, [action])
}
