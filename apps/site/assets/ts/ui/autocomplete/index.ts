import {
  AutocompleteApi,
  AutocompleteOptions,
  autocomplete
} from "@algolia/autocomplete-js";
import { createElement, Fragment } from "react";
import { render } from "react-dom";
import getSources from "./sources";
import { Item } from "./__autocomplete";
import { STATE_CHANGE_HANDLERS } from "./helpers";

// replace the default Preact-based renderer used by AutocompleteJS
const reactRenderer = {
  createElement,
  Fragment,
  render
} as AutocompleteOptions<Item>["renderer"];

// Listens to the veil click to close the autocomplete suggestions
function setupVeilCloseListener(autocompleteApi: AutocompleteApi<Item>): void {
  document
    .querySelector("[data-nav='veil']")
    ?.addEventListener("click", () => autocompleteApi.setIsOpen(false));
}

/**
 * Creates the Algolia Autocomplete instances for various search experiences on
 * MBTA.com.
 */
function setupAlgoliaAutocomplete(wrapper: HTMLElement): void {
  const container = wrapper.querySelector<HTMLElement>(
    ".c-search-bar__autocomplete"
  );
  const panelContainer = wrapper.querySelector<HTMLElement>(
    ".c-search-bar__autocomplete-results"
  );
  if (!container || !panelContainer) throw new Error("container needed");
  const options: AutocompleteOptions<Item> = {
    id: container.id,
    container,
    panelContainer,
    detachedMediaQuery: "none",
    classNames: {
      input: "c-form__input-container"
    },
    openOnFocus: true,
    onStateChange:
      STATE_CHANGE_HANDLERS[`${container.dataset.stateChangeListener}`],
    onSubmit({ state }) {
      window.Turbolinks.visit(`/search?query=${state.query}`);
    },
    placeholder: container.dataset.placeholder,
    getSources: params => getSources(container.dataset, params),
    renderer: reactRenderer
  };
  setupVeilCloseListener(autocomplete(options));
}

export default setupAlgoliaAutocomplete;