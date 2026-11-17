# VR Game Development Environment (Windows 11)

[![Godot Engine](https://img.shields.io/badge/Godot-4.3--stable-blue.svg?logo=godotengine)](https://godotengine.org/)
[![Node.js](https://img.shields.io/badge/Node.js-v24.20.0-green.svg?logo=node.js)](https://nodejs.org/)
[![Three.js](https://img.shields.io/badge/Three.js-r170-black.svg?logo=threedotjs)](https://threejs.org/)
[![Vite](https://img.shields.io/badge/Vite-5.4.21-646CFF.svg?logo=vite)](https://vite.dev/)
[![Graphics](https://img.shields.io/badge/DirectX%2012%20Ultimate-FL%2012__2-76B900.svg)](https://developer.nvidia.com/)
[![Vulkan](https://img.shields.io/badge/Vulkan-1.3-red.svg?logo=vulkan)](https://www.vulkan.org/)

A turnkey, fully validated dual-track Virtual Reality (VR) development environment deployed on Windows 11 at `D:\vr_game_dev`. Designed for native standalone/PC VR game creation via **Godot Engine 4 (OpenXR)** and rapid cross-platform spatial prototyping via **WebXR (Three.js + Vite)**.

---

## Table of Contents

- [Overview & Architecture](#overview--architecture)
- [Directory Layout](#directory-layout)
- [Prerequisites & System Profile](#prerequisites--system-profile)
- [Quickstart Guide](#quickstart-guide)
- [Godot 4 VR Development Guide](#godot-4-vr-development-guide)
  - [Opening in Godot Editor](#1-opening-in-godot-editor)
  - [Running with OpenXR Headset](#2-running-with-openxr-headset)
  - [Desktop Free-Look Fallback Mode](#3-desktop-free-look-fallback-mode)
  - [Headless Automated CI Testing](#4-headless-automated-ci-testing)
  - [Scene & Script Architecture](#5-scene--script-architecture)
- [WebXR Rapid Prototyping Guide](#webxr-rapid-prototyping-guide)
  - [Local Development Server](#1-local-development-server)
  - [Desktop Testing with WebXR API Emulator](#2-desktop-testing-with-webxr-api-emulator)
  - [Standalone Headset Testing via LAN HTTPS](#3-standalone-headset-testing-via-lan-https)
  - [Zero-Latency USB ADB Port Forwarding](#4-zero-latency-usb-adb-port-forwarding)
  - [Production Bundling](#5-production-bundling)
- [Automation & Health-Check Scripts](#automation--health-check-scripts)
  - [check_environment.ps1](#check_environmentps1)
  - [setup_environment.ps1](#setup_environmentps1)
- [Troubleshooting & FAQ](#troubleshooting--faq)

---

## Overview & Architecture

This repository establishes a complete workstation setup for immersive VR development without requiring vendor lock-in or mandatory tethered hardware during initial development cycles. It leverages a **Dual-Track Architecture**:

```
+-----------------------------------------------------------------------------------+
|                        D:\vr_game_dev Workstation Root                            |
+-----------------------------------------------------------------------------------+
        |                                                   |
        v                                                   v
+-----------------------------------+       +---------------------------------------+
|   TRACK A: Native VR (Godot 4)   |       |    TRACK B: WebXR (Three.js + Vite)   |
+-----------------------------------+       +---------------------------------------+
| * Godot Engine 4.3 Stable         |       | * Node.js 24 + npm 11                 |
| * OpenXR 1.0/1.1 Standard         |       | * Three.js r170 (WebGL2/WebXR)        |
| * Forward+ Vulkan 1.3 Renderer    |       | * Vite 5.4 HMR Dev Server             |
| * 6DoF Controllers + Tracking     |       | * @vitejs/plugin-basic-ssl (HTTPS)   |
| * Automatic Desktop Fallback      |       | * Chrome / Edge WebXR Emulator        |
| * Headless CI Test Runner         |       | * Standalone Quest / Pico Support     |
+-----------------------------------+       +---------------------------------------+
        |                                                   |
        +-------------------------+-------------------------+
                                  |
                                  v
+-----------------------------------------------------------------------------------+
|                     AUTOMATION & VERIFICATION LAYER (PowerShell)                 |
|  * scripts/check_environment.ps1 : Multi-tier health diagnostic & exit code 0    |
|  * scripts/setup_environment.ps1 : Idempotent setup, PATH registration & restore  |
|  * TOOL_CATALOG.md               : Detailed runtime & hardware inventory         |
+-----------------------------------------------------------------------------------+
```

---

## Directory Layout

```
D:\vr_game_dev\
├── bin\                                # Global executable wrappers
│   ├── godot.cmd                       # CMD CLI launcher (pipes stdout/stderr)
│   ├── godot.ps1                       # PowerShell launcher
│   └── godot                           # Bash/sh launcher
├── projects\                           # VR project implementations
│   ├── vr_hello_world\                 # Track A: Godot 4 OpenXR Sample Project
│   │   ├── project.godot               # OpenXR & Forward+ engine config
│   │   ├── main.tscn                   # Main 3D scene (XROrigin3D + DesktopCam)
│   │   ├── main.gd                     # Dual-mode VR / Desktop fallback controller
│   │   ├── test_runner.gd              # Headless CI scene tree test runner
│   │   └── openxr_action_map.tres      # OpenXR input action definitions
│   └── webxr_hello_world\              # Track B: WebXR Three.js Sample Project
│       ├── package.json                # Dependencies: three, vite, basic-ssl
│       ├── vite.config.js              # Vite config supporting HTTP and LAN HTTPS
│       ├── index.html                  # HTML5 entry with VR launch button
│       ├── src\
│       │   ├── main.js                 # Three.js 6DoF VR scene & ray interaction
│       │   └── style.css               # HUD styling & responsiveness
│       └── dist\                       # Production bundle (generated via npm run build)
├── scripts\                            # Automation & Maintenance tooling
│   ├── check_environment.ps1           # Comprehensive health-check script (exit code 0)
│   └── setup_environment.ps1           # Environment provisioning & recovery script
├── tools\                              # Engine binaries & SDK distributions
│   └── godot\
│       ├── Godot_v4.3-stable_win64.exe         # GUI Subsystem executable
│       └── Godot_v4.3-stable_win64_console.exe # Console Subsystem CLI executable
├── README.md                           # Master project documentation (this file)
└── TOOL_CATALOG.md                     # Comprehensive tool inventory & specifications
```

---

## Prerequisites & System Profile

The environment is configured and verified for the following workstation hardware profile:

| Component | Specification |
|---|---|
| **Operating System** | Windows 11 Home / Pro 64-bit (Build 22631+) |
| **CPU** | AMD Ryzen 5 6600H (6 Cores / 12 Threads, 3.3 - 4.5 GHz) |
| **System Memory** | 16 GB DDR5 |
| **Discrete GPU** | NVIDIA GeForce RTX 2050 Laptop GPU (4 GB GDDR6) |
| **Graphics Driver** | NVIDIA GeForce Game Ready Driver 551.76+ (DirectX 12 Ultimate FL 12_2, Vulkan 1.3) |
| **Storage** | Kingston NVMe PCIe SSD on `D:\` with >20 GB free space |
| **Terminal** | Windows PowerShell 5.1 / PowerShell 7+ |

---

## Quickstart Guide

Get up and running in less than two minutes:

### Step 1: Clone or Open Directory
Open PowerShell and navigate to the project root:
```powershell
Set-Location D:\vr_game_dev
```

### Step 2: Verify Health Check
Execute the health check to verify tool availability and build pipelines:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check_environment.ps1
```
*Expected Output:* Green checkmarks across OS, GPU, Vulkan, Godot CLI, Node.js, WebXR Build, and Godot Test Runner, concluding with `EXIT CODE 0`.

### Step 3: Run the WebXR Prototype
```powershell
Set-Location D:\vr_game_dev\projects\webxr_hello_world
npm run dev
```
Open `http://localhost:5173` in Google Chrome or Microsoft Edge.

### Step 4: Run the Godot 4 VR Project
```powershell
godot --path D:\vr_game_dev\projects\vr_hello_world
```
The application will launch. If no physical VR headset is connected, it automatically engages the **Desktop Free-Look Fallback Mode**.

---

## Godot 4 VR Development Guide

The Godot project is located at `D:\vr_game_dev\projects\vr_hello_world\`. It is built with Godot 4.3 Stable using OpenXR and Forward+ Vulkan clustered rendering.

### 1. Opening in Godot Editor
To launch the Godot graphical editor directly into the VR project:
```powershell
godot --editor --path D:\vr_game_dev\projects\vr_hello_world
```
Alternatively, launch Godot GUI and select `D:\vr_game_dev\projects\vr_hello_world\project.godot`:
```powershell
& "D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64.exe" --editor --path "D:\vr_game_dev\projects\vr_hello_world"
```

### 2. Running with OpenXR Headset
To run the scene with an active PC VR headset:
1. Connect your headset to the PC:
   - **Meta Quest 2 / 3 / Pro**: Via Link Cable (USB 3.0), Air Link, Virtual Desktop, or Steam Link. Ensure Oculus/Meta Quest Link software or SteamVR is running.
   - **Valve Index / HTC Vive**: Ensure SteamVR is running and room setup is calibrated.
2. In the Godot Editor, press **F5** (or run `godot --path D:\vr_game_dev\projects\vr_hello_world` from terminal).
3. The engine initializes `XRServer.find_interface("OpenXR")`, sets viewport `use_xr = true`, synchronizes refresh rate (72/90/120 Hz), and starts stereoscopic rendering. Put on the headset to view and interact with the scene using your Touch controllers.

### 3. Desktop Free-Look Fallback Mode
When developing without an active VR headset plugged in, the scene automatically detects that OpenXR runtime initialization returned false and enables the **Desktop Free-Look Camera**.

**Desktop Controls:**
- **Left Mouse Click**: Capture mouse cursor to look around.
- **Mouse Movement**: Rotate camera pitch (look up/down) and yaw (turn left/right).
- **Escape (ESC)**: Release mouse cursor back to standard desktop mode.
- **W / S**: Move camera forward / backward.
- **A / D**: Strafe camera left / right.
- **Space / E**: Ascend vertically.
- **Shift / Q**: Descend vertically.
- **Left Click on ColoredCube**: Interact with the 3D rotating cube to cycle through its color palette.

### 4. Headless Automated CI Testing
You can run automated scene validation headlessly without a GPU display or physical headset:
```powershell
godot --headless --path D:\vr_game_dev\projects\vr_hello_world -s res://test_runner.gd
```
The test runner executes six deterministic verification assertions:
1. `PASS [1/6]`: Scene resource loaded (`res://main.tscn`).
2. `PASS [2/6]`: Scene instantiated successfully as `Node3D`.
3. `PASS [3/6]`: `XROrigin3D` node validated.
4. `PASS [4/6]`: `XRCamera3D` node validated under origin.
5. `PASS [5a/6]`: Left `XRController3D` validated with tracker `left_hand`.
6. `PASS [5b/6]`: Right `XRController3D` validated with tracker `right_hand`.
7. `PASS [6/6]`: `XRServer` OpenXR interface confirmed available.
Exits with **Code 0** on success.

### 5. Scene & Script Architecture
- `project.godot`:
  - `xr/openxr/enabled=true`: Forces Godot to attempt OpenXR subsystem bootstrap.
  - `xr/openxr/startup_alert=false`: Suppresses OS modal dialogs when headset is absent, allowing graceful code fallback.
  - `rendering/renderer/rendering_method="forward_plus"`: Leverages Vulkan clustered Forward+ pipeline.
- `main.gd`:
  - Handles runtime interface detection:
    ```gdscript
    xr_interface = XRServer.find_interface("OpenXR")
    if xr_interface and xr_interface.initialize():
        _setup_vr()
    else:
        _setup_desktop_fallback()
    ```
  - Subscribes to `button_pressed` signals on Left and Right `XRController3D` nodes for trigger/grip inputs.
  - Implements physics-based ray interaction and collision feedback on the `ColoredCube`.

---

## WebXR Rapid Prototyping Guide

The WebXR project is located at `D:\vr_game_dev\projects\webxr_hello_world\`. Built on Three.js (r170) and Vite, it enables instant spatial prototyping in standard modern browsers.

### 1. Local Development Server
Start the development server with Hot Module Replacement (HMR):
```powershell
Set-Location D:\vr_game_dev\projects\webxr_hello_world
npm run dev
```
Server starts on `http://localhost:5173/` and binds to `0.0.0.0` for local network access.

### 2. Desktop Testing with WebXR API Emulator
You do not need a physical headset to test full 6DoF VR motion and controller interactions on desktop:
1. Install the **WebXR API Emulator** extension in Google Chrome or Microsoft Edge (available from the Chrome Web Store).
2. Navigate to `http://localhost:5173`.
3. Open DevTools (`F12` or `Ctrl + Shift + I`) and click the **WebXR** tab.
4. Choose a simulated device profile (e.g. **Oculus Quest 2** or **Meta Quest Pro**).
5. Click **ENTER VR** on the webpage.
6. The emulator renders stereoscopic stereo eye views. Use the WebXR tab controls to rotate/translate the headset or trigger controller laser pointers.

### 3. Standalone Headset Testing via LAN HTTPS
The W3C WebXR specification strictly enforces a **Secure Context** (`isSecureContext === true`). Browsers block `navigator.xr` on non-localhost HTTP connections. To test wirelessly from a standalone Meta Quest 2/3 or Pico 4:

1. Launch Vite in HTTPS mode using the preconfigured basic-ssl plugin:
   ```powershell
   npm run dev:https
   ```
2. Find your workstation's LAN IP address:
   ```powershell
   Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*", "Ethernet*" | Select-Object IPAddress
   ```
3. In the Meta Quest Browser, enter: `https://<YOUR-PC-IP>:5173` (e.g. `https://192.168.1.15:5173`).
4. On the SSL certificate warning page ("Your connection is not private"), click **Advanced** -> **Proceed to `<YOUR-PC-IP>` (unsafe)**.
5. Click **ENTER VR**. You are now running immersive 6DoF VR over local Wi-Fi with live HMR updates as you edit your code!

### 4. Zero-Latency USB ADB Port Forwarding
If you prefer not to accept SSL warnings or want rock-solid USB tethering for Meta Quest:
1. Connect Quest to PC via USB-C cable and enable USB debugging.
2. In PowerShell, forward the Vite port:
   ```powershell
   adb reverse tcp:5173 tcp:5173
   ```
3. Run `npm run dev` (standard HTTP).
4. In the Quest Browser, open `http://localhost:5173`. Chromium treats `localhost` as a Secure Context, completely bypassing all SSL requirements!

### 5. Production Bundling
Compile the application into optimized, static production assets:
```powershell
npm run build
```
Build output is saved to `D:\vr_game_dev\projects\webxr_hello_world\dist\`. You can preview the production bundle locally:
```powershell
npm run preview
```
The `dist\` folder can be deployed directly to GitHub Pages, Cloudflare Pages, Vercel, Netlify, or any static HTTPS host.

---

## Automation & Health-Check Scripts

Automated administration scripts are located in `D:\vr_game_dev\scripts\`.

### check_environment.ps1
Performs an automated health check covering hardware, software runtimes, environment PATH, and test builds.

**Execution:**
```powershell
powershell -ExecutionPolicy Bypass -File D:\vr_game_dev\scripts\check_environment.ps1
```

**Parameters:**
- `-Json`: Outputs machine-readable JSON structure ideal for CI/CD test reporting.
  ```powershell
  powershell -ExecutionPolicy Bypass -File D:\vr_game_dev\scripts\check_environment.ps1 -Json
  ```
- `-SkipBuild`: Skips Vite production build and Godot headless test for instant smoke verification (< 2 seconds).
  ```powershell
  powershell -ExecutionPolicy Bypass -File D:\vr_game_dev\scripts\check_environment.ps1 -SkipBuild
  ```

**Exit Codes:**
- `0`: All required tools, drivers, and project builds are healthy.
- `1`: One or more critical dependencies failed (missing Godot CLI, missing Node/npm, broken build).

### setup_environment.ps1
Provides 100% reproducible provisioning, installation, and environment recovery.

**Execution:**
```powershell
powershell -ExecutionPolicy Bypass -File D:\vr_game_dev\scripts\setup_environment.ps1
```

**Parameters:**
- `-Force`: Forces re-download and re-extraction of Godot portable binaries even if already present.
  ```powershell
  powershell -ExecutionPolicy Bypass -File D:\vr_game_dev\scripts\setup_environment.ps1 -Force
  ```

**Workflow Automated by Script:**
1. Validates directory structure (`tools\`, `bin\`, `projects\`, `scripts\`).
2. Downloads Godot 4.3 Stable zip archive from official GitHub releases to `tools\downloads\` if missing.
3. Extracts and links console executable wrapper `godot.cmd` to `D:\vr_game_dev\bin\` and `D:\bin\`.
4. Persists `D:\vr_game_dev\bin` into User PATH (`HKCU:\Environment\Path`).
5. Installs npm dependencies in `projects\webxr_hello_world\`.
6. Pre-populates Godot project import cache via `godot --headless --editor --quit`.
7. Automatically calls `check_environment.ps1` to confirm 100% operational readiness.

---

## Troubleshooting & FAQ

### Q1: When running Godot tests, I see "OpenXR: Failed to find default runtime". Is this an error?
**Answer**: No. This is an informational warning from the OpenXR loader stating that no physical PC VR runtime (SteamVR or Oculus Link) is currently registered as the active OpenXR system runtime in Windows registry. Godot gracefully catches this, enables Desktop Free-Look mode, and continues running. Automated CLI tests succeed with **Exit Code 0**.

To connect a physical headset:
- For Meta Quest Link: Open Meta Quest Link app on PC -> Settings -> General -> Set Meta Quest Link as active OpenXR runtime.
- For SteamVR: Open SteamVR -> Settings -> OpenXR -> Set SteamVR as active OpenXR runtime.

### Q2: Why does the WebXR sample say "VR NOT SUPPORTED" in my browser?
**Answer**: WebXR requires a Secure Context (`window.isSecureContext === true`).
- On desktop: Access via `http://localhost:5173` (treated as secure) and install the WebXR API Emulator extension.
- On external headset over Wi-Fi: You must run `npm run dev:https` and open `https://<PC-IP>:5173`, or use `adb reverse tcp:5173 tcp:5173` and open `http://localhost:5173`.

### Q3: PowerShell displays "running scripts is disabled on this system".
**Answer**: Windows restricts unsigned script execution by default. Run the scripts using `-ExecutionPolicy Bypass`:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check_environment.ps1
```
Alternatively, adjust execution policy for your current user account:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Q4: Port 5173 is already in use by another application.
**Answer**: You can pass custom ports to Vite:
```powershell
npm run dev -- --port 5180
# Or for HTTPS:
npm run dev:https -- --port 5180
```

---

## Licensing & Credits
- **Godot Engine**: MIT License. (C) 2014-present Juan Linietsky, Ariel Manzur, and Godot Engine contributors.
- **Three.js**: MIT License. (C) 2010-present Three.js Authors.
- **Vite**: MIT License. (C) 2019-present Evan You & Vite contributors.
