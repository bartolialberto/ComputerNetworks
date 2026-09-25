/*
 * Reset the navigation drawer state whenever a page is shown.
 *
 * On phones MkDocs Material drives the drawer, its submenus and the
 * integrated TOC with hidden checkboxes. When the user goes back/forward,
 * the browser restores those checkboxes as they were when the page was left
 * (back-forward cache and form-state restoration), so the drawer stays open
 * on a stale submenu instead of reflecting the page being displayed.
 * Here every checkbox is brought back to its state as generated in the HTML.
 */
(function () {
  function resetNav() {
    document
      .querySelectorAll("input.md-toggle, input.md-nav__toggle")
      .forEach(function (input) {
        input.checked = input.defaultChecked;
      });
  }
  window.addEventListener("pageshow", resetNav);
})();
