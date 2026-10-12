/* travary.app: small, dependency-free behaviour. Everything degrades to a
   readable static page without it. */
(function () {
  "use strict";
  var doc = document.documentElement;
  doc.classList.remove("no-js");
  var reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  var store = {
    get: function (k) { try { return window.localStorage.getItem(k); } catch (e) { return null; } },
    set: function (k, v) { try { window.localStorage.setItem(k, v); } catch (e) { /* private mode */ } }
  };

  /* header: a hairline once the page scrolls; the phone menu */
  var header = document.querySelector(".site-header");
  if (header) {
    var onScroll = function () { header.classList.toggle("is-scrolled", window.scrollY > 8); };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    var toggle = header.querySelector(".nav-toggle");
    var menu = document.getElementById("mobile-nav");
    if (toggle && menu) {
      toggle.addEventListener("click", function () {
        var open = toggle.getAttribute("aria-expanded") === "true";
        toggle.setAttribute("aria-expanded", String(!open));
        menu.hidden = open;
      });
    }
  }

  /* reveal on scroll: anything that has reached the lower part of the
     screen, or been scrolled past (a jump to an anchor skips frames, so an
     IntersectionObserver alone would leave those hidden) */
  var pending = Array.prototype.slice.call(document.querySelectorAll(".reveal"));
  var queued = false;
  var reveal = function () {
    queued = false;
    var limit = window.innerHeight * 0.92;
    pending = pending.filter(function (el) {
      if (el.getBoundingClientRect().top < limit) { el.classList.add("is-in"); return false; }
      return true;
    });
    if (!pending.length) window.removeEventListener("scroll", onReveal);
  };
  var onReveal = function () { if (!queued) { queued = true; window.requestAnimationFrame(reveal); } };
  if (reduce) pending.forEach(function (el) { el.classList.add("is-in"); });
  else { window.addEventListener("scroll", onReveal, { passive: true }); window.addEventListener("resize", onReveal); reveal(); }

  /* Travi: his still paints first; the film takes over once it's on screen */
  if (!reduce) {
    var filmIO = "IntersectionObserver" in window ? new IntersectionObserver(function (entries) {
      entries.forEach(function (e) {
        if (!e.isIntersecting) return;
        var img = e.target;
        filmIO.unobserve(img);
        var film = new Image();
        film.decoding = "async";
        film.onload = function () { img.src = film.src; img.classList.add("is-film"); };
        film.src = img.getAttribute("data-film");
      });
    }, { rootMargin: "200px" }) : null;
    document.querySelectorAll("img[data-film]:not(.wl-travi)").forEach(function (img) { if (filmIO) filmIO.observe(img); });
  }

  /* the hero stage: the destination folds up behind Travi */
  var win = document.querySelector(".stage-window");
  if (win) {
    var stages = JSON.parse(win.getAttribute("data-stages") || "[]");
    var chips = document.querySelectorAll(".chips .chip");
    var label = win.querySelector(".stage-place");
    var current = 0, timer = null, busy = false;
    var preload = function (i) { var im = new Image(); im.src = stages[i].src; return im; };
    stages.forEach(function (_, i) { if (i) setTimeout(function () { preload(i); }, 1500 + i * 300); });
    var show = function (i) {
      if (i === current || busy) return;
      busy = true;
      var old = win.querySelector(".stage-plate.is-current");
      var plate = document.createElement("div");
      plate.className = "stage-plate is-current";
      plate.style.backgroundImage = "url(" + stages[i].src + ")";
      if (reduce) {
        win.insertBefore(plate, old.nextSibling);
        old.remove();
        busy = false;
      } else {
        old.classList.remove("is-current");
        old.classList.add("is-folding");
        plate.classList.add("is-rising");
        win.insertBefore(plate, old.nextSibling);
        setTimeout(function () { old.remove(); plate.classList.remove("is-rising"); busy = false; }, 1350);
      }
      current = i;
      chips.forEach(function (c, n) { c.classList.toggle("is-on", n === i); });
      label.textContent = stages[i].name;
      label.classList.remove("is-new"); void label.offsetWidth; label.classList.add("is-new");
    };
    chips.forEach(function (chip, n) {
      chip.addEventListener("click", function () { clearInterval(timer); timer = null; show(n); });
    });
    if (!reduce && stages.length > 1) {
      timer = setInterval(function () {
        if (document.hidden) return;
        show((current + 1) % stages.length);
      }, 4800);
    }
  }

  /* the article's contents as a time rail: done, now, next */
  var toc = document.querySelector(".toc");
  if (toc && "IntersectionObserver" in window) {
    var links = Array.prototype.slice.call(toc.querySelectorAll("a"));
    var heads = links.map(function (a) { return document.getElementById(a.getAttribute("href").slice(1)); });
    var mark = function () {
      var y = window.scrollY + 140, now = -1;
      heads.forEach(function (h, i) { if (h && h.getBoundingClientRect().top + window.scrollY <= y) now = i; });
      links.forEach(function (a, i) {
        a.parentNode.classList.toggle("is-done", i < now);
        a.parentNode.classList.toggle("is-now", i === now);
      });
    };
    window.addEventListener("scroll", mark, { passive: true });
    mark();
  }

  /* the waiting list: every "Get the app" and coming-soon badge opens the
     card; forms post JSON to /api/waitlist (functions/api/waitlist.js) */
  var dialog = document.getElementById("waitlist");
  var joinedKey = "travary:waitlist";
  var messages = {
    email: "That email doesn't look quite right. Could you check it?",
    busy: "That's a lot of tries. Please wait a little and try again.",
    origin: "Something went wrong. Please refresh the page and try again.",
    other: "We couldn't save that just now. Please try again in a minute."
  };
  var traviTo = function (box, attr) {
    var img = box.querySelector(".wl-travi");
    if (img && !reduce && img.getAttribute(attr)) img.src = img.getAttribute(attr);
  };
  var showDone = function (box, email) {
    traviTo(box, "data-done");
    var start = box.querySelector(".wl-start"), done = box.querySelector(".wl-done");
    if (start) start.hidden = true;
    if (done) {
      done.hidden = false;
      var who = done.querySelector(".wl-done-email");
      if (who) who.textContent = email || "you";
    }
  };
  var showStart = function (box) {
    if (box.querySelector(".wl-travi.is-film")) traviTo(box, "data-film");
    var start = box.querySelector(".wl-start"), done = box.querySelector(".wl-done");
    if (start) start.hidden = false;
    if (done) done.hidden = true;
    var form = box.querySelector(".wl-form");
    if (form) {
      form.querySelector('[name="t"]').value = String(Date.now());
      var err = form.querySelector(".wl-error");
      err.hidden = true;
      var input = form.querySelector(".wl-email");
      if (input) setTimeout(function () { input.focus(); }, 60);
    }
  };
  document.querySelectorAll(".wl-form").forEach(function (form) {
    form.querySelector('[name="t"]').value = String(Date.now());
    var box = form.closest(".wl-dialog, .wl-card");
    var err = form.querySelector(".wl-error");
    var button = form.querySelector(".wl-submit");
    var input = form.querySelector(".wl-email");
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      var email = input.value.trim();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        err.textContent = messages.email; err.hidden = false; input.focus(); return;
      }
      var platform = form.querySelector('[name="platform"]:checked');
      var body = {
        email: email,
        platform: platform ? platform.value : "",
        source: location.pathname,
        company: form.querySelector('[name="company"]').value,
        t: Number(form.querySelector('[name="t"]').value) || 0
      };
      err.hidden = true;
      button.disabled = true;
      button.textContent = "Saving…";
      fetch("/api/waitlist", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) })
        .then(function (r) { return r.json().catch(function () { return { ok: false }; }); })
        .then(function (res) {
          if (res && res.ok) {
            store.set(joinedKey, email);
            form.reset();
            showDone(box, email);
          } else {
            err.textContent = messages[res && res.error] || messages.other; err.hidden = false;
          }
        })
        .catch(function () { err.textContent = messages.other; err.hidden = false; })
        .then(function () { button.disabled = false; button.textContent = "Join the waiting list"; });
    });
  });
  document.querySelectorAll(".wl-again").forEach(function (b) {
    b.addEventListener("click", function () { showStart(b.closest(".wl-dialog, .wl-card")); });
  });
  var inline = document.querySelector(".wl-card");
  if (inline) {
    var q = new URLSearchParams(location.search).get("error");
    if (q) { var e1 = inline.querySelector(".wl-error"); e1.textContent = messages[q] || messages.other; e1.hidden = false; }
  }
  if (dialog && typeof dialog.showModal === "function") {
    var travi = dialog.querySelector("img[data-film]");
    document.addEventListener("click", function (e) {
      var trigger = e.target.closest("[data-waitlist]");
      if (!trigger || e.metaKey || e.ctrlKey || e.shiftKey) return;
      e.preventDefault();
      var menu = document.getElementById("mobile-nav"), toggleBtn = document.querySelector(".nav-toggle");
      if (menu && !menu.hidden) { menu.hidden = true; if (toggleBtn) toggleBtn.setAttribute("aria-expanded", "false"); }
      if (inline) { // on /early-access the form is already on the page
        inline.scrollIntoView({ behavior: reduce ? "auto" : "smooth", block: "center" });
        var field = inline.querySelector(".wl-email"); if (field) field.focus({ preventScroll: true });
        return;
      }
      var joined = store.get(joinedKey);
      if (joined) {
        showDone(dialog, joined);
      } else {
        showStart(dialog);
        if (travi && !reduce && !travi.classList.contains("is-film")) {
          var film = new Image();
          film.onload = function () { if (!dialog.querySelector(".wl-done:not([hidden])")) travi.src = film.src; travi.classList.add("is-film"); };
          film.src = travi.getAttribute("data-film");
        }
      }
      dialog.showModal();
    });
    dialog.querySelector(".wl-close").addEventListener("click", function () { dialog.close(); });
    dialog.addEventListener("click", function (e) { if (e.target === dialog) dialog.close(); });
  }

  /* checklists you can tick, remembered on this device */
  document.querySelectorAll("ul.checklist").forEach(function (list, n) {
    var key = "travary:check:" + location.pathname + ":" + n;
    var saved = (store.get(key) || "").split(",");
    var items = list.querySelectorAll("li");
    var progress = document.createElement("p");
    progress.className = "checklist-progress";
    progress.setAttribute("aria-live", "polite");
    list.parentNode.insertBefore(progress, list.nextSibling);
    var update = function () {
      var done = [];
      items.forEach(function (li, i) { if (li.classList.contains("is-done")) done.push(i); });
      store.set(key, done.join(","));
      progress.textContent = done.length + " of " + items.length + " done";
    };
    items.forEach(function (li, i) {
      li.setAttribute("role", "checkbox");
      li.setAttribute("tabindex", "0");
      if (saved.indexOf(String(i)) !== -1) li.classList.add("is-done");
      li.setAttribute("aria-checked", String(li.classList.contains("is-done")));
      var flip = function () {
        li.classList.toggle("is-done");
        li.setAttribute("aria-checked", String(li.classList.contains("is-done")));
        update();
      };
      li.addEventListener("click", function (e) { if (e.target.tagName !== "A") flip(); });
      li.addEventListener("keydown", function (e) { if (e.key === " " || e.key === "Enter") { e.preventDefault(); flip(); } });
    });
    update();
  });
})();
