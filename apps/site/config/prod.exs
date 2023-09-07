use Mix.Config

# For production, we configure the host to read the PORT
# from the system environment. Therefore, you will need
# to set PORT=80 before running your server.
#
# You should also configure the url host to something
# meaningful, we use this information when generating URLs.
#
# Finally, we also include the path to a manifest
# containing the digested version of static files. This
# manifest is generated by the mix phx.digest task
# which you typically run after static files are built.
config :site, SiteWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :site, :websocket_check_origin, [
  "https://*.mbta.com",
  "https://*.mbtace.com"
]

config :site,
  dev_server?: false,
  enable_experimental_features: {:system, "ENABLE_EXPERIMENTAL_FEATURES"}

# Do not print debug messages in production
config :logger,
  level: :info,
  handle_sasl_reports: true,
  backends: [:console]

config :logger, :console,
  level: :info,
  format: "$dateT$time [$level]$levelpad node=$node $metadata$message\n",
  metadata: [:request_id, :ip]

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :site, SiteWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#

# because this is evaluated at compile time, it won't get used when we're
# running the Backstop tests.  It should still be included in the production
# build.
unless System.get_env("PORT") do
  config :site, SiteWeb.Endpoint, url: [scheme: "https", port: 443]

  # configured separately so that we can have the health check not require
  # SSL
  config :site, :secure_pipeline,
    force_ssl: [
      host: nil,
      rewrite_on: [:x_forwarded_proto]
    ]
end

# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
config :phoenix, :serve_endpoints, true

#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :site, SiteWeb.Endpoint, server: true
#
# You will also need to set the application root to `.` in order
# for the new static assets to be served after a hot upgrade:
#

config :site, SiteWeb.ViewHelpers, google_tag_manager_id: "${GOOGLE_TAG_MANAGER_ID}"

config :ehmon, :report_mf, {:ehmon, :info_report}

config :sentry,
  dsn: "${SENTRY_DSN}",
  environment_name: "${SENTRY_ENVIRONMENT}"

config :site, StaticFileController,
  response_fn: {SiteWeb.StaticFileController, :redirect_through_cdn}

config :site, tile_server_url: "https://cdn.mbta.com"

config :site, :react,
  source_path: nil,
  build_path: System.get_env("REACT_BUILD_PATH") || "/root/rel/site/app.js"
