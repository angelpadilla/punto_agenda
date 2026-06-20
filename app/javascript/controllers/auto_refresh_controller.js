import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = { interval: { type: Number, default: 30 } }

    connect() {
        this._timer = setInterval(() => {
            // Turbo.visit con action: "replace" evita saturar el historial
            Turbo.visit(window.location.href, { action: "replace" })
        }, this.intervalValue * 1000)
    }

    disconnect() {
        // ⭐ Seguridad: limpia el timer cuando Turbo reemplaza el DOM
        // Stimulus llama disconnect() automáticamente al desmontar el elemento
        if (this._timer) {
            clearInterval(this._timer)
            this._timer = null
        }
    }
}