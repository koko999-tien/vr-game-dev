# VR Game Development Tool Catalog & Runtime Inventory

Comprehensive inventory of all installed engines, runtimes, compilers, graphics APIs, development tools, and SDKs configured for the Virtual Reality (VR) development environment at `D:\vr_game_dev`.

**Host Profile**: Windows 11 Home 64-bit | AMD Ryzen 5 6600H | NVIDIA GeForce RTX 2050 (DirectX 12 Ultimate FL 12_2, Vulkan 1.3) | Kingston NVMe SSD.

---

## 1. Master Tool & Runtime Inventory Table

| Tool / Runtime | Version | Installation Path | PATH Scope | Verification Command | Expected Output | Purpose & Domain |
|---|---|---|---|---|---|---|
| **Godot Engine** | `4.3-stable` (official `77dcf97d8`) | `D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe` | User & Machine (`D:\vr_game_dev\bin`, `D:\bin`) | `godot --version` | `4.3.stable.official.77dcf97d8` | Core 3D VR Engine, OpenXR 1.0/1.1 runtime integration, Forward+ renderer |
| **Node.js** | `v24.20.0` | `C:\Program Files\nodejs\node.exe` | Machine (`C:\Program Files\nodejs\`) | `node -v` | `v24.20.0` | High-performance JavaScript/TypeScript runtime for WebXR tooling |
| **npm** | `11.19.0` | `C:\Program Files\nodejs\npm.cmd` | Machine (`C:\Program Files\nodejs\`) | `npm -v` | `11.19.0` | Node package manager for WebXR build orchestration |
| **Three.js** | `^0.170.0` (Installed `0.170.0`) | `D:\vr_game_dev\projects\webxr_hello_world\node_modules\three` | Project local | `node -e "console.log(require('three/package.json').version)"` | `0.170.0` | 3D WebGL2/WebXR scene graph, VRButton & controller models |
| **Vite** | `^5.4.11` (Installed `5.4.21`) | `D:\vr_game_dev\projects\webxr_hello_world\node_modules\vite` | Project local | `npx vite --version` | `vite/5.4.21 win32-x64 node-v24.20.0` | Fast dev server, instant HMR, Rollup production bundler |
| **Basic SSL Plugin** | `^1.2.0` (Installed `1.2.0`) | `...\node_modules\@vitejs\plugin-basic-ssl` | Project local | Package manifest | `1.2.0` | Self-signed HTTPS generator for standalone headset testing |
| **Git** | `2.56.0.windows.4` | `C:\Program Files\Git\cmd\git.exe` | Machine (`C:\Program Files\Git\cmd\`) | `git --version` | `git version 2.56.0.windows.4` | Distributed version control, Git LFS asset management |
| **Python** | `3.14.7` | `C:\Python314\python.exe` | Machine (`C:\Python314\`) | `python --version` | `Python 3.14.7` | Build scripts, asset processing pipelines, fallback HTTP server |
| **Visual Studio Code** | `1.107.0` (x64) | `C:\Program Files\Microsoft VS Code\bin\code.cmd` | Machine (`C:\Program Files\Microsoft VS Code\bin\`) | `code --version` | `1.107.0` | IDE for GDScript, WebXR/JS, shaders, and markdown docs |
| **DirectX 12 Ultimate** | Feature Level `12_2` | `C:\Windows\System32\d3d12.dll` | System OS | DxDiag / WMI query | Feature Levels `12_2, 12_1, 12_0` | Hardware ray tracing (DXR 1.1), Variable Rate Shading (VRS), Mesh Shaders |
| **Vulkan API** | `1.3` (Loader `1.3.287+`) | `C:\Windows\System32\vulkan-1.dll` | System OS | `Test-Path C:\Windows\System32\vulkan-1.dll` | `True` | Low-overhead stereoscopic frame rendering for Godot Forward+ |
| **Google Chrome** | `156.0.8078.81` | `C:\Program Files\Google\Chrome\Application\chrome.exe` | Application | `(Get-Item '...chrome.exe').VersionInfo.FileVersion` | `156.0.8078.81` | Primary browser with WebXR Device API and Emulator support |
| **Microsoft Edge** | `157.0.4341.42` | `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` | Application | `(Get-Item '...msedge.exe').VersionInfo.FileVersion` | `157.0.4341.42` | Chromium-based browser with WebXR Device API support |
| **OpenXR Loader** | Khronos OpenXR 1.0/1.1 | Embedded in Godot Engine (`modules/openxr`) | Engine | `XRServer.find_interface("OpenXR")` | Interface present | Cross-vendor VR runtime interface (Oculus, SteamVR, VDXR) |

---

## 2. Detailed Tool Profiles & Capabilities

### 2.1 Godot Engine 4 (OpenXR Edition)
* **Binary Distribution**: Official portable 64-bit release (`Godot_v4.3-stable_win64.exe.zip`).
* **Binaries on Disk**:
  * Console CLI: `D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe` (198 KB) — Attached to console `stdout` and `stderr`.
  * GUI Executable: `D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64.exe` (132.9 MB) — Windows GUI application.
* **CLI Wrapper Scripts**:
  * `D:\vr_game_dev\bin\godot.cmd` and `D:\bin\godot.cmd`:
    ```cmd
    @echo off
    "D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe" %*
    ```
* **Key Capabilities**:
  * **OpenXR Integration**: First-class support for `XROrigin3D`, `XRCamera3D`, and `XRController3D` with OpenXR action maps.
  * **Vulkan Renderers**: Forward+ (clustered forward rendering for high-fidelity PC VR), Mobile (tiled rendering), and Compatibility (OpenGL ES 3.0 / WebGL).
  * **Headless Automation**: Command-line switches `--headless`, `--editor`, `--quit`, and `-s <script>` for fully automated CI/CD validation.
* **Verification**:
  ```powershell
  godot --version
  # Output: 4.3.stable.official.77dcf97d8
  ```

### 2.2 Node.js & npm (WebXR Runtime Stack)
* **Binaries**:
  * `node.exe`: `C:\Program Files\nodejs\node.exe` (Version `v24.20.0`)
  * `npm.cmd`: `C:\Program Files\nodejs\npm.cmd` (Version `11.19.0`)
* **Key Capabilities**:
  * High-performance V8 engine with full ECMAScript Module (ESM) support.
  * Native execution of Vite development servers and bundling toolchains.
  * Fast package dependency installation and lockfile synchronization (`package-lock.json`).
* **Verification**:
  ```powershell
  node -v   # Output: v24.20.0
  npm -v    # Output: 11.19.0
  ```

### 2.3 Three.js, Vite & Basic SSL (Spatial Web Stack)
* **Project Directory**: `D:\vr_game_dev\projects\webxr_hello_world\`
* **Packages**:
  * `three` (`0.170.0`): 3D scenegraph, WebGL2 rendering pipeline, `VRButton` immersive session creator, and `XRControllerModelFactory` for hardware-accurate VR controller models.
  * `vite` (`5.4.21`): Lightning-fast ES module dev server with sub-second HMR updates, preserving WebXR immersive session state during code modifications.
  * `@vitejs/plugin-basic-ssl` (`1.2.0`): Automatically generates local HTTPS certificates fulfilling the W3C WebXR **Secure Context** mandate (`isSecureContext === true`).
* **Verification**:
  ```powershell
  Push-Location D:\vr_game_dev\projects\webxr_hello_world
  npm run build
  # Output: ✓ built in ~2.2s -> dist/index.html generated cleanly
  Pop-Location
  ```

### 2.4 Graphics Hardware & Low-Level APIs
* **Discrete GPU**: NVIDIA GeForce RTX 2050 Laptop GPU (GA107 Ampere architecture, 4 GB GDDR6).
  * Driver Version: `31.0.15.5176` (NVIDIA 551.76)
  * Feature Levels: **DirectX 12 Ultimate (Feature Level 12_2)**
  * Hardware Features: DXR Tier 1.1 (Hardware Ray Tracing), Mesh Shaders Tier 1, Variable Rate Shading (VRS Tier 2), Sampler Feedback Tier 0.9.
* **Vulkan API**:
  * System Loader: `C:\Windows\System32\vulkan-1.dll`
  * API Conformance: Vulkan 1.3
  * Extensions: VK_KHR_surface, VK_KHR_win32_surface, VK_KHR_ray_tracing_pipeline, VK_KHR_timeline_semaphore, VK_EXT_fragment_density_map.
* **Integrated GPU**: AMD Radeon(TM) Graphics (Radeon 660M, Vulkan 1.3, DirectX 12 FL 12_1).
* **Verification**:
  ```powershell
  Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion
  Test-Path "C:\Windows\System32\vulkan-1.dll" # Returns True
  ```

### 2.5 Python & Git Tooling
* **Git**: `C:\Program Files\Git\cmd\git.exe` (`git version 2.56.0.windows.4`)
  * Supports Git Large File Storage (LFS) for tracking heavy binary assets (`.glb`, `.gltf`, `.wav`, `.hdr`).
* **Python**: `C:\Python314\python.exe` (`Python 3.14.7`)
  * Supports automated pipeline scripting, asset processing, and acts as a fallback zero-dependency web server (`python -m http.server 5173`).
* **Verification**:
  ```powershell
  git --version     # git version 2.56.0.windows.4
  python --version  # Python 3.14.7
  ```

### 2.6 Microsoft Visual Studio Code
* **Binary Path**: `C:\Program Files\Microsoft VS Code\bin\code.cmd` (Version `1.107.0`, 64-bit)
* **Integration Points**:
  * GDScript Language Server Protocol (LSP) connection to Godot Editor on port 6005.
  * Three.js ES6 module autocompletion and JSDoc type checking.
  * Integrated PowerShell terminal for running health checks and build scripts.
* **Verification**:
  ```powershell
  code --version    # 1.107.0
  ```

---

## 3. Environment Variables & PATH Configuration

The system registers executables across three persistent and runtime scopes to ensure that development commands work out-of-the-box from any terminal:

### 3.1 Scope Distribution

| Variable | Scope | Configured Path(s) | Mechanism |
|---|---|---|---|
| `PATH` | **User** (`HKCU:\Environment\Path`) | `D:\vr_game_dev\bin;` | Persistent registry via `[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)` as `REG_EXPAND_SZ` |
| `PATH` | **Machine** (`HKLM:\SYSTEM\...\Path`) | `D:\bin;`, `C:\Program Files\nodejs\;`, `C:\Program Files\Git\cmd\;`, `C:\Python314\;`, `C:\Program Files\Microsoft VS Code\bin` | Machine-wide system registration |
| `PATH` | **Current Process** (`$env:PATH`) | Injected dynamically by `setup_environment.ps1` | Session synchronization |

### 3.2 Executable Resolution Matrix

When commands are issued from PowerShell or CMD, they resolve as follows:

| Command | Resolved Executable | Underlying Target |
|---|---|---|
| `godot` | `D:\vr_game_dev\bin\godot.cmd` or `D:\bin\godot.cmd` | `D:\vr_game_dev\tools\godot\Godot_v4.3-stable_win64_console.exe` |
| `node` | `C:\Program Files\nodejs\node.exe` | Native 64-bit Node.js binary |
| `npm` | `C:\Program Files\nodejs\npm.cmd` | npm CLI batch runner |
| `git` | `C:\Program Files\Git\cmd\git.exe` | Git for Windows CLI |
| `python`| `C:\Python314\python.exe` | Python 3.14 interpreter |
| `code` | `C:\Program Files\Microsoft VS Code\bin\code.cmd` | VS Code launcher |

---

## 4. OpenXR Runtime & Ecosystem Mapping

Godot 4 and PC VR headsets communicate through the Khronos OpenXR loader. The registry defines which VR runtime acts as the active driver:

| Headset / Software | OpenXR Runtime Provider | Manifest Location |
|---|---|---|
| **Meta Quest 2 / 3 / Pro** (Link / Air Link) | Oculus XR Runtime | `C:\Program Files\Oculus\Support\oculus-runtime\oculus_openxr_64.json` |
| **SteamVR** (Index, HTC Vive, Quest via Steam Link) | Valve SteamVR OpenXR | `C:\Program Files (x86)\Steam\steamapps\common\SteamVR\steamxr_win64.json` |
| **Virtual Desktop** | VDXR (Virtual Desktop XR) | `%ProgramFiles%\Virtual Desktop Streamer\OpenXR\VirtualDesktop.json` |
| **Windows Mixed Reality** | WMR OpenXR Runtime | `C:\WINDOWS\system32\MixedRealityRuntime.json` |

*Note*: If no active OpenXR runtime is configured in registry (`HKLM:\SOFTWARE\Khronos\OpenXR\1`), Godot automatically activates its built-in **Desktop Free-Look Mode**, ensuring that development, automated CI tests, and scene inspection proceed without interruption.

---

## 5. Automated Health-Check Mapping

Every tool and subsystem documented in this catalog is validated by `D:\vr_game_dev\scripts\check_environment.ps1`:

| Health Check Name | Subsystem Probed | Pass Criteria | Severity on Failure |
|---|---|---|---|
| `OS Architecture` | Windows OS | Must be 64-bit Windows | FATAL (Exit 1) |
| `Discrete GPU` | NVIDIA RTX 2050 | Dedicated GPU detected with active driver | WARNING (Fallback to iGPU) |
| `Vulkan Loader` | `vulkan-1.dll` | DLL exists in `C:\Windows\System32\` | FATAL (Exit 1) |
| `Godot 4 CLI` | `godot` command | Resolves on PATH, version string matches `^4\.` | FATAL (Exit 1) |
| `Node.js Runtime` | `node` command | Resolves on PATH, version >= 18.x | FATAL (Exit 1) |
| `npm Package Manager` | `npm` command | Resolves on PATH | FATAL (Exit 1) |
| `Git & Python` | `git`, `python` | Resolves on PATH | WARNING (Non-blocking) |
| `OpenXR Active Runtime`| Windows Registry | ActiveRuntime key present in registry | WARNING (Non-fatal, desktop fallback) |
| `WebXR Sample Build` | Vite compiler | `npm run build` exits with code 0, `dist/index.html` exists | FATAL (Exit 1) |
| `Godot VR Validation` | Headless Godot runner | `godot -s res://test_runner.gd` exits with code 0 | FATAL (Exit 1) |

---

## 6. Verification Method

To independently reproduce and verify all observations, specifications, and commands formulated in this report, execute the following script from PowerShell:

```powershell
# 1. Verify Godot Engine version & wrapper resolution
godot --version
where.exe godot

# 2. Verify Node.js, npm, Three.js, and Vite
node -v
npm -v
Push-Location D:\vr_game_dev\projects\webxr_hello_world
npm run build
Pop-Location

# 3. Verify Godot Headless CI test runner
godot --headless --path D:\vr_game_dev\projects\vr_hello_world -s res://test_runner.gd

# 4. Verify system tools (Git, Python, VS Code, Vulkan DLL)
git --version
python --version
code --version
Test-Path C:\Windows\System32\vulkan-1.dll

# 5. Verify User PATH persistence
[Environment]::GetEnvironmentVariable('Path', 'User')
```

**Invalidation Conditions**:
- If `godot --version` fails or returns a version other than `4.3.stable...`.
- If `npm run build` in `projects/webxr_hello_world` fails to produce `dist/index.html`.
- If `godot -s res://test_runner.gd` fails any assertion or returns a non-zero exit code.
- If documentation omits any required section specified in `ORIGINAL_REQUEST.md` or `PROJECT.md`.
