import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["canvas"]
    static values = { chartData: Array, type: String }

    connect() {
        if (!window.Chart) {
            console.warn("Chart.js not loaded")
            return
        }
        this._render()
    }

    disconnect() {
        this._chart?.destroy()
    }

    _render() {
        const type = this.typeValue || "bar"
        const data = this.chartDataValue

        if (type === "doughnut") {
            this._renderDoughnut(data)
        } else {
            this._renderBar(data)
        }
    }

    _renderBar(data) {
        const labels = data.map(d => d.label)
        const totals = data.map(d => d.total)
        const last = totals.length - 1

        this._chart = new window.Chart(this.canvasTarget, {
            type: "bar",
            data: {
                labels,
                datasets: [{
                    label: "Venta bruta",
                    data: totals,
                    backgroundColor: totals.map((_, i) =>
                        i === last ? "#a8fb22" : "rgba(168,251,34,0.22)"
                    ),
                    borderColor: totals.map((_, i) =>
                        i === last ? "#a8fb22" : "rgba(168,251,34,0.45)"
                    ),
                    borderWidth: 1,
                    borderRadius: 10,
                    borderSkipped: false
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { display: false },
                    tooltip: {
                        backgroundColor: "#1a1a1a",
                        borderColor: "#313131",
                        borderWidth: 1,
                        titleColor: "#d1d5da",
                        bodyColor: "#a8fb22",
                        padding: 10,
                        callbacks: {
                            label: ctx =>
                                ` $${ctx.parsed.y.toLocaleString("es-MX", { minimumFractionDigits: 2 })}`
                        }
                    }
                },
                scales: {
                    x: {
                        grid: { color: "rgba(255,255,255,0.05)" },
                        ticks: { color: "#69748c", font: { size: 12 } },
                        border: { color: "transparent" }
                    },
                    y: {
                        grid: { color: "rgba(255,255,255,0.05)" },
                        ticks: {
                            color: "#69748c",
                            font: { size: 11 },
                            callback: val => `$${Number(val).toLocaleString("es-MX")}`
                        },
                        border: { color: "transparent" },
                        beginAtZero: true
                    }
                }
            }
        })
    }

    _renderDoughnut(data) {
        const palette = [
            "#a8fb22", "#3ecfcf", "#ff7351", "#ffdd91", "#7b68ee",
            "#ff6699", "#00bfff", "#ffa07a", "#98fb98", "#dda0dd"
        ]
        const labels = data.map(d => d.label)
        const values = data.map(d => d.value ?? d.total ?? 0)

        this._chart = new window.Chart(this.canvasTarget, {
            type: "doughnut",
            data: {
                labels,
                datasets: [{
                    data: values,
                    backgroundColor: palette.slice(0, values.length),
                    borderColor: "#222222",
                    borderWidth: 2,
                    hoverOffset: 6
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                cutout: "65%",
                plugins: {
                    legend: {
                        position: "bottom",
                        labels: {
                            color: "#d1d5da",
                            font: { size: 11 },
                            boxWidth: 12,
                            padding: 10
                        }
                    },
                    tooltip: {
                        backgroundColor: "#1a1a1a",
                        borderColor: "#313131",
                        borderWidth: 1,
                        titleColor: "#d1d5da",
                        bodyColor: "#a8fb22",
                        padding: 10
                    }
                }
            }
        })
    }
}
