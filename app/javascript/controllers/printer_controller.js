import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    async print() {
        const ticket = JSON.parse(this.element.dataset.ticket);

        try {
            const response = await fetch("http://127.0.0.1:9876/print", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    store_name: ticket.store_name,
                    items: ticket.items,
                    total: ticket.total,
                }),
            });

            if (response.ok) {
                alert("🧾 Ticket impreso");
            } else {
                alert("❌ " + (await response.text()));
            }
        } catch (err) {
            alert("⚠️ El puente de impresión no está activo. Abre Miinegocio Printer.");
        }
    }
}