import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {
        console.log("FormCustomerController connected");

        this.docsGrid = document.querySelector('.docs_grid');
        console.log(this.docsGrid);
    }

    previewDocs(event) {
        const input = event.target;
        const files = input.files;

        for (const file of files) {
            // Calculamos el tamaño en MB o KB
            const isMB = file.size > 1024 * 1024;
            const fileSize = isMB
                ? (file.size / (1024 * 1024)).toFixed(2) + " MB"
                : (file.size / 1024).toFixed(2) + " KB";

            // creamos contenedor del documento para mostrar la vista previa
            const docContainer = document.createElement('div');
            docContainer.classList.add('doc_tile');
            docContainer.innerHTML = `
                <span class="material-icons-round mr-2">
                    attach_file
                </span>
                <div class="doc_tile_info flexx-3">
                    <div class="doc_tile__title"></div>
                    <div class="doc_tile__meta"></div>
                </div>
                <div class="doc_tile__actions">
                    <span class="material-icons-round mr-2 trashh has-text-danger cursor-pointer">
                        delete_forever
                    </span>
                </div>
            `;
            this.docsGrid.appendChild(docContainer);

            // put the filename and size in the doc tile
            const docTitle = docContainer.querySelector('.doc_tile__title');
            if (docTitle) {
                docTitle.innerHTML = file.name;
            }

            // add listener to delete the doc tile
            const deleteBtn = docContainer.querySelector('.trashh');
            if (deleteBtn) {
                deleteBtn.addEventListener('click', () => {
                    docContainer.remove();
                });
            }

            // docContainer.style.backgroundImage = `url(${URL.createObjectURL(file)})`;
            // docContainer.style.backgroundSize = 'cover';
            // docContainer.style.backgroundPosition = 'center';
            // docContainer.style.border = '1px solid #a8fb22';

            // Seleccionamos los spans que vamos a actualizar
            const metaSpan = docContainer.querySelector('.doc_tile__meta');

            // Actualizamos la vista con los datos del archivo
            if (metaSpan) metaSpan.textContent = `Tamaño: ${fileSize}`;
        }
    }
}