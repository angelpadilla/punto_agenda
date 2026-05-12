import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    show(event) {
        const panel = event.params.panel

        // Hide all panels
        document.querySelectorAll(".dash_panel").forEach(p => {
            p.style.display = "none"
        })

        // Deactivate all buttons
        document.querySelectorAll(".dash_tab_btn").forEach(b => {
            b.classList.remove("is_active")
        })

        // Show target panel
        const target = document.getElementById(`panel-${panel}`)
        if (target) target.style.display = ""

        // Activate clicked button
        event.currentTarget.classList.add("is_active")
    }
}
