import { Controller } from "@hotwired/stimulus"

export default class DistrictTehsilUcController extends Controller {
  static targets = ["district", "tehsil", "uc", "resetButton"]

  connect() {
  console.log("Filter modal controller connected");
  this.resetButtonTarget.addEventListener("click", () => this.resetData())
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
    resetData() {
      this.tehsilTarget.value = "";
      this.tehsilTarget.setAttribute("disabled", "disabled");
      this.ucTarget.value = "";
      this.ucTarget.setAttribute("disabled", "disabled");
      this.districtTarget.value = "";
      document.querySelectorAll("input[type=text], input[type=date], input[type=datetime-local]").forEach(el => el.value = "");
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
  // ✅ migrated from your <script>
  filterActivities() {
    const submitBtn = document.querySelector(".data_submit")
    if (submitBtn) submitBtn.setAttribute("disabled", true)

    const period = document.querySelector("#period")?.value
    const dateFrom = document.querySelector("#datefrom")?.value
    const dateTo = document.querySelector("#dateto")?.value

    if (period) {
      if (dateFrom !== "" && dateTo !== "") {
        const params = new URLSearchParams({
          act_tag: document.querySelector("#tag")?.value || "",
          tehsil_id: document.querySelector("#tehsil")?.value || "",
          uc: document.querySelector("#uc")?.value || "",
          district_id: document.querySelector("#district")?.value || "",
          datefrom: dateFrom,
          dateto: dateTo,
          sub_department: document.querySelector(".sub_department")?.value || "",
          parent_department: document.querySelector("#parent_department")?.value || "",
          larva_type: document.querySelector("#larva_type")?.value || "",
          period: period,
          submitted_by: document.querySelector("#submitted_by")?.value || ""
        })

        window.location = "?" + params.toString()
      } else {
        alert("Please Select Date From and Date To")
        if (submitBtn) submitBtn.removeAttribute("disabled")
      }
    } else {
      alert("Please Select Duration")
      if (submitBtn) submitBtn.removeAttribute("disabled")
    }
  }
}

