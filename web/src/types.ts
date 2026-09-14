// NUI-Verträge — exakt gespiegelt aus modules/*/client.lua. NICHT ändern.

export interface NotifyType {
  icon: string // FontAwesome-Klassen-String, z.B. "fas fa-info-circle"
  color: string // Hex-Farbe
}

export interface NotifyMessage {
  action: 'notify'
  id?: string // gleiche id aktualisiert eine sichtbare Notification statt zu stapeln
  title?: string // optional, ohne Titel wird die Notification kompakt
  message: string
  type: NotifyType
  time: number
  icon?: string // überschreibt das Icon des Typs
  iconColor?: string
  iconAnimation?: string // spin, spinPulse, spinReverse, beat, beatFade, bounce, fade, flip, shake
  position?: NotifyPosition // greift nur, wenn der Spieler "Automatisch" gewählt hat
  showDuration?: boolean // false blendet den Fortschrittsbalken aus
  sound?: boolean // false = kein NUI-Sound (z. B. weil Lua einen GTA-Sound spielt)
}

export interface OpenInputMessage {
  action: 'openInput'
  header: string
  placeholder: string
  field: boolean // true => Textarea (mehrzeilig)
}

export interface CloseInputMessage {
  action: 'closeInput'
}

export interface ProgressStartMessage {
  action: 'progressBarStart'
  id?: number // Durchlauf-id aus Lua, kommt mit progressEnd zurück
  time: number
  text: string
  color: string
  position?: 'middle' | 'bottom' // Standard beim Balken: bottom
}

export interface ProgressStopMessage {
  action: 'progressBarStop'
}

// Der Code selbst geht NIE an die NUI: sie kennt nur die Länge und schickt die
// eingetippten Ziffern an Lua, verglichen wird in Lua bzw. auf dem Server.
export interface OpenNumpadMessage {
  action: 'openNumpad'
  id: number // Sitzung, kommt mit submitNumpad zurück
  mode: 'code' | 'input' // code = feste Länge und Prüfung, input = bis zu length Ziffern
  length: number
  masked: boolean
  title?: string
  labels: { enter: string; wrong: string; attempts: string }
}

// Antwort von Lua auf submitNumpad
export interface NumpadSubmitResult {
  ok?: boolean
  locked?: boolean
  attemptsLeft?: number
}

export interface CloseNumpadMessage {
  action: 'closeNumpad'
}

export type TextUiPosition = 'bottom-center' | 'top-center' | 'left-center' | 'right-center'

export interface TextUiMessage {
  action: 'textUI'
  show: boolean
  key?: string | false // false = keine Tastenbox
  text?: string
  color?: string
  icon?: string
  iconColor?: string
  iconAnimation?: string // gleiche Werte wie bei Notify
  position?: TextUiPosition // Standard: bottom-center
}

export interface CopyCoordsMessage {
  action: 'copyCoords'
  value: string
}

// ── Context-Menue (Maus-Drilldown) ────────────────────────────────
// Lua normalisiert metadata immer zu dieser Form (auch reine Textlisten).
export interface ContextMetaItem {
  label: string
  value?: string
  progress?: number // 0..100, zeigt einen kleinen Balken unter dem Eintrag
  colorScheme?: string
}

export interface ContextOption {
  index: number
  id?: string
  title: string
  description?: string
  icon?: string
  iconColor?: string
  iconAnimation?: string // gleiche Werte wie bei Notify
  image?: string
  arrow?: boolean
  disabled?: boolean
  readOnly?: boolean
  progress?: number
  colorScheme?: string
  metadata?: ContextMetaItem[] | Record<string, string>
}

export interface OpenContextMessage {
  action: 'openContext'
  id: string
  title: string
  options: ContextOption[]
  canClose: boolean
  position: string
  hasBack: boolean
}

export interface UpdateContextMessage {
  action: 'updateContext'
  options: ContextOption[]
}

export interface CloseContextMessage {
  action: 'closeContext'
}

// ── Menu (Tastatur-navigiert, NativeUI-Stil) ──────────────────────
export interface MenuValue {
  label: string
  description?: string
}

export interface MenuItem {
  index: number
  id?: string
  label: string
  description?: string
  icon?: string
  iconColor?: string
  iconAnimation?: string // gleiche Werte wie bei Notify
  disabled?: boolean
  checked?: boolean
  progress?: number
  colorScheme?: string
  values?: MenuValue[]
  valueIndex?: number
}

