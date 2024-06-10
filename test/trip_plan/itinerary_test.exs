defmodule TripPlan.ItineraryTest do
  use ExUnit.Case, async: true

  import Mox
  import Test.Support.Factory.TripPlanner
  import TripPlan.Itinerary

  alias Test.Support.Factory.MbtaApi
  alias TripPlan.{TransitDetail, Leg, PersonalDetail, TransitDetail}

  @from build(:stop_named_position)
  @to build(:stop_named_position)
  @transit_leg build(:transit_leg, from: @from, to: @to)

  setup :verify_on_exit!

  setup do
    # The itinerary parsing currently queries for trips to aid in assigning fare
    # values to legs, when those legs are transit legs within the MBTA service
    # network.
    stub(MBTA.Api.Mock, :get_json, fn path, _ ->
      case path do
        "/trips/" <> _ ->
          %JsonApi{links: %{}, data: [MbtaApi.build(:trip_item)]}

        "/routes/" <> _ ->
          %JsonApi{links: %{}, data: [MbtaApi.build(:route_item)]}

        _ ->
          %JsonApi{links: %{}, data: []}
      end
    end)

    stub(Stops.Repo.Mock, :get, fn _ ->
      Test.Support.Factory.Stop.build(:stop)
    end)

    itinerary = build(:itinerary, legs: [@transit_leg])

    %{itinerary: itinerary}
  end

  describe "destination/1" do
    test "returns the final destination of the itinerary", %{itinerary: itinerary} do
      assert destination(itinerary) == @to
    end
  end

  describe "transit_legs/1" do
    test "returns all transit legs excluding personal legs", %{itinerary: itinerary} do
      assert Enum.all?(transit_legs(itinerary), &Leg.transit?/1)
    end
  end

  describe "route_ids/1" do
    test "returns all the route IDs from the itinerary", %{itinerary: itinerary} do
      test_calculated_ids =
        Enum.flat_map(itinerary, fn leg ->
          case leg.mode do
            %TransitDetail{route: route} -> [route.id]
            _ -> []
          end
        end)

      assert test_calculated_ids == route_ids(itinerary)
    end
  end

  describe "trip_ids/1" do
    test "returns all the trip IDs from the itinerary", %{itinerary: itinerary} do
      test_calculated_ids =
        Enum.flat_map(itinerary, fn leg ->
          case leg.mode do
            %TransitDetail{trip_id: trip_id} -> [trip_id]
            _ -> []
          end
        end)

      assert test_calculated_ids == trip_ids(itinerary)
    end
  end

  describe "route_trip_ids/1" do
    test "returns all the route and trip IDs from the itinerary", %{itinerary: itinerary} do
      test_calculated_ids =
        Enum.flat_map(itinerary.legs, fn leg ->
          case leg.mode do
            %TransitDetail{} = td -> [{td.route.id, td.trip_id}]
            _ -> []
          end
        end)

      assert test_calculated_ids == route_trip_ids(itinerary)
    end
  end

  describe "positions/1" do
    test "returns all named positions for the itinerary" do
      itinerary =
        build(:itinerary,
          legs: build_list(3, :walking_leg, from: @from, to: @to)
        )

      [first, second, third] = itinerary.legs
      expected = [first.from, first.to, second.from, second.to, third.from, third.to]
      assert positions(itinerary) == expected
    end
  end

  describe "stop_ids/1" do
    test "returns all the stop IDs from the itinerary", %{itinerary: itinerary} do
      test_calculated_ids =
        Enum.uniq(Enum.flat_map(itinerary.legs, &[&1.from.stop.id, &1.to.stop.id]))

      assert test_calculated_ids == stop_ids(itinerary)
    end
  end

  describe "walking_distance/1" do
    test "calculates walking distance of itinerary" do
      itinerary = %TripPlan.Itinerary{
        start: DateTime.from_unix(10),
        stop: DateTime.from_unix(13),
        legs: [
          %Leg{mode: %PersonalDetail{distance: 12.3}},
          %Leg{mode: %TransitDetail{}},
          %Leg{mode: %PersonalDetail{distance: 34.5}}
        ]
      }

      assert abs(walking_distance(itinerary) - 46.8) < 0.001
    end
  end

  describe "intermediate_stop_ids" do
    test "returns intermediate stop ids if the leg is transit detail and has them" do
      itinerary = %TripPlan.Itinerary{
        start: DateTime.from_unix(10),
        stop: DateTime.from_unix(13),
        legs: [
          %Leg{mode: %PersonalDetail{}},
          %Leg{
            mode: %TransitDetail{
              intermediate_stops: ["1", "2", "3"] |> Enum.map(&%Stops.Stop{id: &1})
            }
          },
          %Leg{mode: %PersonalDetail{}}
        ]
      }

      assert intermediate_stop_ids(itinerary) == ["1", "2", "3"]
    end

    test "does not return duplicate ids" do
      itinerary = %TripPlan.Itinerary{
        start: DateTime.from_unix(10),
        stop: DateTime.from_unix(13),
        legs: [
          %Leg{mode: %PersonalDetail{}},
          %Leg{
            mode: %TransitDetail{
              intermediate_stops: ["1", "2", "3"] |> Enum.map(&%Stops.Stop{id: &1})
            }
          },
          %Leg{
            mode: %TransitDetail{
              intermediate_stops: ["1", "2", "3"] |> Enum.map(&%Stops.Stop{id: &1})
            }
          }
        ]
      }

      assert intermediate_stop_ids(itinerary) == ["1", "2", "3"]
    end
  end
end
