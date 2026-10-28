# Astorka Engine

A native macOS (Apple Silicon & Intel) **No-Code Game Engine** designed from the ground up for creating **CLI (Terminal) Games** and **UI Games**.

Astorka Engine provides a rich, native macOS editor UI while maintaining a pure no-code philosophy: empower creators to design and publish complex terminal and UI games without writing code or wrestling with node-spaghetti.

---

## 🎯 Core Philosophy: True No-Code Game Creation

- **Fullscreen Launch:** Opens automatically in native macOS fullscreen mode.
- **Main Menu (Project Hub):** Starts at an interactive project dashboard displaying all your created games:
  - **[➕ Create New Project]**: Enter your game title, select **CLI** or **UI** game type, and immediately begin creation.
  - **Saved Projects:** Browse your `.astorkaproject` files with modification timestamps and launch them with a single click.
- **Custom Project Format (`.astorkaproject`):** All projects are saved automatically to `~/Documents/AstorkaProjects/[ProjectName].astorkaproject`.
- **Declarative Choices & Formulas:**
  - Choice Label: `1. Sell Raw Materials`
  - Condition: `raw_materials >= 5`
  - Formula: `cash += item_price * 5 / 10`, `raw_materials -= 5`
  - Feedback Message: `5 raw materials processed and sold!`
- **Dual Execution Environments:**
  - In-Editor Live Terminal & Canvas Simulator.
  - One-click launch in native macOS `Terminal.app`.
  - One-click export into a standalone, double-clickable macOS `.app` bundle.

---

## 🚀 Quick Start

### 1. Launch the Engine Editor
```bash
open AstorkaEditor.app
```
*(or double-click `AstorkaEditor.app` from Finder)*