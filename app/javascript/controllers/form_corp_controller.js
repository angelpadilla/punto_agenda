import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["selects", "businessHoursContainer", "calendarcheck"]

    connect() {
        // Apply close-time filtering for all rows on page load
        this._wdays().forEach(wday => this._syncCloseOptions(wday))
        this.setBussinessHours()
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

    _syncCloseOptions(wday) {
        const divs = this.selectsTargets.filter(el => el.dataset.wday === wday)
        const openDiv = divs.find(el => el.dataset.type === "open")
        const closeDiv = divs.find(el => el.dataset.type === "close")
        if (!openDiv || !closeDiv) return

        const openSelect = openDiv.querySelector("select")
        const closeSelect = closeDiv.querySelector("select")
        if (!openSelect || !closeSelect) return

        const openTime = openSelect.value

        // Disable options in close that are <= open time
        Array.from(closeSelect.options).forEach(opt => {
            opt.disabled = opt.value <= openTime
        })

        // If current close value is now invalid, advance to first valid option
        if (closeSelect.value <= openTime) {
            const firstValid = Array.from(closeSelect.options).find(o => o.value > openTime)
            if (firstValid) closeSelect.value = firstValid.value
        }
    }
}
