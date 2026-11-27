---
name: lo-thieng-pixel-assets
description: >-
  Standardized 32-bit Hoả Tâm Pixel Art asset creation and validation pipeline for Lò Thiêng.
  Activate whenever creating, converting, or validating character sprite sheets, NPCs, customers,
  enemies, 3/4 top-down room backgrounds (WorkshopHub, ShopScene, ExplorationScene), combat
  backgrounds, UI icons, or SFX so every character asset is movable and animation-ready across
  all game environments.
---

# Lò Thiêng — 32-Bit Pixel Art & Movable Character Pipeline

This skill provides a **deterministic, model-agnostic workflow** for generating, converting, and integrating
32-bit Pixel Art assets for **Lò Thiêng**. Any AI model (Gemini, Claude, Codex, GPT, Flash/Pro)
can execute this skill by running the bundled PowerShell/C# pipeline script instead of writing
ad-hoc image code.

> **📖 Master Architecture & Character Guide:**
> For the comprehensive engine architecture, `BaseCharacter.gd` API, Node hierarchy, collision & shadow anchoring, audio integration, and 10-minute rapid onboarding, see [docs/CHARACTER_PIPELINE_GUIDE.md](../../../docs/CHARACTER_PIPELINE_GUIDE.md).

---

## 1. Non-Negotiable Core Rules (Read Before Generating)

0. **ZERO LEGACY ASSET REUSE (100% Fresh 32-Bit Assets Only):**
   - Legacy folders (`assets/weapons/`, `assets/UI/`, `assets/sprites/`, `assets/characters/`) exist **strictly as concept ideas / item lists**.
   - **NEVER** load legacy textures into active scenes, **NEVER** keep fallback paths pointing to legacy folders, **NEVER** downscale legacy images, and **NEVER** build new 32-bit frames/pedestals/anvils/tubs that wrap around old high-res weapon or material PNGs.
   - Every visual element rendered in the game (backgrounds, characters, weapons, blanks, materials, UI frames, icons, props) must be **100% newly created in 32-bit Hoả Tâm Pixel Art** inside `res://assets/pixel/`.

1. **Every Character Must Be Movable (Never Static Statues):**
   - Characters, customers, visiting NPCs, and enemies move across **4 environments**:
     `WorkshopHub`, `ShopScene` (store), `ExplorationScene` (dungeon/region patrol & chase), and `CombatScene`.
   - All characters inherit from `BaseCharacter.gd` (`class_name BaseCharacter extends CharacterBody2D`).
   - Every character/customer/enemy asset **MUST be exported as a multi-row Sprite Sheet** (`64×64` per cell, 4 columns per row) with a **locked foot baseline (`y = 60`)** and **centered X pivot (`x = 32`)** so `flip_h` and walking animations never jitter or clip into walls.
2. **Locked Spatial Metrics & Resolution Standard (`1920×1080` Viewport, Nearest Filter):**
   - **Full-screen Room / Combat Backgrounds:** `640×360 px` (exact `3×` integer scale → `1920×1080`).
   - **Character / Customer / NPC / Enemy Sprite Cell:** `64×64 px` per frame.
   - **Scene Render Scales:**
     - Room Scenes (`WorkshopHub`, `ShopScene`): `RENDER_SCALE = 3.0×` for Player Nấm (~170–192 px), `2.75×` for visiting NPCs/customers (~155–165 px).
     - Exploration Scenes (`ExplorationScene`): `RENDER_SCALE = 1.0×` (camera zoom 1.5×, tile size `TILE = 64`).
     - Combat Arena (`CombatScene`): `RENDER_SCALE = 3.0×`.
   - **3/4 RPG Environmental Ratios:**
     - Anvil / Workbench: `0.5–0.6×` character height (waist-to-chest high, ~125 px vs Nam ~170 px).
     - Door / Archway: `1.5–1.8×` character height (~250–300 px vs Nam ~170 px).
     - Counter / Desk: `0.6–0.7×` character height (~110–125 px).
   - **Map Tiles & Props:** `16×16 px` base tile (`4×` scale → `64×64` matching `const TILE := 64`), multi-tile props in multiples of `16px` (`32×32`, `32×48`, `48×48`).
   - **File Naming:** 100% `snake_case`, ASCII only (no Vietnamese accents, no spaces) inside `assets/pixel/`. Never overwrite the 102 legacy reference images in `assets/`.
