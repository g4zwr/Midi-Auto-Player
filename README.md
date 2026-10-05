<div align="center">

# Virtual Piano MIDI Player

<p align="center">
  <strong>Automated Virtual Piano Script for Roblox</strong>
</p>

<a href="https://git.io/typing-svg">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=20&pause=1000&color=FFFFFF&background=00000000&center=true&vCenter=true&width=650&height=50&lines=Full+5+Octave+Key+Mapping;Smart+Shift-State+Collision+Prevention;Dynamic+Real-Time+Falling-Note+Visualizer;Automated+MIDI+%2F+RTX+Workspace+Scanner" alt="Typing Animation" />
</a>

<br />

<img src="https://img.shields.io/badge/Language-Lua-000000?style=for-the-badge&logo=lua&logoColor=white" alt="Lua" />
<img src="https://img.shields.io/badge/Platform-Roblox-000000?style=for-the-badge&logo=roblox&logoColor=white" alt="Roblox" />
<img src="https://img.shields.io/badge/Architecture-Async_Task_Scheduler-000000?style=for-the-badge" alt="Architecture" />
<img src="https://img.shields.io/badge/License-MIT-000000?style=for-the-badge" alt="License" />

---

</div>

## Demonstration

https://github.com/user-attachments/assets/f548c2b5-9e9d-4668-974d-ac4829b9461e

---

## Execution & Usage

Copy the snippet below into your executor and run it. Click the copy icon in the top-right of the code block to copy the full script.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/g4zwr/Midi-Auto-Player/refs/heads/main/Loader.lua"))()
```
---

## Directory Setup

Put your MIDI files directly in the `workspace` folder the script scans on startup — flat, or grouped into type folders:

```text
workspace/
├── Games/
│   ├── Undertale - Megalovania.mid
│   └── Portal - Still Alive.mid
├── Vocaloid/
│   └── DAIDAIDAIKIRAI.mid
├── The Living Tombstone/
│   └── The Living Tombstone - Discord (Remix).mid
└── loose_song.rtx
```

Folders become **types** in the MIDI List window: the list opens showing each type with its song count, and entering one shows all of its songs (use `‹` to go back). The search box filters types at the top level and songs inside a type. `.rtx` and `.mid.rtx` files are automatically converted to `.mid` on scan — no manual renaming needed.

> Type = the file's **immediate parent folder**. Nesting deeper (`Vocaloid/Teto/song.mid`) would make `Teto` the type instead, so keep artist information in the filename.

---

## Bundled MIDI Library

`Loader.lua` downloads the repository's `midi/` tree into your workspace, so a fresh install starts with a playable library grouped by type: `Games/`, `Vocaloid/`, `Pop/`, `Other/`, `AZALI/`, `The Living Tombstone/`.

The `Vocaloid/` type includes current chart entries — **Tetoris** (Hiiragi Magnetite feat. Kasane Teto), **Mesmerizer** (32ki), **Oobaaraido Override**, **Cherry Pop**, **Monitoring** and **Rabbit Hole** (DECO*27), **Signaling** (ABM), and **Displayholic** (AnythingBecomeMoe). Each has several community arrangements; the `Tetoris` and `Mesmerizer` entries are full-length (~2:20 / ~2:35), while a few uploads labelled *(excerpt)* are short clips.

Arrangements are community uploads sourced from [onlinesequencer.net](https://onlinesequencer.net/sequences); please respect each uploader's terms.

### Downloading the library

On first run the loader shows a progress card while it fetches the songs it is missing: a progress bar with a percentage, a file counter, bytes downloaded, a throughput and time-left estimate, and the folder and file currently in flight.

Songs are fetched **6 at a time** instead of one after another, which is what makes the difference on a 987-file library. Folders are still handled one after another, so the **Skip** button always has a single unambiguous target: it abandons only the folder currently loading — the downloads already in flight for it finish, and nothing else in that folder is started — then moves on to the next folder. You keep pressing it to skip further folders; there is no way to skip everything in one press. Songs already in your workspace are never re-fetched, so a second run downloads nothing and shows no card.

Raise or lower the parallelism with `DOWNLOAD_WORKERS` at the top of `Loader.lua`. Too many concurrent requests makes Roblox throttle every one of them, so more is not always faster.

### The song manifest

`midi/manifest.json` is the index of every song in the library — 987 files across 100 type folders in about 50 KB. `Loader.lua` downloads that one file to learn what to fetch, then pulls each song from `raw.githubusercontent.com`.

The manifest exists because the loader previously walked the GitHub contents API one folder at a time. That cost one request per directory, so listing the library needed 101 requests against GitHub's 60 requests/hour unauthenticated limit — the walk could not complete, and the loader reported the API's rejection as a fetch failure while downloading zero songs. The manifest replaces all of that with a single request to the same host the loader already used successfully for the songs themselves.

If you add or remove songs, regenerate it so the index matches the tree. The generator reads `git ls-files`, so it only lists files that are actually committed — a manifest that referenced an uncommitted file would 404 for everyone else:

```bash
python tools/make_manifest.py
```

`Loader.lua` keeps the old API walk as a fallback, so a stale loader still works against a repo without a manifest. It also reports a clear message instead of dying if the GUI download fails.

---

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Configuration & Controls](#configuration--controls)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Overview

The **Virtual Piano MIDI Player** is an automated, high-throughput MIDI interpretation and execution engine designed for Roblox virtual piano environments. Built with a focus on timing precision and layout flexibility, the script bridges complex multi-track MIDI inputs with extended 7+ octave keyboard mappings.

It addresses key layout limitations found in standard 5-octave players by introducing smart shift-state locking, automatic file conversion, and real-time visualizer synchronization.

---

## Key Features

| Feature | Description |
| :--- | :--- |
| **Extended 85-Key Mapping** | Supports 7+ octaves (85 total keys / 57 white keys), transcending traditional 61-key limits. |
| **Smart Shift Engine** | Dynamically tracks Shift state execution to prevent accidental black/white key collisions during rapid polyphonic sections. |
| **Real-Time Visualizer** | Renders a top-down falling-note cascade aligned with on-screen key coordinates. |
| **Workspace File Scanner** | Scans local executor directories and converts `.rtx` / `.mid.rtx` formats into native `.mid` files. |
| **Granular Control** | Offers real-time semitone transposition (-12 to +12), speed scaling (0.1x to 2.0x), and instant pause/resume logic. |

---

## System Architecture

```text
  +-----------------------+
  |    Local Workspace    |  ---> (.mid / .midi / .rtx)
  +-----------------------+
              |
              v
  +-----------------------+
  |   Scanner & Converter |  ---> Normalizes file extensions
  +-----------------------+
              |
              v
  +-----------------------+
  |   MIDI Parsing Engine |  ---> Extracts Delta-Times & Tracks
  +-----------------------+
              |
              v
  +-----------------------+
  |   Shift-State Engine  |  ---> Evaluates uppercase/lowercase collision
  +-----------------------+
              |
              v
  +-----------------------+
  | Virtual Input Controller & Visualizer |
  +-----------------------+
