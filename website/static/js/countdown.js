/* The holiday countdown: calendar days, like the app's countdown_text.dart
   (LocalDate.daysUntil), so a clock change can't move the number. */
(function () {
  "use strict";
  var form = document.getElementById("cd-form");
  if (!form) return;
  var places = JSON.parse(form.getAttribute("data-places"));
  var byId = {};
  places.forEach(function (p) { byId[p.id] = p; });
  var $ = function (id) { return document.getElementById(id); };
  var stage = $("cd-stage"), img = stage.querySelector(".postcard-img");
  var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  var KEY = "travary:countdown";

  var parseDate = function (s) {
    var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s || "");
    return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null;
  };
  var iso = function (d) {
    return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
  };
  var daysBetween = function (a, b) { // calendar dates, via UTC so DST can't shift it
    return Math.round((Date.UTC(b.getFullYear(), b.getMonth(), b.getDate()) - Date.UTC(a.getFullYear(), a.getMonth(), a.getDate())) / 864e5);
  };
  var range = function (s, e) {
    if (!e || daysBetween(s, e) <= 0) return s.getDate() + " " + months[s.getMonth()] + " " + s.getFullYear();
    if (s.getFullYear() !== e.getFullYear()) {
      return s.getDate() + " " + months[s.getMonth()] + " " + s.getFullYear() + " – " + e.getDate() + " " + months[e.getMonth()] + " " + e.getFullYear();
    }
    if (s.getMonth() === e.getMonth()) return s.getDate() + "–" + e.getDate() + " " + months[s.getMonth()] + " " + s.getFullYear();
    return s.getDate() + " " + months[s.getMonth()] + " – " + e.getDate() + " " + months[e.getMonth()] + " " + s.getFullYear();
  };

  var state = { n: "", p: "city_jp_kyoto", d: "", e: "" };
  var read = function () {
    var q = new URLSearchParams(location.search), saved = {};
    try { saved = JSON.parse(window.localStorage.getItem(KEY) || "{}"); } catch (e) { saved = {}; }
    var src = q.get("d") ? { n: q.get("n"), p: q.get("p"), d: q.get("d"), e: q.get("e") } : saved;
    // A postcard picked on the home page's wall: that place, keeping any saved dates.
    if (!q.get("d") && q.get("p")) src = { n: "", p: q.get("p"), d: saved.d, e: saved.e };
    if (src.p && byId[src.p]) state.p = src.p;
    if (src.n) state.n = String(src.n).slice(0, 40);
    if (parseDate(src.d)) state.d = src.d;
    if (parseDate(src.e)) state.e = src.e;
    if (!state.d) { var t = new Date(); t.setDate(t.getDate() + 58); state.d = iso(t); }
    $("cd-trip").value = state.n; $("cd-place").value = state.p; $("cd-start").value = state.d; $("cd-end").value = state.e;
  };
  var save = function () { try { window.localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { /* private mode */ } };

  var lastPlace = null;
  var render = function (animate) {
    var place = byId[state.p] || places[0];
    if (place.id !== lastPlace) {
      img.src = place.src;
      img.alt = "A postcard from " + place.name;
      lastPlace = place.id;
    }
    if (animate) { stage.classList.remove("is-new"); void stage.offsetWidth; stage.classList.add("is-new"); }
    var start = parseDate(state.d), end = parseDate(state.e);
    $("cd-name").textContent = state.n || place.name;
    if (!start) { $("cd-days").textContent = "—"; $("cd-dates").textContent = "Pick a date"; return; }
    var today = new Date(); today.setHours(0, 0, 0, 0);
    var days = daysBetween(today, start);
    $("cd-dates").textContent = range(start, end);
    if (days > 0) {
      $("cd-eyebrow").textContent = "Next trip";
      $("cd-days").textContent = String(days);
      $("cd-unit").textContent = days === 1 ? "day to go" : "days to go";
    } else if (days === 0 || (end && daysBetween(today, end) >= 0)) {
      $("cd-eyebrow").textContent = "It's here";
      $("cd-days").textContent = "0";
      $("cd-unit").textContent = days === 0 ? "it's today!" : "you're away";
    } else {
      $("cd-eyebrow").textContent = "Welcome home";
      $("cd-days").textContent = String(-days);
      $("cd-unit").textContent = -days === 1 ? "day ago" : "days ago";
    }
    tick();
  };
  var tick = function () {
    var start = parseDate(state.d);
    if (!start) return;
    var ms = Math.max(0, start.getTime() - Date.now());
    $("cd-wk").textContent = String(Math.floor(ms / 6048e5));
    $("cd-hr").textContent = Math.floor(ms / 36e5).toLocaleString();
    $("cd-min").textContent = Math.floor(ms / 6e4).toLocaleString();
    $("cd-sec").textContent = String(Math.floor(ms / 1e3) % 60);
  };
  var shareUrl = function () {
    var q = new URLSearchParams();
    if (state.n) q.set("n", state.n);
    q.set("p", state.p); q.set("d", state.d);
    if (state.e) q.set("e", state.e);
    return location.origin + location.pathname + "?" + q.toString();
  };

  form.addEventListener("input", function (e) {
    state.n = $("cd-trip").value.trim();
    state.p = $("cd-place").value;
    state.d = $("cd-start").value;
    state.e = $("cd-end").value;
    if (state.e && state.d && state.e < state.d) state.e = "";
    save();
    render(e.target.id === "cd-place" || e.target.id === "cd-start");
  });
  form.addEventListener("submit", function (e) { e.preventDefault(); });
  form.addEventListener("reset", function () {
    setTimeout(function () {
      state = { n: "", p: "city_jp_kyoto", d: "", e: "" };
      try { window.localStorage.removeItem(KEY); } catch (e) { /* private mode */ }
      history.replaceState(null, "", location.pathname);
      read(); render(true);
    }, 0);
  });
  $("cd-share").addEventListener("click", function () {
    var url = shareUrl(), msg = $("cd-msg");
    var done = function () { msg.textContent = "Link copied. Send it to everyone coming."; };
    if (navigator.share && /Mobi|Android|iPhone|iPad/.test(navigator.userAgent)) {
      navigator.share({ title: (state.n || byId[state.p].name) + " countdown", url: url }).catch(function () {});
    } else if (navigator.clipboard) {
      navigator.clipboard.writeText(url).then(done, function () { msg.textContent = url; });
    } else { msg.textContent = url; }
  });

  read();
  render(false);
  setInterval(tick, 1000);
})();
