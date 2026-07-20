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
