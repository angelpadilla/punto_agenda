import { Controller } from "@hotwired/stimulus";
import Splide from "@splidejs/splide";

export default class extends Controller {
    connect() {
        const main_splide = new Splide('.splide', {
            type: 'fade',
            rewind: true,
            pagination: false,
            arrows: false,
            // cover: true,
            gap: "10rem",
        });
        const splide_thumbnail = new Splide('.splide_thumbnail_carousel', {
            fixedWidth: 100,
            // fixedHeight: 60,
            gap: 10,
            rewind: true,
            pagination: false,
            isNavigation: true,
            // focus: 'center',
            breakpoints: {
                600: {
                    fixedWidth: 60,
                    // fixedHeight: 44,
                },
            },
        });

        main_splide.sync(splide_thumbnail);
        main_splide.mount();
        splide_thumbnail.mount();
    }

}