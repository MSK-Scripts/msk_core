import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'

// Fonts (lokal gebündelt -> offline-tauglich)
import '@fontsource/syne/400.css'
import '@fontsource/syne/600.css'
import '@fontsource/syne/700.css'
import '@fontsource/space-mono/400.css'
import '@fontsource/space-mono/700.css'
import '@fontsource/dm-sans/400.css'
import '@fontsource/dm-sans/500.css'
import '@fontsource/dm-sans/600.css'

// FontAwesome Free (lokal gebündelt)
import '@fortawesome/fontawesome-free/css/all.min.css'

import './index.css'
import App from './App'
import { isEnvBrowser } from './lib/isEnvBrowser'

if (isEnvBrowser()) {
  document.body.classList.add('msk-dev')
}

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
