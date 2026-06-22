import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js/auto"

Chart.register(...registerables)

export default class extends Controller {
  static values = { type: String, data: Object, options: Object }

  connect() {
    const ctx = this.element.getContext("2d")
    new Chart(ctx, {
      type: this.typeValue || "bar",
      data: this.dataValue,
      options: this.optionsValue || this.defaultOptions
    })
  }

  get defaultOptions() {
    return {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: { display: false }
      },
      scales: {
        y: { beginAtZero: true }
      }
    }
  }
}
