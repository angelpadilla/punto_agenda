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
    static targets = ["diaHidden", "diaDisplay", "inicioHora", "finalHora"]
    static values = { businessHours: Object, slotDuration: Number }

    connect() {
        this._initDatepicker()

        // If editing an existing event, pre-filter the time selects
        if (this.diaHiddenTarget.value) {
            this._applyBusinessHoursForDate(this.diaHiddenTarget.value)
            if (this.inicioHoraTarget.value) {
                this._restrictFinalHora(this.inicioHoraTarget.value)
            }
        }
    }

    disconnect() {
        if (this._dp) {
            this._dp.destroy()
            this._dp = null
        }
    }

    inicioChanged() {
        const selected = this.inicioHoraTarget.value
        if (!selected) return
        this._restrictFinalHora(selected)
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
                    this._resetHours()
                    return
                }
                const yyyy = date.getFullYear()
                const mm = String(date.getMonth() + 1).padStart(2, "0")
                const dd = String(date.getDate()).padStart(2, "0")
                const iso = `${yyyy}-${mm}-${dd}`
                this.diaHiddenTarget.value = iso
                this._applyBusinessHoursForDate(iso)
                // Reset final when date changes
                this.finalHoraTarget.value = ""
            }
        })
    }

    _applyBusinessHoursForDate(isoDate) {
        const wday = new Date(isoDate + "T00:00:00").getDay().toString()
        const cfg = this.businessHoursValue[wday]
        if (!cfg || !cfg.active) return

        const slotMins = this.slotDurationValue || 15
        const openMins = this._toMinutes(cfg.open)
        const closeMins = this._toMinutes(cfg.close)

        // Generate slots anchored at the business open time (not midnight).
        // e.g. open=9:30, slot=3hr → inicio slots: [9:30], final slots: [12:30]
        const inicioSlots = []
        for (let t = openMins; t < closeMins; t += slotMins) {
            inicioSlots.push(this._minutesToTimeStr(t))
        }

        const finalSlots = []
        for (let t = openMins + slotMins; t <= closeMins; t += slotMins) {
            finalSlots.push(this._minutesToTimeStr(t))
        }
        // Always include the close time in final options
        const closeStr = this._minutesToTimeStr(closeMins)
        if (!finalSlots.includes(closeStr)) {
            finalSlots.push(closeStr)
            finalSlots.sort((a, b) => this._toMinutes(this._to24h(a)) - this._toMinutes(this._to24h(b)))
        }

        this._availableHoras = inicioSlots
        this._availableHorasFinal = finalSlots

        const prevInicio = this.inicioHoraTarget.value
        const prevFinal = this.finalHoraTarget.value
        this._rebuildSelect(this.inicioHoraTarget, inicioSlots, prevInicio)
        this._rebuildSelect(this.finalHoraTarget, finalSlots, prevFinal)
    }

    _restrictFinalHora(inicioVal) {
        const inicioMins = this._toMinutes(this._to24h(inicioVal))
        const source = this._availableHorasFinal || this._generateHoras()
        const filtered = source.filter(h => this._toMinutes(this._to24h(h)) > inicioMins)
        this._rebuildSelect(this.finalHoraTarget, filtered, this.finalHoraTarget.value)
    }

    _resetHours() {
        const allHoras = this._generateHoras()
        this._availableHoras = null
        this._availableHorasFinal = null
        this._rebuildSelect(this.inicioHoraTarget, allHoras, "")
        this._rebuildSelect(this.finalHoraTarget, allHoras, "")
    }

    // Generates hours matching Ruby Time#strftime("%I:%M %p"): "12:00 AM" … "11:45 PM"
    // Step is determined by corp.slot_duration (minutes).
    _generateHoras() {
        const step = this.slotDurationValue || 15
        const horas = []
        for (let totalMin = 0; totalMin < 24 * 60; totalMin += step) {
            const h = Math.floor(totalMin / 60)
            const m = totalMin % 60
            const period = h < 12 ? "AM" : "PM"
            const h12 = h % 12 === 0 ? 12 : h % 12
            horas.push(`${String(h12).padStart(2, "0")}:${String(m).padStart(2, "0")} ${period}`)
        }
        return horas
    }

    // "09:00 AM" → "09:00",  "01:00 PM" → "13:00"
    _to24h(timeStr) {
        const [time, period] = timeStr.split(" ")
        let [h, m] = time.split(":").map(Number)
        if (period === "PM" && h !== 12) h += 12
        if (period === "AM" && h === 12) h = 0
        return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`
    }

    // "09:30" → 570
    _toMinutes(hhmm) {
        const [h, m] = hhmm.split(":").map(Number)
        return h * 60 + m
    }

    // 750 → "12:30 PM"
    _minutesToTimeStr(totalMins) {
        const h = Math.floor(totalMins / 60)
        const m = totalMins % 60
        const period = h < 12 ? "AM" : "PM"
        const h12 = h % 12 === 0 ? 12 : h % 12
        return `${String(h12).padStart(2, "0")}:${String(m).padStart(2, "0")} ${period}`
    }

    _rebuildSelect(select, options, selected) {
        const prompt = select.querySelector('option[value=""]')
        const promptText = prompt ? prompt.textContent : "Selecciona hora"
        select.innerHTML = `<option value="">${promptText}</option>`
        options.forEach(h => {
            const opt = document.createElement("option")
            opt.value = h
            opt.textContent = h
            if (h === selected) opt.selected = true
            select.appendChild(opt)
        })
    }
}
