(() => {
  "use strict";

  const STORAGE_KEY = "lodge-profile-builds-v1";
  const STATUSES = ["Planning", "In progress", "Blocked", "Ready", "Archived"];
  const ACCESS_LEVELS = ["Private", "Invite link", "Public link"];
  const buildForm = document.getElementById("build-form");
  const manageList = document.getElementById("build-manage-list");
  const landingList = document.getElementById("landing-build-list");
  const managerStatus = document.getElementById("build-manager-status");
  const landingStatus = document.getElementById("landing-build-status");

  function readBuilds() {
    try {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || "[]");
      if (!Array.isArray(saved)) return [];
      return saved.filter((build) => build && typeof build.id === "string").map((build) => ({
        id: build.id.slice(0, 100),
        title: typeof build.title === "string" ? build.title.slice(0, 100) : "Untitled build",
        description: typeof build.description === "string" ? build.description.slice(0, 800) : "",
        artwork: typeof build.artwork === "string" && build.artwork.startsWith("data:image/") ? build.artwork : "",
        status: STATUSES.includes(build.status) ? build.status : "Planning",
        access: ACCESS_LEVELS.includes(build.access) ? build.access : "Private",
        link: safeHttpUrl(build.link),
        updatedAt: typeof build.updatedAt === "string" ? build.updatedAt : new Date().toISOString()
      }));
    } catch (error) {
      return [];
    }
  }

  function safeHttpUrl(value) {
    if (typeof value !== "string" || !value.trim()) return "";
    try {
      const url = new URL(value.trim());
      return ["http:", "https:"].includes(url.protocol) ? url.toString() : "";
    } catch (error) {
      return "";
    }
  }

  function saveBuilds(builds) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(builds));
      render();
      if (managerStatus) managerStatus.textContent = "Build portfolio saved in this browser only.";
      if (landingStatus) landingStatus.textContent = "Build updates saved in this browser. They are not live deployment checks.";
      return true;
    } catch (error) {
      const message = "Could not save this build. Browser storage may be full; try a smaller artwork image.";
      if (managerStatus) managerStatus.textContent = message;
      if (landingStatus) landingStatus.textContent = message;
      return false;
    }
  }

  function makeId() {
    return globalThis.crypto?.randomUUID ? crypto.randomUUID() : `build-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  }

  function buildCard(build, editable) {
    const article = document.createElement("article");
    article.className = "rounded-[var(--radius)] border border-[var(--color-line)] bg-[var(--color-surface)] p-4 sm:p-5";

    const heading = document.createElement("div");
    heading.className = "flex items-start gap-4";
    const artwork = document.createElement("button");
    artwork.type = "button";
    artwork.className = "focus-ring grid h-16 w-16 shrink-0 place-items-center overflow-hidden rounded-[var(--radius)] border border-[var(--color-line)] bg-[var(--color-overlay-soft)] text-3xl text-[var(--color-primary)]";
    artwork.setAttribute("aria-label", `Update state or access for ${build.title}`);
    artwork.title = "Click to update this build’s state or access";
    if (build.artwork) {
      const image = document.createElement("img");
      image.src = build.artwork;
      image.alt = `${build.title} artwork`;
      image.className = "h-full w-full object-cover";
      artwork.appendChild(image);
    } else {
      artwork.textContent = "🍝🧠";
      artwork.setAttribute("aria-label", "Build artwork placeholder");
    }

    const titleWrap = document.createElement("div");
    titleWrap.className = "min-w-0 flex-1";
    const title = document.createElement("h3");
    title.className = "display-font text-xl font-semibold";
    title.textContent = build.title;
    const description = document.createElement("p");
    description.className = "mt-1 whitespace-pre-wrap break-words text-sm leading-6 text-[var(--color-muted)]";
    description.textContent = build.description || "No build summary yet.";
    titleWrap.append(title, description);
    heading.append(artwork, titleWrap);

    const meta = document.createElement("p");
    meta.className = "mt-4 text-xs text-[var(--color-muted)]";
    meta.textContent = `Updated ${new Date(build.updatedAt).toLocaleString()}`;

    const controls = document.createElement("div");
    controls.className = "mt-4 grid gap-3 sm:grid-cols-2";
    const statusLabel = document.createElement("label");
    statusLabel.className = "text-xs font-semibold uppercase tracking-wide text-[var(--color-muted)]";
    statusLabel.textContent = "Build state";
    const statusSelect = document.createElement("select");
    statusSelect.className = "focus-ring mt-2 w-full rounded-[var(--radius)] border border-[var(--color-line-strong)] bg-[var(--color-bg)] px-3 py-2.5 text-sm normal-case tracking-normal text-[var(--color-text)]";
    STATUSES.forEach((value) => statusSelect.add(new Option(value, value)));
    statusSelect.value = build.status;
    statusSelect.disabled = !editable;
    statusLabel.appendChild(statusSelect);

    const accessLabel = document.createElement("label");
    accessLabel.className = "text-xs font-semibold uppercase tracking-wide text-[var(--color-muted)]";
    accessLabel.textContent = "Access";
    const accessSelect = document.createElement("select");
    accessSelect.className = "focus-ring mt-2 w-full rounded-[var(--radius)] border border-[var(--color-line-strong)] bg-[var(--color-bg)] px-3 py-2.5 text-sm normal-case tracking-normal text-[var(--color-text)]";
    ACCESS_LEVELS.forEach((value) => accessSelect.add(new Option(value, value)));
    accessSelect.value = build.access;
    accessSelect.disabled = !editable;
    accessLabel.appendChild(accessSelect);
        controls.append(statusLabel, accessLabel);
    artwork.addEventListener("click", () => {
      statusSelect.focus();
      controls.scrollIntoView({ block: "nearest", behavior: "smooth" });
      const message = `Update the state or access label for ${build.title} using the controls below.`;
      if (landingStatus && landingList?.contains(article)) landingStatus.textContent = message;
      if (managerStatus && manageList?.contains(article)) managerStatus.textContent = message;
    });

    statusSelect.addEventListener("change", () => updateBuild(build.id, { status: statusSelect.value }));
    accessSelect.addEventListener("change", () => updateBuild(build.id, {
      access: accessSelect.value
    }));

    const actions = document.createElement("div");
    actions.className = "mt-4 flex flex-wrap items-center gap-3";
    if (build.link) {
      const open = document.createElement("a");
      open.href = build.link;
      open.target = "_blank";
      open.rel = "noopener noreferrer";
      open.className = "focus-ring rounded-[var(--radius)] text-sm font-semibold text-[var(--color-primary)] underline";
      open.textContent = "Open build link ↗";
      actions.appendChild(open);
    }
    if (editable) {
      const remove = document.createElement("button");
      remove.type = "button";
      remove.className = "focus-ring rounded-[var(--radius)] border border-[var(--color-line-strong)] px-3 py-2 text-xs font-semibold";
      remove.textContent = "Remove build";
      remove.addEventListener("click", () => saveBuilds(readBuilds().filter((entry) => entry.id !== build.id)));
      actions.appendChild(remove);
    }

    article.append(heading, controls, meta, actions);
    return article;
  }

  function updateBuild(id, changes) {
    const builds = readBuilds().map((build) => build.id === id ? {
      ...build,
      ...changes,
      updatedAt: new Date().toISOString()
    } : build);
    saveBuilds(builds);
  }

  function render() {
    const builds = readBuilds();
    if (manageList) {
      manageList.replaceChildren();
      if (!builds.length) {
        const empty = document.createElement("p");
        empty.className = "rounded-[var(--radius)] border border-dashed border-[var(--color-line-strong)] p-4 text-sm text-[var(--color-muted)]";
        empty.textContent = "No builds yet. Add a build to give it a title, artwork, state, and access label.";
        manageList.appendChild(empty);
      } else {
        builds.forEach((build) => manageList.appendChild(buildCard(build, true)));
      }
    }
    if (landingList) {
      landingList.replaceChildren();
      if (!builds.length) {
        const empty = document.createElement("p");
        empty.className = "rounded-[var(--radius)] border border-dashed border-[var(--color-line-strong)] bg-[var(--color-surface)] p-5 text-sm leading-6 text-[var(--color-muted)]";
        empty.textContent = "No builds are listed yet. Create one in your profile workspace to feature it here.";
        landingList.appendChild(empty);
      } else {
        builds.forEach((build) => landingList.appendChild(buildCard(build, true)));
      }
    }
  }

  if (buildForm) {
    buildForm.addEventListener("submit", async (event) => {
      event.preventDefault();
      const form = event.currentTarget;
      const title = form.elements.buildTitle.value.trim().slice(0, 100);
      const description = form.elements.buildDescription.value.trim().slice(0, 800);
      const linkInput = form.elements.buildLink.value.trim();
      const link = safeHttpUrl(linkInput);
      if (linkInput && !link) {
        managerStatus.textContent = "Enter a valid http(s) link, or leave the link empty.";
        return;
      }
      const imageFile = form.elements.buildArtwork.files[0];
      let artwork = "";
      if (imageFile) {
        if (!imageFile.type.startsWith("image/")) {
          managerStatus.textContent = "Choose an image file for build artwork.";
          return;
        }
        if (imageFile.size > 2 * 1024 * 1024) {
          managerStatus.textContent = "Artwork must be 2 MB or smaller. A smaller image helps browser storage.";
          return;
        }
        artwork = await new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onerror = () => reject(new Error("Could not read the selected artwork."));
          reader.onload = () => resolve(String(reader.result));
          reader.readAsDataURL(imageFile);
        }).catch((error) => {
          managerStatus.textContent = error.message;
          return "";
        });
        if (!artwork && imageFile) return;
      }
      const builds = readBuilds();
      builds.unshift({
        id: makeId(),
        title,
        description,
        artwork,
        status: "Planning",
        access: "Private",
        link,
        updatedAt: new Date().toISOString()
      });
      if (saveBuilds(builds)) {
        form.reset();
        managerStatus.textContent = "Build added to your browser-local profile and landing page.";
      }
    });
  }

  window.addEventListener("storage", (event) => {
    if (event.key === STORAGE_KEY) render();
  });
  render();
})();
