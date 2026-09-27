// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Eager-load all pack application modules discovered from the importmap
const importMapEl = document.querySelector('script[type="importmap"]')
if (importMapEl) {
  const imports = JSON.parse(importMapEl.textContent).imports
  Object.keys(imports)
    .filter(name => name.startsWith("packs/") && name.endsWith("/application"))
    .forEach(name => import(name))
}
