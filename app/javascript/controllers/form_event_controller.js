import { Controller } from "@hotwired/stimulus"
import AirDatepicker from "air-datepicker"

// Spanish locale for AirDatepicker
const localeEs = {
    days: ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"],
    daysShort: ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"],
    daysMin: ["Do", "Lu", "Ma", "Mi", "Ju", "Vi", "Sá"],
    months: ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"],
    monthsShort: ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"],
    today: "Hoy",
    clear: "Limpiar",
    dateFormat: "dd/MM/yyyy",
    timeFormat: "HH:mm",
    firstDay: 1
}

export default class extends Controller {
    static targets = ["diaHidden", "diaDisplay", "slotSelect"]
    static values = { businessHours: Object, currentSlot: String }

    connect() {
        this._initDatepicker()

        // If editing an existing event, populate slot options for the pre-selected day
        if (this.diaHiddenTarget.value) {
            this._applyBusinessHoursForDate(this.diaHiddenTarget.value)
        }
    }

    disconnect() {
        if (this._dp) {
            this._dp.destroy()
            this._dp = null
        }
    }

    // ── private ──────────────────────────────────────────────────────────────

    _initDatepicker() {
        const bh = this.businessHoursValue

        // Collect disabled weekdays (0=Sun … 6=Sat)
        const disabledDays = Object.entries(bh)
            .filter(([, cfg]) => !cfg.active)
            .map(([wday]) => Number(wday))

        // Pre-select existing date if editing
        const existingDate = this.diaHiddenTarget.value
            ? new Date(this.diaHiddenTarget.value + "T00:00:00")
            : null

        this._dp = new AirDatepicker(this.diaDisplayTarget, {
            locale: localeEs,
            dateFormat: "dd/MM/yyyy",
            selectedDates: existingDate ? [existingDate] : [],
            startDate: existingDate || new Date(),
            onRenderCell: ({ date, cellType }) => {
                if (cellType !== "day") return {}
                const wday = date.getDay()
                if (disabledDays.includes(wday)) {
                    return { disabled: true, classes: "-non-working-" }
                }
                return {}
            },
            onSelect: ({ date }) => {
                if (!date) {
                    this.diaHiddenTarget.value = ""
                    this._clearSlotSelect()
                    return
                }
                const yyyy = date.getFullYear()
                const mm = String(date.getMonth() + 1).padStart(2, "0")
                const dd = String(date.getDate()).padStart(2, "0")
                const iso = `${yyyy}-${mm}-${dd}`
                this.diaHiddenTarget.value = iso
                this._applyBusinessHoursForDate(iso)
            }
        })
    }

    _applyBusinessHoursForDate(isoDate) {
        const wday = new Date(isoDate + "T00:00:00").getDay().toString()
        const cfg = this.businessHoursValue[wday]

        if (!cfg || !cfg.active || !cfg.hours || cfg.hours.length === 0) {
            this._clearSlotSelect()
            return
        }

        // Each entry in hours is a slot: { open: "09:00", close: "11:00" }
        const slots = cfg.hours.map(h => ({
            label: `${h.open} – ${h.close}`,
            value: `${h.open}|${h.close}`
        }))

        // Determine pre-selection: currentSlot value (from editing) or empty
        const preselect = this.currentSlotValue || ""
        this._rebuildSlotSelect(slots, preselect)
    }

    _clearSlotSelect() {
        this.slotSelectTarget.innerHTML = '<option value="">Selecciona primero el día</option>'
    }

    _rebuildSlotSelect(slots, selectedValue) {
        this.slotSelectTarget.innerHTML = '<option value="">Selecciona horario</option>'
        slots.forEach(slot => {
            const opt = document.createElement("option")
            opt.value = slot.value
            opt.textContent = slot.label
            if (slot.value === selectedValue) opt.selected = true
            this.slotSelectTarget.appendChild(opt)
        })
    }
}

