import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        console.log("side_nav_controller connected");
        this.blur = this.element.querySelector(".blur_for_nav");
        this.sideNavLauncher = this.element.querySelector(".side_nav_launcher");
        this.glassNav = this.element.querySelector(".glass_nav");

        this.close();
    }

    toggle() {
        const isOpen = !this.blur.classList.contains("is_active");

        this.blur.classList.toggle("is_active", isOpen);
        this.sideNavLauncher.classList.toggle("is_active", isOpen);
        this.glassNav.classList.toggle("is_active", isOpen);
        document.body.classList.toggle("nav-open", isOpen);
        document.documentElement.classList.toggle("nav-open", isOpen);
    }

    close() {
        this.blur.classList.remove("is_active");
        this.sideNavLauncher.classList.remove("is_active");
        this.glassNav.classList.remove("is_active");
        document.body.classList.remove("nav-open");
        document.documentElement.classList.remove("nav-open");
    }

    disconnect() {
        this.close();
    }


}
