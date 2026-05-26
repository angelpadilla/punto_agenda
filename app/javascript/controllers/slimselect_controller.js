import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

export default class extends Controller {
    connect() {
        const ajaxUrl = this.element.dataset.ajaxUrl;
        const config = {
            select: this.element,
            settings: {
                placeholder: null,
            },
        };

        if (ajaxUrl) {
            config.events = {
                search: (searchValue, _currentData) => {
                    return new Promise((resolve, reject) => {
                        if (searchValue.length < 2) return reject("Escribe al menos 2 caracteres");
                        fetch(`${ajaxUrl}?q=${encodeURIComponent(searchValue)}`, {
                            headers: { Accept: "application/json" },
                        })
                            .then((r) => r.json())
                            .then((data) => resolve(data.map((p) => ({ value: String(p.id), text: p.label }))))
                            .catch(reject);
                    });
                },
            };
        }

        this.selectt = new SlimSelect(config);        // Expose instance on element so other controllers can refresh it
        this.element._slimInstance = this.selectt
    }
}