import { Controller } from "@hotwired/stimulus"

export default class ResetButtonController extends Controller {
  static targets = ["resetButton","tag"]

  connect() {
  console.log("Reset Button controller connected");
  this.resetButtonTarget.addEventListener("click", () => this.resetData())
    // Listen for modal open
    const modal = this.element.closest('.modal')
  }
  resetData() {
    // reset tags (multi select)
    this.tagTarget.value = ""
    this.tagTarget.dispatchEvent(new Event("change"))  // for select2 or similar
      document.querySelectorAll("input[type=text], input[type=date], input[type=datetime-local]").forEach(el => el.value = "");
    }
}