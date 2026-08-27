# GTA: San Andreas (PortMaster) - D-Pad to Left Analog Fix

[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20ARM64-blue.svg)](#)
[![Device Support](https://img.shields.io/badge/Devices-RG35XX%20Plus%20%7C%20SP%20%7C%202024%20%7C%20RG28XX%20%7C%20RG34XX-brightgreen.svg)](#)
[![OS Support](https://img.shields.io/badge/OS-muOS%20%7C%20KNULLI%20%7C%20ROCKNIX%20%7C%20ArkOS-purple.svg)](#)
[![License](https://img.shields.io/badge/License-MIT-orange.svg)](#)


A clean, non-destructive binary fix for the **Grand Theft Auto: San Andreas** Linux/PortMaster ARM64 port.

This fix allows you to play GTA: San Andreas on D-Pad-only Anbernic handheld consoles by routing D-Pad inputs directly into the game's **Left Analog Stick** (movement and steering) **without altering or scrambling the face buttons (A/B/X/Y), shoulder buttons, or Start/Select**.

**I tested on RG35XX Plus with MuOS firmware**.

Best Experience on MuOS
---

## Supported Devices
* **Anbernic RG35XX Plus**
* **Anbernic RG35XX (2024)**
* **Anbernic RG35XXSP**
* **Anbernic RG28XX**
* **Anbernic RG34XX**

---

## The Problem with Existing Fixes

* **The SDL2 Mapping Limitation:** The GTA SA Linux wrapper directly polls Linux kernel input events (`/dev/input/eventX`) and completely ignores `SDL_GAMECONTROLLERCONFIG` environment variables in the launch script. Remapping at the script level does not work.
* **The Profile 8 Flaw:** Previous community patches forced the internal controller profile to an alternative layout (Profile 8). While this enabled D-Pad movement, it loaded a foreign button table that reversed and scrambled **A, B, X, Y, L2, R2, Start, and Select**!

---

## What This Fix Does

* **Native RG35XX Profile Active:** Keeps the native Anbernic RG35XX profile active with its genuine button mapping table.
* **Internal Decoupling:** Removes the internal profile-gating checks in the evdev D-Pad handler so:
  - D-Pad (Up, Down, Left, Right) writes directly into the game's Left Analog memory registers (`32767` values).
  - D-Pad Release instantly centers the Left Analog Stick (`0`).
  - All face buttons, shoulders, Start, and Select retain their perfect native layout.

---

## Controller Layout on Anbernic Devices

### On Foot (Walking / Running / Combat)
| Button | Action | In-Game Behavior |
| :--- | :--- | :--- |
| **D-Pad** | Left Analog Stick | Walk & Run in all directions |
| **B Button** (Bottom) | Sprint / Run Fast | Hold while moving with D-Pad to sprint |
| **Y Button** (Left) | Jump / Climb | Jump over obstacles / climb walls |
| **A Button** (Right) | Attack / Shoot | Punch, kick, or fire weapon |
| **X Button** (Top) | Enter / Exit Vehicle | Get into cars, bikes, and planes |
| **L1** (Top Left Shoulder) | Horn / Look Behind | Look backwards |
| **R1** (Top Right Shoulder) | Lock-On Target | Auto-aim weapon at nearest enemy |
| **L2 / R2** (Back Shoulders) | Cycle Weapons | Switch weapons left / right |
| **Select** | Camera Mode | Toggle camera views |
| **Start** | Pause Menu | Open game map and pause menu |

### In Vehicles (Driving / Flying)
| Button | Action | In-Game Behavior |
| :--- | :--- | :--- |
| **D-Pad Left / Right** | Steering | Steer vehicle left and right |
| **B Button** | Accelerate / Drive | Drive forward / accelerate |
| **Y Button** | Reverse / Brake | Reverse or brake vehicle |
| **A Button** | Handbrake | Sharp turns and drifting |
| **X Button** | Exit Vehicle | Jump out of vehicle |
| **L1** | Horn / Siren | Honk horn / toggle police siren |
| **R1** | Drive-By / Shoot | Fire weapon while driving |

---

## OS Compatibility & Video Driver Settings

Different custom firmwares use different display pipelines. Forcing `kmsdrm` directly on devices running muOS or KNULLI causes an immediate crash (`[setup] SDL_Init failed: kmsdrm not available`).

The included [`Grand Theft Auto San Andreas.sh`](Grand%20Theft%20Auto%20San%20Andreas.sh) script features **automatic video driver detection**:

| Operating System | Display Pipeline | Script Configuration |
| :--- | :--- | :--- |
| **muOS** (RG35XX Plus/SP/28XX/34XX/2024) | Auto-Probe | Unsets `SDL_VIDEODRIVER` so SDL2 auto-selects the working display |
| **KNULLI / Batocera** | Wayland | `export SDL_VIDEODRIVER=wayland` |
| **ROCKNIX** (KNULLI-based) | Wayland / Direct | `export SDL_VIDEODRIVER=wayland` |
| **ArkOS / AmberELEC** (R36S, RG351, RG353) | KMSDRM | `export SDL_VIDEODRIVER=kmsdrm` |
| **EmuELEC** | Framebuffer | Unsets `SDL_VIDEODRIVER`, sets `SDL_FBDEV=/dev/fb0` |

---

## Installation Guide

1. Download this repository (or from Releases).
2. Copy the following files to your SD card:
   - [`gtasa/gtasa`](gtasa/gtasa) -> `/mnt/union/ports/gtasa/gtasa` (or `/roms/ports/gtasa/gtasa`)
   - [`Grand Theft Auto San Andreas.sh`](Grand%20Theft%20Auto%20San%20Andreas.sh) -> `/roms/ports/` (or ports folder)
3. Ensure your original GTA SA v2.10 (ARMv7) game data files are present in your `gtasa` folder:
   - `GTA SA v2.10.apk`
   - `main.8.com.rockstargames.gtasa.obb`
   - `patch.8.com.rockstargames.gtasa.obb`
4. Make sure `gtasa` is executable (`chmod +x gtasa`).
5. Launch the game from PortMaster and enjoy!

---

## Credits & Disclaimer

* GTA: San Andreas is a registered trademark of Rockstar Games.
* This repository does not contain copyrighted game assets (APK, OBB, textures, or audio).
* Reverse-engineered and patched by **Erfan2255**.
