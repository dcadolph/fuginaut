(function () {
  "use strict";

  var heroClock = document.getElementById("hero-clock");
  var appleClock = document.getElementById("apple-clock");
  var playClock = document.getElementById("play-clock");
  var form = document.getElementById("play-form");

  // format runs Intl with options, and drops any calendar or numeral the browser refuses.
  function format(locale, options, now) {
    try {
      return new Intl.DateTimeFormat(locale, options).format(now);
    } catch (e) {
      var plain = Object.assign({}, options);
      delete plain.calendar;
      delete plain.numberingSystem;
      return new Intl.DateTimeFormat(locale, plain).format(now);
    }
  }

  // iso writes the date as YYYY-MM-DD in the local zone. ISO styles stay Gregorian, as they do in the app.
  function iso(now) {
    function pad(n) { return String(n).padStart(2, "0"); }
    return now.getFullYear() + "-" + pad(now.getMonth() + 1) + "-" + pad(now.getDate());
  }

  // dateOptions maps a style to Intl's date fields.
  function dateOptions(style) {
    switch (style) {
      case "long": return { weekday: "long", month: "long", day: "numeric" };
      case "year": return { weekday: "short", month: "short", day: "numeric", year: "numeric" };
      case "numeric": return { weekday: "short", month: "numeric", day: "numeric" };
      default: return { weekday: "short", month: "short", day: "numeric" };
    }
  }

  // playText writes the playground clock from the form's choices.
  function playText(now) {
    var d = new FormData(form);
    var lang = d.get("lang");
    var world = {};
    if (d.get("nu")) { world.numberingSystem = d.get("nu"); }
    var clock = Object.assign({ hour: "numeric", minute: "2-digit", hourCycle: d.get("h24") ? "h23" : "h12" }, world);
    if (d.get("seconds")) { clock.second = "2-digit"; }
    var parts = [];
    var style = d.get("style");
    if (style === "iso") {
      parts.push(iso(now));
    } else if (style !== "none") {
      var date = Object.assign(dateOptions(style), world);
      if (d.get("ca")) { date.calendar = d.get("ca"); }
      var written = format(lang, date, now);
      // The app writes English without the comma after the weekday, except in the Long style.
      parts.push(lang === "en-US" && style !== "long" ? written.replace(",", "") : written);
    }
    parts.push(format(lang, clock, now));
    var text = parts.join("\u00a0\u00a0");
    if (d.get("tokyo")) {
      // The ordinary space lets a narrow bar wrap after the dot and keeps the label with its time.
      text += "\u00a0\u00a0\u00b7\u00a0 TYO\u00a0" + format(lang, Object.assign({}, clock, { timeZone: "Asia/Tokyo" }), now);
    }
    return d.get("caps") ? text.toLocaleUpperCase(lang) : text;
  }

  var fonts = {
    system: "var(--sans)",
    rounded: 'ui-rounded, "SF Pro Rounded", var(--sans)',
    mono: "var(--mono)",
    serif: 'ui-serif, "New York", Georgia, serif'
  };

  // stylePlay applies the font, color, and backing. Every swatch here reads as light, so the backing is the
  // black the app draws behind light text, at the app's opacity.
  function stylePlay() {
    var d = new FormData(form);
    var el = playClock.parentNode;
    var color = d.get("color");
    el.style.fontFamily = fonts[d.get("font")];
    el.style.color = color;
    el.style.background = d.get("backing") === "pill" ? "rgb(0 0 0 / 0.42)" : "transparent";
    el.style.textShadow = d.get("backing") === "shadow" ? "0 0 3px rgb(0 0 0 / 0.85)" : "none";
  }

  // tick redraws every clock from the visitor's own time.
  function tick() {
    var now = new Date();
    var date = format("en-US", { weekday: "short", month: "short", day: "numeric" }, now).replace(",", "");
    var time = format("en-US", { hour: "numeric", minute: "2-digit" }, now);
    var day = format("en-US", { weekday: "short" }, now);
    if (heroClock) { heroClock.textContent = date + "  " + time; }
    if (appleClock) { appleClock.textContent = day + " " + time; }
    if (playClock) { playClock.textContent = playText(now); }
  }

  if (form) {
    form.addEventListener("input", function () { stylePlay(); tick(); });
    form.addEventListener("submit", function (e) { e.preventDefault(); });
    stylePlay();
  }
  tick();
  setInterval(tick, 1000);

  Array.prototype.forEach.call(document.querySelectorAll("[data-copy]"), function (button) {
    var label = button.querySelector("[data-copied]");
    button.addEventListener("click", function () {
      if (!navigator.clipboard) { return; }
      navigator.clipboard.writeText(button.getAttribute("data-copy")).then(function () {
        label.textContent = "Copied";
        setTimeout(function () { label.textContent = "Copy"; }, 1600);
      });
    });
  });
})();
