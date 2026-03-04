import { Controller } from "@hotwired/stimulus"
import WebUSBReceiptPrinter from "@point-of-sale/webusb-receipt-printer"
import ReceiptPrinterEncoder from "@point-of-sale/receipt-printer-encoder"

export default class extends Controller {
    static targets = ["status", "connectButton"]
    static values = {
        printerLanguage: String,
        printerMapping: Object
    }

    connect() {
        this.printer = new WebUSBReceiptPrinter()
        this.setupListeners()
        this.attemptAutoReconnect()
    }

    setupListeners() {
        this.printer.addEventListener('connected', (device) => {
            console.log(`Connected to ${device.manufacturerName} ${device.productName} (#${device.serialNumber})`);
            this.printerLanguageValue = device.language
            this.printerMappingValue = device.codepageMapping
            this.statusTarget.textContent = `Conectado a: ${device.productName}`
            this.connectButtonTarget.classList.add("hidden")
            localStorage.setItem('pos_printer_data', JSON.stringify(device))
        })

        this.printer.addEventListener('disconnected', () => {
            console.log("Printer disconnected")
            this.statusTarget.textContent = "Impresora desconectada"
            this.connectButtonTarget.classList.remove("hidden")
        })
    }

    async attemptAutoReconnect() {
        const savedDevice = JSON.parse(localStorage.getItem('pos_printer_data'))
        if (savedDevice) {
            try {
                await this.printer.reconnect(savedDevice)
            } catch (e) {
                console.log("No se pudo reconectar automáticamente")
            }
        }
    }

    async connectPrinter() {
        try {
            console.log("Secure context:", window.isSecureContext)
            console.log("navigator.usb:", navigator.usb)

            // Ver dispositivos ya autorizados
            const known = await navigator.usb.getDevices()
            console.log("Known USB devices:", known)

            // Forzar selector sin filtros (solo para prueba)
            const device = await navigator.usb.requestDevice({ filters: [] })
            console.log("Selected device:", device)

            // Conectar directamente
            if (!device.opened) {
                await device.open()
            }

            // Simular evento connected para que funcione el resto del código
            this.printer.printer = device
            const mockDevice = {
                manufacturerName: device.manufacturerName || "STMicroelectronics",
                productName: device.productName || "USB POS Printer",
                serialNumber: device.serialNumber || "unknown",
                language: "ESC/POS",
                codepageMapping: {}
            }

            // Disparar evento como si la librería lo hiciera
            this.setupListeners()
            const event = new CustomEvent('connected', { detail: mockDevice })
            this.printer.dispatchEvent(event)

            this.statusTarget.textContent = `Conectado a: ${mockDevice.productName}`
            this.connectButtonTarget.classList.add("hidden")
            localStorage.setItem('pos_printer_data', JSON.stringify(mockDevice))
        } catch (error) {
            console.error("Error de conexión USB:", error)
            this.statusTarget.textContent = `Error: ${error.message}`
        }
    }

    async printSampleTicket() {
        if (!this.printerLanguageValue) return

        const encoder = new ReceiptPrinterEncoder({
            language: this.printerLanguageValue,
            codepageMapping: this.printerMappingValue
        })

        const data = encoder
            .initialize()
            .align('center')
            .size('normal')
            .line('RESTAURANTE RAILS')
            .line('Calle de la Web, 123')
            .line('--------------------------------')
            .align('left')
            .text('1x Hamburguesa Gourmet    $15.00')
            .newline()
            .text('1x Refresco Grande        $3.00')
            .newline()
            .line('--------------------------------')
            .align('right')
            .bold(true)
            .line('TOTAL: $18.00')
            .bold(false)
            .newline()
            .align('center')
            .qrcode('https://mi-app-rails.com/pedidos/456')
            .newline()
            .cut()
            .encode()

        await this.printer.print(data)
    }
}