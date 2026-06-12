// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", setBrowserTimeZone)
document.addEventListener("click", copyPublicLink)

function setBrowserTimeZone() {
  const field = document.querySelector("[data-time-zone-field]")
  if (!field) return

  const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
  if (!timeZone) return

  field.value = timeZone

  const label = document.querySelector("[data-time-zone-label]")
  if (label) label.textContent = timeZone
}

async function copyPublicLink(event) {
  const button = event.target.closest("[data-copy-public-link]")
  if (!button) return

  const container = button.closest("[data-public-link]")
  const source = container.querySelector("[data-public-link-source]")
  const status = container.querySelector("[data-public-link-status]")
  const copied = await writeToClipboard(source.value)

  window.clearTimeout(button.copyResetTimeout)

  if (copied) {
    showCopySuccess(container, button, status)
  } else {
    showCopyFallback(container, source, status)
  }

  button.copyResetTimeout = window.setTimeout(() => {
    button.textContent = container.dataset.copyDefaultLabel
    status.textContent = ""
  }, 3000)
}

async function writeToClipboard(value) {
  if (navigator.clipboard?.writeText) {
    try {
      await navigator.clipboard.writeText(value)
      return true
    } catch {
      // Fall back when clipboard permission is denied.
    }
  }

  return copyWithSelection(value)
}

function copyWithSelection(value) {
  const textarea = document.createElement("textarea")
  textarea.value = value
  textarea.setAttribute("readonly", "")
  textarea.style.position = "fixed"
  textarea.style.opacity = "0"
  document.body.appendChild(textarea)
  textarea.select()
  textarea.setSelectionRange(0, textarea.value.length)

  try {
    return document.execCommand("copy")
  } catch {
    return false
  } finally {
    textarea.remove()
  }
}

function showCopySuccess(container, button, status) {
  button.textContent = container.dataset.copySuccessLabel
  status.textContent = container.dataset.copySuccessStatus
  status.className = "small mt-2 text-success"
}

function showCopyFallback(container, source, status) {
  source.focus()
  source.select()
  source.setSelectionRange(0, source.value.length)
  status.textContent = container.dataset.copyBlockedStatus
  status.className = "small mt-2 text-danger"
}
