import React, { useState } from "react";
import { StateUpdater } from "@algolia/autocomplete-core";
import { SourceTemplates } from "@algolia/autocomplete-js";
import geolocationPromise from "../../../../js/geolocation-promise";
import { Item } from "../__autocomplete";

function GeolocationComponent(props: {
  setIsOpen: StateUpdater<boolean>;
  setQuery: StateUpdater<string>;
  onSelect: Function;
}): React.ReactElement {
  const { setIsOpen, setQuery, onSelect } = props;
  const [loading, setLoading] = useState<string>();
  const [hasError, setHasError] = useState(false);

  if (loading) {
    return (
      <div style={{ textAlign: "center" }}>
        {loading} <i aria-hidden="true" className="fa fa-cog fa-spin" />
      </div>
    );
  }

  if (hasError) {
    return (
      <div className="u-error">
        {`${window.location.host} needs permission to use your location. Please update your browser's settings or refresh the page and try again.`}
      </div>
    );
  }

  return (
    <button
      id="search-bar__my-location"
      className="c-search-bar__my-location"
      type="button"
      onClick={event => {
        event.stopPropagation();
        setIsOpen(true);
        setLoading("Getting your location...");
        geolocationPromise()
          .then(({ coords }) => {
            setLoading("Thanks");
            const { latitude, longitude } = coords;
            onSelect({
              item: {
                latitude,
                longitude,
                name: `Near ${latitude}, ${longitude}`
              },
              setQuery
            });
            setTimeout(() => {
              setLoading(undefined);
              setHasError(false);
              setIsOpen(false);
            }, 300);
          })
          .catch(e => {
            console.error(e);
            setHasError(true);
            setLoading(undefined);
          });
      }}
    >
      <span>
        <span
          className="c-search-result__content-icon fa fa-location-arrow"
          aria-hidden="true"
        />
      </span>
      <span className="aa-ItemContentTitle">Use my location</span>
    </button>
  );
}

const getGeolocationTemplate = (
  setIsOpen: StateUpdater<boolean>,
  setQuery: StateUpdater<string>,
  onSelect: Function
): SourceTemplates<Item>["item"] =>
  function GeolocationTemplate() {
    return (
      <GeolocationComponent
        setIsOpen={setIsOpen}
        onSelect={onSelect}
        setQuery={setQuery}
      />
    );
  };

export default getGeolocationTemplate;
