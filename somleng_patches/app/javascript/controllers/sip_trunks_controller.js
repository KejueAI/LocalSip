import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "authenticationModeInput",
    "countrySelectInput",
    "ipAddressAuthenticationSection",
    "outboundRegistrationSection",
    "regionInput",
    "regionHint",
  ];

  connect() {
    this.toggleAuthenticationMode();
    this.toggleRegion();
  }

  toggleAuthenticationMode() {
    const element = this.authenticationModeInputTargets.find(
      (element) => element.checked
    );

    if (element.value == "client_credentials") {
      if (!("selectedCountry" in this.countrySelectInputTarget.dataset)) {
        this.countrySelectInputTarget.value =
          this.countrySelectInputTarget.dataset.defaultCountry;
      }
      this.ipAddressAuthenticationSectionTargets.forEach(
        (target) => (target.style.display = "none")
      );
      this.outboundRegistrationSectionTargets.forEach(
        (target) => (target.style.display = "none")
      );
    } else if (element.value == "outbound_registration") {
      this.countrySelectInputTarget.value =
        this.countrySelectInputTarget.dataset.selectedCountry;
      this.ipAddressAuthenticationSectionTargets.forEach(
        (target) => (target.style.display = "none")
      );
      this.outboundRegistrationSectionTargets.forEach(
        (target) => (target.style.display = "block")
      );
    } else {
      this.countrySelectInputTarget.value =
        this.countrySelectInputTarget.dataset.selectedCountry;
      this.ipAddressAuthenticationSectionTargets.forEach(
        (target) => (target.style.display = "block")
      );
      this.outboundRegistrationSectionTargets.forEach(
        (target) => (target.style.display = "none")
      );
    }
  }

  toggleRegion() {
    const element = this.regionInputTarget;
    const hint = this.regionHintTarget;
    const regionNameHint = hint.querySelector(hint.dataset.regionNameTarget);
    const ipAddressHint = hint.querySelector(hint.dataset.ipAddressTarget);
    const selectedRegion = element.options[element.selectedIndex];
    regionNameHint.textContent = selectedRegion.text;
    ipAddressHint.textContent = selectedRegion.dataset.ipAddress;
  }
}
