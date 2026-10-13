/*
 * Mark the top-level list items that start with a link, e.g.
 *     - [Title](url) description
 * with the class "link-card", which css/custom.css renders as a card.
 *
 * "Starts with a link" means that the very first content of the item,
 * plain text included, is a link: "- Some text [link](url)" is not a card.
 * (CSS alone cannot see plain text, hence this script.)
 */
(function () {
  // First child node that is not whitespace-only text
  function firstContent(node) {
    for (var n = node.firstChild; n; n = n.nextSibling) {
      if (n.nodeType === Node.TEXT_NODE && !n.textContent.trim()) continue;
      if (n.nodeType === Node.COMMENT_NODE) continue;
      return n;
    }
    return null;
  }

  function isLink(n) {
    return n && n.nodeType === Node.ELEMENT_NODE && n.tagName === "A";
  }

  document
    .querySelectorAll(".md-content .md-typeset > ul > li")
    .forEach(function (li) {
      var first = firstContent(li);
      // Loose lists wrap the item content in a <p>
      if (first && first.nodeType === Node.ELEMENT_NODE && first.tagName === "P") {
        first = firstContent(first);
      }
      if (isLink(first)) li.classList.add("link-card");
    });
})();
