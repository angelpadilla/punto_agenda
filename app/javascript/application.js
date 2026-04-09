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



    var modal_backgrounds = document.querySelectorAll(".modal-background");
    var modal_closes = document.querySelectorAll(".modal-close");
    var modal_closes2 = document.querySelectorAll(".delete");

    var triggers = document.querySelectorAll(".mtrigger");

    if (triggers) {
        triggers.forEach((el) => {
            el.addEventListener("click", () => {
                const target = el.dataset.target;
                const $target = document.getElementById(target);

                $target.classList.add("is-active");
            });
        });
    }

    if (modal_backgrounds) {
        modal_backgrounds.forEach((el) => {
            el.addEventListener("click", (e) => {
                el.parentElement.classList.remove("is-active");
            });
        });
    }

    if (modal_closes) {
        modal_closes.forEach((el) => {
            el.addEventListener("click", (e) => {
                console.log(el.parentElement);
                el.parentElement.classList.remove("is-active");
            });
        });
    }

    if (modal_closes2) {
        modal_closes2.forEach((el) => {
            el.addEventListener("click", (e) => {
                const parent = el.parentElement.parentElement.parentElement;
                console.log(parent);
                parent.classList.remove("is-active");
            });
        });
    }

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