import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "step", "progressBar", "progressText",
        "nextBtn", "prevBtn",
        "calendarCheck", "slotDuration", "selects", "form"
    ]

    connect() {
        this._current = 0

        // If the form was re-rendered with validation errors, jump to the first step that has them
        const errorStep = this.stepTargets.findIndex(el =>
            el.querySelector(".is-danger, .select-is-danger, .help.is-danger")
        )
        this._showStep(errorStep >= 0 ? errorStep : 0)

        // Sync business hours close selects on load
        this._wdays().forEach(wday => this._syncCloseOptions(wday))
    }

    // ── Wizard navigation ────────────────────────────────────────────

    next() {
        const hasCalendar = this.hasCalendarCheckTarget && this.calendarCheckTarget.checked
        const isLast = this._current === 2 || (this._current === 1 && !hasCalendar)

        if (isLast) {
            this.formTarget.requestSubmit()
            return
        }
        this._showStep(this._current + 1)
    }

    prev() {
        if (this._current > 0) {
            this._showStep(this._current - 1)
        }
    }

    // Called when the calendar checkbox changes — update button label & progress
    calendarChanged() {
        this._updateProgress(this._current)
        this._updateButtons(this._current)
    }

    // ── Business hours (mirrors form_corp_controller) ─────────────────

    toggle(event) {
        const wday = String(event.params.wday)
        const active = event.target.checked
        this.selectsTargets
            .filter(el => el.dataset.wday === wday)
            .forEach(el => {
                const select = el.querySelector("select")
                if (select) select.disabled = !active
            })
    }

    updateClose(event) {
        const wday = event.target.closest("[data-wday]")?.dataset.wday
        if (wday) this._syncCloseOptions(wday)
    }

    updateAllCloses() {
        this._wdays().forEach(wday => this._syncCloseOptions(wday))
    }

    // ── Doc upload preview ────────────────────────────────────────────

    previewDoc(event) {
        const input = event.target
        const file = input.files[0]
        if (!file) return
        const docInput = input.closest(".doc_input")
        const nameEl = docInput?.querySelector(".doc_file_name")
        const sizeEl = docInput?.querySelector(".doc_file_size")
        if (nameEl) nameEl.textContent = `Archivo: ${file.name}`
        if (sizeEl) sizeEl.textContent = `Tamaño: ${(file.size / 1024).toFixed(2)} KB`
    }

    // ── Private ───────────────────────────────────────────────────────

    _showStep(index) {
        this._current = index
        this.stepTargets.forEach((el, i) => {
            el.style.display = i === index ? "" : "none"
        })
        this._updateProgress(index)
        this._updateButtons(index)
    }

    _totalSteps() {
        const hasCalendar = this.hasCalendarCheckTarget && this.calendarCheckTarget.checked
        return hasCalendar ? 3 : 2
    }

    _updateProgress(index) {
        const total = this._totalSteps()
        const current = index + 1
        const pct = Math.round((current / total) * 100)
        if (this.hasProgressBarTarget) {
            this.progressBarTarget.value = pct
            this.progressBarTarget.max = 100
        }
        if (this.hasProgressTextTarget) {
            this.progressTextTarget.textContent = `Paso ${current} de ${total}`
        }
    }

    _updateButtons(index) {
        const hasCalendar = this.hasCalendarCheckTarget && this.calendarCheckTarget.checked
        const isLast = index === 2 || (index === 1 && !hasCalendar)

        if (this.hasPrevBtnTarget) {
            this.prevBtnTarget.style.display = index === 0 ? "none" : ""
        }
        if (this.hasNextBtnTarget) {
            this.nextBtnTarget.textContent = isLast ? "Guardar y agregar tarjeta →" : "Siguiente →"
        }
    }

    _wdays() {
        return [...new Set(this.selectsTargets.map(el => el.dataset.wday))]
    }

    _getSlotDuration() {
        return this.hasSlotDurationTarget ? (parseInt(this.slotDurationTarget.value) || 15) : 15
    }

    _timeToMinutes(timeStr) {
        const [h, m] = timeStr.split(":").map(Number)
        return h * 60 + m
    }

    _syncCloseOptions(wday) {
        const divs = this.selectsTargets.filter(el => el.dataset.wday === wday)
        const openDiv = divs.find(el => el.dataset.type === "open")
        const closeDiv = divs.find(el => el.dataset.type === "close")
        if (!openDiv || !closeDiv) return

        const openSelect = openDiv.querySelector("select")
        const closeSelect = closeDiv.querySelector("select")
        if (!openSelect || !closeSelect) return

        const openMins = this._timeToMinutes(openSelect.value)
        const slot = this._getSlotDuration()

        Array.from(closeSelect.options).forEach(opt => {
            const diff = this._timeToMinutes(opt.value) - openMins
            const isValid = diff > 0 && diff % slot === 0
            opt.disabled = !isValid
            opt.style.display = isValid ? "" : "none"
        })

        if (closeSelect.options[closeSelect.selectedIndex]?.disabled) {
            const firstValid = Array.from(closeSelect.options).find(o => !o.disabled)
            if (firstValid) closeSelect.value = firstValid.value
        }
    }
}
