import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["fields"]

    toggle(event) {
        this.fieldsTarget.style.display = event.target.checked ? "block" : "none"
    }
}
