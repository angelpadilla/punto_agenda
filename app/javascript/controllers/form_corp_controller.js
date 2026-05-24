import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["hoursContainer", "businessHoursContainer", "calendarcheck", "slotDuration", "onlinePaymentsCheck", "publicCalendarCheck"]

    connect() {
        this.setBussinessHours()
        this.toggleMinBookAmount()
        this._boundSubmit = this._onSubmit.bind(this)
        this.element.closest("form")?.addEventListener("submit", this._boundSubmit)
    }

    // Toggled by the "Abierto" checkbox
    toggle(event) {
        const wday = String(event.params.wday)
        const active = event.target.checked

        const container = this._containerFor(wday)
        if (container) {
            container.querySelectorAll("select, button").forEach(el => el.disabled = !active)
        }

        // Enable/disable the "add slot" button for this wday
        this.element.querySelectorAll(`[data-action*="addHour"][data-form-corp-wday-param="${wday}"]`)
            .forEach(btn => btn.disabled = !active)
    }

    toggleMinBookAmount() {
        const show = this.onlinePaymentsCheckTarget.checked && this.publicCalendarCheckTarget.checked
        const minBookContainer = document.querySelector(".minBookAmountContainer")
        if (minBookContainer) minBookContainer.style.display = show ? "" : "none"
    }

    setBussinessHours() {
        if (this.calendarcheckTarget.checked) {
            this.businessHoursContainerTarget.style.display = "block"
        } else {
            this.businessHoursContainerTarget.style.display = "none"
        }
    }

    // ── Submit guard ──────────────────────────────────────────────────────────

    _onSubmit(event) {
        if (!this._validateAllHourRanges()) {
            event.preventDefault()
            event.stopImmediatePropagation()
            alert("Hay rangos de horario inválidos o solapados. Revisa los campos marcados en rojo/naranja antes de guardar.")
        }
    }

    // Returns true if all ranges are valid, false if any error found
    _validateAllHourRanges() {
        let valid = true
        this.hoursContainerTargets.forEach(container => {
            if (!this._validateContainer(container)) valid = false
        })
        return valid
    }

    // Add a new hour-range row for the given wday
    addHour(event) {
        const wday = String(event.params.wday)
        const container = this._containerFor(wday)
        if (!container) return

        const ranges = container.querySelectorAll(".hour-range")
        const newIdx = ranges.length

        // Default open = last range's close; close = open + 1hr (or 23:45 cap)
        const lastCloseSel = ranges[ranges.length - 1]?.querySelector(`select[name*="[close]"]`)
        const openVal = lastCloseSel?.value || "09:00"
        const closeVal = this._addMinutes(openVal, 60)

        const isActive = !(lastCloseSel?.disabled ?? false)

        container.appendChild(this._buildRangeDiv(wday, newIdx, openVal, closeVal, isActive))
    }

    // Remove an hour-range row and re-index remaining
    removeHour(event) {
        const wday = String(event.params.wday)
        const container = this._containerFor(wday)
        if (!container) return

        const rangeDiv = event.currentTarget.closest(".hour-range")
        if (!rangeDiv) return
        rangeDiv.remove()

        // Re-index
        container.querySelectorAll(".hour-range").forEach((div, newIdx) => {
            div.dataset.index = newIdx
            div.querySelectorAll("select").forEach(sel => {
                sel.name = sel.name.replace(/\[hours\]\[\d+\]/, `[hours][${newIdx}]`)
            })
            const removeBtn = div.querySelector("[data-form-corp-index-param]")
            if (removeBtn) removeBtn.dataset.formCorpIndexParam = newIdx
        })
    }

    // Validate close > open for each range in a wday
    validateHourRange(event) {
        const wday = String(event.params.wday)
        const container = this._containerFor(wday)
        if (!container) return
        this._validateContainer(container)
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

    previewDoc(event) {
        const input = event.target
        const file = input.files[0]
        if (file) {
            const docInput = input.closest(".doc_input")
            const fileNameContainer = docInput?.querySelector(".doc_file_name")
            if (fileNameContainer) fileNameContainer.textContent = `Archivo: ${file.name}`
            const fileSizeContainer = docInput?.querySelector(".doc_file_size")
            if (fileSizeContainer) fileSizeContainer.textContent = `Tamaño: ${(file.size / 1024).toFixed(2)} KB`
        }
    }

    // --- private ---

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
        const actionAttr = `data-action="change->form-corp#validateHourRange" data-form-corp-wday-param="${wday}"`

        const removeBtn = idx > 0
            ? `<button type="button" class="button is-small is-danger is-light ml-1"
                       data-action="form-corp#removeHour"
                       data-form-corp-wday-param="${wday}"
                       data-form-corp-index-param="${idx}"${disAttr}>✕</button>`
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

