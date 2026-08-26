document.addEventListener("DOMContentLoaded", function () {
  var link = null;
  document.querySelectorAll(".navbar a.nav-link").forEach(function (a) {
    if (a.textContent.indexOf("🇬🇧") !== -1 || a.textContent.indexOf("🇮🇩") !== -1) {
      link = a;
    }
  });
  if (!link) return;
  link.classList.add("pbp-lang-toggle");

  var libLink = document.querySelector('link[href*="site_libs/"]');
  if (!libLink) return;
  var upCount = (libLink.getAttribute("href").match(/\.\.\//g) || []).length;

  var pathParts = window.location.pathname.split("/");
  var splitIndex = pathParts.length - 1 - upCount;
  var rootPrefix = pathParts.slice(0, splitIndex);
  var relFromRoot = pathParts.slice(splitIndex);

  var isEn = document.documentElement.lang === "en";
  var target;
  if (isEn) {
    var trueRoot = rootPrefix.slice(0, -1);
    target = trueRoot.concat(relFromRoot).join("/");
    link.textContent = "🇮🇩 Indonesia";
    link.setAttribute("aria-label", "Ganti ke Bahasa Indonesia");
  } else {
    target = rootPrefix.concat(["en"], relFromRoot).join("/");
    link.textContent = "🇬🇧 English";
    link.setAttribute("aria-label", "Switch to English");
  }
  link.setAttribute("href", target);
});

// Quarto's frontmatter `title:` can't vary per language profile, so a page
// using the .pbp-banner/.pbp-page-title pattern (which replaces the VISIBLE
// heading per language already) still leaves the browser tab/<title> tag
// showing the original-language frontmatter text. Override it from whichever
// translated heading is actually on the page.
document.addEventListener("DOMContentLoaded", function () {
  var headingEl = document.querySelector(".pbp-banner-title, h1.pbp-page-title");
  if (!headingEl) return;
  var correctTitle = headingEl.textContent.trim();
  var parts = document.title.split(" – ");
  var suffix = parts.length > 1 ? parts.slice(1).join(" – ") : null;
  document.title = suffix ? correctTitle + " – " + suffix : correctTitle;
});
