# Virtual Piano MIDI Player

An automated Lua-based Virtual Piano MIDI Player designed for Roblox piano games. It features full 7+ octave key mapping, dynamic falling-note visualization, and intelligent shift-key state tracking to prevent accidental key misfires.

---

## Video Showcase (Rush E Proof)

<p align="center">
  <a href="https://www.youtube.com/watch?v=YOUR_VIDEO_ID_HERE">
    <img src="https://img.youtube.com/vi/YOUR_VIDEO_ID_HERE/maxresdefault.jpg" alt="Virtual Piano Playing Rush E" width="700">
  </a>
</p>

```html
<!-- Local / Direct Video Embed Template -->
<video src="path/to/your/rush_e_proof.mp4" controls width="100%"></video>

Features
 * Extended 7+ Octave Keyboard: Mapped across 85 chromatic pitches (57 white keys), extending well beyond basic 5-octave piano layouts.
 * Smart Shift-State Tracker: Manages LeftShift state per active chord to ensure white keys are never misread as black keys during complex playback.
 * Falling Note Visualizer: Displays real-time falling blocks mapped to key positions and duration.
 * Automatic .rtx Conversion: Scans for .rtx / .mid.rtx files and automatically renames and copies them into standard .mid format.
 * Playback Controls: Built-in transposing (semitones), speed scaling, smooth pause/resume transitions, and file rescanning.
File Directory Setup
 * Open your executor's root folder on your device.
 * Locate and open the workspace directory:
   * Example Path: <Executor Folder>/workspace (e.g., Delta/workspace, Fluxus/workspace, Codex/workspace).
 * Drag and drop your .mid or .midi files into this workspace folder.
> Note on .rtx Files: If your MIDI files have the extension .rtx or .mid.rtx, simply leave them as is. The script's built-in file scanner automatically creates a duplicate .mid copy inside your workspace.
> 
Usage Instructions
 * Attach/Inject your Roblox executor in-game.
 * Execute script.lua.
 * Click the VP button in the top-left corner to toggle the GUI.
 * Click Rescan Files to populate your MIDI list from the workspace directory.
 * Select a file from the right panel.
 * Adjust the Transpose or Speed settings if desired.
 * Click Play to start playback.
Technical Requirements
Your executor must support standard file-system and input functions:
 * readfile / writefile
 * listfiles or listfile
 * isfile / isfolder
 * VirtualInputManager service

