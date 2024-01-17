defmodule DotCom.Mixfile do
  use Mix.Project

  def project do
    [
      # app and version expected by `mix compile.app`
      app: :dotcom,
      version: "0.0.1",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:gettext, :yecc, :leex] ++ Mix.compilers(),
      # configures `mix compile` to embed all code and priv content in the _build directory instead of using symlinks
      build_embedded: Mix.env() == :prod,
      # used by `mix app.start` to start the application and children in permanent mode, which guarantees the node will shut down if the application terminates (typically because its root supervisor has terminated).
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_add_apps: [:mix, :phoenix_live_reload, :laboratory, :ex_aws, :ex_aws_ses],
        flags: [:race_conditions, :unmatched_returns],
        ignore_warnings: ".dialyzer.ignore-warnings"
      ],
      deps: deps(),
      aliases: aliases(),

      # docs
      name: "MBTA Website",
      source_url: "https://github.com/mbta/dotcom",
      homepage_url: "https://www.mbta.com/",
      # The main page in the docs
      docs: [main: "Dotcom", logo: "assets/static/images/mbta-logo-t.png"]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Configuration for the OTP application generated by `mix compile.app`
  def application do
    extra_apps = [
      :logger,
      :runtime_tools,
      :os_mon
    ]

    extra_apps =
      if Mix.env() == :prod do
        [:sasl | extra_apps]
      else
        extra_apps
      end

    [
      # the module to invoke when the application is started
      mod: {Dotcom.Application, []},
      # a list of applications that will be included in the application
      included_applications: [:laboratory],
      # a list of OTP applications your application depends on which are not included in :deps
      extra_applications: extra_apps
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe_client, "~> 0.1.0"},
      {:benchfella, "~> 0.3", [only: :dev]},
      {:briefly, "~> 0.3"},
      {:bypass, "~> 1.0", [only: :test]},
      {:castore, "~> 0.1.11"},
      {:con_cache, "~> 1.0.0"},
      {:crc, "0.10.5"},
      {:credo, "~> 1.5", only: [:dev, :test]},
      {:csv, "~> 3.0.5"},
      {:decorator, "1.4.0"},
      {:dialyxir, ">= 1.0.0-rc.4", [only: [:test, :dev], runtime: false]},
      {:diskusage_logger, "~> 0.2.0"},
      {:eflame, "~> 1.0", only: :dev},
      {:ehmon, [github: "mbta/ehmon", only: :prod]},
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.4"},
      {:ex_aws_ses, "~> 2.1.1"},
      {:ex_doc, "~> 0.31", only: :dev},
      {:excoveralls, "~> 0.16", only: :test},
      {:fast_local_datetime, "~> 0.1.0"},
      {:floki, "~> 0.31.0"},
      {:gen_stage, "~> 1.2"},
      {:gettext, "~> 0.9"},
      {:hackney, "~> 1.18"},
      {:hammer, "~> 6.0"},
      {:html_sanitize_ex, "1.3.0"},
      {:httpoison, "~> 1.5"},
      {:inflex, "~> 1.8.0"},
      {:jason, "~> 1.1"},
      {:laboratory, [github: "paulswartz/laboratory", ref: "cookie_opts"]},
      {:logster, "~> 0.4.0"},
      {:mail, "~> 0.2"},
      {:mock, "~> 0.3.3", [only: :test]},
      {:nebulex, "2.5.2"},
      {:nebulex_redis_adapter, "2.3.1"},
      {:parallel_stream, "~> 1.0.5"},
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:phoenix_live_reload, "~> 1.0", [only: :dev]},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_pubsub, "~> 2.1.3"},
      {:phoenix_view, "~> 2.0.3"},
      {:plug, "~> 1.14.2"},
      {:plug_cowboy, "~> 2.6.1"},
      {:poison, "~> 3.0"},
      {:polyline, "~> 1.3"},
      {:poolboy, "~> 1.5"},
      {:quixir, "~> 0.9", [only: :test]},
      # Required to mock challenge failures. Upgrade once a version > 3.0.0 is released.
      {:recaptcha,
       [
         github: "samueljseay/recaptcha",
         ref: "8ea13f63990ca18725ac006d30e55d42c3a58457"
       ]},
      {:recon, "~> 2.5.1", [only: :prod]},
      {:rstar, github: "armon/erl-rstar"},
      {:sentry, "~> 10.0"},
      {:server_sent_event_stage, "~> 1.0"},
      {:sizeable, "~> 0.1.5"},
      {:sweet_xml, "~> 0.7.1", only: [:prod, :dev]},
      {:telemetry, "0.4.3"},
      {:telemetry_metrics, "0.6.1"},
      {:telemetry_metrics_statsd, "0.7.0"},
      {:telemetry_poller, "0.5.1"},
      {:timex, ">= 2.0.0"},
      {:unrooted_polytree, "~> 0.1.1"},
      {:wallaby, "~> 0.30", [runtime: false, only: [:test, :dev]]}
    ]
  end

  defp aliases do
    [
      "compile.assets": &compile_assets/1,
      "phx.server": [&server_setup/1, "phx.server"]
    ]
  end

  defp compile_assets(_) do
    # starts the Phoenix framework mix phx.digest command, that takes content
    # from assets/static and processes it into priv/static
    print("(1/3) mix phx.digest")
    Mix.Task.run("phx.digest", [])

    # builds the node script that lets us render some react components
    # server-side, compiling assets/react_app.js,
    # outputting react_renderer/dist/app.js
    print("(2/3) webpack --config webpack.config.react_app.js --env.production")

    {_, 0} =
      System.cmd("npm", ["run", "--prefix", "assets", "webpack:build:react"],
        stderr_to_stdout: true
      )

    # 3 - transpiles/builds our typescript/CSS/everything else for production
    print("(3/3) webpack --config webpack.config.prod.js --env.production (long)")

    {_, 0} =
      System.cmd("npm", ["run", "--prefix", "assets", "webpack:build"], stderr_to_stdout: true)

    Mix.Task.run("phx.digest", [])
  end

  defp server_setup(_) do
    env = Mix.env()

    # the test environment server needs assets compiled for production,
    # in the dev environment the dev server would normally serve those
    if env == :test, do: compile_assets([])

    print_with_bg([
      "\nCompiling Dotcom for the ",
      :light_magenta_background,
      " #{env} ",
      :white_background,
      " Mix environment."
    ])

    Mix.Task.run("compile")

    print_with_bg([
      "\nReady to start server @ ",
      :light_green_background,
      " #{site_url()} ",
      :white_background,
      " now."
    ])
  end

  defp site_url do
    host = Application.get_env(:dotcom, DotcomWeb.Endpoint)[:url][:host]

    port =
      System.get_env("PORT") || Application.get_env(:dotcom, DotcomWeb.Endpoint)[:http][:port]

    "#{host}:#{port}"
  end

  defp print(text), do: Mix.shell().info([:cyan, text, :reset])

  defp print_with_bg(text_list),
    do: Mix.shell().info([:white_background, :blue] ++ text_list ++ [:reset])
end
