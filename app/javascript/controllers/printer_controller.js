import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    async print(event) {
        // const ticket = JSON.parse(event.params.ticket);

        console.log("Ticket to print:", event.params.ticket);

        try {
            const response = await fetch("http://127.0.0.1:9876/print", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(event.params.ticket),
            });

            if (!response.ok) {
                alert("❌ " + (await response.text()));
            }
        } catch (err) {
            alert("⚠️ La app de impresión no está activa. Abre Miinegocio Printer.");
        }
    }
}