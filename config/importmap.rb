# typed: false

# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "date-fns/isPast", to: "https://unpkg.com/date-fns@latest/isPast.js"
pin "date-fns/formatDuration", to: "https://unpkg.com/date-fns@latest/formatDuration.js"
pin "date-fns/formatDistanceToNow", to: "https://unpkg.com/date-fns@latest/formatDistanceToNow.js"
pin "date-fns/toDate", to: "https://unpkg.com/date-fns@latest/toDate.js"
pin "date-fns/intervalToDuration", to: "https://unpkg.com/date-fns@latest/intervalToDuration.js"
pin "mitt", to: "https://unpkg.com/mitt@latest/dist/mitt.mjs"
pin "@stimulus-library/utilities", to: "https://unpkg.com/@stimulus-library/utilities@latest/dist/index.js"
pin "@stimulus-library/mixins", to: "https://unpkg.com/@stimulus-library/mixins@latest/dist/index.js"
pin "@stimulus-library/controllers", to: "https://unpkg.com/@stimulus-library/controllers@latest/dist/index.js"
pin "stimulus-library", to: "https://unpkg.com/stimulus-library@latest/dist/index.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Dynamically pin pack JavaScript assets
Dir.glob("packs/*/app/javascript").each do |js_root|
  pack_name = js_root.split("/")[1]

  # Pin controllers so Stimulus eager-loads them as <pack>--<controller>
  controllers_path = File.join(js_root, "controllers")
  if Dir.exist?(controllers_path)
    pin_all_from controllers_path, under: "controllers/#{pack_name}"
  end

  # Pin pack application.js as the pack's initialization entry point
  app_js = File.join(js_root, "application.js")
  if File.exist?(app_js)
    pin "packs/#{pack_name}/application", to: app_js
  end
end
