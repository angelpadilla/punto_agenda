import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["panel", "dateLabel"]
    static values = { posts: Object }

    connect() {
        this.calendar = null
        this.initWhenReady()
    }

    disconnect() {
        this.calendar = null
    }

    initWhenReady() {
        if (typeof calendarjs === "undefined") {
            setTimeout(() => this.initWhenReady(), 100)
            return
        }
        this.buildCalendar()
    }

    buildCalendar() {
        const today = new Date()
        const todayStr = today.toISOString().split("T")[0]

        const datesWithPosts = Object.keys(this.postsValue).map((date) => ({
            date,
        }))

        this.calendar = calendarjs.Calendar(
            this.element.querySelector("[data-calendar-grid]"),
            {
                type: "inline",
                value: todayStr,
                format: "MM/DD/YYYY",
                data: datesWithPosts,
                onchange: (_self, value) => {
                    this.showPostsForDate(value)
                },
            }
        )

        // Show today's posts on load
        this.showPostsForDate(todayStr)
    }

    showPostsForDate(dateStr) {
        const iso = this.toISODate(dateStr)
        const posts = this.postsValue[iso] || []
        const panel = this.panelTarget
        const label = this.dateLabelTarget

        const [y, m, d] = iso.split("-")
        label.textContent = `${d}/${m}/${y}`

        if (posts.length === 0) {
            panel.innerHTML = `<p class="has-text-grey-light">Sin artículos para esta fecha</p>`
            return
        }

        panel.innerHTML = posts
            .map((post) => {
                const color = this.statusColor(post)
                const badge = post.borrador
                    ? "Borrador"
                    : post.scheduled
                        ? "Programado"
                        : "Publicado"
                return `
                <a href="/admin/posts/${post.id}" class="box p-3 mb-2">
                    <div class="is-flex is-align-items-center is-justify-content-space-between">
                        <strong class="mr-2">${this.escape(post.title)}</strong>
                        <span class="tag is-rounded ${color}">${badge}</span>
                    </div>
                    ${post.publish_at ? `<small class="has-text-grey">Programado: ${this.escape(post.publish_at)}</small>` : ""}
                    ${post.extract ? `<p class="mt-1 has-text-grey-light" style="font-size: 0.85rem;">${this.escape(post.extract)}</p>` : ""}
                </a>`
            })
            .join("")
    }

    // Normalize any date value to YYYY-MM-DD ISO string
    toISODate(value) {
        if (!value) return ""
        // If it's already YYYY-MM-DD
        if (/^\d{4}-\d{2}-\d{2}$/.test(value)) return value
        // Try parsing as Date
        const d = new Date(value)
        if (isNaN(d.getTime())) return value
        return d.toISOString().split("T")[0]
    }

    statusColor(post) {
        if (post.borrador) return "is-warning"
        if (post.scheduled) return "is-info"
        return "is-success"
    }

    escape(str) {
        if (!str) return ""
        const div = document.createElement("div")
        div.textContent = str
        return div.innerHTML
    }
}
