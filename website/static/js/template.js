/* The printable itinerary template: a section per day, kept in this browser. */
(function () {
  "use strict";
  var form = document.getElementById("tpl-form");
  if (!form) return;
  var $ = function (id) { return document.getElementById(id); };
  var KEY = "travary:itinerary";
  var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  var MAX_DAYS = 31;
  var state = { name: "", start: "", end: "", who: "", stay: "", notes: "", blank: 0, rows: {} };
  try { state = Object.assign(state, JSON.parse(window.localStorage.getItem(KEY) || "{}")); } catch (e) { /* none */ }
  var save = function () { try { window.localStorage.setItem(KEY, JSON.stringify(state)); } catch (e) { /* private mode */ } };
  var parse = function (s) { var m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s || ""); return m ? new Date(+m[1], +m[2] - 1, +m[3]) : null; };
  var el = function (tag, cls, text) { var n = document.createElement(tag); if (cls) n.className = cls; if (text) n.textContent = text; return n; };

  var dayList = function () {
    var s = parse(state.start), e = parse(state.end), out = [];
    if (s) {
      if (!e || e < s) e = s;
      for (var d = new Date(s), i = 0; d <= e && i < MAX_DAYS; d.setDate(d.getDate() + 1), i++) {
        out.push({ key: "d" + i, label: days[d.getDay()], date: d.getDate() + " " + months[d.getMonth()] });
      }
    } else if (state.blank) {
      for (var j = 0; j < state.blank; j++) out.push({ key: "d" + j, label: "Day " + (j + 1), date: "____ / ____" });
    }
    return out;
  };

  var row = function (dayKey, i, values) {
    var r = el("div", "tpl-row");
    [["time", "Time"], ["what", "What"], ["ref", "Where / ref"]].forEach(function (f) {
      var input = el("input");
      input.type = "text"; input.maxLength = 120; input.placeholder = f[1];
      input.setAttribute("aria-label", f[1]); input.setAttribute("data-k", f[0]);
      input.value = (values && values[f[0]]) || "";
      input.addEventListener("input", function () {
        state.rows[dayKey] = state.rows[dayKey] || [];
        state.rows[dayKey][i] = state.rows[dayKey][i] || {};
        state.rows[dayKey][i][f[0]] = input.value;
        save();
      });
      r.appendChild(input);
    });
    var del = el("button", "", "✕");
    del.type = "button"; del.setAttribute("aria-label", "Remove this line");
    del.addEventListener("click", function () {
      var list = state.rows[dayKey] || [];
      list.splice(i, 1);
      state.rows[dayKey] = list;
      state.rowCount[dayKey] = Math.max(1, (state.rowCount[dayKey] || 3) - 1);
      save(); render();
    });
    r.appendChild(del);
    return r;
  };

  var render = function () {
    state.rowCount = state.rowCount || {};
    var s = parse(state.start), e = parse(state.end);
    $("tpl-title").textContent = state.name || "Your trip";
    var list = dayList();
    var sub = [];
    if (s) {
      var end = e && e >= s ? e : s;
      sub.push(s.getDate() + " " + months[s.getMonth()] + " – " + end.getDate() + " " + months[end.getMonth()] + " " + end.getFullYear());
      sub.push(list.length + (list.length === 1 ? " day" : " days"));
    }
    if (state.who) sub.push(state.who);
    $("tpl-sub").textContent = sub.join(" · ") || "Add your dates";
    $("tpl-stay-out").textContent = state.stay || "—";
    $("tpl-notes-out").textContent = state.notes || "—";
    var box = $("tpl-days");
    box.textContent = "";
    list.forEach(function (d, n) {
      var card = el("section", "tpl-day paper");
      var h = el("h3");
      h.appendChild(document.createTextNode("Day " + (n + 1) + " · " + d.label));
      h.appendChild(el("small", "", d.date));
      card.appendChild(h);
      var count = Math.max(state.rowCount[d.key] || 3, (state.rows[d.key] || []).length);
      for (var i = 0; i < count; i++) card.appendChild(row(d.key, i, (state.rows[d.key] || [])[i]));
      var add = el("button", "tpl-add", "+ Add a line");
      add.type = "button";
      add.addEventListener("click", function () { state.rowCount[d.key] = count + 1; save(); render(); });
      card.appendChild(add);
      box.appendChild(card);
    });
    var msg = $("tpl-msg");
    if (!list.length) msg.textContent = "Pick your dates and a day appears for each one.";
    else if (s && e && (e - s) / 864e5 >= MAX_DAYS) msg.textContent = "Showing the first " + MAX_DAYS + " days.";
    else msg.textContent = "Saved in this browser as you type.";
  };

  ["name", "start", "end", "who", "stay", "notes"].forEach(function (k) {
    var input = $("tpl-" + k);
    input.value = state[k] || "";
    input.addEventListener("input", function () {
      state[k] = input.value;
      if (k === "start" || k === "end") state.blank = 0;
      save();
      if (k === "start" || k === "end") render(); else render();
    });
  });
  $("tpl-print").addEventListener("click", function () { window.print(); });
  $("tpl-blank").addEventListener("click", function () {
    state = { name: "", start: "", end: "", who: "", stay: "", notes: "", blank: 7, rows: {}, rowCount: {} };
    ["name", "start", "end", "who", "stay", "notes"].forEach(function (k) { $("tpl-" + k).value = ""; });
    save(); render();
    $("tpl-msg").textContent = "A blank 7-day template is ready to print.";
  });
  render();
})();
