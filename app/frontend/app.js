const loginButton = document.querySelector("#login");
const logoutButton = document.querySelector("#logout");
const workspace = document.querySelector("#workspace");
const status = document.querySelector("#status");
const form = document.querySelector("#note-form");
const saveButton = document.querySelector("#save");
const content = document.querySelector("#content");
const notes = document.querySelector("#notes");

let config;
let accessToken;

function showStatus(message) {
  status.textContent = message;
}

function base64url(bytes) {
  return btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

function randomValue() {
  return base64url(crypto.getRandomValues(new Uint8Array(32)));
}

function showSignedIn(signedIn) {
  loginButton.hidden = signedIn;
  logoutButton.hidden = !signedIn;
  workspace.hidden = !signedIn;
}

async function login() {
  const verifier = randomValue();
  const state = randomValue();

  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(verifier),
  );

  sessionStorage.setItem("oauth_verifier", verifier);
  sessionStorage.setItem("oauth_state", state);

  const url = new URL("/oauth2/authorize", config.login_base_url);

  url.search = new URLSearchParams({
    response_type: "code",
    client_id: config.client_id,
    redirect_uri: config.redirect_uri,
    scope: "openid email profile",
    state,
    code_challenge: base64url(new Uint8Array(digest)),
    code_challenge_method: "S256",
  });

  window.location.assign(url);
}

async function finishLogin() {
  const params = new URLSearchParams(window.location.search);

  if (!params.has("code") && !params.has("error")) {
    return false;
  }

  // Прибираємо одноразовий код з адресного рядка.
  history.replaceState({}, "", "/");

  const verifier = sessionStorage.getItem("oauth_verifier");
  const expectedState = sessionStorage.getItem("oauth_state");

  sessionStorage.removeItem("oauth_verifier");
  sessionStorage.removeItem("oauth_state");

  if (
    !verifier ||
    !expectedState ||
    params.get("state") !== expectedState
  ) {
    throw new Error("Не вдалося перевірити вхід. Спробуй ще раз.");
  }

  if (params.has("error")) {
    throw new Error("Cognito не завершив вхід. Спробуй ще раз.");
  }

  const response = await fetch(
    new URL("/oauth2/token", config.login_base_url),
    {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        grant_type: "authorization_code",
        client_id: config.client_id,
        redirect_uri: config.redirect_uri,
        code: params.get("code"),
        code_verifier: verifier,
      }),
    },
  );

  if (!response.ok) {
    throw new Error("Не вдалося отримати токен входу.");
  }

  const tokens = await response.json();

  if (!tokens.access_token) {
    throw new Error("Cognito не повернув access token.");
  }

  accessToken = tokens.access_token;
  return true;
}

async function api(path, options = {}) {
  const response = await fetch(path, {
    ...options,
    headers: {
      ...options.headers,
      Authorization: `Bearer ${accessToken}`,
    },
  });

  if (response.status === 401) {
    accessToken = undefined;
    notes.replaceChildren();
    showSignedIn(false);
    throw new Error("Сеанс завершився. Увійди ще раз.");
  }

  if (!response.ok) {
    throw new Error(`Помилка API: ${response.status}`);
  }

  return response.json();
}

async function loadNotes() {
  const data = await api("/api/notes");

  notes.replaceChildren();

  for (const note of data.notes) {
    const item = document.createElement("li");
    item.textContent = note.content;
    notes.append(item);
  }

  showStatus(data.notes.length ? "" : "Нотаток поки немає.");
}

loginButton.addEventListener("click", () => {
  login().catch(() => {
    showStatus("Не вдалося почати вхід.");
  });
});

logoutButton.addEventListener("click", () => {
  accessToken = undefined;
  notes.replaceChildren();
  content.value = "";
  showSignedIn(false);

  const url = new URL("/logout", config.login_base_url);

  url.search = new URLSearchParams({
    client_id: config.client_id,
    logout_uri: config.redirect_uri,
  });

  window.location.assign(url);
});

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const text = content.value.trim();
  if (!text) return;

  saveButton.disabled = true;
  showStatus("Зберігаємо…");

  try {
    await api("/api/notes", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ content: text }),
    });

    content.value = "";
    await loadNotes();
  } catch (error) {
    showStatus(error.message);
  } finally {
    saveButton.disabled = false;
  }
});

async function start() {
  const response = await fetch("/config.json", {
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error("Не вдалося завантажити конфігурацію.");
  }

  config = await response.json();
  loginButton.disabled = false;

  if (await finishLogin()) {
   showSignedIn(true);
   await loadNotes();
   await loadFiles();
  } else {
    showStatus("Увійди, щоб працювати зі своїми нотатками.");
  }
}

const fileForm = document.querySelector("#file-form");
const fileInput = document.querySelector("#file-input");
const uploadButton = document.querySelector("#upload");
const fileList = document.querySelector("#files");

async function loadFiles() {
  const data = await api("/api/files");
  fileList.replaceChildren();

  for (const file of data.files) {
    const item = document.createElement("li");
    const button = document.createElement("button");

    button.textContent = `${file.name} (${file.size} байт)`;

    button.addEventListener("click", async () => {
      try {
        const result = await api(
          `/api/files/download?name=${encodeURIComponent(file.name)}`,
        );

        const bytes = Uint8Array.from(
          atob(result.base64),
          (character) => character.charCodeAt(0),
        );

        const url = URL.createObjectURL(
          new Blob([bytes], { type: "application/octet-stream" }),
        );

        const link = document.createElement("a");
        link.href = url;
        link.download = result.name;
        document.body.append(link);
        link.click();
        link.remove();

        setTimeout(() => URL.revokeObjectURL(url), 1000);
      } catch (error) {
        showStatus(error.message);
      }
    });

    item.append(button);
    fileList.append(item);
  }
}

fileForm.addEventListener("submit", async (event) => {
  event.preventDefault();

  const file = fileInput.files[0];
  if (!file) return;

  if (file.size > 4096) {
    showStatus("Для лабораторної вибери файл до 4 КіБ.");
    return;
  }

  uploadButton.disabled = true;

  try {
    const bytes = new Uint8Array(await file.arrayBuffer());

    await api("/api/files", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        name: file.name,
        base64: btoa(String.fromCharCode(...bytes)),
      }),
    });

    fileForm.reset();
    await loadFiles();
    showStatus("Файл завантажено.");
  } catch (error) {
    showStatus(error.message);
  } finally {
    uploadButton.disabled = false;
  }
});

start().catch((error) => {
  showStatus(error.message);
});
