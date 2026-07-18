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
    // Kein event.origin-Check: NUI-Messages kommen ueber SendNUIMessage aus dem
    // CEF des Spielclients (nui://), nicht aus einem cross-origin Web-Kontext.
    // Es gibt keine stabile, pruefbare Origin, und ein Check wuerde den
    // Browser-Dev-Modus (DevPanel) brechen. Gefiltert wird streng ueber data.action.
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
