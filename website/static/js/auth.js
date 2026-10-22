/* travary.app/auth/action: finishes the links in Travary's account emails
   (Firebase sends them; their action URL points here). Confirming an email
   applies the link's code at once; a new password is asked for, then saved.
   Codes only ever go to Firebase's Identity Toolkit, with Travary's own key:
   a link carrying another project's key is refused. */
(function () {
  "use strict";
  var card = document.getElementById("auth");
  if (!card) return;
  var title = document.getElementById("auth-title");
  var text = document.getElementById("auth-text");
  var form = document.getElementById("auth-form");
  var password = document.getElementById("auth-password");
  var error = document.getElementById("auth-error");
  var save = document.getElementById("auth-save");
  var key = card.getAttribute("data-key");

  var params = new URLSearchParams(location.search);
  var mode = params.get("mode");
  var code = params.get("oobCode");
  var linkKey = params.get("apiKey");
  // The code is a one-time key to the account: keep it out of the history.
  if (location.search && window.history && history.replaceState) history.replaceState(null, "", location.pathname);

  function show(heading, words) {
    title.textContent = heading;
    text.textContent = words;
    form.hidden = true;
  }

  var expired = "This link has expired or was already used. In Travary, ask for a new one: " +
    "“Send it again”, or “Forgot your password?” on the sign-in screen.";

  function problem(message) {
    var m = String(message || "");
    if (/^(INVALID_OOB_CODE|EXPIRED_OOB_CODE)/.test(m)) return expired;
    if (/^USER_DISABLED/.test(m)) return "This account has been switched off. Email us and we’ll help.";
    if (/^EMAIL_NOT_FOUND|^USER_NOT_FOUND/.test(m)) return "There’s no Travary account for this link any more.";
    if (/^(WEAK_PASSWORD|PASSWORD_DOES_NOT_MEET_REQUIREMENTS)/.test(m)) return "Choose a longer password: at least 8 characters.";
    if (/^TOO_MANY_ATTEMPTS/.test(m)) return "Too many tries in a row. Wait a few minutes, then try again.";
    return "That didn’t work. Check your connection and try again.";
  }

  function call(method, body) {
    return fetch("https://identitytoolkit.googleapis.com/v1/accounts:" + method + "?key=" + encodeURIComponent(key), {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body)
    }).then(function (response) {
      return response.json().then(function (data) {
        if (!response.ok || data.error) throw new Error((data.error && data.error.message) || "UNKNOWN");
        return data;
      });
    });
  }

  if (!code || !mode) {
    show("Open the link from your email",
      "This page finishes the links in Travary’s emails. Open the link from the email again, the whole of it.");
    return;
  }
  if (linkKey && linkKey !== key) {
    show("This link isn’t from Travary", "It wasn’t sent by Travary, so nothing has been changed. Don’t enter a password here.");
    return;
  }

  if (mode === "verifyEmail" || mode === "verifyAndChangeEmail") {
    call("update", { oobCode: code }).then(function (data) {
      show("You’re confirmed.",
        (data.email ? data.email + " is confirmed. " : "Your email is confirmed. ") +
        "Go back to Travary and it signs you in by itself. You can close this page.");
    }, function (e) { show("That link didn’t work", problem(e.message)); });
    return;
  }

  if (mode === "recoverEmail") {
    call("update", { oobCode: code }).then(function (data) {
      show("Your email is back.",
        "Your account uses " + (data.email || "your old email") + " again. " +
        "If you didn’t ask for the change, choose a new password in Travary: “Forgot your password?”.");
    }, function (e) { show("That link didn’t work", problem(e.message)); });
    return;
  }

  if (mode === "resetPassword") {
    // Check the code first, so an old link says so before anything is typed.
    call("resetPassword", { oobCode: code }).then(function (data) {
      title.textContent = "Choose a new password";
      text.textContent = data.email ? "For " + data.email + "." : "For your Travary account.";
      document.getElementById("auth-email").value = data.email || "";
      form.hidden = false;
      password.focus();
    }, function (e) { show("That link didn’t work", problem(e.message)); });

    document.getElementById("auth-show").addEventListener("change", function (event) {
      password.type = event.target.checked ? "text" : "password";
    });
    form.addEventListener("submit", function (event) {
      event.preventDefault();
      error.hidden = true;
      if (password.value.length < 8) {
        error.textContent = "Choose a longer password: at least 8 characters.";
        error.hidden = false;
        return;
      }
      save.disabled = true;
      call("resetPassword", { oobCode: code, newPassword: password.value }).then(function () {
        password.value = "";
        show("Password changed.", "Go back to Travary and sign in with your new password. You can close this page.");
      }, function (e) {
        save.disabled = false;
        error.textContent = problem(e.message);
        error.hidden = false;
      });
    });
    return;
  }

  show("Open the link from your email", "This link isn’t one this page knows. Open it from the email again.");
})();
