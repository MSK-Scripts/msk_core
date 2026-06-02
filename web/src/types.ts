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
