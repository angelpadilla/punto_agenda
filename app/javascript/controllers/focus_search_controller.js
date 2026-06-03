import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["inputt"]

    connect() {
        this._keydownHandler = this._onKeydown.bind(this)
        this._submitHandler = this._onSubmit.bind(this)
        document.addEventListener("keydown", this._keydownHandler)
        console.log(this.inputtTarget)

        const form = this.inputtTarget.closest("form")
        if (form) form.addEventListener("submit", this._submitHandler)
    }

    disconnect() {
        document.removeEventListener("keydown", this._keydownHandler)

        const form = this.inputtTarget.closest("form")
        if (form) form.removeEventListener("submit", this._submitHandler)
    }

    _onSubmit() {
        // After Turbo renders the response, clear the input and keep focus
        const clear = () => {
            const input = document.querySelector("[data-focus-search-target='inputt']")
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

        const input = this.inputtTarget
        if (!input) return

        // Don't redirect if the user is already typing in an input/textarea/select
        const active = document.activeElement
        if (active && (active.tagName === "INPUT" || active.tagName === "TEXTAREA" || active.tagName === "SELECT")) return

        input.focus()
        // Let the keystroke land naturally in the input
    }
}
