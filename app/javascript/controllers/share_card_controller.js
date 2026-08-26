import { Controller } from "@hotwired/stimulus"
import html2canvas from "html2canvas"

export default class extends Controller {
  static targets = [
    "card",
    "aspectBtn",
    "themeBtn",
    "copyBtn",
    "downloadBtn",
    "copyStatus",
    "urlInput",
    "brandHeader",
    "extraTextInput",
    "extraTextPreview"
  ]

  static values = {
    filename: String,
    url: String
  }

  connect() {
    if (this.hasCardTarget && !this.cardTarget.dataset.aspect) {
      this.cardTarget.dataset.aspect = "1:1"
    }
    if (this.hasCardTarget && !this.cardTarget.dataset.theme) {
      this.cardTarget.dataset.theme = "blue-purple"
    }
  }

  changeAspect(event) {
    const btn = event.currentTarget
    const aspect = btn.dataset.aspect || "1:1"

    if (this.hasCardTarget) {
      this.cardTarget.dataset.aspect = aspect
    }

    this.aspectBtnTargets.forEach(b => {
      if (b === btn) {
        b.classList.add("is-active", "is-selected")
      } else {
        b.classList.remove("is-active", "is-selected")
      }
    })
  }

  changeTheme(event) {
    const btn = event.currentTarget
    const theme = btn.dataset.theme || "blue-purple"

    if (this.hasCardTarget) {
      this.cardTarget.dataset.theme = theme
    }

    this.themeBtnTargets.forEach(b => {
      if (b === btn) {
        b.classList.add("is-active")
      } else {
        b.classList.remove("is-active")
      }
    })
  }

  toggleBrand(event) {
    const isChecked = event.currentTarget.checked
    if (this.hasBrandHeaderTarget) {
      this.brandHeaderTarget.style.display = isChecked ? "flex" : "none"
    }
  }

  updateExtraText(event) {
    const text = event.currentTarget.value
    if (this.hasExtraTextPreviewTarget) {
      this.extraTextPreviewTarget.textContent = text
      this.extraTextPreviewTarget.style.display = text.trim().length > 0 ? "block" : "none"
    }
  }

  async copyLink(event) {
    const url = this.urlValue || (this.hasUrlInputTarget ? this.urlInputTarget.value : window.location.href)
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(url)
      } else {
        const textarea = document.createElement("textarea")
        textarea.value = url
        textarea.style.position = "fixed"
        textarea.style.opacity = "0"
        document.body.appendChild(textarea)
        textarea.select()
        document.execCommand("copy")
        document.body.removeChild(textarea)
      }

      const origText = event.currentTarget.innerHTML
      event.currentTarget.innerHTML = `<span class="icon mr-1">✓</span> Copiado`
      event.currentTarget.classList.add("is-success")
      
      if (this.hasCopyStatusTarget) {
        this.copyStatusTarget.style.display = "block"
        setTimeout(() => { this.copyStatusTarget.style.display = "none" }, 2500)
      }

      setTimeout(() => {
        event.currentTarget.innerHTML = origText
        event.currentTarget.classList.remove("is-success")
      }, 2500)
    } catch (err) {
      console.error("Error al copiar enlace:", err)
    }
  }

  async downloadSnapshot(event) {
    if (!this.hasCardTarget) return

    const btn = event.currentTarget
    const origHtml = btn.innerHTML
    const aspect = this.cardTarget.dataset.aspect || "1:1"
    const theme = this.cardTarget.dataset.theme || "blue-purple"
    const baseName = this.filenameValue || "miinegocio-calendario"
    const fileName = `${baseName}-${theme}-${aspect.replace(":", "x")}.png`

    btn.disabled = true
    btn.innerHTML = `<span class="icon mr-1"><i class="spin-loader"></i></span> Descargando...`

    try {
      const canvas = await html2canvas(this.cardTarget, {
        scale: 3, // High-res retina 3x
        useCORS: true,
        allowTaint: true,
        logging: false,
        backgroundColor: null,
        onclone: (clonedDoc) => {
          const clonedCard = clonedDoc.querySelector(`[data-share-card-target="card"]`)
          if (clonedCard) {
            clonedCard.style.transform = "none"
            clonedCard.style.boxShadow = "none"
          }
        }
      })

      const image = canvas.toDataURL("image/png")
      const link = document.createElement("a")
      link.download = fileName
      link.href = image
      link.click()

      btn.innerHTML = `<span class="icon mr-1">✓</span> ¡Descargado!`
      btn.classList.add("is-success")

      setTimeout(() => {
        btn.disabled = false
        btn.innerHTML = origHtml
        btn.classList.remove("is-success")
      }, 2500)

    } catch (err) {
      console.error("Error al generar la imagen snapshot:", err)
      btn.disabled = false
      btn.innerHTML = origHtml
      alert("Hubo un problema al generar la foto snapshot. Intenta de nuevo.")
    }
  }
}
