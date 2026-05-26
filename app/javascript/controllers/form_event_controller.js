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
    static targets = ["diaHidden", "diaDisplay", "slotSelect", "userSelect"]
    static values = { businessHours: Object, currentSlot: String, availabilityUrl: String }

    connect() {
        this._availability = {}
        this._initDatepicker()

        if (this.diaHiddenTarget.value) {
            this._applyBusinessHoursForDate(this.diaHiddenTarget.value)
            this._fetchAvailability(this.diaHiddenTarget.value, this.currentSlotValue || null)
        }
    }

    disconnect() {
        if (this._dp) {
            this._dp.destroy()
            this._dp = null
        }
    }

    slotChanged() {
        this._applyAgentFilter(this.slotSelectTarget.value)
    }

    // ── private ──────────────────────────────────────────────────────────────

    _initDatepicker() {
        const bh = this.businessHoursValue

        const disabledDays = Object.entries(bh)
            .filter(([, cfg]) => !cfg.active)
            .map(([wday]) => Number(wday))

        const existingDate = this.diaHiddenTarget.value
            ? new Date(this.diaHiddenTarget.value + "T00:00:00")
            : null

        this._dp = new AirDatepicker(this.diaDisplayTarget, {
            locale: localeEs,
            dateFormat: "dd/MM/yyyy",
            minDate: new Date(),
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
                    this._availability = {}
                    this._applyAgentFilter(null)
                    return
                }
                const yyyy = date.getFullYear()
                const mm = String(date.getMonth() + 1).padStart(2, "0")
                const dd = String(date.getDate()).padStart(2, "0")
                const iso = `${yyyy}-${mm}-${dd}`
                this.diaHiddenTarget.value = iso
                this._applyBusinessHoursForDate(iso)
                this._fetchAvailability(iso, null)
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

        const slots = cfg.hours.map(h => ({
            label: `${h.open} – ${h.close}`,
            value: `${h.open}|${h.close}`
        }))

        const preselect = this.currentSlotValue || ""
        this._rebuildSlotSelect(slots, preselect)
    }

    _fetchAvailability(isoDate, applySlot) {
        if (!this.hasAvailabilityUrlValue) return
        const url = `${this.availabilityUrlValue}?dia=${isoDate}`
        fetch(url, { headers: { Accept: "application/json" } })
            .then(r => r.json())
            .then(data => {
                this._availability = data  // { "09:00|11:00": [1, 3], ... }
                if (applySlot) this._applyAgentFilter(applySlot)
            })
            .catch(() => { this._availability = {} })
    }

    _applyAgentFilter(slotRange) {
        if (!this.hasUserSelectTarget) return
        const bookedIds = (slotRange && this._availability[slotRange]) ? this._availability[slotRange] : []
        const select = this.userSelectTarget
        const slim = select._slimInstance

        if (slim) {
            const currentSelected = slim.getSelected()
            const data = Array.from(select.options).map(opt => {
                const item = { text: opt.text, value: opt.value }
                if (!opt.value) item.placeholder = true
                else item.disabled = bookedIds.includes(Number(opt.value))
                return item
            })
            slim.setData(data)
            if (currentSelected.length && !bookedIds.includes(Number(currentSelected[0]))) {
                slim.setSelected(currentSelected)
            }
        } else {
            Array.from(select.options).forEach(opt => {
                if (!opt.value) return
                opt.disabled = bookedIds.includes(Number(opt.value))
            })
        }
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

