import Config

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
config :site, SiteWeb.Endpoint,
  http: [
    # Enable IPv6 and bind on all interfaces.
    # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
    # See the documentation on https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html
    # for details about using IPv6 vs IPv4 and loopback vs public addresses.
    ip: {0, 0, 0, 0, 0, 0, 0, 0},
    port: {:system, "PORT"},
    transport_options: [
      num_acceptors: 2_048,
      max_connections: 32_768,
      socket_opts: [:inet6]
    ],
    compress: true,
    protocol_options: [
      max_header_value_length: 16_384,
      max_request_line_length: 16_384
    ],
    # dispatch websockets but don't dispatch any other URLs, to avoid parsing invalid URLs
    # see https://hexdocs.pm/phoenix/Phoenix.Endpoint.CowboyHandler.html
    dispatch: [
      {:_,
       [
         {:_, Phoenix.Endpoint.Cowboy2Handler, {SiteWeb.Endpoint, []}}
       ]}
    ]
  ],
  url: [host: {:system, "HOST"}],
  static_url: [
    scheme: {:system, "STATIC_SCHEME"},
    host: {:system, "STATIC_HOST"},
    port: {:system, "STATIC_PORT"}
  ],
  cache_static_manifest: "priv/static/cache_manifest.json"

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

config :site,
  v3_api_default_timeout: 10_000,
  v3_api_cache_size: 200_000

config :site,
  google_api_key: "${GOOGLE_API_KEY}",
  google_client_id: "${GOOGLE_MAPS_CLIENT_ID}",
  google_signing_key: "${GOOGLE_MAPS_SIGNING_KEY}",
  geocode: {:system, "LOCATION_SERVICE", :google},
  reverse_geocode: {:system, "LOCATION_SERVICE", :google},
  autocomplete: {:system, "LOCATION_SERVICE", :google},
  aws_index_prefix: {:system, "AWS_PLACE_INDEX_PREFIX", "dotcom-prod"}

