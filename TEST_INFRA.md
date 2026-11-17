# VR Game Development Environment — Test Infrastructure Specification
**Document**: `TEST_INFRA.md`  
**Location**: `D:\vr_game_dev\TEST_INFRA.md`  
**Author**: `test_writer_e2e`  
**Integrity Mode**: Development / Automated Verification  
**Target Platform**: Windows 11 64-bit (x64), AMD Ryzen 5 6600H, NVIDIA GeForce RTX 2050 (DirectX 12 Ultimate FL 12_2, Vulkan 1.3)

---

## 1. Testing Philosophy & Guiding Principles

The testing framework for the VR game development environment follows strict enterprise-grade quality principles:

### 1.1 Opaque-Box (Black-Box) Testing
All tests interact with the environment strictly from the perspective of an external developer or automated CI agent:
- **Observable Interfaces**: Terminal commands, process standard input/output/error streams, exit codes (`$LASTEXITCODE`), filesystem layout, and Windows registry entries (`HKCU:\Environment\Path`).
- **No White-Box Shortcuts**: Tests do not mock system binaries or inject artificial environment states. They execute actual binaries (`godot.cmd`, `Godot_v4.3-stable_win64_console.exe`, `node.exe`, `npm.cmd`, `vite`) and verify real disk outputs.
- **Strict Separation of Concerns**: The testing track writes only test specifications and test runners (`tests\`). It never modifies implementation code (`tools\`, `bin\`, `projects\`, `scripts\`). Implementation defects are surfaced and escalated.

### 1.2 Progressive Testability
During milestone execution across the multi-agent development lifecycle, the test suite is designed with progressive milestone awareness:
- Tests for completed milestones (e.g. M1: F1–F3, M2: F4–F6) execute strict, deterministic assertions.
- Tests for planned or in-progress milestones (e.g. M3: F7–F9) contain fully defined opaque-box assertions. When run in default progressive mode prior to milestone delivery, pending features are recognized as `[SKIPPED - Pending Milestone]` without generating false positive failures.
- When run in `-Strict` or `-Milestone All` mode after full deployment, 100% of the tests are asserted strictly, ensuring zero regressions.

### 1.3 Authoritative Expected Output Derivation
Every test assertion is anchored to an authoritative source:
1. **Engine & CLI (F1–F3)**: Godot Engine 4.3 Stable official release specifications, Windows PE 64-bit headers, and CMD/PowerShell process exit code contracts.
2. **WebXR & Three.js (F4, F6)**: W3C WebXR Device API specifications (secure context requirements, 6DoF input sources, `navigator.xr`), Vite 5 build bundling standards, and Three.js r170 module structures.
3. **VR Sample Scene (F5)**: Godot OpenXR module interface contracts (`XROrigin3D`, `XRCamera3D`, `XRController3D`), and headless script execution protocol (`res://test_runner.gd`).
4. **Automation & Documentation (F7–F9)**: Project requirements from `ORIGINAL_REQUEST.md` and architecture definitions in `PROJECT.md`.

### 1.4 Test Isolation & Determinism
- **Self-Contained State**: Each test establishes its own working directory and context, cleans up temporary artifacts, and does not depend on test execution order.
- **Side-Effect Free**: Tests operate within isolated subdirectories or scratch directories without mutating the global developer configuration.
- **Non-Elevated Compliance**: Workstation execution runs under standard non-administrator user permissions (`IsAdministrator: False`). Tests verify that all operations succeed without UAC elevation.

---

## 2. Four-Tier Testing Methodology

```
+--------------------------------------------------------------------------+
|                 Tier 4: Real-World Application Scenarios                 |
|       (Fresh Terminal Onboarding, Headless CI, Rapid Dev Workflows)      |
+--------------------------------------------------------------------------+
                                     ^
+--------------------------------------------------------------------------+
|                  Tier 3: Cross-Feature Combinations                      |
|       (CLI + PATH, Godot VR + Test Runner, WebXR + Vite Bundling)        |
+--------------------------------------------------------------------------+
                                     ^
+--------------------------------------------------------------------------+
|                 Tier 2: Boundary & Corner Cases (>=5/feature)            |
|       (Spaces in Paths, Missing Flags, Non-Elevated, Exit Codes)         |
+--------------------------------------------------------------------------+
                                     ^
+--------------------------------------------------------------------------+
|                 Tier 1: Feature Coverage (>=5/feature)                   |
|       (Isolated Happy-Path Assertions for all Features F1 to F9)         |
+--------------------------------------------------------------------------+
```

### 2.1 Tier 1: Feature Coverage (Isolated Happy Path)
Tests that every single feature F1 through F9 operates according to nominal design parameters in isolation:
- At least 5 distinct test cases per feature (minimum 45 tests across F1–F9).
- Validates file presence, binary integrity, exit code 0, standard output text patterns, and configuration parameters.

### 2.2 Tier 2: Boundary, Edge & Corner Cases
Subject each feature to boundary stress and hostile invocation conditions:
- Path strings containing spaces and special characters.
- Unknown flags, missing parameters, and empty arguments.
- Rapid sequential and burst executions to test file locking.
- Non-elevated execution boundary (ensuring no administrator prompt is triggered).
- Exit code fidelity: non-zero return code propagation on error conditions.

### 2.3 Tier 3: Cross-Feature Combinations
Validates end-to-end interactions between interconnected modules:
- Godot CLI wrapper (F2) resolving target binary (F1) through User PATH (F3).
- Godot CLI (F2) launching VR Hello World project (F5) and executing headless test runner (`res://test_runner.gd`).
- WebXR tooling (F4) compiling Three.js VR scene (F6) into production assets via Vite.
- Health-check automation (F7) auditing installed tools (F1–F4) and validating sample projects (F5–F6).
- Setup script (F8) configuring environment and successfully invoking health-check (F7).

### 2.4 Tier 4: Real-World Application Scenarios
End-to-end workflows representing realistic developer journeys:
- **Scenario 4.1: Fresh Developer Onboarding**: Launching a clean terminal session, resolving `godot` without absolute paths, querying version, and verifying engine responsiveness.
- **Scenario 4.2: VR Scene Modification & Verification**: Creating an experimental scene in the Godot VR project, running headless validation, and ensuring test pass.
- **Scenario 4.3: WebXR Development & Build Cycle**: Running package builds, inspecting asset outputs, and ensuring local web serving capability.
- **Scenario 4.4: Headless CI/CD Pipeline**: Emulating a continuous integration build runner that checks environment health, compiles WebXR, and validates Godot scenes headlessly.
- **Scenario 4.5: Disaster Recovery & Environmental Integrity**: Auditing critical files, permissions, and registry keys to confirm system self-sufficiency.

---

## 3. Feature Inventory & Verification Matrix

| Feature ID | Feature Name | Primary Target Path | Minimum Tests (T1 + T2) | Authoritative Source |
|---|---|---|---|---|
| **F1** | Godot 4 Engine Installation | `D:\vr_game_dev\tools\godot\` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R1`, `PROJECT.md §F1` |
| **F2** | Godot CLI Terminal Wrapper | `D:\vr_game_dev\bin\godot.cmd` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R1`, `PROJECT.md §F2` |
| **F3** | Environment PATH Persistence | `HKCU:\Environment\Path` & `D:\bin` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R1`, `PROJECT.md §F3` |
| **F4** | WebXR Tooling & Project Setup | `D:\vr_game_dev\projects\webxr_hello_world\` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R1, §R3`, `PROJECT.md §F4` |
| **F5** | Godot 4 VR Hello World Project | `D:\vr_game_dev\projects\vr_hello_world\` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R3`, `PROJECT.md §F5` |
| **F6** | WebXR Three.js VR Scene | `D:\vr_game_dev\projects\webxr_hello_world\src\` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R3`, `PROJECT.md §F6` |
| **F7** | Environment Health-Check Script | `D:\vr_game_dev\scripts\check_environment.ps1` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R2`, `PROJECT.md §F7` |
| **F8** | Environment Setup & Restore Script | `D:\vr_game_dev\scripts\setup_environment.ps1` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R2`, `PROJECT.md §F8` |
| **F9** | Documentation & Tool Catalog | `D:\vr_game_dev\README.md` & `TOOL_CATALOG.md` | 10 (5 Happy + 5 Edge) | `ORIGINAL_REQUEST §R2`, `PROJECT.md §F9` |
| **T3** | Cross-Feature Integration | System Integration Points | 6 Inter-Module Suites | `PROJECT.md §Interface Contracts` |
| **T4** | Real-World Workflows | End-to-End User Journeys | 5 Workflow Scenarios | `PROJECT.md §Dual Track Orchestration` |
| **TOTAL** | **Comprehensive E2E Suite** | **All Artifacts** | **101 Test Assertions** | **Full System Scope** |

---

## 4. Test Execution Instructions

### 4.1 Running the Complete E2E Suite
From any PowerShell 5.1 or PowerShell 7 terminal:

```powershell
# Navigate to project root or tests folder
Set-Location D:\vr_game_dev

# Execute default E2E test runner (Progressive Milestone Aware)
powershell -ExecutionPolicy Bypass -File .\tests\run_e2e_tests.ps1
```

### 4.2 Runner Command-Line Options

| Parameter | Type | Default | Description |
|---|---|---|---|
| `-Milestone` | `string` | `"Auto"` | Filter by milestone: `Auto`, `M1`, `M2`, `M3`, `All`. |
| `-Tier` | `int` | `0` (All) | Filter by tier: `1` (Feature), `2` (Boundary), `3` (Integration), `4` (Real-World), or `0` for all tiers. |
| `-Feature` | `string` | `""` | Target specific feature (e.g. `F1`, `F5`). |
| `-Strict` | `switch` | `False` | Enforce strict failure if any feature across F1–F9 is missing. |
| `-Json` | `switch` | `False` | Emits structured JSON summary to stdout for CI ingestion. |
| `-VerboseReport` | `switch` | `False` | Displays detailed assertion diagnostics and timing metrics. |

### 4.3 Examples

```powershell
# Run only Tier 1 Feature Coverage tests:
powershell -ExecutionPolicy Bypass -File .\tests\run_e2e_tests.ps1 -Tier 1

# Run tests for Godot VR Sample Project (Feature F5):
powershell -ExecutionPolicy Bypass -File .\tests\run_e2e_tests.ps1 -Feature F5

# Run in CI mode emitting JSON:
powershell -ExecutionPolicy Bypass -File .\tests\run_e2e_tests.ps1 -Json > e2e_results.json

# Run strict full suite enforcement:
powershell -ExecutionPolicy Bypass -File .\tests\run_e2e_tests.ps1 -Milestone All -Strict
```

### 4.4 Exit Code Contract
- `0`: All executed tests passed successfully.
- `1`: One or more test assertions failed.
