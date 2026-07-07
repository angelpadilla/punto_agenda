import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        this.forma_pago = document.getElementById("purchase_forma_pago");
        this.status_pago = document.getElementById("purchase_status_pago");
        this.deadline = document.getElementById("purchase_deadline");

        this.forma_pago_container = this.forma_pago.parentElement.parentElement;
        this.status_pago_container = this.status_pago.parentElement.parentElement;
        this.deadline_container = this.deadline.parentElement;

        this.checkStatusPago();

        this.status_pago.addEventListener("change", () => this.checkStatusPago());
    }

    checkStatusPago() {
        const credito = this.status_pago.value === "credito";
        this.setDeadline(credito);
        this.forma_pago.disabled = credito;
        this.forma_pago.value = credito ? "por_definir" : "efectivo";
    }

    $show(container, visible) {
        container.style.display = visible ? "block" : "none";
    }

    setStatusPago(visible) {
        this.status_pago.value = visible ? "pagado" : "";
        this.status_pago.required = visible;
        this.$show(this.status_pago_container, visible);
        this.setFormaPago(visible);
    }

    setFormaPago(visible) {
        this.forma_pago.value = visible ? "efectivo" : "por_definir";
        this.$show(this.forma_pago_container, visible);
    }



    setDeadline(visible) {
        this.deadline.value = null;
        this.deadline.required = visible;
        this.$show(this.deadline_container, visible);
    }
}