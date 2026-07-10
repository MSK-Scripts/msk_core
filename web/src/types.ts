// NUI-Verträge — exakt gespiegelt aus modules/*/client.lua. NICHT ändern.

export interface NotifyType {
  icon: string // FontAwesome-Klassen-String, z.B. "fas fa-info-circle"
  color: string // Hex-Farbe
}

export interface NotifyMessage {
  action: 'notify'
  title: string
  message: string
  type: NotifyType
  time: number
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
  time: number
  text: string
  color: string
}

export interface ProgressStopMessage {
  action: 'progressBarStop'
}

export interface OpenNumpadMessage {
  action: 'openNumpad'
  code: string
  length: number
  show: boolean
  EnterCode: string
  WrongCode: string
}

export interface CloseNumpadMessage {
  action: 'closeNumpad'
}

export interface TextUiMessage {
  action: 'textUI'
  show: boolean
  key?: string
  text?: string
  color?: string
}

export interface CopyCoordsMessage {
  action: 'copyCoords'
  value: string
}

// ── Context-Menue (Maus-Drilldown) ────────────────────────────────
export interface ContextMetaItem {
  label: string
  value?: string
}

export interface ContextOption {
  index: number
  id?: string
  title: string
  description?: string
  icon?: string
  iconColor?: string
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

export type NuiMessage =
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
