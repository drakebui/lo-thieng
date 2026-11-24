# 32-Bit Asset & Movement Technical Specification (`ASSET_SPEC_32BIT.md`)

> **📖 Master Architecture Guide:**
> For the authoritative Godot 4 architecture, `BaseCharacter.gd` API, Node hierarchy, collision & shadow anchoring, and rapid onboarding checklist, refer to [docs/CHARACTER_PIPELINE_GUIDE.md](../../../docs/CHARACTER_PIPELINE_GUIDE.md).

## 1. Environment Movement & Collision Constraints

Every character sprite (`64×64` cell) moves inside these 4 environments. Do **not** design oversized trailing cloaks or wide horizontal props that exceed the `64×64` frame, or they will clip through doors, shelves, and walls.

| Environment | Script | Camera / Scale | Player Collision | NPC / Enemy Collision | Movement Behavior |
|---|---|---|---|---|---|
| **WorkshopHub** | `scripts/main/workshop_hub.gd` | `1920×1080` (`TILE = 64`), BG `640×360` scaled `3.0×` | `44×56 px` (`player_shop.gd`) | `38×54 px` (Visitors / Debt Agents) | 8-dir free walk (`idle`, `walk`, `flip_h`) between 5 zones: Forge, Book, Bed, Left Exit, Right Shop Door |
| **ShopScene** | `scripts/shop/shop_scene.gd` | `CAMERA_ZOOM = 1.5×`, `TILE = 64` | `44×56 px` (`player_shop.gd`) | `36×48 px` (`customer_ai.gd`) | Customers spawn at door → walk to shelves (`Row 1: walk`) → pause (`Row 0: idle`) → walk to counter → leave |
| **ExplorationScene** | `scripts/regions/exploration_scene.gd` | `TILE = 64`, `72×40` tiles | `player_shop.gd` | Roaming enemies (`SPEED_PATROL = 55`, `SPEED_CHASE = 110`) | Player & enemies move top-down across sub-scenes (`STORY_1`, `LOOP_A`, `LOOP_B`, `STORY_2`) |
| **CombatScene** | `scripts/combat/combat_scene.gd` | `1920×1080` UI control layout | Left side facing Right (`flip_h = false`) | Right side facing Left (`flip_h = false` on left-facing sheet) | Plays `idle`, `attack` (`Row 2`), and `hurt` (`Row 3`) |

---

## 2. Exact GDScript `[PIXEL ART CONFIG]` Values for 32-Bit Standard

When switching `scripts/shop/player_shop.gd` and `scripts/combat/combat_scene.gd` to the 32-bit 4-directional 16-frame player sheet (`res://assets/pixel/sprites/player/nam_4dir_sheet_64.png`, `1024×896 px`, 16 cols × 14 rows of `64×64`):

### In `scripts/shop/player_shop.gd`:
```gdscript
const SPRITE_SHEET_PATH := "res://assets/pixel/sprites/player/nam_4dir_sheet_64.png"
const FRAME_W := 64
const FRAME_H := 64
const SPRITE_RENDER_SCALE := 3.0 # Scale nguyên 3.0x trong phòng/shop (~192px), 2.75x cho NPC, 1.0x trong ExplorationScene
const IDLE_FPS := 12.0           # 16 frames per cycle (breathing + tail + eye blink)
const WALK_FPS := 24.0           # 16 frames per cycle (2-bone IK @ 1.5 cycles/sec)
const RUN_FPS := 28.0            # 16 frames per cycle
```

### In `scripts/combat/combat_scene.gd`:
```gdscript
const SPRITE_SHEET_PATH := "res://assets/pixel/sprites/player/nam_4dir_sheet_64.png"
const FRAME_W := 64
const FRAME_H := 64
const SPRITE_RENDER_SCALE := 3.0 # 64 * 3.0 = 192px in combat arena (integer scale)
# Uses Row 2 (idle_right, 16f @ 12 FPS), Row 6 (walk_right, 16f @ 24 FPS), Row 12 (hurt, 8f), Row 13 (special, 8f)
```

### Standard `AnimatedSprite2D` Builder for 4×4 Movable NPCs / Customers / Enemies (`256×256`):
```gdscript
func _build_character_sprite(sheet_path: String, render_scale: float = 2.0) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var texture := load(sheet_path) as Texture2D
	if texture == null:
		return sprite
	var defs: Array[Dictionary] = [
		{"name": "idle", "row": 0, "count": 4, "fps": 6.0, "loop": true},
		{"name": "walk", "row": 1, "count": 4, "fps": 8.0, "loop": true},
		{"name": "attack", "row": 2, "count": 4, "fps": 10.0, "loop": false},
		{"name": "hurt", "row": 3, "count": 4, "fps": 10.0, "loop": false},
	]
	for d: Dictionary in defs:
		var anim: String = d["name"]
		var r: int = d["row"]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, d["fps"])
		frames.set_animation_loop(anim, d["loop"])
		for c in int(d["count"]):
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(c * 64, r * 64, 64, 64)
			frames.add_frame(anim, atlas)
	sprite.sprite_frames = frames
	sprite.scale = Vector2(render_scale, render_scale)
	sprite.play("idle")
	return sprite
```

---

## 3. Directory Layout Under `assets/pixel/`

```text
assets/pixel/
├── backgrounds/
│   ├── workshop_hub_bg_640x360.png
│   ├── shop_bg_640x360.png
│   ├── opening_old_forge_640x360.png
│   └── combat_v1_dong_may_640x360.png
├── sprites/
│   ├── player/
│   │   └── nam_sheet_64.png               # 256x512 (4x8 cells of 64x64)
│   ├── npcs/
│   │   ├── ba_hac_nguyet_sheet_64.png     # 256x256 (4x4 cells: idle, walk, attack, hurt)
│   │   └── co_long_gio_sheet_64.png       # 256x256 (4x4 cells: idle, walk, attack, hurt)
│   ├── customers/
│   │   ├── nong_dan_sheet_64.png          # 256x256 (4x4 cells)
│   │   ├── ve_binh_sheet_64.png           # 256x256 (4x4 cells)
│   │   ├── tho_san_sheet_64.png           # 256x256 (4x4 cells)
│   │   └── hiep_khach_sheet_64.png        # 256x256 (4x4 cells)
│   └── enemies/
│       ├── soi_dong_co_t1_sheet_64.png    # 256x256 (4x4 cells)
│       ├── bandit_tre_t1_sheet_64.png     # 256x256 (4x4 cells)
│       └── soi_gia_t2_sheet_64.png        # 256x256 (4x4 cells)
├── tilesets/
│   ├── workshop/
│   └── v1_dong_may/
└── vfx/
```
