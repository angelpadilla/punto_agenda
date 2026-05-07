import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        this.tipo = document.getElementById("order_tipo");
        this.forma_pago = document.getElementById("order_forma_pago");
        this.status_pago = document.getElementById("order_status_pago");
        this.uso_cfdi = document.getElementById("order_uso_cfdi");
        this.deadline = document.getElementById("order_deadline");

        this.forma_pago_container = this.forma_pago.parentElement.parentElement;
        this.status_pago_container = this.status_pago.parentElement.parentElement;
        this.uso_cfdi_container = this.uso_cfdi.parentElement.parentElement;
        this.deadline_container = this.deadline.parentElement;

        this.checkTipo();
        this.checkStatusPago();

        this.tipo.addEventListener("change", () => this.checkTipo());
        this.status_pago.addEventListener("change", () => this.checkStatusPago());
    }

    checkTipo() {
        const tipo = this.tipo.value;
        const pagable = tipo === "remision" || tipo === "factura";
        this.setFormaPago(pagable);
        this.setStatusPago(pagable);
        this.setUsoCFDI(tipo === "factura");

        this.checkStatusPago();
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

    setUsoCFDI(visible) {
        this.uso_cfdi.value = visible ? "G03" : "";
        this.uso_cfdi.required = visible;
        this.$show(this.uso_cfdi_container, visible);
    }

    setDeadline(visible) {
        this.deadline.value = null;
        this.deadline.required = visible;
        this.$show(this.deadline_container, visible);
    }
}