// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("click", async (event) => {
  const button = event.target.closest("[data-copy-public-link]")
  if (!button) return

  const container = button.closest("[data-public-link]")
  const source = container.querySelector("[data-public-link-source]")
  const status = container.querySelector("[data-public-link-status]")
  const value = source.value
  const {
    copyBlockedStatus,
    copyDefaultLabel,
    copySuccessLabel,
    copySuccessStatus
  } = container.dataset
  let copied = false

  if (navigator.clipboard?.writeText) {
    try {
      await navigator.clipboard.writeText(value)
      copied = true
    } catch {
      // Fall through when clipboard permission is denied.
    }
  }

  if (!copied) {
    const textarea = document.createElement("textarea")
    textarea.value = value
    textarea.setAttribute("readonly", "")
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()
    textarea.setSelectionRange(0, textarea.value.length)

    try {
      copied = document.execCommand("copy")
    } catch {
      copied = false
    } finally {
      textarea.remove()
    }
  }

  window.clearTimeout(button.copyResetTimeout)

  if (copied) {
    button.textContent = copySuccessLabel
    status.textContent = copySuccessStatus
    status.className = "small mt-2 text-success"
  } else {
    source.focus()
    source.select()
    source.setSelectionRange(0, value.length)
    status.textContent = copyBlockedStatus
    status.className = "small mt-2 text-danger"
  }

  button.copyResetTimeout = window.setTimeout(() => {
    button.textContent = copyDefaultLabel
    status.textContent = ""
  }, 3000)
})
