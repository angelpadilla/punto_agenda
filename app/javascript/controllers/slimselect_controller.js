import { Controller } from "@hotwired/stimulus";
import SlimSelect from "slim-select";

export default class extends Controller {
    connect() {
        this.selectt = new SlimSelect({
            select: this.element,
            settings: {
                placeholder: null,
                // allowDeselect: false,
                // closeOnSelect: true,
            },
        });
    }
}