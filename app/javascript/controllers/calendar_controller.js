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
            if (opens.length) slotMinTime = opens.sort()[0]
            if (closes.length) slotMaxTime = closes.sort().reverse()[0]
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
            nowIndicatorSnap: false, // Snap to slot intervals
            allDaySlot: false,
            businessHours,
            views: {
                dayGridMonth: {
                    // Show business hours in month view as well (shaded)
                    // titleFormat: { year: 'numeric', month: '2-digit', day: '2-digit' }


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

            // Clicking an event navigates to its show URL
            eventClick: (info) => {
                if (info.event.url) {
                    info.jsEvent.preventDefault()
                    window.location.href = info.event.url
                }
            },

            // Color coding by status class
            eventDidMount: (info) => {
                const status = info.event.extendedProps.status
                if (status === "pendiente") info.el.style.borderLeft = "4px solid #f5a623"
                if (status === "completado") info.el.style.borderLeft = "4px solid #23d160"
                if (status === "cancelado") info.el.style.borderLeft = "4px solid #ff3860"
            },

            dateClick: (info) => {
                // Extract DD/MM/YYYY
                const dateStr = info.dateStr.slice(0, 10).split("-").reverse().join("/")
                const url = new URL(this.newEventUrlValue, window.location.origin)
                url.searchParams.set("dia", dateStr)
                window.location.href = url.toString()
            }
        })

        this.calendar.render()
    }

    disconnect() {
        this.calendar?.destroy()
    }
}
