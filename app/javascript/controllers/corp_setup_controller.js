import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = [
        "step", "progressBar", "progressText",
        "nextBtn", "prevBtn",
        "calendarCheck", "slotDuration", "hoursContainer", "form",
        "onlinePaymentsCheck", "publicCalendarCheck"
    ]

    connect() {
        this._current = 0

        // If the form was re-rendered with validation errors, jump to the first step that has them
        const errorStep = this.stepTargets.findIndex(el =>
            el.querySelector(".is-danger, .select-is-danger, .help.is-danger")
        )
        this._showStep(errorStep >= 0 ? errorStep : 0)

        this.toggleMinBookAmount()
    }

    // ── Wizard navigation ────────────────────────────────────────────

    next() {
        const hasCalendar = this.hasCalendarCheckTarget && this.calendarCheckTarget.checked
        const isLast = this._current === 2 || (this._current === 1 && !hasCalendar)

        if (isLast) {
            if (!this._validateAllHourRanges()) {
                alert("Hay rangos de horario inválidos o solapados. Revisa los campos marcados en rojo/naranja antes de guardar.")
                return
            }
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

        const container = this._containerFor(wday)
        if (container) {
            container.querySelectorAll("select, button").forEach(el => el.disabled = !active)
        }

        this.element.querySelectorAll(`[data-action*="addHour"][data-corp-setup-wday-param="${wday}"]`)
            .forEach(btn => btn.disabled = !active)
    }

    toggleMinBookAmount() {
        const show = this.onlinePaymentsCheckTarget.checked && this.publicCalendarCheckTarget.checked
        const minBookContainer = document.querySelector(".minBookAmountContainer")
        if (minBookContainer) minBookContainer.style.display = show ? "" : "none"
    }

    addHour(event) {
        const wday = String(event.params.wday)
        const container = this._containerFor(wday)
        if (!container) return

        const ranges = container.querySelectorAll(".hour-range")
        const newIdx = ranges.length

        const lastCloseSel = ranges[ranges.length - 1]?.querySelector(`select[name*="[close]"]`)
        const openVal = lastCloseSel?.value || "09:00"
        const closeVal = this._addMinutes(openVal, 60)
        const isActive = !(lastCloseSel?.disabled ?? false)

        container.appendChild(this._buildRangeDiv(wday, newIdx, openVal, closeVal, isActive))
    }

    removeHour(event) {
        const wday = String(event.params.wday)
        const container = this._containerFor(wday)
        if (!container) return

        const rangeDiv = event.currentTarget.closest(".hour-range")
        if (!rangeDiv) return
        rangeDiv.remove()

        container.querySelectorAll(".hour-range").forEach((div, newIdx) => {
            div.dataset.index = newIdx
            div.querySelectorAll("select").forEach(sel => {
                sel.name = sel.name.replace(/\[hours\]\[\d+\]/, `[hours][${newIdx}]`)
            })
            const removeBtn = div.querySelector("[data-corp-setup-index-param]")
            if (removeBtn) removeBtn.dataset.corpSetupIndexParam = newIdx
        })
    }

    validateHourRange(event) {
        const wday = String(event.params.wday)
        const container = this._containerFor(wday)
        if (!container) return
        this._validateContainer(container)
    }

    _validateAllHourRanges() {
        let valid = true
        this.hoursContainerTargets.forEach(container => {
            if (!this._validateContainer(container)) valid = false
        })
        return valid
    }

    _validateContainer(container) {
        let valid = true
        let prevCloseMins = null
        container.querySelectorAll(".hour-range").forEach(rangeDiv => {
            const openSel = rangeDiv.querySelector(`select[name*="[open]"]`)
            const closeSel = rangeDiv.querySelector(`select[name*="[close]"]`)
            if (!openSel || !closeSel) return

            const openMins = this._timeToMinutes(openSel.value)
            const closeMins = this._timeToMinutes(closeSel.value)

            const closeOk = closeMins > openMins
            closeSel.style.outline = closeOk ? "" : "2px solid red"
            if (!closeOk) valid = false

            if (prevCloseMins !== null) {
                const gapOk = openMins >= prevCloseMins
                openSel.style.outline = gapOk ? "" : "2px solid orange"
                if (!gapOk) valid = false
            } else {
                openSel.style.outline = ""
            }
            prevCloseMins = closeMins
        })
        return valid
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

    _containerFor(wday) {
        return this.hoursContainerTargets.find(el => el.dataset.wday === wday)
    }

    _timeToMinutes(timeStr) {
        const [h, m] = (timeStr || "00:00").split(":").map(Number)
        return h * 60 + m
    }

    _addMinutes(timeStr, minutes) {
        const total = this._timeToMinutes(timeStr) + minutes
        const capped = Math.min(total, 23 * 60 + 45)
        return `${String(Math.floor(capped / 60)).padStart(2, "0")}:${String(capped % 60).padStart(2, "0")}`
    }

    _generateTimeOptions() {
        const opts = []
        for (let h = 0; h < 24; h++) {
            for (const m of [0, 15, 30, 45]) {
                opts.push(`${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`)
            }
        }
        return opts
    }

    _buildRangeDiv(wday, idx, openVal, closeVal, isActive) {
        const times = this._generateTimeOptions()
        const openOpts = times.map(t => `<option value="${t}"${t === openVal ? " selected" : ""}>${t}</option>`).join("")
        const closeOpts = times.map(t => `<option value="${t}"${t === closeVal ? " selected" : ""}>${t}</option>`).join("")
        const disAttr = isActive ? "" : " disabled"
        const actionAttr = `data-action="change->corp-setup#validateHourRange" data-corp-setup-wday-param="${wday}"`

        const removeBtn = idx > 0
            ? `<button type="button" class="button is-small is-danger is-light ml-1"
                       data-action="corp-setup#removeHour"
                       data-corp-setup-wday-param="${wday}"
                       data-corp-setup-index-param="${idx}"${disAttr}>✕</button>`
            : ""

        const div = document.createElement("div")
        div.className = "hour-range is-flex is-align-items-center mb-1"
        div.dataset.wday = wday
        div.dataset.index = idx
        div.innerHTML = `
            <div class="select is-small mr-1">
              <select name="corp[business_hours][${wday}][hours][${idx}][open]" class="select-time" ${actionAttr}${disAttr}>${openOpts}</select>
            </div>
            <span class="mx-1">–</span>
            <div class="select is-small mr-1">
              <select name="corp[business_hours][${wday}][hours][${idx}][close]" class="select-time" ${actionAttr}${disAttr}>${closeOpts}</select>
            </div>
            ${removeBtn}
        `
        return div
    }
}

