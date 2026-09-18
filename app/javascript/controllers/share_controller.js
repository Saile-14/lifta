import { Controller } from "@hotwired/stimulus"

// Shares a link through the native share sheet where there is one (phones),
// otherwise copies it to the clipboard.
export default class extends Controller {
  static targets = [ "label" ]
  static values = { url: String, title: String, text: String, copied: String }

  async share() {
    if (navigator.share) {
      try {
        await navigator.share({ url: this.urlValue, title: this.titleValue, text: this.textValue })
      } catch {
        // Dismissed the share sheet
      }
    } else {
      await navigator.clipboard.writeText(this.urlValue)
      const label = this.labelTarget.textContent
      this.labelTarget.textContent = this.copiedValue
      setTimeout(() => { this.labelTarget.textContent = label }, 2000)
    }
  }
}
