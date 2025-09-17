import { application } from "./application"

// Import controllers explicitly
import HelloController from "./hello_controller.js"

application.register("hello", HelloController)
