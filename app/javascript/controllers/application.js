import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Development mode logging
application.debug = false
window.Stimulus = application

export { application }