3. **Unified 96-Color Hoả Tâm Palette:**
   - All assets must pass through [hoa_tam_32bit_pipeline.ps1](./scripts/hoa_tam_32bit_pipeline.ps1), which enforces the 96-color Hoả Tâm palette and seals characters with a `1px` deep plum-ink outline (`#120C10`, never pure `#000000`).

---

## 2. Standard Sprite-Sheet Grid Contract

All character sprite sheets use **`64×64 px` cells** (`FRAME_W = 64`, `FRAME_H = 64`) with foot baseline anchored at `(32, 60)`:

### A. NPCs, Shop Customers & Enemies (`256×256 px` — 4 cols × 4 rows)

| Row | Animation Name | Frames | FPS | Loop | Gameplay Usage |
|---:|---|---:|---:|---|---|
| `0` | `idle` | 4 | `6.0` | `true` | Standing in WorkshopHub, waiting at Shop counter, Combat idle |
| `1` | `walk` | 4 | `10.0` | `true` | Walking in Shop (`CustomerAI`), patrolling/chasing in `ExplorationScene`, Hub walking |
| `2` | `attack` | 4 | `10.0` | `false` | Strike / lunge in `CombatScene` (or interaction gesture for NPCs) |
| `3` | `hurt` | 4 | `10.0` | `false` | Hit recoil + flash in `CombatScene` (or impatient reaction in Shop) |

*Directional Control:* Standard 4 directions (`down`, `up`, `right`, `left`) are supported via `BaseCharacter.set_facing(dir)`. Direction `left` is automatically flipped using `flip_h = true` when mirrored from `right`.

### B. Player Protagonist `Nấm` (`1024×896 px` — 16 cols × 14 rows, 4-Directional Cinema Fluidity)
Matches `scripts/shop/player_shop.gd` (extending `BaseCharacter`) across `WorkshopHub`, `ShopScene`, `ExplorationScene`, and `CombatScene`:
- `Row 0..3`: `idle_down`, `idle_up`, `idle_right`, `idle_left` (16 frames @ `12.0 FPS`, loop — breathing, waving tail, natural eye blink)
- `Row 4..7`: `walk_down`, `walk_up`, `walk_right`, `walk_left` (16 frames @ `24.0 FPS`, loop — 2-bone IK digitigrade legs, paw heel-toe pitch, multi-segment tail wave, intact apron)
- `Row 8..11`: `run_down`, `run_up`, `run_right`, `run_left` (16 frames @ `28.0 FPS`, loop)
- `Row 12`: `hurt` (8 frames @ `16.0 FPS`, non-loop)
- `Row 13`: `special` / `attack` (8 frames @ `18.0 FPS`, non-loop)
- Legacy aliases `"idle"` (`Row 2`), `"walk"` (`Row 6`), `"run"` (`Row 10`) are also registered in `SpriteFrames` for backward compatibility.

To rebuild the 4-directional player sheet:
```powershell
powershell -ExecutionPolicy Bypass -File .agents\skills\lo-thieng-pixel-assets\scripts\hoa_tam_32bit_pipeline.ps1 -Mode player4Dir -FrontPath "<front_img>" -BackPath "<back_img>" -SideSheetPath "<side_img>" -OutputPath "assets\pixel\sprites\player\nam_4dir_sheet_64.png" -CellSize 64
```

---

## 3. Step-by-Step Execution Procedure (Under 10 Minutes)

### Case A — Create a New Movable Character / Customer / Enemy

**Step 1: Generate a clean master pose on flat `#FF00FF` magenta background**
Invoke `image-generator` (or prepare a reference image) using this exact prompt template:

```text
Generate a single 2D indie RPG 32-bit pixel art character sprite of [CHARACTER_NAME & SPECIES, e.g., "Thợ Săn Cáo Rừng" Animal Folk forest fox hunter], in the style of Sea of Stars / Eastward / Octopath Traveler.
- Pose & Orientation: Full-body standing upright in a 3/4 side-view walk-ready stance facing [LEFT for enemies/NPCs | RIGHT for player], both feet planted clearly on the same ground level, silhouette compact enough to walk through doors and shop aisles.
- Art style: Detailed 32-bit pixel art, warm dark plum-brown outlines (NO pure black), earthy Hoả Tâm palette (warm woods, amber, indigo, olive, terracotta).
- Anatomy: For beastfolk/cats, use digitigrade legs (curved thigh 7px, backward hock joint 5px, soft paws with 3 toe accents), organic S-curved tail, and naturally draped clothing.
- Composition: Single centered full-body character with generous margin, NO ground shadow ellipse, NO text, NO UI, NO multiple poses.
- Background: Completely flat, uniform solid bright magenta (#FF00FF) chroma-key background with zero gradients.
```

