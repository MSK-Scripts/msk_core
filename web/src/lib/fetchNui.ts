import { isEnvBrowser } from './isEnvBrowser'

declare global {
  interface Window {
    GetParentResourceName?: () => string
  }
}

/**
 * Ersatz für das alte jQuery `$.post`. Sendet an die FiveM-NUI-Callbacks
 * (`https://<resource>/<event>`). Im Browser-Dev ein No-Op.
 */
export async function fetchNui<T = unknown>(
  eventName: string,
  data?: unknown,
): Promise<T | void> {
  if (isEnvBrowser()) return

  const resource = window.GetParentResourceName
    ? window.GetParentResourceName()
    : 'msk_core'

  const resp = await fetch(`https://${resource}/${eventName}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  })

  return resp.json().catch(() => undefined) as Promise<T | void>
}
