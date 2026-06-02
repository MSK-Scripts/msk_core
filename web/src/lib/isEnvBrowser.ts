// FiveM-NUI injiziert window.invokeNative. Fehlt es, laufen wir im normalen Browser (Dev).
export const isEnvBrowser = (): boolean =>
  !(window as unknown as { invokeNative?: unknown }).invokeNative
