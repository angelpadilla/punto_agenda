import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = [
        "container",
        "itemInput",
        "itemLista",
        "itemsSeleccionados",
        "itemsHiddenInput",
    ];

    connect() {
        console.log("Conectado");
        console.log(this.itemListaTarget);

        console.log("container", this.containerTarget);
        this.itemListaTarget.style.display = "none";
        this.filtrarLista();

        // si hago click fuera del container se oculta la lista
        document.addEventListener("click", (event) => {
            if (!this.containerTarget.contains(event.target)) {
                this.itemListaTarget.style.display = "none";
            }
        });
    }

    mostrarLista() {
        console.log("Mostrar lista de alergias");
        this.itemListaTarget.style.display = "block";
        const filtro = this.itemInputTarget.value.toLowerCase();

        if (filtro === "") {
            this.itemListaTarget
                .querySelector(".lista_mensaje")
                .classList.add("is-hidden");
        }
    }

    filtrarLista() {
        console.log("Filtrar lista");
        const filtro = this.itemInputTarget.value.toLowerCase();
        const opciones = this.itemListaTarget.querySelectorAll(".lista-opcion");

        for (const opcion of opciones) {
            const texto = opcion.textContent.toLowerCase();
            const valor = opcion.dataset.value;

            // Ocultar si no coincide con el filtro O si ya está seleccionado
            if (!texto.includes(filtro) || this.itemSeleccionado(valor)) {
                opcion.classList.add("is-hidden");
            } else {
                opcion.classList.remove("is-hidden");
            }
        }

        const opcionesOcultas = this.itemListaTarget.querySelectorAll(
            ".lista-opcion.is-hidden",
        );

        if (opcionesOcultas.length === opciones.length) {
            this.itemListaTarget
                .querySelector(".lista_mensaje")
                .classList.remove("is-hidden");
        } else {
            this.itemListaTarget
                .querySelector(".lista_mensaje")
                .classList.add("is-hidden");
        }
    }

    seleccionarItem(event) {
        const valor = event.target.dataset.value;
        if (!this.itemSeleccionado(valor)) {
            this.agregarTag(valor);
            this.itemInputTarget.value = "";
            this.filtrarLista();
            this.updateitemsHiddenInput();
        }
        this.itemListaTarget.style.display = "none";
    }

    agregarTag(valor) {
        console.log("Agregando tag", valor);
        const tag = document.createElement("span");
        tag.classList.add("tag");
        tag.dataset.value = valor;
        tag.innerHTML = `${valor} <button class="delete is-small" data-action="click->super-select#eliminarTagItem"></button>`;
        this.itemsSeleccionadosTarget.appendChild(tag);
    }

    agregarTagDesdeMensaje(event) {
        const valor = this.itemInputTarget.value.trim().toLowerCase();
        if (!this.itemSeleccionado(valor)) {
            this.agregarTag(valor);
            this.itemInputTarget.value = "";
            this.filtrarLista();
            this.updateitemsHiddenInput();
        }
        this.itemListaTarget.style.display = "none";
        this.itemInputTarget.value = "";
    }

    eliminarTagItem(event) {
        event.target.closest(".tag").remove();
        this.updateitemsHiddenInput();
    }

    itemSeleccionado(valor) {
        return Array.from(
            this.itemsSeleccionadosTarget.querySelectorAll(".tag"),
        ).some((tag) => tag.dataset.value === valor);
    }

    updateitemsHiddenInput() {
        const valores = Array.from(
            this.itemsSeleccionadosTarget.querySelectorAll(".tag"),
        ).map((tag) => tag.dataset.value);
        this.itemsHiddenInputTarget.value = valores.join(",");
    }
}