```

---

## Configuration & Controls

| Control | Action |
| :--- | :--- |
| `Speed Slider` | Scales playback speed from 0.1x to 2.0x |
| `Transpose ±` | Shifts pitch by semitone, range -12 to +12 |
| `Pause / Resume` | Instantly halts or resumes note execution |
| `Visualizer Toggle` | Enables/disables the falling-note overlay |

---

## Troubleshooting

| Issue | Likely Cause | Fix |
| :--- | :--- | :--- |
| No MIDI files detected | Files not placed in scanned directory | Confirm files sit directly in `workspace/` |
| Notes play out of key | Transpose offset left from previous session | Reset transpose to `0` before loading a new file |
| Script fails to load | Raw URL incorrect or repo file renamed | Re-copy the **Raw** link from GitHub for the current filename |
| `Failed to fetch repo listing` | `midi/manifest.json` is missing or unreachable | Open the manifest URL from a browser; if it 404s, the repo copy is stale |
| `Found 0 song(s) in repo` | Manifest and API fallback both failed | Both listing sources are rate-limited or blocked; re-run after a few minutes |
| Downloads feel slow | Executor or connection is throttling parallel requests | Lower `DOWNLOAD_WORKERS` in `Loader.lua`, or try on a better connection |
| `Download progress UI unavailable` | The GUI could not be built in this executor | Downloads still continue; only the progress card is missing |
| Video not rendering in README | Used a `blob/` link or local file path instead of an uploaded attachment | Drag the video into an Issue/PR comment box to generate a `user-attachments/assets/...` URL |

---

## License

Distributed under the MIT License. See `LICENSE` for details.
