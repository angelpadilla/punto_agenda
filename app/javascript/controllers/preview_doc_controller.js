import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    previewDoc(event) {
        const input = event.target
        const file = input.files[0]
        if (file) {
            // Calculamos el tamaño en MB o KB
            const isMB = file.size > 1024 * 1024;
            const fileSize = isMB
                ? (file.size / (1024 * 1024)).toFixed(2) + " MB"
                : (file.size / 1024).toFixed(2) + " KB";

            const docInput = input.closest(".doc_input")


            const fileNameContainer = docInput?.querySelector(".doc_file_name")
            if (fileNameContainer) fileNameContainer.textContent = `Archivo: ${file.name}`
            const fileSizeContainer = docInput?.querySelector(".doc_file_size")
            if (fileSizeContainer) fileSizeContainer.textContent = `Tamaño: ${fileSize}`
        }
    }
}