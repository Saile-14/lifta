import { Controller } from "@hotwired/stimulus"

// Switches between light and dark. Until the lifter picks one the page
// follows the system setting; a pick is kept in a cookie so the server can
// render <html data-theme> and the page never flashes the wrong theme.
export default class extends Controller {
  connect() {
    this.media = window.matchMedia("(prefers-color-scheme: dark)")
    this.render = this.render.bind(this)
    this.media.addEventListener("change", this.render)
    this.render()
    // Hidden in the markup, so there is no dead button without JavaScript
    this.element.hidden = false
  }

  disconnect() {
    this.media.removeEventListener("change", this.render)
  }

  toggle() {
    const theme = this.dark ? "light" : "dark"
    document.documentElement.dataset.theme = theme
    document.cookie = `theme=${theme}; path=/; max-age=31536000; samesite=lax`
    this.render()
  }

  render() {
    this.element.setAttribute("aria-pressed", String(this.dark))
  }

  get dark() {
    const chosen = document.documentElement.dataset.theme
    return chosen ? chosen === "dark" : this.media.matches
  }
}
