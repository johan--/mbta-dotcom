import React, { ReactElement } from "react";
import { groupBy } from "lodash";
import { Alert, Route } from "../../__v3api";
import { routeName, routeToModeIcon } from "../../helpers/route-headers";
import { routeBgClass } from "../../helpers/css";
import renderSvg from "../../helpers/render-svg";
import DepartureTimes from "./DepartureTimes";
import { allAlertsForDirection } from "../../models/alert";
import { DepartureInfo } from "../../models/departureInfo";

const DepartureCard = ({
  route,
  departuresForRoute,
  alertsForRoute = [],
  stopName
}: {
  route: Route;
  departuresForRoute: DepartureInfo[];
  alertsForRoute: Alert[];
  stopName: string;
}): ReactElement<HTMLElement> => {
  const departuresByDirection = groupBy(
    departuresForRoute,
    "trip.direction_id"
  );

  return (
    <li className="departure-card">
      <a
        className={`departure-card__route ${routeBgClass(route)}`}
        href={`/schedules/${route.id}`}
        data-turbolinks="false"
      >
        {renderSvg("c-svg__icon", routeToModeIcon(route), true)}{" "}
        {routeName(route)}
      </a>
      {/* TODO can we avoid hard coding the direction ids? */}
      <>
        <DepartureTimes
          key={`${route.id}-0`}
          route={route}
          directionId={0}
          stopName={stopName}
          departuresForDirection={departuresByDirection[0] || []}
          alertsForDirection={allAlertsForDirection(alertsForRoute, 0)}
        />
        <DepartureTimes
          key={`${route.id}-1`}
          route={route}
          directionId={1}
          stopName={stopName}
          departuresForDirection={departuresByDirection[1] || []}
          alertsForDirection={allAlertsForDirection(alertsForRoute, 1)}
        />
      </>
    </li>
  );
};

export default DepartureCard;
