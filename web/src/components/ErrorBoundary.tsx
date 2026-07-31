import { Component, type ErrorInfo, type ReactNode } from 'react'
import { fetchNui } from '../lib/fetchNui'

/**
 * Isolates ONE NUI component. Every component in App.tsx gets its own boundary,
 * so a crash in, say, the numpad can no longer unmount notifications, textui,
 * progressbar and both menus along with it.
 *
 * Behaviour on a crash:
 *   1. the failed component renders nothing (in browser dev: a small red badge)
 *   2. the error goes to the CEF console and, via the 'nuiError' callback, to
 *      the client console as an msk_core error line
 *   3. the next NUI message remounts the component
 *
 * The message that triggers the recovery is lost: the child is still unmounted
 * while it is dispatched, so its useNuiEvent listener does not exist yet. The
 * component is back for the message after that. That is the price for not
 * re-rendering a broken component in a loop.
 *
 * Recovery only stops when the component crashes MAX_RECOVERIES times in a row
 * inside CRASH_WINDOW_MS, which is a real crash loop. A single bad call every
 * few minutes keeps being recovered: the counter resets as soon as the
 * component has survived longer than that window. Otherwise three unrelated
 * bad calls spread over an evening would kill the component for the rest of
 * the session.
 */

const MAX_RECOVERIES = 3
const CRASH_WINDOW_MS = 30_000

interface Props {
  /** Component name, shows up in the console and in the Lua error line. */
  name: string
  children: ReactNode
}

interface State {
  failed: boolean
}

export default class ErrorBoundary extends Component<Props, State> {
  state: State = { failed: false }

  private recoveries = 0
  private lastCrash = 0
  private listening = false

  static getDerivedStateFromError(): State {
    return { failed: true }
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    const message = error?.message ?? String(error)

    // Survived longer than the window? Then this is a fresh incident, not a
    // loop, and the component earns its recovery attempts back.
    const now = Date.now()
    if (now - this.lastCrash > CRASH_WINDOW_MS) this.recoveries = 0
    this.lastCrash = now

    console.error(
      `[msk_core] NUI component "${this.props.name}" crashed:`,
      error,
      info.componentStack,
    )

    // Report to Lua. Deliberately not gated behind Config.Debug on the Lua side:
    // a dead UI component is an error, not debug noise.
    void fetchNui('nuiError', {
      component: this.props.name,
      message,
      stack: (info.componentStack ?? '').trim().split('\n').slice(0, 6).join('\n'),
      recoveries: this.recoveries,
      final: this.recoveries >= MAX_RECOVERIES,
    }).catch(() => {
      /* the callback may be missing on an older core — never crash the boundary itself */
    })

    this.armRecovery()
  }

  componentWillUnmount() {
    this.disarmRecovery()
  }

  private armRecovery() {
    if (this.listening || this.recoveries >= MAX_RECOVERIES) return
    this.listening = true
    window.addEventListener('message', this.recover)
  }

  private disarmRecovery() {
    if (!this.listening) return
    this.listening = false
    window.removeEventListener('message', this.recover)
  }

  private recover = () => {
    this.disarmRecovery()
    this.recoveries += 1
    this.setState({ failed: false })
  }

  render() {
    if (!this.state.failed) return this.props.children

    // In the game the component simply stays away, an error overlay on top of
    // the running game would be worse than the missing element. In browser dev
    // it has to be visible, otherwise a crash looks like "nothing happened".
    if (import.meta.env.DEV) {
      return (
        <div className="pointer-events-none fixed bottom-[2vh] left-[2vh] rounded-sm border border-notify-error/40 bg-panel/95 px-[1.2vh] py-[0.8vh] font-mono text-[1.4vh] uppercase text-notify-error shadow-msk">
          <i className="fa-solid fa-circle-exclamation" /> {this.props.name} crashed
          {this.recoveries >= MAX_RECOVERIES && ' (final)'}
        </div>
      )
    }

    return null
  }
}
