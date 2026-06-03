import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this._keydownHandler = this._onKeydown.bind(this)
        this._submitHandler = this._onSubmit.bind(this)
        document.addEventListener("keydown", this._keydownHandler)

        const form = document.getElementById("q_name_or_sku_cont")?.closest("form")
        if (form) form.addEventListener("submit", this._submitHandler)
    }

    disconnect() {
        document.removeEventListener("keydown", this._keydownHandler)

        const form = document.getElementById("q_name_or_sku_cont")?.closest("form")
        if (form) form.removeEventListener("submit", this._submitHandler)
    }

    _onSubmit() {
        // After Turbo renders the response, clear the input and keep focus
        const clear = () => {
            const input = document.getElementById("q_name_or_sku_cont")
            if (input) {
                input.value = ""
                input.focus()
            }
            document.removeEventListener("turbo:render", clear)
        }
        document.addEventListener("turbo:render", clear)
    }

    _onKeydown(event) {
        // Ignore modifier-only keys, function keys, and special keys
        if (
            event.metaKey || event.ctrlKey || event.altKey ||
            event.key === "Tab" || event.key === "Enter" || event.key === "Escape" ||
            event.key.startsWith("F") && event.key.length > 1 ||
            event.key === "Shift" || event.key === "CapsLock" ||
            event.key === "ArrowUp" || event.key === "ArrowDown" ||
            event.key === "ArrowLeft" || event.key === "ArrowRight"
        ) return

        const input = document.getElementById("q_name_or_sku_cont")
        if (!input) return

        // Don't redirect if the user is already typing in an input/textarea/select
        const active = document.activeElement
        if (active && (active.tagName === "INPUT" || active.tagName === "TEXTAREA" || active.tagName === "SELECT")) return

        input.focus()
        // Let the keystroke land naturally in the input
    }
}
