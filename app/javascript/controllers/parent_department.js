import { Controller } from "@hotwired/stimulus"

export default class ParentDepartmentController extends Controller {
  static targets = ["parentDepartment", "subDepartment", "resetButton"]

  connect() {
    console.log("Parent-Sub Department controller connected")

    if (this.hasResetButtonTarget) {
      this.resetButtonTarget.addEventListener("click", () => this.resetData())
    }

    // Handle modal open
    const modal = this.element.closest('.modal')
    if (modal) {
      modal.addEventListener('shown.bs.modal', () => {
        // Enable sub department if parent already selected
        if (this.hasParentDepartmentTarget && this.hasSubDepartmentTarget) {
          const parentId = this.parentDepartmentTarget.value
          if (parentId) {
            this.fetchSubDepartments({ target: this.parentDepartmentTarget })
          }
        }
      })
    }
  }

  resetData() {
    if (this.hasSubDepartmentTarget) {
      this.subDepartmentTarget.value = ""
      this.subDepartmentTarget.setAttribute("disabled", "disabled")
    }
    if (this.hasParentDepartmentTarget) {
      this.parentDepartmentTarget.value = ""
    }
    document.querySelectorAll("input[type=text], input[type=date], input[type=datetime-local]").forEach(el => el.value = "")
  }

  fetchSubDepartments(event) {
    const parentId = event.target.value
    if (!parentId) return

    fetch(`/ajax/populate_sub_departments?parent_department=${parentId}`, { headers: { Accept: "application/json" } })
      .then(response => response.json())
      .then(data => {
        this.subDepartmentTarget.removeAttribute("disabled")
        this.subDepartmentTarget.innerHTML = ""

        if (data.length > 0) {
          this.subDepartmentTarget.insertAdjacentHTML("beforeend", `<option value="">All</option>`)
          data.forEach(item => {
            this.subDepartmentTarget.insertAdjacentHTML("beforeend", `<option value="${item[1]}">${item[0]}</option>`)
          })
        } else {
          this.subDepartmentTarget.insertAdjacentHTML("beforeend", `<option value=""></option>`)
        }
      })
  }
}
