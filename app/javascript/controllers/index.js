import { application } from "./application"

// Import controllers explicitly
import HelloController from "./hello_controller.js"

application.register("hello", HelloController)
import DistrictTehsilUcController from "./district_tehsil_uc"
application.register("district-tehsil-uc", DistrictTehsilUcController)
import ParentDepartmentController from "./parent_department"
application.register("parent-department", ParentDepartmentController)
import ResetButtonController from "./reset_button"
application.register("reset-button", ResetButtonController)