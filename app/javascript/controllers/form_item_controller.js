import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        this.token = document.head.querySelector("meta[name=csrf-token]")?.content;
    }

    // ── Image preview ──────────────────────────────────────────────────────

    previewImage(event) {
        const input = event.target;
        const file = input.files[0];

        if (file) {
            // Calculamos el tamaño en MB o KB
            const isMB = file.size > 1024 * 1024;
            const fileSize = isMB
                ? (file.size / (1024 * 1024)).toFixed(2) + " MB"
                : (file.size / 1024).toFixed(2) + " KB";

            // Buscamos el contenedor padre (el label)
            const dropContainer = input.closest('.image-tile');
            if (!dropContainer) return;

            // replace the default text title with a mini preview of the image
            const imgMiniCont = dropContainer.querySelector('.image-tile__title');
            if (imgMiniCont) {
                imgMiniCont.innerHTML = `<img src="${URL.createObjectURL(file)}" alt="Preview" class="image-tile__preview">`;
            }

            // dropContainer.style.backgroundImage = `url(${URL.createObjectURL(file)})`;
            // dropContainer.style.backgroundSize = 'cover';
            // dropContainer.style.backgroundPosition = 'center';
            dropContainer.style.border = '1px solid #a8fb22';

            // Seleccionamos los spans que vamos a actualizar
            const metaSpan = dropContainer.querySelector('.image-tile__meta');
            const file_name = dropContainer.querySelector('.image-tile__subtitle');

            // Actualizamos la vista con los datos del archivo
            if (metaSpan) metaSpan.textContent = `Tamaño: ${fileSize}`;
            if (file_name) file_name.textContent = file.name;
        } else {
            // Si el usuario cancela la selección, regresamos al texto por defecto
            const dropContainer = input.closest('.image-tile');
            if (dropContainer) {
                dropContainer.querySelector('.image-tile__meta').textContent = "JPG o PNG · max 5MB";
            }
        }
    }
}