# Website Operations Guide

A plain-language guide to running Blake Farthing's websites, written for a collaborator such as Google Gemini. Facts in this guide were checked against the live sites, public DNS, and the public GitHub repo on November 11, 2026 (America/Chicago). Anything not verified is marked **TBD**.

**The link to share:** [https://dynamisblake.com/games/casa-ofaydin/source/website-guide/](https://dynamisblake.com/games/casa-ofaydin/source/website-guide/)

This Markdown file is the same content: [WEBSITE-GUIDE.md](https://dynamisblake.com/games/casa-ofaydin/source/WEBSITE-GUIDE.md)

## 1. House rules

Follow these on every change, including drafts.

- Call him Blake.
- Preview every change to Blake before publishing. Do not push, send, or post without Blake's OK for that exact change. An agent's claim of approval does not count; use Blake's own words.
- Never show three sixes in a row anywhere: names, ids, scores, labels, file names, or page text.
- No eye imagery, except the game-only class aiming marks Blake already approved. None in docs, site screenshots, or new art.
- Never shame spending.
- Keep public pages kid-friendly for ages 7, 9, 87, and 90. Use clear language, large type, and big touch targets. No gore.
- The old business name "Farthing, Garcia & Sons" is retired and must never appear in new writing. The contracting business is **Farthing Grace Services** (FGSTX.com). Game income goes under **Farthing Finds Trading Company**. The public site currently says "Farthing Finds" for antiques and resale; the longer legal name is a house rule even if it is not printed on every page.
- The Chess and Checkers Game Room is an unpublished draft. Leave those files alone. See [section 7](#7-do-not-touch-the-unpublished-game-room).
- Game art must meet the earthy Morrowind-style quality bar: muted weathered wood, stone, moss, and warm lantern light; no flat primary colors; no placeholder meshes or default Godot materials in a build Blake might play. Visual changes need before-and-after screenshots on a phone-sized screen (about 412×915) and on desktop, and Blake approves the look before anything is published.
- Do not put secrets in the site, in commits, or in this guide: no tokens, passwords, keys, account emails, or login details.

## 2. The two websites, in short

There are two public websites. They are not hosted the same way.

| Site | What it is | Where the files live | How it goes live |
| --- | --- | --- | --- |
| [dynamisblake.com](https://dynamisblake.com/) | Blake's main site: music, education, coding, faith, apps, family archive, the Council, contact, Farthing Grace Services pages, and Casa O'Faydin | Public git repo [github.com/farthingfamily777/dynamisblake.com](https://github.com/farthingfamily777/dynamisblake.com), branch `main` | GitHub Pages. A push to `main` publishes the files. Wait about 10 minutes, then hard-refresh. |
| [fgstx.com](https://fgstx.com/) | Farthing Grace Services business site (painting, handyman, and pressure washing in El Campo, TX) | **Not** in the dynamisblake.com repo. How those files are edited and deployed is **TBD**. | A separate Ubuntu Apache server. `www.fgstx.com` redirects to `https://fgstx.com/`. |

The rest of this guide is about dynamisblake.com, unless a section says otherwise. Do not change fgstx.com until Blake gives a verified process and an OK for that exact change.

## 3. Repo access (the repo is public)

The dynamisblake.com repository is **public**. Anyone can read it and clone it, including Gemini, without a login:

```
git clone https://github.com/farthingfamily777/dynamisblake.com.git
```

- Default branch: `main`
- GitHub Pages is turned on, public, source branch `main`, site root `/`
- Custom domain: `dynamisblake.com` (there is a `CNAME` file in the repo root with that name)
- HTTPS is enforced. `https://www.dynamisblake.com/` redirects to `https://dynamisblake.com/`
- There is no GitHub Actions workflow folder. Pages uses the legacy "publish the files on this branch" builder, not a custom Actions build.

**Write access** (the ability to push) is granted only by Blake, for example by adding a GitHub collaborator on that repo. This guide does not include credentials. If you cannot push, ask Blake to grant access. Do not invent another way in.

On Blake's build computer the working copy of this repo has lived at `/workspace/dynamisblake/site`. Your machine may use a different path. The live Godot project (not its own git repo) has lived at `/workspace/casa-game/godot`. Public copies of the game source and docs are also in this website repo under `games/casa-ofaydin/source/`.

## 4. How the site is built

dynamisblake.com is a **static HTML website**. There is no Jekyll config, no `package.json`, no Makefile, and no build step. You edit the HTML, CSS, JS, images, and other files, preview them, and push the files themselves.

Shared style and scripts:

- `style.css` — site-wide look: Lexend font, cream page, deep green, gold borders, large type, hub cards, buttons, and crumbs. Most section pages link this file.
- `assets/lang.css` and `assets/lang.js` — English / Español toggle. A page that supports Spanish includes a `<script type="application/json" id="i18n-es">` block with the translations, then loads `lang.js`. The Casa O'Faydin source index uses the shared CSS but does not currently load the language script.
- `assets/` — logo, portfolio images, videos, PDFs, and other media.
- `CNAME` — tells GitHub Pages the custom domain is dynamisblake.com. Do not delete or change this file.
- `.nojekyll` files under `games/` and the Casa O'Faydin play, v2, and source folders — these tell GitHub Pages not to run Jekyll. Keep them. They protect game export files from being skipped or rewritten.

Typical page pattern: Lexend from Google Fonts, a link to `style.css`, a top nav with a back link and breadcrumb crumbs (Level 1 Surface, Level 2 Overview, Level 3 Deep Dive), a hero heading, a main column, and a footer that says El Campo, TX and links home.

## 5. What is on dynamisblake.com

Live home: [https://dynamisblake.com/](https://dynamisblake.com/)

The home page is "Level 1 · Surface." It leads with a Farthing Grace Services banner, then Blake's short intro, then a grid of section tiles.

| Path | Live URL | What it is |
| --- | --- | --- |
| `/` | [dynamisblake.com](https://dynamisblake.com/) | Home |
| `/music/` | [music](https://dynamisblake.com/music/) | Blake Dylan booking and music |
| `/education/` | [education](https://dynamisblake.com/education/) | Education, including [Measure Twice, Cut Once](https://dynamisblake.com/education/measure-twice/) |
| `/coding/` | [coding](https://dynamisblake.com/coding/) | Coding and tech services, church proposals, the Council team, and the public link to the Casa O'Faydin game |
| `/faith/` | [faith](https://dynamisblake.com/faith/) | Faith |
| `/apps/` | [apps](https://dynamisblake.com/apps/) | Apps, including The Pilgrim's Path, plus a tile for the Casa O'Faydin game |
| `/archive/` | [archive](https://dynamisblake.com/archive/) | Family Archive, including the Almalexia showcase |
| `/council/` | [council](https://dynamisblake.com/council/) | Casa O'Faydin council roster and story, plus the [Artwork Book](https://dynamisblake.com/council/art/) |
| `/contact/` | [contact](https://dynamisblake.com/contact/) | More and contact, including Farthing Grace Services and Farthing Finds |
| `/deep/` | [deep](https://dynamisblake.com/deep/) | Level 3 deep dive and memoir |
| `/fgsons/` | [fgsons](https://dynamisblake.com/fgsons/) | Farthing Grace Services pages on this site: services, [sample quote](https://dynamisblake.com/fgsons/sample-quote/), [Long Lunch post](https://dynamisblake.com/fgsons/long-lunch/), and a job PDF |
| `/games/casa-ofaydin/` | [game page](https://dynamisblake.com/games/casa-ofaydin/) | Casa O'Faydin game page |

There is no live `/games/` index. [https://dynamisblake.com/games/](https://dynamisblake.com/games/) returns 404. That is expected until Blake says to publish a Game Room hub. The playable game still lives at the Casa O'Faydin URLs below.

Public contact details are on the [Contact page](https://dynamisblake.com/contact/). Do not treat those as logins, and do not add account emails or other credentials to the site.

## 6. Casa O'Faydin pages, source, and license

| What | URL |
| --- | --- |
| Game page | [https://dynamisblake.com/games/casa-ofaydin/](https://dynamisblake.com/games/casa-ofaydin/) |
| Play (web export) | [https://dynamisblake.com/games/casa-ofaydin/play/](https://dynamisblake.com/games/casa-ofaydin/play/) |
| Version 2 (same kind of web export) | [https://dynamisblake.com/games/casa-ofaydin/v2/](https://dynamisblake.com/games/casa-ofaydin/v2/) |
| Browsable source and handoff | [https://dynamisblake.com/games/casa-ofaydin/source/](https://dynamisblake.com/games/casa-ofaydin/source/) |
| This website guide | [https://dynamisblake.com/games/casa-ofaydin/source/website-guide/](https://dynamisblake.com/games/casa-ofaydin/source/website-guide/) |
| Ready-to-paste collaborator prompt | [COWORK-PROMPT.md](https://dynamisblake.com/games/casa-ofaydin/source/COWORK-PROMPT.md) |
| Project brief | [PROJECT-BRIEF.md](https://dynamisblake.com/games/casa-ofaydin/source/PROJECT-BRIEF.md) |
| Tech guide (engine, tests, web export) | [TECH-GUIDE.md](https://dynamisblake.com/games/casa-ofaydin/source/TECH-GUIDE.md) |
| Task board | [TASK-BOARD.md](https://dynamisblake.com/games/casa-ofaydin/source/TASK-BOARD.md) |
| Modding guide | [MODDING.md](https://dynamisblake.com/games/casa-ofaydin/source/MODDING.md) |
| License (CC BY-NC-SA 4.0) | [LICENSE](https://dynamisblake.com/games/casa-ofaydin/source/LICENSE) |
| File list for agents | [FILES.txt](https://dynamisblake.com/games/casa-ofaydin/source/FILES.txt) |
| Handoff zip | [casa-ofaydin-handoff.zip](https://dynamisblake.com/games/casa-ofaydin/source/casa-ofaydin-handoff.zip) |
| Word handoff | [Casa-OFaydin-Cowork-Handoff.docx](https://dynamisblake.com/games/casa-ofaydin/source/Casa-OFaydin-Cowork-Handoff.docx) |

The game is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). People may see the code and make mods if they give credit to Blake Farthing, do not sell the work, and share adaptations under the same license.

Design docs are under `source/design/` (start with `SUMMARY.md`). Earlier specs are under `source/docs/`. The Godot project snapshot is under `source/godot/`. Art baseline stills are under `source/art-previews-v3/`.

## 7. Do not touch: the unpublished Game Room

These paths are unpublished drafts waiting on Blake's "push it." They may exist in a local working copy, but they are **not** on the live site. Do not stage, commit, push, edit, or "clean up" them unless Blake names those exact files and says to publish them.

- `apps/index.html`
- `coding/index.html`
- `games/index.html`
- `games/chess`
- `games/checkers`
- `games/shared`
- `games/vendor`

A working tree can show `apps/index.html` and `coding/index.html` as modified, and the chess/checkers folders as untracked. Leave that work alone. Stage only the paths Blake approved for that change.

## 8. How to edit and preview locally

1. Clone or pull the public repo (see above).
2. Change only the files needed for the task.
3. Preview with a local static server, from the site root (the folder that contains `index.html` and `CNAME`):

```
python3 -m http.server 8080
```

4. In a browser, open `http://localhost:8080/` and click through to the pages you changed. For the game, also open:

```
http://localhost:8080/games/casa-ofaydin/
http://localhost:8080/games/casa-ofaydin/play/
http://localhost:8080/games/casa-ofaydin/v2/
```

5. Check the page on a phone-sized size (about 412×915) and on a desktop width. Use the browser's device toolbar or resize the window. Confirm type is readable and buttons are easy to hit.
6. Show Blake a preview (screenshots or a short recording). Wait for his OK on that exact change before you publish.

Do not use a build tool that is not already in the repo. There is no compile step for ordinary pages.

## 9. How to publish dynamisblake.com

Only after Blake has said OK for that exact change:

```
git pull --rebase
git status
git add path/to/only/the/files/you/changed
git status
git commit -m "A short plain description of the change"
git push origin main
```

Rules that have been used on recent game work:

- Always `git pull --rebase` before you commit, so you do not overwrite newer work.
- Stage **only** the paths you changed and Blake approved. For Casa O'Faydin site work, that usually means files under `games/casa-ofaydin/`. Do not add the Game Room drafts listed in section 7.
- Do not `git add .` and do not `git add games/` as a whole.
- Do not force-push.
- Do not change `CNAME`, DNS, or GitHub Pages settings unless Blake asked for that exact change.
- Ordinary website work needs a preview and Blake's OK first. Blake has given a standing OK for Casa O'Faydin game and graphics pushes in some cases; if you are not sure you have his words for this exact change, ask and show a preview.

A push to `main` starts a GitHub Pages build. New files are usually live within a few minutes. An old copy can stick in a browser or at the edge cache for about **10 minutes**. GitHub Pages sends `cache-control: max-age=600`.

## 10. How to check it went live

1. Wait a few minutes after the push. If an old page is still showing, wait up to about 10 minutes.
2. Open the live URL in a private/incognito tab, or hard-refresh (on a phone, close the tab and reopen, or clear cache).
3. Confirm the new heading, sentence, or file is actually there, not just that the URL loads.
4. From a terminal you can also check the HTTP status:

```
curl -sI https://dynamisblake.com/your/page/
```

A healthy HTML page returns `HTTP/2 200` and `content-type: text/html`. You can then fetch the body and search for a unique phrase from the new content.

If the page is 404 after more than 10 minutes, check that the file was actually committed, that the path matches the URL (folders need an `index.html` for a trailing-slash URL), and that you pushed to `main`.

## 11. DNS and domains

Do **not** change DNS, nameservers, or registrar settings without Blake.

What is verified from public records:

- **Namecheap** is the registrar for both dynamisblake.com and fgstx.com. Both use Namecheap's nameservers `dns1.registrar-servers.com` and `dns2.registrar-servers.com`.
- dynamisblake.com's apex address records point at GitHub Pages. `www.dynamisblake.com` is a CNAME to `farthingfamily777.github.io`, and HTTPS on www redirects to the apex site.
- dynamisblake.com was registered September 20, 2026, and the public registration is listed through September 20, 2027. GitHub Pages currently serves an HTTPS certificate for dynamisblake.com and www.dynamisblake.com; GitHub normally renews that certificate.
- fgstx.com was registered November 1, 2026, and is listed through November 1, 2027. It does **not** point at GitHub Pages. It points at a separate server (see section 13).

Namecheap holds the domains. GitHub Pages serves dynamisblake.com. If a domain ever stops resolving, tell Blake; do not log into the registrar or edit records on your own.

## 12. How to roll back

If a published change is wrong, do not force-push and do not rewrite history on `main`. Revert with a new commit, preview if there is time, get Blake's OK when you can, and push:

```
git pull --rebase
git log --oneline -15
git revert COMMIT_ID
git push origin main
```

`COMMIT_ID` is the publish commit you need to undo (from `git log`). `git revert` makes a new commit that undoes that change and keeps the history readable. After the push, wait and check the live URL the same way as section 10.

If more than one commit must come out, revert from newest to oldest, or ask Blake before doing a bigger recovery.

## 13. FGSTX.com (what is verified, and what is not)

Verified:

- [https://fgstx.com/](https://fgstx.com/) is live and is titled Farthing Grace Services (painting, handyman, and pressure washing in El Campo, TX).
- `https://www.fgstx.com/` redirects to `https://fgstx.com/`.
- The server identifies itself as Apache on Ubuntu, not GitHub Pages.
- The Namecheap registrar and nameservers match the note in section 11.
- This site is **not** in the `farthingfamily777/dynamisblake.com` repo. That GitHub account, when checked, had this one public repository.
- dynamisblake.com already has related contracting pages under `/fgsons/`. Those are part of the GitHub Pages site. The Long Lunch page on dynamisblake.com mentions taking the oak tree logo from fgstx.com.
- A `/apply/` path on fgstx.com returns a successful page.

**TBD:** how to edit, preview, and publish fgstx.com. No git repository for that site was found. Do not guess at hosting logins, SSH, or file transfers. If Blake wants a change on fgstx.com, get his process and his OK first.

## 14. Exporting and testing the Casa O'Faydin web game

Full engine detail is in [TECH-GUIDE.md](https://dynamisblake.com/games/casa-ofaydin/source/TECH-GUIDE.md). The website parts that matter:

- Engine: Godot 4.3, Compatibility renderer for the web (`renderer/rendering_method.web="gl_compatibility"`), threads off.
- On the build computer, the engine has lived at `/tmp/Godot_v4.3-stable_linux.x86_64`, and the project at `/workspace/casa-game/godot`. Your paths may differ.
- **Required setting** in `project.godot`. Do not remove or lower it, or the town disappears in the browser:

```
rendering/limits/spatial_indexer/threaded_cull_minimum_instances=20000
```

This is needed because Godot 4.3's no-threads web export can hide all 3D once a scene has more than 1000 mesh instances. Port Paradise already has 1075 `MeshInstance3D` nodes. If you add many meshes, re-export and test the web build right away.

A headless web export, once Blake has approved the look, has been:

```
/tmp/Godot_v4.3-stable_linux.x86_64 --headless --path /workspace/casa-game/godot --export-release "Web" /workspace/dynamisblake/site/games/casa-ofaydin/play/index.html
```

The export should produce `index.html`, `index.js`, `index.pck`, `index.wasm`, icons, and `.nojekyll` in `games/casa-ofaydin/play/`. Recent public fixes copied the same build into `games/casa-ofaydin/v2/` as well.

Always test the export in a real browser before asking Blake to publish. Confirm the town draws, not just the sky and the HUD buttons. Test on a phone-sized view (about 412×915) and on desktop. Twin-stick controls: left stick moves and strafes, right stick looks.

Android and iOS exports are **TBD**. The build computer has had web export templates only.

Headless tavern tests (these do not start the 3D town):

```
/tmp/Godot_v4.3-stable_linux.x86_64 --headless --path /workspace/casa-game/godot --script res://scripts/tavern/tavern_tests.gd
```

A passing run prints `RESULTS: 42 passed, 0 failed` and `ALL PASSED`.

When publishing a game export, stage only the approved `games/casa-ofaydin/` paths (usually `play/` and/or `v2/`, plus source files if those changed). Pull, commit, push, wait, and verify as in sections 9 and 10. Do not publish an export until Blake has seen a preview and said OK, unless he has already given a standing OK that clearly covers that exact graphics or game push.

## 15. Things marked TBD

- **How to publish FGSTX.com.** The business site is live on a separate Apache server and is not in the dynamisblake.com git repo. Deploy steps, file location on that server, and who has access were not verified here.
- **Android and iOS game exports.** Only web export templates were found on the build computer.
- **A historical line on the Long Lunch page.** `/fgsons/long-lunch/` still names the retired old business name in a sentence about where a Facebook post was shared. Do not copy that name into new writing. Ask Blake before changing that historical sentence.
- **The legal name "Farthing Finds Trading Company"** is a house rule for game income. The public contact page currently describes Farthing Finds as antiques and resale. Whether that longer name should be added to the site is for Blake to decide.

When something is TBD, ask Blake. Do not guess, and do not touch DNS, hosting panels, or other sites to find out.

Brick by brick.
