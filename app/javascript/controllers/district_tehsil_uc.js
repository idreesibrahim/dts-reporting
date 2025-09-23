import { Controller } from "@hotwired/stimulus"

export default class DistrictTehsilUcController extends Controller {
  static targets = ["district", "tehsil", "uc"]

  connect() {
  console.log("Filter modal controller connected");

    // Listen for modal open
    const modal = this.element.closest('.modal')
    if (modal) {
        modal.addEventListener('shown.bs.modal', () => {
        // Enable tehsil if district is already selected
        if (this.hasDistrictTarget && this.hasTehsilTarget) {
            const districtId = this.districtTarget.value
            if (districtId) {
            this.fetchTehsil({ target: this.districtTarget })
            }
        }
        })
    }
    }

  fetchTehsil(event) {
    // if (!this.hasTehsilTarget) return
    const districtId = event.target.value
    if (!districtId) return

    fetch(`/ajax/populate_tehsil?district=${districtId}`, { headers: { Accept: "application/json" } })
      .then(response => response.json())
      .then(data => {
        this.tehsilTarget.removeAttribute("disabled")
        this.tehsilTarget.innerHTML = ""
        if (data.length > 0) {
          this.tehsilTarget.insertAdjacentHTML("beforeend", `<option value="">All</option>`)
          data.forEach(item => {
            this.tehsilTarget.insertAdjacentHTML("beforeend", `<option value="${item[1]}">${item[0]}</option>`)
          })
        } else {
          this.tehsilTarget.insertAdjacentHTML("beforeend", `<option value=""></option>`)
        }

        // Clear UC select
        if (this.hasUcTarget) {
          this.ucTarget.innerHTML = `<option value="">All</option>`
          this.ucTarget.setAttribute("disabled", "disabled")
        }
      })
  }

  fetchUc(event) {
    const tehsilId = event.target.value
    if (!tehsilId) return

    fetch(`/ajax/populate_uc?town=${tehsilId}`, { headers: { Accept: "application/json" } })
      .then(response => response.json())
      .then(data => {
        this.ucTarget.removeAttribute("disabled")
        this.ucTarget.innerHTML = ""
        if (data.length > 0) {
          this.ucTarget.insertAdjacentHTML("beforeend", `<option value="">All</option>`)
          data.forEach(item => {
            this.ucTarget.insertAdjacentHTML("beforeend", `<option value="${item[1]}">${item[0]}</option>`)
          })
        } else {
          this.ucTarget.insertAdjacentHTML("beforeend", `<option value=""></option>`)
        }
      })
  }
}
