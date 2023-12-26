defmodule SiteWeb.LineApiTest do
  use SiteWeb.ConnCase, async: true

  describe "show" do
    test "success response", %{conn: conn} do
      conn = get(conn, line_api_path(conn, :show, %{"id" => "Red", "direction_id" => "1"}))

      assert json_response(conn, 200)
    end

    test "bad route", %{conn: conn} do
      conn = get(conn, line_api_path(conn, :show, %{"id" => "Puce", "direction_id" => "1"}))

      assert conn.status == 400
      body = json_response(conn, 400)
      assert body["error"] == "Invalid arguments"
    end
  end

  describe "realtime" do
    setup do
      # needed by an underlying Plug
      _ = start_supervised({Phoenix.PubSub, name: Vehicles.PubSub})
      _ = start_supervised(Vehicles.Repo)
      :ok
    end

    @tag :live_data
    test "success response", %{conn: conn} do
      conn =
        get(
          conn,
          line_api_path(conn, :realtime, %{"id" => "Red", "direction_id" => "1", "v" => "2"})
        )

      assert %{"place-brdwy" => %{"headsigns" => _, "vehicles" => _}} = json_response(conn, 200)
    end
  end
end
