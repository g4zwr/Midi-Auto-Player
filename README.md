<div align="center">

# Virtual Piano MIDI Player

<p align="center">
  <strong>High-Precision Automated Virtual Piano Engine for Roblox</strong>
</p>

<a href="https://git.io/typing-svg">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=20&pause=1000&color=FFFFFF&background=00000000&center=true&vCenter=true&width=650&height=50&lines=Full+7%2B+Octave+Key+Mapping+(85+Keys);Smart+Shift-State+Collision+Prevention;Dynamic+Real-Time+Falling-Note+Visualizer;Automated+MIDI+%2F+RTX+Workspace+Scanner" alt="Typing Animation" />
</a>

<br />

<img src="https://img.shields.io/badge/Language-Lua-000000?style=for-the-badge&logo=lua&logoColor=white" alt="Lua" />
<img src="https://img.shields.io/badge/Platform-Roblox-000000?style=for-the-badge&logo=roblox&logoColor=white" alt="Roblox" />
<img src="https://img.shields.io/badge/Architecture-Async_Task_Scheduler-000000?style=for-the-badge" alt="Architecture" />
<img src="https://img.shields.io/badge/License-MIT-000000?style=for-the-badge" alt="License" />

---

</div>

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [System Architecture](#system-architecture)
- [Demonstration](#demonstration)
- [Directory Setup](#directory-setup)
- [Execution & Usage](#execution--usage)
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
  | Virtual Input Controller & Visualizer
  +-----------------------+
