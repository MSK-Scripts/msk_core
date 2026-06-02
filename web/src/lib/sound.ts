// Sounds liegen unter public/sounds/ -> im Build relativ erreichbar.
export function playSound(file: string, volume: number): void {
  try {
    const audio = new Audio(`./sounds/${file}`)
    audio.volume = volume
    void audio.play().catch(() => {
      /* Autoplay-Restriktionen im Browser-Dev ignorieren */
    })
  } catch {
    /* no-op */
  }
}
