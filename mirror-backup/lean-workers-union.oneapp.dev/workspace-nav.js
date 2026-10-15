(() => {
  const WORKSPACE_KEY = "lean-worker-seats-tasks-v3";
  const LIBRARY_KEY = "lodge-public-link-library-v1";
  const INBOX_KEY = "lodge-shared-data-inbox-v1";
  const LIMIT_KEY = "lodge-public-link-limit-v1";
  const DEFAULT_LIMIT = 100;
  const SHARED_KEYS = ["data", "state", "members", "backlog", "import", "playbook", "invite", "response"];

  function storageRead(key, fallback) {
    try {
      const value = localStorage.getItem(key);
      return value === null ? fallback : JSON.parse(value);
    } catch (error) {
      return fallback;
    }
  }

  function readWorkspace() {
    const value = storageRead(WORKSPACE_KEY, null);
    return value && typeof value === "object" && !Array.isArray(value) ? value : null;
  }

  function profileName() {
    const profile = readWorkspace()?.profile;
    const name = profile?.name || profile?.displayName;
    return typeof name === "string" ? name.trim() : "";
  }

  function updateProfileLinks() {
    const name = profileName();
    document.querySelectorAll('a[href="/seats/share"], a[href="/seats#profile"]').forEach((link) => {
      link.href = "/seats#profile";
      link.textContent = name ? `My profile · ${name}` : "Create profile / Login";
      link.setAttribute("aria-label", name ? `Open your browser-local profile for ${name}` : "Create or open your browser-local profile");
      link.title = name ? "Your profile is saved in this browser, not signed in to a server." : "Create a profile saved in this browser; this is not a server login.";
    });
  }

  function encodeJson(value) {
    const bytes = new TextEncoder().encode(JSON.stringify(value));
    let binary = "";
    bytes.forEach((byte) => binary += String.fromCharCode(byte));
    return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replace(/=+$/g, "");
  }

  function decodeJson(value) {
    const text = String(value || "").trim();
    if (!text) throw new Error("No embedded data was found in this URL.");
    if (text.startsWith("{") || text.startsWith("[")) return JSON.parse(text);
    const normalized = text.replace(/-/g, "+").replace(/_/g, "/");
    const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
    const bytes = Uint8Array.from(atob(padded), (character) => character.charCodeAt(0));
    return JSON.parse(new TextDecoder().decode(bytes));
  }

  function safeCurrentUrl() {
    const candidates = [window.location.href, document.referrer];

    try {
      if (window.parent && window.parent !== window) {
        candidates.push(window.parent.location.href);
      }
    } catch (error) {
      // A cross-origin preview wrapper may block access to its address.
    }

    try {
      if (window.top && window.top !== window.parent && window.top !== window) {
        candidates.push(window.top.location.href);
      }
    } catch (error) {
      // A cross-origin top-level page may block access to its address.
    }

    try {
      const ancestors = window.location.ancestorOrigins;
      if (ancestors && ancestors.length > 0) {
        candidates.push(ancestors[ancestors.length - 1]);
      }
    } catch (error) {
      // ancestorOrigins is not available in every browser.
    }

    for (const candidate of candidates) {
      try {
        const url = new URL(candidate);
        if (url.protocol === "http:" || url.protocol === "https:") return url;
      } catch (error) {
        // Ignore invalid preview bases such as about:srcdoc and try the next hint.
      }
    }

    return null;
  }

  function buildRelativeOrAbsoluteUrl(path, fragment) {
    const current = new URL(window.location.href);
    const isEmbeddedPreview = current.protocol === "about:" || current.protocol === "blob:";

    if (isEmbeddedPreview) {
      return `https://lean-workers-union.oneapp.dev#${fragment}`;
    }

    const base = safeCurrentUrl();
    if (!base) return `https://lean-workers-union.oneapp.dev#${fragment}`;
    const url = new URL(path, base.origin);
    url.hash = fragment;
    return url.toString();
  }

  function payloadFromUrl(value) {
    let url;
    try {
      const base = safeCurrentUrl();
      url = base ? new URL(value, base) : new URL(value);
    } catch (error) {
      throw new Error("Enter a complete http(s) share URL. This preview cannot resolve relative URLs.");
    }
    if (url.protocol !== "http:" && url.protocol !== "https:") {
      throw new Error("Only http(s) share URLs are supported.");
    }
    const fragment = new URLSearchParams(url.hash.replace(/^#/, ""));
    for (const key of SHARED_KEYS) {
      const embedded = fragment.get(key) || url.searchParams.get(key);
      if (embedded) return {
        url: url.toString(),
        key,
        payload: decodeJson(embedded)
      };
    }
    if (url.hash) {
      try {
        return {
          url: url.toString(),
          key: "fragment",
          payload: decodeJson(decodeURIComponent(url.hash.slice(1)))
        };
      } catch (error) {
        // Report the common unsupported-link message below.
      }
    }
    throw new Error("No supported embedded data field was found in this URL.");
  }

  function profilePayload(profile, compact = false) {
    return {
      formatVersion: 1,
      kind: "workspace",
      workspace: {
        formatVersion: 1,
        profile: {
          name: String(profile.name || profile.displayName || "").trim().slice(0, 80),
          slug: String(profile.slug || "").trim().toLowerCase().slice(0, 40),
          note: compact ? "" : String(profile.note || profile.bio || "").trim().slice(0, 240),
          icon: compact ? "" : (typeof profile.icon === "string" && profile.icon.startsWith("data:image/") ? profile.icon : ""),
          photos: compact || !Array.isArray(profile.photos) ? [] : profile.photos.filter((photo) => typeof photo === "string" && photo.startsWith("data:image/"))
        },
        people: [],
        invitations: [],
        tasks: [],
        schedules: [],
        document: null
      }
    };
  }

  function makeButton(label, primary = false) {
    const button = document.createElement("button");
    button.type = "button";
    button.textContent = label;
    button.className = "focus-ring rounded-[var(--radius)] border px-3 py-2 text-sm font-semibold transition";
    button.style.borderColor = primary ? "var(--color-primary)" : "var(--color-line-strong)";
    button.style.background = primary ? "var(--color-primary)" : "var(--color-surface)";
    button.style.color = primary ? "var(--color-primary-contrast)" : "var(--color-text)";
    return button;
  }

  function ensurePanel() {
    let panel = document.getElementById("shared-data-sync-panel");
    if (panel) return panel;

    panel = document.createElement("section");
    panel.id = "shared-data-sync-panel";
    panel.hidden = true;
    panel.setAttribute("aria-labelledby", "shared-data-sync-heading");
    Object.assign(panel.style, {
      position: "fixed",
      zIndex: "10001",
      right: "1rem",
      bottom: "1rem",
      top: "auto",
      left: "auto",
      width: "min(36rem, calc(100vw - 2rem))",
      maxHeight: "min(72vh, 44rem)",
      overflow: "auto",
      overscrollBehavior: "contain",
      padding: "1rem",
      border: "1px solid var(--color-line-strong)",
      borderRadius: "var(--radius)",
      background: "var(--color-surface)",
      color: "var(--color-text)",
      boxShadow: "0 1rem 3rem var(--color-shadow)"
    });

    const heading = document.createElement("h2");
    heading.id = "shared-data-sync-heading";
    heading.textContent = "Sync, edit & use shared URL data";
    heading.style.cssText = "font-family:var(--font-heading);font-size:1.65rem;font-weight:700";

    const intro = document.createElement("p");
    intro.textContent = "Review data already saved in this browser, or decode one or more share URLs into editable JSON. Nothing is fetched or changed until you choose an action.";
    intro.style.cssText = "margin-top:.35rem;font-size:.875rem;line-height:1.55;color:var(--color-muted)";

    const currentTitle = document.createElement("h3");
    currentTitle.textContent = "Current browser data";
    currentTitle.style.cssText = "margin-top:1.1rem;font-weight:700";
    const currentInfo = document.createElement("p");
    currentInfo.textContent = "Edit the JSON below, then choose Use edits to replace this browser's workspace. This data stays on this device unless you share or save it.";
    currentInfo.style.cssText = "margin-top:.25rem;font-size:.8rem;line-height:1.5;color:var(--color-muted)";
    const currentEditor = document.createElement("textarea");
    currentEditor.id = "shared-current-data";
    currentEditor.rows = 8;
    currentEditor.setAttribute("aria-label", "Editable current browser workspace JSON");
    currentEditor.style.cssText = fieldCss(".78rem");

    const currentActions = document.createElement("div");
    currentActions.style.cssText = "display:flex;flex-wrap:wrap;gap:.5rem;margin-top:.5rem";
    const refreshCurrent = makeButton("Refresh current data");
    const copyCurrent = makeButton("Copy current JSON");
    const saveCurrent = makeButton("Save current JSON");
    const useCurrent = makeButton("Use edits on this device", true);
    currentActions.append(refreshCurrent, copyCurrent, saveCurrent, useCurrent);

    const incomingTitle = document.createElement("h3");
    incomingTitle.textContent = "Decode shared URL(s)";
    incomingTitle.style.cssText = "margin-top:1.4rem;font-weight:700";
    const incomingInfo = document.createElement("p");
    incomingInfo.textContent = "Paste one or more complete share URLs, one per line. Decode turns embedded data into editable JSON; Encode makes a share link again.";
    incomingInfo.style.cssText = "margin-top:.25rem;font-size:.8rem;line-height:1.5;color:var(--color-muted)";
    const urlInput = document.createElement("textarea");
    urlInput.id = "shared-data-url-input";
    urlInput.rows = 3;
    urlInput.placeholder = "Paste share URL(s), one per line";
    urlInput.setAttribute("aria-label", "Share URLs to decode");
    urlInput.style.cssText = fieldCss(".78rem");

    const decodeActions = document.createElement("div");
    decodeActions.style.cssText = "display:flex;flex-wrap:wrap;align-items:center;gap:.5rem;margin-top:.5rem";
    const parseButton = makeButton("Decode URL(s)", true);
    const select = document.createElement("select");
    select.id = "shared-data-candidate-select";
    select.setAttribute("aria-label", "Choose a decoded URL");
    select.style.cssText = "max-width:100%;padding:.55rem;border:1px solid var(--color-line-strong);border-radius:var(--radius);background:var(--color-bg);color:var(--color-text)";
    const publicLabel = document.createElement("label");
    publicLabel.style.cssText = "display:flex;align-items:center;gap:.4rem;font-size:.8rem;color:var(--color-muted)";
    const publicCheck = document.createElement("input");
    publicCheck.id = "shared-data-public-check";
    publicCheck.type = "checkbox";
    publicCheck.checked = true;
    const publicText = document.createElement("span");
    publicText.textContent = "Remember as public link";
    publicLabel.append(publicCheck, publicText);
    const limitLabel = document.createElement("label");
    limitLabel.style.cssText = "display:flex;align-items:center;gap:.4rem;font-size:.8rem;color:var(--color-muted)";
    limitLabel.append(document.createTextNode("Keep up to"));
    const limitInput = document.createElement("input");
    limitInput.id = "shared-data-limit";
    limitInput.type = "number";
    limitInput.min = "1";
    limitInput.max = "5000";
    limitInput.value = String(readLimit());
    limitInput.setAttribute("aria-label", "Maximum remembered public links");
    limitInput.style.cssText = "width:5rem;padding:.45rem;border:1px solid var(--color-line-strong);border-radius:var(--radius);background:var(--color-bg);color:var(--color-text)";
    limitLabel.append(limitInput, document.createTextNode("unique links"));
    decodeActions.append(parseButton, select, publicLabel, limitLabel);

    const decodedTitle = document.createElement("h3");
    decodedTitle.textContent = "Decoded data · editable JSON";
    decodedTitle.style.cssText = "margin-top:1rem;font-weight:700";
    const decodedEditor = document.createElement("textarea");
    decodedEditor.id = "shared-data-decoded-json";
    decodedEditor.rows = 10;
    decodedEditor.placeholder = "Decode a URL to inspect and edit its JSON data.";
    decodedEditor.setAttribute("aria-label", "Decoded shared data JSON editor");
    decodedEditor.style.cssText = fieldCss(".78rem");
    const decodedActions = document.createElement("div");
    decodedActions.style.cssText = "display:flex;flex-wrap:wrap;gap:.5rem;margin-top:.5rem";
    const encodeButton = makeButton("Encode edits as link", true);
    const copyJson = makeButton("Copy edited JSON");
    const saveJson = makeButton("Save edited JSON");
    const useDecoded = makeButton("Use / commit edits");
    const rememberButton = makeButton("Remember this public link");
    decodedActions.append(encodeButton, copyJson, saveJson, useDecoded, rememberButton);

    const outputTitle = document.createElement("label");
    outputTitle.htmlFor = "shared-data-encoded-url";
    outputTitle.textContent = "Encoded share URL";
    outputTitle.style.cssText = "display:block;margin-top:1rem;font-size:.8rem;font-weight:700";
    const encodedOutput = document.createElement("textarea");
    encodedOutput.id = "shared-data-encoded-url";
    encodedOutput.rows = 3;
    encodedOutput.readOnly = true;
    encodedOutput.placeholder = "Encoded link will appear here.";
    encodedOutput.setAttribute("aria-label", "Encoded share URL containing current edited JSON");
    encodedOutput.style.cssText = fieldCss(".72rem");
    const outputActions = document.createElement("div");
    outputActions.style.cssText = "display:flex;flex-wrap:wrap;gap:.5rem;margin-top:.5rem";
    const currentAsUrl = makeButton("Current data as URL", true);
    const copyLink = makeButton("Copy share link", true);
    const shareLink = makeButton("Share…");
    outputActions.append(currentAsUrl, copyLink, shareLink);

    const libraryTitle = document.createElement("h3");
    libraryTitle.textContent = "Remembered public links";
    libraryTitle.style.cssText = "margin-top:1.25rem;font-weight:700";
    const librarySummary = document.createElement("p");
    librarySummary.id = "shared-data-library-summary";
    librarySummary.style.cssText = "margin-top:.25rem;font-size:.8rem;color:var(--color-muted)";
    const libraryList = document.createElement("ol");
    libraryList.id = "shared-data-library-list";
    libraryList.style.cssText = "display:grid;gap:.35rem;max-height:8rem;overflow:auto;margin-top:.35rem;padding-left:1.3rem;font-size:.8rem;color:var(--color-muted)";

    const status = document.createElement("p");
    status.id = "shared-data-sync-status";
    status.setAttribute("role", "status");
    status.setAttribute("aria-live", "polite");
    status.style.cssText = "min-height:1.4rem;margin-top:.85rem;font-size:.85rem;color:var(--color-muted)";
    const savedViewLink = document.createElement("a");
    savedViewLink.id = "shared-data-saved-view";
    savedViewLink.href = "/seats#members";
    savedViewLink.textContent = "View saved profile in Members →";
    savedViewLink.hidden = true;
    savedViewLink.className = "focus-ring inline-block rounded-[var(--radius)] text-sm font-semibold text-[var(--color-primary)] underline";
    savedViewLink.style.marginTop = ".5rem";
    const close = makeButton("Close");

    panel.append(heading, intro, currentTitle, currentInfo, currentEditor, currentActions, incomingTitle, incomingInfo, urlInput, decodeActions, decodedTitle, decodedEditor, decodedActions, outputTitle, encodedOutput, outputActions, libraryTitle, librarySummary, libraryList, status, savedViewLink, close);
    close.addEventListener("click", () => {
      panel.hidden = true;
    });
    panel.addEventListener("keydown", (event) => {
      if (event.key === "Escape") panel.hidden = true;
    });
    document.body.appendChild(panel);

    let candidates = [];
    let activeCandidate = null;

    function setStatus(message) {
      status.textContent = message;
    }

    function updateCurrentEditor() {
      currentEditor.value = JSON.stringify(readWorkspace() || emptyWorkspace(), null, 2);
    }

    function refreshLibrary() {
      renderLibrary(librarySummary, libraryList);
    }

    function showCandidate(index) {
      activeCandidate = candidates[index] || null;
      if (!activeCandidate) return;
      decodedEditor.value = JSON.stringify(activeCandidate.payload, null, 2);
      encodedOutput.value = "";
      publicCheck.checked = isPublicOnly(activeCandidate.payload);
      setStatus(`URL ${index + 1} decoded (${activeCandidate.key}). Review or edit the JSON before using it.`);
    }

    refreshCurrent.addEventListener("click", () => {
      updateCurrentEditor();
      setStatus("Current browser data refreshed from local storage.");
    });
    copyCurrent.addEventListener("click", () => copyValue(currentEditor.value, setStatus, "Current JSON copied."));
    saveCurrent.addEventListener("click", () => saveJsonFile("lodge-house-current-workspace.json", currentEditor.value, setStatus));
    useCurrent.addEventListener("click", () => {
      try {
        const payload = JSON.parse(currentEditor.value);
        const workspace = extractWorkspace(payload);
        if (!workspace) throw new Error("Current data must be a workspace object.");
        localStorage.setItem(WORKSPACE_KEY, JSON.stringify(workspace));
        window.dispatchEvent(new Event("workspace:changed"));
        updateProfileLinks();
        setStatus("Edited workspace saved on this device.");
      } catch (error) {
        setStatus(`Could not use current data: ${error.message}`);
      }
    });

    parseButton.addEventListener("click", () => {
      const pastedText = urlInput.value.trim();
      const entries = [...pastedText.matchAll(/https?:\/\/[^\s<>"']+/g)]
        .map(([match]) => match.replace(/[.,;!?)}\]]+$/g, ""));

      if (entries.length === 0 && (pastedText === "about:srcdoc" || pastedText.startsWith("about:srcdoc#"))) {
        const workspace = readWorkspace() || emptyWorkspace();
        const currentShareUrl = buildRelativeOrAbsoluteUrl("/", `data=${encodeJson(workspace)}`);
        entries.push(currentShareUrl);
        urlInput.value = currentShareUrl;
      } else if (entries.length === 0 && pastedText) {
        entries.push(pastedText);
      }
      candidates = [];
      select.replaceChildren();
      const failures = [];
      entries.forEach((entry, index) => {
        try {
          candidates.push(payloadFromUrl(entry));
          const option = new Option(`URL ${index + 1} · ${candidates[candidates.length - 1].key}`, String(candidates.length - 1));
          select.add(option);
        } catch (error) {
          failures.push(`URL ${index + 1}: ${error.message}`);
        }
      });
      if (candidates.length) {
        showCandidate(0);
        const limit = clampLimit(limitInput.value);
        limitInput.value = String(limit);
        try {
          localStorage.setItem(LIMIT_KEY, String(limit));
        } catch (error) {
          /* Session still works. */ }
        if (failures.length) setStatus(`${candidates.length} URL(s) decoded. ${failures.join(" ")}`);
      } else {
        setStatus(failures.join(" ") || "Paste one or more share URLs, then choose Decode URL(s).");
      }
      refreshLibrary();
    });
    select.addEventListener("change", () => showCandidate(Number(select.value)));

    function encodeAsShareUrl(payload, key = "data") {
      const fragment = `${encodeURIComponent(key)}=${encodeJson(payload)}`;
      return buildRelativeOrAbsoluteUrl("/seats", fragment);
    }

    encodeButton.addEventListener("click", () => {
      try {
        const payload = JSON.parse(decodedEditor.value);
        const key = activeCandidate?.key === "fragment" ? "data" : activeCandidate?.key || "data";
        encodedOutput.value = encodeAsShareUrl(payload, key);
        setStatus("Edited JSON encoded into a share link. Anyone with the link can read its contents.");
      } catch (error) {
        setStatus(`Could not encode JSON: ${error.message}`);
      }
    });
    currentAsUrl.addEventListener("click", () => {
      try {
        const payload = readWorkspace() || emptyWorkspace();
        decodedEditor.value = JSON.stringify(payload, null, 2);
        activeCandidate = { key: "data", payload };
        encodedOutput.value = encodeAsShareUrl(payload, "data");
        setStatus("Current browser workspace encoded as a share URL. Anyone with the link can read its contents.");
      } catch (error) {
        setStatus(`Could not create a URL from current data: ${error.message}`);
      }
    });
    copyJson.addEventListener("click", () => copyValue(decodedEditor.value, setStatus, "Edited JSON copied."));
    saveJson.addEventListener("click", () => saveJsonFile("shared-data.json", decodedEditor.value, setStatus));
    useDecoded.addEventListener("click", () => {
      try {
        const payload = JSON.parse(decodedEditor.value);
        const workspace = extractWorkspace(payload);
        const isProfileOnly = Boolean(workspace?.profile) &&
          ["people", "invitations", "tasks", "schedules"].every((key) =>
            !Array.isArray(workspace[key]) || workspace[key].length === 0
          ) && !workspace.document;
        commitPayload(payload, setStatus);
        savedViewLink.href = isProfileOnly ? "/seats#members" : "/seats#tasks";
        savedViewLink.textContent = isProfileOnly
          ? "View saved profile in Members →"
          : "Open saved workspace →";
        savedViewLink.hidden = !workspace;
        rememberIfSelected(payload, activeCandidate, publicCheck.checked, limitInput.value, setStatus);
        updateCurrentEditor();
        updateProfileLinks();
        refreshLibrary();
      } catch (error) {
        savedViewLink.hidden = true;
        setStatus(`Could not use edited JSON: ${error.message}`);
      }
    });
    rememberButton.addEventListener("click", () => {
      try {
        const payload = JSON.parse(decodedEditor.value);
        rememberIfSelected(payload, activeCandidate, true, limitInput.value, setStatus);
        refreshLibrary();
      } catch (error) {
        setStatus(`Could not remember this data: ${error.message}`);
      }
    });
    copyLink.addEventListener("click", () => {
      if (!encodedOutput.value) {
        setStatus("Choose Encode edits as link first.");
        return;
      }
      copyValue(encodedOutput.value, setStatus, "Share link copied. Anyone with it can read the encoded data.");
    });
    shareLink.addEventListener("click", async () => {
      if (!encodedOutput.value) {
        setStatus("Choose Current data as URL or Encode edits as link first.");
        return;
      }
      if (!navigator.share) {
        setStatus("Mobile sharing is unavailable here. Choose Copy share link instead.");
        return;
      }
      try {
        await navigator.share({
          title: "Shared browser data",
          text: "Here is the data link.",
          url: encodedOutput.value
        });
        setStatus("Share sheet opened. The link contains readable data for its recipients.");
      } catch (error) {
        setStatus(error.name === "AbortError" ? "Sharing cancelled; the link is still available above." : "Could not open the share sheet. Use Copy share link instead.");
      }
    });
    close.addEventListener("click", () => panel.hidden = true);

    updateCurrentEditor();
    refreshLibrary();
    return panel;
  }

  function fieldCss(fontSize) {
    return `display:block;width:100%;margin-top:.4rem;padding:.7rem;border:1px solid var(--color-line-strong);border-radius:var(--radius);background:var(--color-bg);color:var(--color-text);font:${fontSize}/1.5 monospace;overflow-wrap:anywhere`;
  }

  function emptyWorkspace() {
    return {
      formatVersion: 1,
      profile: null,
      people: [],
      invitations: [],
      tasks: [],
      schedules: [],
      document: null
    };
  }

  function extractWorkspace(payload) {
    const candidate = payload?.workspace || payload;
    if (!candidate || typeof candidate !== "object" || Array.isArray(candidate)) return null;
    const looksLikeWorkspace = ["profile", "people", "invitations", "tasks", "schedules", "document"].some((key) => Object.hasOwn(candidate, key));
    return looksLikeWorkspace ? candidate : null;
  }

  function commitPayload(payload, setStatus) {
    const incoming = extractWorkspace(payload);
    if (incoming) {
      const current = readWorkspace() || emptyWorkspace();
      const isProfileOnly = Boolean(incoming.profile) && ["people", "invitations", "tasks", "schedules"].every((key) => !Array.isArray(incoming[key]) || incoming[key].length === 0) && !incoming.document;
      if (isProfileOnly) {
        const name = String(incoming.profile.name || incoming.profile.displayName || "").trim();
        const slug = String(incoming.profile.slug || "").trim();
        if (name) {
          current.people = Array.isArray(current.people) ? current.people : [];
          const existing = current.people.find((person) => person?.name?.toLowerCase() === name.toLowerCase() || (slug && person?.profile?.slug === slug));
          const profile = incoming.profile;
          if (existing) Object.assign(existing, {
            name,
            note: profile.note || profile.bio || existing.note || "",
            profile
          });
          else current.people.unshift({
            id: `shared-profile-${slug || name.toLowerCase().replace(/[^a-z0-9]+/g, "-")}`,
            name,
            note: profile.note || profile.bio || "Shared profile",
            profile
          });
        }
        localStorage.setItem(WORKSPACE_KEY, JSON.stringify(current));
        window.dispatchEvent(new Event("workspace:changed"));
        setStatus("Public profile added to this browser’s People list. Your own profile was not replaced.");
        return;
      }
      const merged = {
        ...current
      };
      for (const field of ["people", "invitations", "tasks", "schedules"]) {
        const oldItems = Array.isArray(current[field]) ? current[field] : [];
        const newItems = Array.isArray(incoming[field]) ? incoming[field] : [];
        const ids = new Set(oldItems.map((item) => item?.id).filter(Boolean));
        merged[field] = [...oldItems, ...newItems.filter((item) => !item?.id || !ids.has(item.id))];
      }
      if (!merged.profile && incoming.profile) merged.profile = incoming.profile;
      if (!merged.document && incoming.document) merged.document = incoming.document;
      localStorage.setItem(WORKSPACE_KEY, JSON.stringify(merged));
      window.dispatchEvent(new Event("workspace:changed"));
      setStatus("Workspace data merged into this browser. Existing profile data was kept.");
      return;
    }
    const inbox = storageRead(INBOX_KEY, []);
    const entries = Array.isArray(inbox) ? inbox : [];
    entries.unshift({
      kind: payload?.kind || "shared data",
      payload,
      savedAt: new Date().toISOString()
    });
    localStorage.setItem(INBOX_KEY, JSON.stringify(entries.slice(0, 500)));
    setStatus("Data saved to this browser’s shared-data inbox for review; unrelated workspace data was not changed.");
  }

  async function copyValue(value, setStatus, success) {
    try {
      if (!navigator.clipboard || !window.isSecureContext) throw new Error("Clipboard unavailable");
      await navigator.clipboard.writeText(value);
      setStatus(success);
    } catch (error) {
      const field = document.activeElement?.tagName === "TEXTAREA" ? document.activeElement : null;
      if (field) {
        field.focus();
        field.select();
      }
      setStatus(`${success} Clipboard access was blocked; select the displayed text and copy it manually.`);
    }
  }

  function saveJsonFile(filename, value, setStatus) {
    try {
      const parsed = JSON.parse(value);
      const blob = new Blob([JSON.stringify(parsed, null, 2)], {
        type: "application/json;charset=utf-8"
      });
      const objectUrl = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = objectUrl;
      link.download = filename;
      link.click();
      window.setTimeout(() => URL.revokeObjectURL(objectUrl), 1000);
      setStatus(`${filename} download requested. The file remains on your device unless you share it.`);
    } catch (error) {
      setStatus(`Could not save JSON: ${error.message}`);
    }
  }

  function clampLimit(value) {
    const number = Number(value);
    return Number.isInteger(number) ? Math.min(5000, Math.max(1, number)) : DEFAULT_LIMIT;
  }

  function readLimit() {
    try {
      const value = Number(localStorage.getItem(LIMIT_KEY));
      return Number.isInteger(value) && value >= 1 && value <= 5000 ? value : DEFAULT_LIMIT;
    } catch (error) {
      return DEFAULT_LIMIT;
    }
  }

  function stableValue(value) {
    if (Array.isArray(value)) return value.map(stableValue);
    if (!value || typeof value !== "object") return value;
    return Object.keys(value).sort().reduce((result, key) => {
      result[key] = stableValue(value[key]);
      return result;
    }, {});
  }

  function isPublicOnly(payload) {
    const workspace = extractWorkspace(payload);
    if (!workspace) return false;
    const profile = Boolean(workspace.profile?.name || workspace.profile?.displayName);
    const noPrivateCollections = ["people", "invitations", "tasks", "schedules"].every((key) => !Array.isArray(workspace[key]) || workspace[key].length === 0);
    return profile && noPrivateCollections && !workspace.document;
  }

  function rememberIfSelected(payload, source, selected, limitValue, setStatus) {
    if (!selected) return;
    if (!isPublicOnly(payload)) {
      setStatus("This data is not profile-only. Review carefully; only public profile data should be remembered as a public link.");
      return;
    }
    try {
      const limit = clampLimit(limitValue);
      localStorage.setItem(LIMIT_KEY, String(limit));
      const key = JSON.stringify(stableValue(payload));
      const library = storageRead(LIBRARY_KEY, []);
      const entries = Array.isArray(library) ? library : [];
      if (entries.some((item) => item.key === key)) {
        setStatus("This unique public profile data is already remembered.");
        return;
      }
      entries.unshift({
        key,
        url: source?.url || "",
        kind: payload?.kind || "public profile",
        savedAt: new Date().toISOString(),
        payload
      });
      localStorage.setItem(LIBRARY_KEY, JSON.stringify(entries.slice(0, limit)));
      setStatus(`Public profile data remembered. Library keeps up to ${limit} unique links on this device.`);
    } catch (error) {
      setStatus("Could not remember this link; browser storage may be unavailable.");
    }
  }

  function renderLibrary(summary, list) {
    if (!summary || !list) return;
    const limit = readLimit();
    const entries = storageRead(LIBRARY_KEY, []);
    const items = Array.isArray(entries) ? entries.slice(0, limit) : [];
    summary.textContent = `${items.length} remembered unique public item${items.length === 1 ? "" : "s"} · maximum ${limit} · stored in this browser`;
    list.replaceChildren();
    if (!items.length) {
      const empty = document.createElement("li");
      empty.textContent = "No public profile data remembered yet.";
      list.appendChild(empty);
      return;
    }
    items.slice(0, 20).forEach((item) => {
      const row = document.createElement("li");
      row.textContent = `${item.kind || "Public data"} · ${new Date(item.savedAt).toLocaleString()}`;
      list.appendChild(row);
    });
    if (items.length > 20) {
      const more = document.createElement("li");
      more.textContent = `${items.length - 20} more remembered item(s).`;
      list.appendChild(more);
    }
  }

  function openSyncPanel() {
    const panel = ensurePanel();
    panel.hidden = false;
    const input = panel.querySelector("#shared-data-url-input");
    const enteredUrl = input.value.trim();
    if (!enteredUrl || enteredUrl === "about:srcdoc" || enteredUrl.startsWith("about:srcdoc#")) {
      const workspace = readWorkspace() || emptyWorkspace();
      input.value = buildRelativeOrAbsoluteUrl("/", `data=${encodeJson(workspace)}`);
    }
    panel.querySelector("#shared-data-sync-status").textContent = "Current browser JSON is ready to inspect. Decode any pasted share URL to edit and re-encode its data.";
  }

  function publicSharePanel() {
    let panel = document.getElementById("public-share-panel");
    if (panel) return panel;
    panel = document.createElement("section");
    panel.id = "public-share-panel";
    panel.hidden = true;
    panel.setAttribute("aria-labelledby", "public-share-heading");
    Object.assign(panel.style, {
      position: "fixed",
      zIndex: "10000",
      right: "1rem",
      bottom: "1rem",
      width: "min(34rem,calc(100vw - 2rem))",
      maxHeight: "min(80vh,42rem)",
      overflow: "auto",
      padding: "1rem",
      border: "1px solid var(--color-line-strong)",
      borderRadius: "var(--radius)",
      background: "var(--color-surface)",
      color: "var(--color-text)",
      boxShadow: "0 1rem 3rem var(--color-shadow)"
    });
    const heading = document.createElement("h2");
    heading.id = "public-share-heading";
    heading.textContent = "Public profile share link";
    heading.style.cssText = "font-family:var(--font-heading);font-size:1.25rem;font-weight:700";
    const note = document.createElement("p");
    note.textContent = "This link carries public profile data in its fragment. Anyone with it can read that data.";
    note.style.cssText = "margin-top:.35rem;font-size:.875rem;line-height:1.5;color:var(--color-muted)";
    const field = document.createElement("textarea");
    field.id = "public-share-url-output";
    field.readOnly = true;
    field.rows = 4;
    field.setAttribute("aria-label", "Public profile link containing encoded profile data");
    field.style.cssText = fieldCss(".75rem");
    const actions = document.createElement("div");
    actions.style.cssText = "display:flex;flex-wrap:wrap;gap:.5rem;margin-top:.65rem";
    const copy = makeButton("Copy public link", true);
    const share = makeButton("Share…");
    const close = makeButton("Close");
    const status = document.createElement("p");
    status.setAttribute("role", "status");
    status.setAttribute("aria-live", "polite");
    status.style.cssText = "margin-top:.6rem;font-size:.85rem;color:var(--color-muted)";
    actions.append(copy, share, close);
    panel.append(heading, note, field, actions, status);
    document.body.appendChild(panel);
    copy.addEventListener("click", () => copyValue(field.value, (message) => status.textContent = message, "Public link copied. It contains profile data; share it only with the intended audience."));
    share.addEventListener("click", async () => {
      if (!navigator.share) {
        status.textContent = "Mobile sharing is unavailable here. Use Copy public link instead.";
        return;
      }
      try {
        await navigator.share({
          title: "Public profile",
          text: "Here is my public profile.",
          url: field.value
        });
        status.textContent = "Share sheet opened for your public profile link.";
      } catch (error) {
        status.textContent = error.name === "AbortError" ? "Sharing cancelled; the link is still ready above." : "Could not open sharing. Copy the link instead.";
      }
    });
    close.addEventListener("click", () => panel.hidden = true);
    return panel;
  }

  function showPublicShare() {
    const profile = readWorkspace()?.profile;
    const name = profile?.name || profile?.displayName;
    if (!profile || typeof name !== "string" || !name.trim()) {
      window.location.assign("/seats#profile");
      return;
    }
    const panel = publicSharePanel();
    const field = panel.querySelector("#public-share-url-output");
    const payload = profilePayload(profile);
    field.value = buildRelativeOrAbsoluteUrl("/seats", `profile-sharing&data=${encodeJson(payload)}`);
    panel.hidden = false;
    field.focus({ preventScroll: true });
    field.select();
    const status = panel.querySelector('[role="status"]');
    copyValue(field.value, (message) => status.textContent = message, "Public profile link copied. It contains readable profile data.");
  }

  function addHeaderActions() {
    document.querySelectorAll("header").forEach((header) => {
      const nav = header.querySelector("nav");
      if (!nav || header.querySelector("[data-shared-data-actions]")) return;
      const group = document.createElement("div");
      group.dataset.sharedDataActions = "true";
      group.className = "flex flex-wrap items-center gap-2";
      const share = makeButton("PUBLIC SHARE LINK", true);
      share.setAttribute("aria-label", "Create a share link containing public profile data");
      const sync = makeButton("SYNC URL DATA");
      sync.setAttribute("aria-label", "Review, decode, edit, save, and use data shared in URLs");
      group.append(share, sync);
      nav.before(group);
      share.addEventListener("click", showPublicShare);
      sync.addEventListener("click", openSyncPanel);
    });
  }

  function applyContrastPreference() {
    try {
      if (localStorage.getItem("lodge-high-contrast") === "on") {
        document.documentElement.dataset.contrast = "high";
      }
    } catch (error) {
      // Contrast preference is optional when browser storage is unavailable.
    }
  }

  function initialize() {
    applyContrastPreference();
    addHeaderActions();
    updateProfileLinks();
  }

  initialize();
  window.addEventListener("storage", initialize);
  window.addEventListener("workspace:changed", initialize);
})();
