import { Controller } from "@hotwired/stimulus"

// Wraps FullCalendar (loaded via CDN global bundle).
// Expected data attributes on the element:
//   data-calendar-events-url-value  — JSON endpoint (e.g. /events.json)
//   data-calendar-business-hours-value — JSON array of businessHours objects
//   data-calendar-new-event-url-value  — URL for the "new event" button
export default class extends Controller {
    static values = {
        eventsUrl: String,
        businessHours: Array,
        newEventUrl: String,
        slotDuration: Number
    }

    connect() {
        const FC = window.FullCalendar
        if (!FC) {
            console.error("FullCalendar not loaded")
            return
        }

        const businessHours = this.hasBusinessHoursValue ? this.businessHoursValue : false

        const slotMins = this.hasSlotDurationValue ? this.slotDurationValue : 15
        const slotH = String(Math.floor(slotMins / 60)).padStart(2, "0")
        const slotM = String(slotMins % 60).padStart(2, "0")
        const slotDurationStr = `${slotH}:${slotM}:00`

        // Derive slotMinTime / slotMaxTime from businessHours so the grid
        // only shows the relevant hours.
        let slotMinTime = "07:00:00"
        let slotMaxTime = "22:00:00"
        if (businessHours && businessHours.length > 0) {
            const opens = businessHours.map(bh => bh.startTime).filter(Boolean)
            const closes = businessHours.map(bh => bh.endTime).filter(Boolean)
            if (opens.length) {
                const [oh, om] = opens.sort()[0].split(":").map(Number)
                const snapped = Math.floor((oh * 60 + om) / slotMins) * slotMins
                slotMinTime = `${String(Math.floor(snapped / 60)).padStart(2, "0")}:${String(snapped % 60).padStart(2, "0")}:00`
            }
            if (closes.length) {
                const [ch, cm] = closes.sort().reverse()[0].split(":").map(Number)
                const snapped = Math.ceil((ch * 60 + cm) / slotMins) * slotMins
                slotMaxTime = `${String(Math.floor(snapped / 60)).padStart(2, "0")}:${String(snapped % 60).padStart(2, "0")}:00`
            }
        }

        this.calendar = new FC.Calendar(this.element, {
            locale: "es",
            initialView: "timeGridWeek",
            headerToolbar: {
                left: "prev,next today",
                center: "title",
                right: "dayGridMonth,timeGridWeek,timeGridDay"
            },
            buttonText: {
                today: "Hoy",
                month: "Mes",
                week: "Semana",
                day: "Día"
            },
            height: "auto",
            slotMinTime,
            slotMaxTime,
            slotDuration: slotDurationStr,
            now: new Date(), // Ensure "now" is correct even if user's clock is off
            nowIndicator: true,
            allDaySlot: false,
            businessHours,
            slotLabelFormat: { hour: "numeric", minute: "2-digit", omitZeroMinute: true, hour12: true },
            slotLabelContent: (arg) => {
                // e.g. "3 PM" or "3:30 PM"
                const h = arg.date.getHours()
                const m = arg.date.getMinutes()
                const ampm = h >= 12 ? "PM" : "AM"
                const h12 = h % 12 || 12
                const timeStr = m === 0 ? `${h12} ${ampm}` : `${h12}:${String(m).padStart(2, "0")} ${ampm}`
                return { html: timeStr }
            },
            views: {
                dayGridMonth: {},
                timeGridWeek: {
                    dayHeaderFormat: { weekday: "short", day: "numeric" }
                },
                timeGridDay: {
                    dayHeaderFormat: { weekday: "long", day: "numeric", month: "long" }
                }
            },
            // Dim non-business slots visually (FullCalendar built-in)
            // Non-business hours appear shaded automatically when businessHours is set.

            events: (info, successCallback, failureCallback) => {
                const url = new URL(this.eventsUrlValue, window.location.origin)
                url.searchParams.set("start", info.startStr)
                url.searchParams.set("end", info.endStr)

                fetch(url, {
                    headers: {
                        "Accept": "application/json",
                        "X-Requested-With": "XMLHttpRequest"
                    },
                    credentials: "same-origin"
                })
                    .then(r => r.json())
                    .then(successCallback)
                    .catch(failureCallback)
            },

            // Clicking an event opens the detail modal
            eventClick: (info) => {
                info.jsEvent.preventDefault()
                console.log("Clicked event:", info.event)
                const ev = info.event
                const p = ev.extendedProps
                const modal = document.getElementById("calendar-event-modal")

                modal.querySelector("#cem-title").textContent = ev.title

                const statusTag = modal.querySelector("#cem-status")
                const statusClass = p.status === "pendiente" ? "is-warning" :
                    p.status === "completado" ? "is-success" : "is-danger"
                statusTag.className = `tag is-rounded ${statusClass}`
                statusTag.textContent = p.status

                const customerParts = [p.customer, p.customer_tel ? `(${p.customer_tel})` : null].filter(Boolean)
                modal.querySelector("#cem-customer").textContent = customerParts.join(" ")
                modal.querySelector("#cem-agente").textContent = p.agente

                const fmt = { hour: "numeric", minute: "2-digit", hour12: true }
                const dayFmt = { weekday: "long", year: "numeric", month: "long", day: "numeric" }
                const dayStr = ev.start.toLocaleDateString("es-MX", dayFmt)
                const startStr = ev.start.toLocaleTimeString("es-MX", fmt)
                const endStr = ev.end ? ev.end.toLocaleTimeString("es-MX", fmt) : ""
                modal.querySelector("#cem-day").textContent = dayStr
                modal.querySelector("#cem-time").textContent =
                    `${startStr}${endStr ? ` - ${endStr}` : ""}`

                const bodyWrap = modal.querySelector("#cem-body-wrap")
                bodyWrap.hidden = !p.body
                if (p.body) modal.querySelector("#cem-body").textContent = p.body

                const isPending = p.status === "pendiente"
                const asistenciaBtn = modal.querySelector("#cem-asistencia")
                const ausenciaBtn = modal.querySelector("#cem-ausencia")
                // const editBtn = modal.querySelector("#cem-edit")
                const showBtn = modal.querySelector("#cem-show")
                showBtn.href = p.show_url
                asistenciaBtn.href = p.marcar_asistencia_url
                asistenciaBtn.style.display = isPending ? "flex" : "none"
                ausenciaBtn.href = p.marcar_ausencia_url
                ausenciaBtn.style.display = isPending ? "flex" : "none"
                // editBtn.href = p.edit_url
                // editBtn.style.display = isPending ? "flex" : "none"


                modal.classList.add("is-active")
            },

            // Color coding by status class
            eventDidMount: (info) => {
                const status = info.event.extendedProps.status
                if (status === "pendiente") info.el.style.borderLeft = "4px solid #f5a623"
                if (status === "completado") info.el.style.borderLeft = "4px solid #23d160"
                if (status === "cancelado") info.el.style.borderLeft = "4px solid #ff3860"
            },

            dateClick: (info) => {
                // console.log("Clicked date:", info.dateStr)
                // Extract YYYY-MM-DD (ISO format; keeps JS Date parsing valid)
                const dateStr = info.dateStr.slice(0, 10)
                const hour = info.date.getHours()
                const minute = info.date.getMinutes()
                const timeStr = `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`
                const url = new URL(this.newEventUrlValue, window.location.origin)
                url.searchParams.set("dia", dateStr)
                url.searchParams.set("hora_inicio", timeStr)
                window.location.href = url.toString()
            }
        })

        this.calendar.render()
    }

    disconnect() {
        this.calendar?.destroy()
    }
}