export interface OpenMenuMessage {
  action: 'openMenu'
  id: string
  title: string
  position: string
  selected: number
  items: MenuItem[]
}

export interface UpdateMenuMessage {
  action: 'updateMenu'
  selected: number
  items: MenuItem[]
}

export interface CloseMenuMessage {
  action: 'closeMenu'
}

// ── Input-Dialog (mehrere Felder) ─────────────────────────────────
export type InputDialogFieldType =
  | 'input'
  | 'textarea'
  | 'number'
  | 'checkbox'
  | 'select'
  | 'multi-select'
  | 'slider'
  | 'color'
  | 'date'
  | 'date-range'
  | 'time'

export interface InputDialogOption {
  value: string | number
  label: string
}

export interface InputDialogRow {
  index: number
  id?: string
  type: InputDialogFieldType
  label?: string
  description?: string
  placeholder?: string
  icon?: string
  required?: boolean
  disabled?: boolean
  default?: unknown
  min?: number | string // Zahl bei number/slider, 'YYYY-MM-DD' bei date
  max?: number | string
  step?: number
  maxLength?: number
  password?: boolean
  options?: InputDialogOption[]
}

export interface OpenInputDialogMessage {
  action: 'openInputDialog'
  header: string
  rows: InputDialogRow[]
  allowCancel: boolean
  size: 'sm' | 'md' | 'lg'
  labels?: { confirm?: string; cancel?: string }
}

export interface CloseInputDialogMessage {
  action: 'closeInputDialog'
}

// ── Alert-Dialog ──────────────────────────────────────────────────
export interface OpenAlertMessage {
  action: 'openAlert'
  header?: string
  content: string
  size?: 'sm' | 'md' | 'lg'
  centered?: boolean
  cancel?: boolean
  labels?: { confirm?: string; cancel?: string }
}

export interface CloseAlertMessage {
  action: 'closeAlert'
}

// ── Radial-Menü ───────────────────────────────────────────────────
export interface RadialItem {
  index: number
  label: string
  icon?: string
  iconColor?: string
  hasMenu?: boolean
}

export interface OpenRadialMessage {
  action: 'openRadial'
  items: RadialItem[]
  hasBack: boolean
  title?: string
}

export interface CloseRadialMessage {
  action: 'closeRadial'
}

// ── Skillcheck ────────────────────────────────────────────────────
export interface StartSkillcheckMessage {
  action: 'startSkillcheck'
  areaSize: number // Grad
  speed: number // Multiplikator
  key: string // lowercase
  round: number
  rounds: number
}

export interface CancelSkillcheckMessage {
  action: 'cancelSkillcheck'
}

// ── Progress-Kreis ────────────────────────────────────────────────
export interface ProgressCircleStartMessage {
  action: 'progressCircleStart'
  id?: number // Durchlauf-id aus Lua, kommt mit progressEnd zurück
  time: number
  text: string
  color: string
  position: 'middle' | 'bottom'
}

// ── Clipboard + Spieler-Einstellungen ─────────────────────────────
export interface SetClipboardMessage {
  action: 'setClipboard'
  value: string
}

export type NotifyPosition =
  | 'top-left'
  | 'top'
  | 'top-right'
  | 'center-left'
  | 'center-right'
  | 'bottom-left'
  | 'bottom'
  | 'bottom-right'

export interface SettingsMessage {
  action: 'settings'
  notifyPosition: NotifyPosition | '' // '' = Automatisch, das Script entscheidet
  notifySound: boolean
}

export type NuiMessage =
  | OpenInputDialogMessage
  | CloseInputDialogMessage
  | OpenAlertMessage
  | CloseAlertMessage
  | OpenRadialMessage
  | CloseRadialMessage
  | StartSkillcheckMessage
  | CancelSkillcheckMessage
  | ProgressCircleStartMessage
  | SetClipboardMessage
  | SettingsMessage
  | NotifyMessage
  | OpenInputMessage
  | CloseInputMessage
  | ProgressStartMessage
  | ProgressStopMessage
  | OpenNumpadMessage
  | CloseNumpadMessage
  | TextUiMessage
  | CopyCoordsMessage
  | OpenContextMessage
  | UpdateContextMessage
  | CloseContextMessage
  | OpenMenuMessage
  | UpdateMenuMessage
  | CloseMenuMessage
