import { Controller } from "@hotwired/stimulus"

// Fills a hidden field with the browser's time zone, e.g. "Europe/Berlin",
// so "today" on a new lift is the lifter's today.
export default class extends Controller {
  connect() {
    this.element.value = Intl.DateTimeFormat().resolvedOptions().timeZone || ""
  }
}
