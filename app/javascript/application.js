// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"


document.addEventListener("turbo:load", (e) => {

    const toggleBoxes = document.querySelectorAll(".box.expandable .box_header");

    toggleBoxes.forEach((header) => {
        header.addEventListener("click", () => {
            const box = header.parentElement;
            const content = header.nextElementSibling;
            const icon = header.querySelector(".toggle_icon");

            box.classList.toggle("is_active");

            // if (box.classList.contains("is_active")) {
            //     // content.style.height = 0;
            //     box.classList.remove("is_active");
            //     // icon.style.transform = "rotate(0deg)";
            // } else {
            //     // content.style.height = content.scrollHeight + "px";
            //     box.classList.add("is_active");
            //     // icon.style.transform = "rotate(180deg)";
            // }
        });
    });



    document.addEventListener("click", (e) => {
        // Abrir modal (.mtrigger)
        const trigger = e.target.closest(".mtrigger");
        if (trigger) {
            e.preventDefault();
            const target = trigger.dataset.target;
            const $target = document.getElementById(target);
            if ($target) $target.classList.add("is-active");
        }

        // Cerrar modal al clickear el fondo
        if (e.target.matches(".modal-background")) {
            e.target.parentElement.classList.remove("is-active");
        }

        // Cerrar modal al clickear `.modal-close`
        const modalClose = e.target.closest(".modal-close");
        if (modalClose) {
            modalClose.parentElement.classList.remove("is-active");
        }

        // Cerrar modal al clickear `.delete` dentro del `.modal`
        const deleteBtn = e.target.closest(".modal .delete");
        if (deleteBtn) {
            const modal = deleteBtn.closest(".modal");
            if (modal) modal.classList.remove("is-active");
        }
    });

    // Get all "navbar-burger" elements
    const $navbarBurgers = Array.prototype.slice.call(
        document.querySelectorAll(".navbar-burger"),
        0
    );

    // Add a click event on each of them
    $navbarBurgers.forEach((el) => {
        el.addEventListener("click", () => {
            // Get the target from the "data-target" attribute
            const target = el.dataset.target;
            const $target = document.getElementById(target);

            // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
            el.classList.toggle("is-active");
            $target.classList.toggle("is-active");
        });
    });

    var notice = document.querySelector(".notice");
    var alert = document.querySelector(".alert");

    if (notice) {
        setTimeout(function () {
            notice.style.opacity = 0;
            notice.style.bottom = "-100px";
        }, 3500);

        setTimeout(function () {
            notice.style.display = "none";
        }, 4500);
    }
    if (alert) {
        setTimeout(function () {
            alert.style.opacity = 0;
            alert.style.bottom = "-100px";
        }, 3500);

        setTimeout(function () {
            alert.style.display = "none";
        }, 4500);
    }
});