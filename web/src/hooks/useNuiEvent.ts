import { useEffect, useRef } from 'react'

/**
 * Registers a listener for a NUI action (window 'message').
 * The handler is ref-stable, so current closures apply without re-subscribing.
 */
export function useNuiEvent<T = unknown>(
  action: string,
  handler: (data: T) => void,
): void {
  const saved = useRef(handler)
  saved.current = handler

  useEffect(() => {
    // No event.origin check: NUI messages arrive via SendNUIMessage from the
    // game client CEF (nui://), not from a cross-origin web context. There is no
    // stable, checkable origin, and a check would break browser dev mode (DevPanel).
    // Filtering is done strictly through data.action.
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
