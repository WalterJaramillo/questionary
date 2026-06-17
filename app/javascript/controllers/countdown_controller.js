import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display"]
  static values = { seconds: Number }

  connect() {
    this.interval = setInterval(() => this.tick(), 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  tick() {
    if (this.secondsValue <= 0) {
      this.submitForm()
      return
    }

    this.secondsValue--
    this.updateDisplay()
  }

  updateDisplay() {
    if (!this.hasDisplayTarget) return

    const mins = Math.floor(this.secondsValue / 60)
    const secs = this.secondsValue % 60
    const formatted = `${mins}:${secs.toString().padStart(2, "0")}`

    this.displayTarget.textContent = formatted

    if (this.secondsValue <= 300) {
      this.displayTarget.classList.add("text-danger")
      this.displayTarget.classList.remove("text-white")
    }
  }

  submitForm() {
    const form = document.getElementById("quiz-form")
    if (form) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "auto_submit"
      input.value = "true"
      form.appendChild(input)
      form.submit()
    }
  }
}
