defmodule DotcomWeb.VehicleMapMarkerChannelTest do
  use DotcomWeb.ChannelCase, async: false

  alias Leaflet.MapData.Marker
  alias DotcomWeb.{VehicleMapMarkerChannel, UserSocket}
  alias Vehicles.Vehicle
  import Mock

  @vehicles [
    %Vehicle{
      id: "1",
      route_id: "CR-Lowell",
      direction_id: 0,
      stop_id: "BNT-0000-01",
      status: :in_transit,
      trip_id: "trip"
    }
  ]

  setup_all do
    # needed by DotcomWeb.ScheduleController.VehicleLocations plug
    _ = start_supervised({Phoenix.PubSub, name: Vehicles.PubSub})
    _ = start_supervised(Vehicles.Repo)

    :ok
  end

  test "sends vehicles and marker data" do
    # subscribes to a random channel name to
    # avoid receiving real data in assert_push
    assert {:ok, _, socket} =
             UserSocket
             |> socket("", %{some: :assign})
             |> subscribe_and_join(
               VehicleMapMarkerChannel,
               "vehicles:VehicleMapMarkerChannelTest"
             )

    [vehicle | _] = @vehicles

    assert {:noreply, %Phoenix.Socket{}} =
             VehicleMapMarkerChannel.handle_out("reset", %{data: @vehicles}, socket)

    assert_push("data", vehicles)

    assert %{data: [vehicle_with_marker | _]} = vehicles

    assert %{
             data: %{stop_name: _, vehicle: ^vehicle},
             marker: %Marker{}
           } = vehicle_with_marker
  end

  test "sends vehicle ids for remove event" do
    assert {:ok, _, socket} =
             UserSocket
             |> socket("", %{some: :assign})
             |> subscribe_and_join(
               VehicleMapMarkerChannel,
               "vehicles:VehicleMapMarkerChannelTest2"
             )

    assert {:noreply, %Phoenix.Socket{}} =
             VehicleMapMarkerChannel.handle_out("remove", %{data: ["vehicle_id"]}, socket)

    assert_push("data", vehicles)

    assert vehicles == %{data: ["vehicle_id"], event: "remove"}
  end

  test "responds to init push by sending data" do
    assert {:ok, _, socket} =
             UserSocket
             |> socket("", %{some: :assign})
             |> subscribe_and_join(
               VehicleMapMarkerChannel,
               "vehicles:VehicleMapMarkerChannelTest3"
             )

    assert {:noreply, %Phoenix.Socket{}} =
             VehicleMapMarkerChannel.handle_in(
               "init",
               %{"route_id" => "route_id", "direction_id" => "0"},
               socket
             )

    assert_push("data", _)
  end

  test "fetches and processes vehicle prediction when buliding tooltip_text" do
    route = %Routes.Route{id: "CR-Lowell"}

    trip = %Schedules.Trip{
      id: "trip",
      headsign: "Train Trip"
    }

    stop = %Stops.Stop{name: "North Station", id: "place-north"}

    prediction = %Predictions.Prediction{
      route: route,
      trip: trip,
      stop: stop,
      direction_id: 0,
      status: "All aboard",
      track: "20",
      vehicle_id: List.first(@vehicles) |> Map.get(:id),
      departing?: true
    }

    with_mocks [
      {Routes.Repo, [:passthrough], [get: fn _ -> route end]},
      {Schedules.Repo, [:passthrough], [trip: fn _ -> trip end]},
      {Predictions.Repo, [:passthrough], [all: fn _ -> [prediction] end]},
      {Stops.Repo, [:passthrough], [get: fn _ -> stop end]}
    ] do
      assert {:ok, _, socket} =
               UserSocket
               |> socket("", %{some: :assign})
               |> subscribe_and_join(
                 VehicleMapMarkerChannel,
                 "vehicles:VehicleMapMarkerChannelTest4"
               )

      [vehicle | _] = @vehicles

      VehicleMapMarkerChannel.handle_out("reset", %{data: @vehicles}, socket)

      assert_push("data", vehicles)

      assert %{data: [vehicle_with_marker | _]} = vehicles

      assert %{
               data: %{stop_name: _, vehicle: ^vehicle},
               marker: %Marker{
                 tooltip_text: tooltip_text
               }
             } = vehicle_with_marker

      assert tooltip_text =~ "Train Trip train is on the way to North Station"
      assert tooltip_text =~ "all aboard on track 20"
    end
  end
end
