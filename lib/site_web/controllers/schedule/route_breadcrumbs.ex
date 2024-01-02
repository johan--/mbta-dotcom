defmodule SiteWeb.ScheduleController.RouteBreadcrumbs do
  @moduledoc "Fetches the route from `conn.assigns` and assigns breadcrumbs."
  @behaviour Plug
  import Plug.Conn, only: [assign: 3]
  import SiteWeb.Router.Helpers, only: [mode_path: 2]
  alias Util.Breadcrumb

  @impl true
  def init([]), do: []

  @impl true
  def call(%{assigns: %{route: route}} = conn, []) do
    conn
    |> assign(:breadcrumbs, breadcrumbs(route))
  end

  def breadcrumbs(%{name: name, type: type}) do
    [
      Breadcrumb.build("Schedules & Maps", mode_path(SiteWeb.Endpoint, :index)),
      route_type_display(type),
      Breadcrumb.build(name)
    ]
  end

  def route_type_display(type) when type == 0 or type == 1 do
    Breadcrumb.build("Subway", mode_path(SiteWeb.Endpoint, :subway))
  end

  def route_type_display(2) do
    Breadcrumb.build("Commuter Rail", mode_path(SiteWeb.Endpoint, :commuter_rail))
  end

  def route_type_display(3) do
    Breadcrumb.build("Bus", mode_path(SiteWeb.Endpoint, :bus))
  end

  def route_type_display(4) do
    Breadcrumb.build("Ferry", mode_path(SiteWeb.Endpoint, :ferry))
  end
end
