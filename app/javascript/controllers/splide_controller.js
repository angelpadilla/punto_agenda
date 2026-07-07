import { Controller } from "@hotwired/stimulus";
import Splide from "@splidejs/splide";

// Generic Splide controller — attach to a .splide element (simple carousel)
// or to a wrapper that contains child .splide elements (synced main + thumbnail).
//
// Data attributes (all optional, on the element with data-controller="splide"):
//   data-splide-type="fade|slide|loop"     (default: "slide")
//   data-splide-per-page="3"               (default: 1)
//   data-splide-gap="1rem"                 (default: "0")
//   data-splide-arrows="false"             (default: true)
//   data-splide-pagination="false"         (default: true)
//   data-splide-rewind="true"              (default: false)
//   data-splide-autoplay="true"            (default: false)
//   data-splide-interval="5000"            (autoplay ms, default: 3000)
//   data-splide-fixed-width="200"          (optional)
//   data-splide-fixed-height="300"         (optional)
//   data-splide-click-to-go="true"          (click any slide → navigate to it)

export default class extends Controller {
    connect() {
        if (this.element.classList.contains("splide")) {
            // ── Simple: controller is on the .splide element itself ──
            this.instance = new Splide(this.element, this._mainOptions());
            this.instance.mount();
            this._registerClickToGo(this.instance);
        } else {
            // ── Wrapper: find child .splide elements ──
            const mainEl =
                this.element.querySelector(".splide:not(.splide_thumbnail_carousel)");
            const thumbEl = this.element.querySelector(
                ".splide_thumbnail_carousel"
            );

            if (mainEl) {
                this.main = new Splide(mainEl, this._mainOptions());
                this.main.mount();
                this._registerClickToGo(this.main);
            }

            if (thumbEl) {
                this.thumb = new Splide(thumbEl, {
                    fixedWidth: 100,
                    gap: 10,
                    rewind: true,
                    pagination: false,
                    arrows: false,
                    isNavigation: true,
                    breakpoints: { 600: { fixedWidth: 60 } },
                });
                this.thumb.mount();
                if (this.main) this.main.sync(this.thumb);
            }
        }
    }

    disconnect() {
        this.instance?.destroy();
        this.main?.destroy();
        this.thumb?.destroy();
    }

    // ── public actions (for custom prev/next buttons) ──

    prev() {
        const splide = this.instance || this.main;
        if (splide) splide.go("<");
    }

    next() {
        const splide = this.instance || this.main;
        if (splide) splide.go(">");
    }

    // ── private helpers ──

    _mainOptions() {
        const d = this.element.dataset;
        const opts = {
            type: d.splideType || "slide",
            perPage: this._int(d.splidePerPage, 1),
            gap: d.splideGap || "0",
            arrows: this._bool(d.splideArrows, true),
            pagination: this._bool(d.splidePagination, true),
            rewind: this._bool(d.splideRewind, false),
            focus: "center",
            snap: true,
            pauseOnHover: true,
            lazyLoad: "nearby",
        };

        if (this._bool(d.splideAutoplay, false)) {
            opts.autoplay = {
                interval: this._int(d.splideInterval, 3000),
                pauseOnHover: true,
            };
        }

        const fw = this._int(d.splideFixedWidth, 0);
        if (fw > 0) opts.fixedWidth = fw;
        const fh = this._int(d.splideFixedHeight, 0);
        if (fh > 0) opts.fixedHeight = fh;

        return opts;
    }

    _bool(value, fallback) {
        if (value === undefined || value === null) return fallback;
        return value === "true" || value === "";
    }

    _int(value, fallback) {
        const n = parseInt(value, 10);
        return Number.isNaN(n) ? fallback : n;
    }

    _registerClickToGo(splide) {
        if (this._bool(this.element.dataset.splideClickToGo, false)) {
            splide.on("click", (slide) => {
                splide.go(slide.index);
            });
        }
    }
}