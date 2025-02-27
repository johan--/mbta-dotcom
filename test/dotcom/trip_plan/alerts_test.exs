defmodule Dotcom.TripPlan.AlertsTest do
  use ExUnit.Case, async: true

  import Dotcom.TripPlan.Alerts
  import Mox

  alias Alerts.{Alert, InformedEntity}
  alias Dotcom.TripPlan.Itinerary
  alias Test.Support.Factories.{MBTA.Api, Stops.Stop, TripPlanner.TripPlanner}

  setup :verify_on_exit!

  setup do
    stub(Stops.Repo.Mock, :get, fn _ ->
      Stop.build(:stop)
    end)

    leg = TripPlanner.build(:transit_leg)

    itinerary =
      TripPlanner.build(:itinerary,
        legs: [leg]
      )

    [route_id] = Itinerary.route_ids(itinerary)
    [trip_id] = Itinerary.trip_ids(itinerary)

    {:ok, %{itinerary: itinerary, route_id: route_id, trip_id: trip_id, route: leg.mode.route}}
  end

  describe "filter_for_itinerary/2" do
    test "returns an alert if it affects the route", %{itinerary: itinerary, route_id: route_id} do
      expect(MBTA.Api.Mock, :get_json, fn "/trips/" <> id, [] ->
        %JsonApi{
          data: [
            Api.build(:trip_item, %{id: id})
          ]
        }
      end)

      good_alert =
        Alert.new(
          active_period: [valid_active_period(itinerary)],
          informed_entity: [%InformedEntity{route: route_id}]
        )

      bad_alert = Alert.update(good_alert, informed_entity: [%InformedEntity{route: "not_valid"}])
      assert_only_good_alert(good_alert, bad_alert, itinerary)
    end

    test "returns an alert if it affects the trip", %{itinerary: itinerary, trip_id: trip_id} do
      expect(MBTA.Api.Mock, :get_json, fn "/trips/" <> ^trip_id, [] ->
        %JsonApi{
          data: [
            Api.build(:trip_item, %{id: trip_id})
          ]
        }
      end)

      good_alert =
        Alert.new(
          active_period: [valid_active_period(itinerary)],
          informed_entity: [%InformedEntity{trip: trip_id}]
        )

      bad_alert = Alert.update(good_alert, informed_entity: [%InformedEntity{trip: "not_valid"}])
      assert_only_good_alert(good_alert, bad_alert, itinerary)
    end

    test "returns an alert if it affects the route in a direction", %{
      itinerary: itinerary,
      route_id: route_id
    } do
      expect(MBTA.Api.Mock, :get_json, fn "/trips/" <> id, [] ->
        %JsonApi{
          data: [
            Api.build(:trip_item, %{
              id: id,
              attributes: %{"direction_id" => 1}
            })
          ]
        }
      end)

      good_alert =
        Alert.new(
          active_period: [valid_active_period(itinerary)],
          informed_entity: [%InformedEntity{route: route_id, direction_id: 1}]
        )

      bad_alert =
        Alert.update(good_alert,
          informed_entity: [%InformedEntity{route: route_id, direction_id: 0}]
        )

      assert_only_good_alert(good_alert, bad_alert, itinerary)
    end

    test "returns an alert if it affects the route's type", %{
      itinerary: itinerary,
      route: route
    } do
      expect(MBTA.Api.Mock, :get_json, fn "/trips/" <> id, [] ->
        %JsonApi{
          data: [
            Api.build(:trip_item, %{id: id})
          ]
        }
      end)

      good_alert =
        Alert.new(
          active_period: [valid_active_period(itinerary)],
          informed_entity: [%InformedEntity{route_type: route.type}]
        )

      bad_alert =
        Alert.update(good_alert, informed_entity: [%InformedEntity{route_type: route.type + 1}])

      assert_only_good_alert(good_alert, bad_alert, itinerary)
    end

    test "returns an alert if it matches a transfer stop", %{itinerary: itinerary} do
      expect(MBTA.Api.Mock, :get_json, fn "/trips/" <> id, [] ->
        %JsonApi{
          data: [
            Api.build(:trip_item, %{id: id})
          ]
        }
      end)

      stop_id = itinerary |> Itinerary.stop_ids() |> Enum.at(1)

      good_alert =
        Alert.new(
          active_period: [valid_active_period(itinerary)],
          informed_entity: [%InformedEntity{stop: stop_id}]
        )

      bad_alert =
        Alert.update(good_alert,
          informed_entity: [%InformedEntity{stop: stop_id, route: "different route"}]
        )

      assert_only_good_alert(good_alert, bad_alert, itinerary)
    end

    test "ignores an alert if it's at the wrong time", %{itinerary: itinerary, route_id: route_id} do
      expect(MBTA.Api.Mock, :get_json, fn "/trips/" <> id, [] ->
        %JsonApi{
          data: [
            Api.build(:trip_item, %{id: id})
          ]
        }
      end)

      good_alert =
        Alert.new(
          active_period: [valid_active_period(itinerary)],
          informed_entity: [%InformedEntity{route: route_id}]
        )

      bad_alert = Alert.update(good_alert, active_period: [invalid_active_period(itinerary)])
      assert_only_good_alert(good_alert, bad_alert, itinerary)
    end
  end

  defp assert_only_good_alert(good_alert, bad_alert, itinerary) do
    assert filter_for_itinerary([good_alert, bad_alert], itinerary) == [good_alert]
  end

  defp valid_active_period(%Itinerary{start: start, stop: stop}) do
    {start, stop}
  end

  defp invalid_active_period(%Itinerary{start: start}) do
    {nil, Timex.shift(start, hours: -1)}
  end
end
