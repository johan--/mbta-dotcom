{:ok, _} = Application.ensure_all_started(:bypass)

# Ensure tzdata is up to date
{:ok, _} = Application.ensure_all_started(:tzdata)
{:ok, _} = Application.ensure_all_started(:wallaby)
_ = Tzdata.ReleaseUpdater.poll_for_update()
Application.put_env(:wallaby, :base_url, DotcomWeb.Endpoint.url())

# Avoid starting unneeded background processing during tests
System.put_env("USE_SERVER_SENT_EVENTS", "false")
System.put_env("WARM_CACHES", "false")
# Ensure the deps are all started
Application.ensure_all_started(:dotcom)
ExUnit.start(capture_log: true)