**Step 2: Run the deterministic 4×4 Movable Sprite-Sheet Synthesizer**
Run via `run_command` (set `-FacingSign -1` if character faces left, `1` if facing right):

```powershell
powershell -ExecutionPolicy Bypass -File .agents\skills\lo-thieng-pixel-assets\scripts\hoa_tam_32bit_pipeline.ps1 -Mode sheetFromSingle -InputPath "<path_to_raw_image>" -OutputPath "assets\pixel\sprites\<category>\<snake_case_name>_sheet_64.png" -CellSize 64 -FacingSign -1
```

What this script does automatically:
1. Flood-fill removes the `#FF00FF` chroma-key background + suppresses 2px magenta edge spill.
2. Quantizes colors to the 96-color Hoả Tâm Master Palette.
3. Synthesizes all 16 frames (`Row 0: idle`, `Row 1: walk` split-leg stride + torso bounce, `Row 2: attack` windup/lunge, `Row 3: hurt` knockback + hit-flash) with locked foot baseline (`y = 60`) and seals a crisp `1px` dark plum outline around every frame.
4. Prints `PASS:` or `FAIL:` validation metrics (`256×256`, transparent pixel count, `0` magenta spill).

**Step 3: Create GDScript inheriting `BaseCharacter`**
See [docs/CHARACTER_PIPELINE_GUIDE.md](../../../docs/CHARACTER_PIPELINE_GUIDE.md#5-quy-trình-6-bước-thêm-mới-npcenemy-dưới-10-phút) for the plug-and-play GDScript template with foot collision, contact shadow, emote anchor, and audio hooks.

---

### Case B — Create a 32-Bit Room or Combat Background (`640×360`)

**Step 1: Generate a 16:9 cutaway or side-view background**
- For **Walkable Rooms (`WorkshopHub`, `ShopScene`, `ExplorationScene`):** Must use a **3/4 Top-Down RPG Cutaway angle** with a clear, unobstructed walkable floor center and zones placed at the exact coordinates required by the scene script (see [ASSET_SPEC_32BIT.md](./references/ASSET_SPEC_32BIT.md)).
- For **Combat (`CombatScene`):** Side-view battle arena with open flat ground on the left (`x: 15%..45%`) for `Nấm` and on the right (`x: 55%..85%`) for the enemy.

**Step 2: Run the 96-Color 32-Bit Background Pixelizer (`640×360`)**

```powershell
powershell -ExecutionPolicy Bypass -File .agents\skills\lo-thieng-pixel-assets\scripts\hoa_tam_32bit_pipeline.ps1 -Mode background -InputPath "<path_to_raw_16x9_bg>" -OutputPath "assets\pixel\backgrounds\<snake_case_name>_640x360.png" -TargetW 640 -TargetH 360
```

---

### Case C — Convert an Existing 4×8 Grid Sprite Sheet

```powershell
powershell -ExecutionPolicy Bypass -File .agents\skills\lo-thieng-pixel-assets\scripts\hoa_tam_32bit_pipeline.ps1 -Mode sheetFromGrid -InputPath "<path_to_4x8_sheet>" -OutputPath "assets\pixel\sprites\player\<name>_sheet_64.png" -CellSize 64
```

---

## 4. Mandatory Verification Checklist (Before Reporting Done)

1. **Automated CLI Check:** Every run of `hoa_tam_32bit_pipeline.ps1` must output `PASS:` (`0` magenta spill, exact pixel dimensions).
2. **Visual Inspection (`read_file`):** Always call `read_file` on the generated PNG (or a `2×`/`3×` nearest-neighbor preview) to verify:
   - Feet in Row 0 (`idle`) and Row 1 (`walk`) sit on the same ground baseline (`y = 60`) with no floating shadow lines.
   - Character silhouette fits inside the `64×64` cell without clipping during `walk` or `attack`.
   - Walkable floor areas in `640×360` room backgrounds align with collision walls and interactive zones.
3. **Architecture & Code Integration:**
   - Script extends `BaseCharacter.gd`.
   - Contact shadow is present at feet (`z_index = -1`, `Color(0.06, 0.03, 0.04, 0.42)`).
   - Collision shape is anchored at feet (`CapsuleShape2D` ~34×18 px).
   - `EmoteAnchor` is positioned at `(0, -56)`.
   - Footstep audio integrates with `AudioManager.play_sfx_key`.
   - Run `gdlint <modified_script.gd>` if available in PATH.
