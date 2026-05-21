import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["selects", "businessHoursContainer", "calendarcheck", "slotDuration", "onlinePaymentsCheck", "publicCalendarCheck"]

    connect() {
        // Apply close-time filtering for all rows on page load
        this._wdays().forEach(wday => this._syncCloseOptions(wday))
        this.setBussinessHours()
        this.toggleMinBookAmount()
    }

    // Toggled by the "Abierto" checkbox
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

    toggleMinBookAmount() {
        const show = this.onlinePaymentsCheckTarget.checked && this.publicCalendarCheckTarget.checked
        const minBookContainer = document.querySelector(".minBookAmountContainer")
        if (minBookContainer) minBookContainer.style.display = show ? "" : "none"
    }

    setBussinessHours() {
        console.log("toggleBussinessHours", this.calendarcheckTarget.checked)
        if (this.calendarcheckTarget.checked) {
            this.businessHoursContainerTarget.style.display = "block"
        } else {
            this.businessHoursContainerTarget.style.display = "none"
        }
    }

    // Fired when the "Apertura" select changes
    updateClose(event) {
        const wday = event.target.closest("[data-wday]")?.dataset.wday
        if (wday) this._syncCloseOptions(wday)
    }

    // Fired when slot_duration changes — re-sync all days
    updateAllCloses() {
        this._wdays().forEach(wday => this._syncCloseOptions(wday))
    }

    previewDoc(event) {
        const input = event.target;
        const file = input.files[0];

        console.log(file)

        if (file) {
            const docInput = input.closest('.doc_input');
            const fileName = file.name;
            const fileSize = (file.size / 1024).toFixed(2) + " KB";


            const fileNameContainer = docInput?.querySelector('.doc_file_name');
            if (fileNameContainer) {
                fileNameContainer.textContent = `Archivo: ${fileName}`;
            }

            const fileSizeContainer = docInput?.querySelector('.doc_file_size');
            if (fileSizeContainer) {
                fileSizeContainer.textContent = `Tamaño: ${fileSize}`;
            }
        }
    }

    // --- private ---

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

        // Show only options that are a positive multiple of slot_duration after open time
        Array.from(closeSelect.options).forEach(opt => {
            const diff = this._timeToMinutes(opt.value) - openMins
            const isValid = diff > 0 && diff % slot === 0
            opt.disabled = !isValid
            opt.style.display = isValid ? "" : "none"
        })

        // If current close value is now invalid, pick the first valid option
        if (closeSelect.options[closeSelect.selectedIndex]?.disabled) {
            const firstValid = Array.from(closeSelect.options).find(o => !o.disabled)
            if (firstValid) closeSelect.value = firstValid.value
        }
    }
}
