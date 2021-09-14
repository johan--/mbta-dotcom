// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//

/**
 * Helper to run an arbirary mix task.
 *
 * Usage: `cy.mix('test_helpers.feedback_email').then((result) => {
 *    yields the 'result' object, e.g
 *    {
 *      code: 0,
 *      stdout: "Files successfully built",
 *      stderr: ""
 *    }
 *  })`
 */
Cypress.Commands.add("mix", cmd => cy.exec(`mix ${cmd}`));

/**
 * Checks the Recaptcha checkbox, verifying checked state before proceeding.
 * Relies on "chromeWebSecurity": false configured in cypress.json
 * as it interacts with an iframe generated by the recaptcha script.
 *
 * Usage: `cy.fillRecaptcha()`
 */
Cypress.Commands.add("fillRecaptcha", () => {
  cy.iframe('iframe[title="reCAPTCHA"]')
    .find("#recaptcha-anchor")
    .click();
  cy.iframe('iframe[title="reCAPTCHA"]')
    .find("#recaptcha-accessible-status", { timeout: 10000 })
    .should("contain.text", "You are verified");
});

/**
 * On the customer support form, select an arbitrary service and subject pairing
 * out of all possible values. Also saves the selected values to an alias so it
 * can be used later in a test.
 *
 * Usage: `cy.selectRandomServiceAndSubject()`
 * Get values: `cy.get('@selectedService')` or `cy.get('@selectedSubject')`
 */
const randomSelection = availableSelections =>
  availableSelections[Cypress._.random(0, availableSelections.length - 1)];

Cypress.Commands.add("selectRandomServiceAndSubject", () => {
  cy.get("#js-subjects-by-service")
    .invoke("text")
    .then(text => {
      const subjectsByService = JSON.parse(text);
      const service = randomSelection(Object.keys(subjectsByService));
      const subject = randomSelection(subjectsByService[service]);
      cy.get(`#service-${service}`).check({ force: true });
      cy.get("#support_subject").select(subject);
      cy.get('[name="support[service]"]:checked')
        .invoke("val")
        .as("selectedService");
      cy.get("#support_subject option:selected")
        .invoke("text")
        .as("selectedSubject");
    });
});

/**
 * Use the same way as cy.screenshot()
 * 
 * This includes a hack so that full page snapshots can be properly captured.
 */
Cypress.Commands.add("takeFullScreenshot", (subject, name, options={}) => {
  /**
   * Hack for dealing with screenshots.
   * See Cypress bugs: https://github.com/cypress-io/cypress/issues/2681
   * and https://github.com/cypress-io/cypress/issues/3200
   */
  cy.get('html')
    .invoke('css', 'height', 'initial')
    .invoke('css', 'scrollBehavior', 'initial');
  cy.get('body').invoke('css', 'height', 'initial');

  cy.wait(100);
  cy.screenshot(subject, name, options);
});
