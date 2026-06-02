import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// FiveM-NUI lädt index.html über nui://<resource>/web/dist/index.html.
// base: './' ist daher PFLICHT, damit Asset-Pfade relativ aufgelöst werden.
export default defineConfig({
  plugins: [react(), tailwindcss()],
  base: './',
  build: {
    outDir: 'dist',
    emptyOutDir: true,
    // Fonts/Webfonts bleiben separate Dateien in dist/assets (relativ referenziert,
    // ebenfalls offline-tauglich) -> hält die CSS klein. Nur sehr kleine Assets inlinen.
    assetsInlineLimit: 4096,
    chunkSizeWarningLimit: 5000,
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].js',
        chunkFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name].[ext]',
        manualChunks: undefined, // kein Code-Splitting -> Single-Bundle
      },
    },
  },
})
