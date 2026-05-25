# 🔥 LÒ THIÊNG — KẾ HOẠCH PHÁT TRIỂN v2.0

> **Cách dùng:** Tick `[x]` khi hoàn thành. Copy phần Current Status vào CLAUDE.md sau mỗi session.
> **Priority:** 🔴 Must → 🟡 Should → 🟢 Nice-to-have
> **Scope tag:** `[DEMO]` = cần cho demo 4 ngày | `[FULL]` = full game only

---

## THAY ĐỔI TỪ v1.0

| Hạng mục | v1.0 | v2.0 |
|---|---|---|
| Thời lượng game | ~25 ngày | **52 ngày** |
| Hệ thống nợ | 3 Stage (5k/15k/30k) | **4 Checkpoint (3k/8k/24k/65k = 100k tổng)** |
| Cấu trúc checkpoint | Đều nhau | **4/8/16/24 ngày (không đều)** |
| Demo target | Vertical slice 1 ngày | **4 ngày đầu, trả C1** |
| Resource classes | 5 classes cơ bản | **+DebtCheckpoint, +RouteState, +MercenaryContract** |

---

## HỆ THỐNG NỢ — 4 CHECKPOINT

```
Total nợ: 100,000G trên 52 ngày (~63% thu nhập dự kiến)

C1  ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  3,000G  → Ngày 4
C2  ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  8,000G  → Ngày 12
C3  ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 24,000G  → Ngày 28
C4  ████████████████████████████████████████████████████ 65,000G  → Ngày 52
```

| # | Tên | Agent | Trigger | Deadline | Số tiền | Window |
|---|---|---|---|---|---|---|
| C1 | Tiền mặt bằng lò | Người Thu Nợ Chợ Ngoài | Ngày 1 | **Ngày 4** | 3,000G | 4 ngày |
| C2 | Tiền dẫn đường vào rừng | Tay Sai Rừng | Ngày 5 | **Ngày 12** | 8,000G | 8 ngày |
| C3 | Thuế lớn giữa mùa | Thương Nhân Sa Mạc | Ngày 13 | **Ngày 28** | 24,000G | 16 ngày |
| C4 | Nợ gốc — đối mặt cuối | Bà Trùm Hắc Nguyệt | Ngày 29 | **Ngày 52** | 65,000G | 24 ngày |

**Penalty rule:**
- Trễ 1-2 ngày: +10% (C1→3,300G, C2→8,800G, C3→26,400G)
- Trễ 3+ ngày: +20% + Debt Agent harass shop (1 khách/ngày bị cản)
- Trễ 2 checkpoint liên tiếp: Trigger Ending C

**Reward on-time:** Mỗi checkpoint trả đúng hạn unlock 1 story hint hoặc NPC benefit nhỏ.

---

## DEMO TARGET — NGÀY 1–4, TRẢ C1

> **Mục tiêu:** Player trải nghiệm đầy đủ 1 vòng lặp Trinity Hook (Explore → Forge → Sell),
> cảm nhận áp lực C1 (3,000G deadline), và trả được nợ trước ngày 4 chiều.

### Features CÓ trong Demo

**Core Loop:**
- [x] 4 phase ngày: Sáng (Explore) / Trưa (Forge) / Chiều (Shop) / Đêm (Planning)
- [x] 4 ngày game (Ngày 1 scripted tutorial → Ngày 2-3 free play → Ngày 4 deadline)
- [x] Day counter + phase indicator trên HUD

**Exploration:**
- [x] V1 Đồng Mây Trắng (semi-open map, kích thước ~50×40 tile)
- [x] Stamina system: base 14, drain theo terrain, restore qua đêm
- [x] Enemy spawn: Sói Đồng Cỏ (T1), Bandit Trẻ (T1), Sói Già (T2)
- [x] Random encounter → combat transition
- [x] Patrol AI cơ bản (IDLE → ALERT → CHASE → ENCOUNTER)
- [x] Counter mechanic: tấn công từ sau lưng → player đánh trước +30%

**Forge:**
- [x] Phase 1: Heat bar mini-game (timing meter, sweet spot 60-80)
- [x] Phase 2: Rhythm mini-game (5 nhát búa, Perfect/Good/Miss → prefix tier)
- [x] Phase 3: Auto resolve + element animation (nhúng nguyên tố)
- [x] 4 Prefix demo: Bén Ngọt / Kiên Cố / Nặng Tay / Huyền Bí
- [x] 2 Suffix demo: Hỏa / Gió (đủ để thấy weapon identity)
- [x] 2 loại phôi: Kiếm Đơn / Kiếm Ngắn
- [x] WeaponCard UI: hiển thị stats + skill 1 + skill 2
- [x] Curse system (miss nhiều → Curse affix, weapon giảm giá trị)

**Shop:**
- [x] Shop layout 16×12 tile: 3 kệ trưng bày + quầy thu ngân
- [x] Customer AI: walk in → browse → approach → bargain
- [x] Bargaining mini-game: 4-zone slider (Quá Cao/Hơi Cao/Vừa/Quá Thấp)
- [x] Patience system: 2-3 lần mặc cả tối đa
- [x] 4 loại customer demo: Kiếm Sĩ / Vệ Binh / Thợ Săn / Dân Làng
- [x] 3-5 khách/ngày (random từ pool nhỏ)

**Economy & Debt:**
- [x] Gold counter (HUD + Planning screen)
- [x] C1 scene: Người Thu Nợ xuất hiện Ngày 1 sáng
- [x] Debt tracker UI (Planning screen đêm): hiển thị C1 còn thiếu bao nhiêu
- [x] Payment scene: player trả C1 tại Planning screen Ngày 4 chiều
- [x] Kết quả: trả đúng hạn → Agent farewell scene + teaser C2 | trễ → penalty + next checkpoint hint

**Loot & Inventory:**
- [x] Drop system: 3 loot từ V1 (Lông Sói R3, Da Sói R2, Nanh Sói R3)
- [x] Inventory cơ bản: 12 slot hand limit, kho xưởng không giới hạn
- [x] Filter: Material / Weapon / Consumable

**NPC Demo:**
- [x] Người Thu Nợ Chợ Ngoài (C1 agent — scripted scene ngày 1 + 4)
- [x] Cô Lộng Gió (V1 VIP — gặp trong map, dialogue intro)
- [x] 4 loại customer regular (walk-in, không có quest line)

**UI & UX:**
- [x] Main Menu + New Game
- [x] HUD: Gold / Stamina / Day counter / Phase indicator
- [x] Pause menu
- [x] Save/Load (chỉ lưu tại xưởng ban đêm)
- [x] Game Over screen (Ending D: 3 ngày liên tiếp tiền = 0)
- [x] Tutorial tooltips ngày 1 (contextual, không pop-up spam)

### Features KHÔNG có trong Demo

- Add-ons system (Bao Kiếm Da, Dầu Mài...)
- Services system (Mài Kiếm, Sửa Kiếm...)
- Proof Grades / Chiến Chứng / Test Slot
- Mercenary system
- Route State machine
- Reputation system (chỉ display, không có effect)
- V2–V6 (map chưa dùng)
- Quest system (ngoài scripted tutorial 4 ngày)
- NPC Affinity depth
- Di Vật system
- Endings A/B/C (chỉ có Ending D — game over)
- Difficulty selection
- C2/C3/C4 scenes (chỉ tease trong kết thúc demo)

---

## PHASE 0 — Foundation `[DEMO]`

### Project Setup
- [ ] Tạo Godot 4 project, đặt tên `lo_thieng`
- [ ] Tạo cấu trúc thư mục: `assets/ data/ scenes/ scripts/ resources/`
- [ ] Git init + commit đầu tiên
- [ ] Tạo `CLAUDE.md` ở root

### Input Map
- [ ] `pump_bellows` — giữ để bơm bễ (Phase 1)
- [ ] `hammer_hit` — nhấn theo nhịp (Phase 2)
- [ ] `confirm` / `cancel` / `menu`
- [ ] `move_up/down/left/right`
- [ ] `interact` — tương tác NPC/object

### Autoloads
- [ ] `GameManager.gd` — game state, day/phase, gold, reputation, debt tracker
- [ ] `EventBus.gd` — tất cả signals toàn cục
- [ ] `SaveSystem.gd` — read/write JSON (lưu tại xưởng đêm)
- [ ] `AudioManager.gd` — music + sfx

### Custom Resource Classes
- [ ] `WeaponData.gd` — stats, prefix, suffix, durability, curse_state
- [ ] `ItemData.gd` — material, consumable, quest item
- [ ] `NPCData.gd` — budget, patience, preferences, role
- [ ] `SkillData.gd` — effect type, cost, value
- [ ] `DebtCheckpoint.gd` — id, amount, trigger_day, deadline_day, agent_id, penalty, reward `[NEW]`

### Scene Skeleton
- [ ] `Main.tscn` — root scene
- [ ] `SceneManager.gd` — chuyển scene có transition

---

## PHASE 1 — Forge System ⚒️ `[DEMO]`

### Logic
- [ ] `forge_system.gd` — Phase 1: heat bar, pump logic, tier evaluation 🔴
- [ ] `forge_system.gd` — Phase 2: rhythm timing, 5 hits, score → prefix tier 🔴
- [ ] `forge_system.gd` — Phase 3: auto resolve + suffix apply 🔴
- [ ] `weapon_builder.gd` — combine phôi + materials + prefix + suffix → WeaponData 🔴
- [ ] Curse logic: score ≤ -3 → apply Curse affix 🔴

### Data (Demo subset)
- [ ] 4 Prefix .tres: Bén Ngọt, Kiên Cố, Nặng Tay, Huyền Bí 🔴
- [ ] 2 Suffix .tres: Hỏa, Gió 🔴
- [ ] 2 Phôi .tres: Kiếm Đơn, Kiếm Ngắn 🔴
- [ ] 3 Material V1 .tres: Lông Sói, Da Sói, Nanh Sói 🔴
- [ ] Curse affix list (Array trong forge_system) 🟡

### UI
- [ ] `ForgeScene.tscn` — container 3 phase 🔴
- [ ] `ForgePhase1UI.tscn` — heat bar + pump visual 🔴
- [ ] `ForgePhase2UI.tscn` — rhythm bar + 5 hit indicators (Perfect/Good/Miss) 🔴
- [ ] `ForgePhase3UI.tscn` — element dip animation + weapon reveal 🟡
- [ ] `WeaponCardUI.tscn` — stats + skill 1 + skill 2 + price estimate 🟡

### Demo Milestone ✓
- [ ] Rèn 1 cây kiếm hoàn chỉnh từ đầu đến cuối
- [ ] Prefix thay đổi theo skill Phase 2
- [ ] Curse xuất hiện khi Phase 2 điểm âm

---

## PHASE 2 — Combat System ⚔️ `[DEMO]`

### Logic
- [ ] `combat_manager.gd` — state machine: PLAYER_TURN → ENEMY_TURN → RESOLVE 🔴
- [ ] `player_combat_unit.gd` — HP, Stamina combat, 1-2 weapon slots (demo: 1 vũ khí) 🔴
- [ ] `enemy_combat_unit.gd` — stats, tier, AI type 🔴
- [ ] `enemy_ai.gd` — Aggressive archetype (đủ cho T1-T2 V1) 🔴
- [ ] `skill_executor.gd` — resolve SkillData effect lên target 🔴
- [ ] Counter mechanic: nếu player tấn công từ sau → +30% damage, đánh trước 🔴

### Data (Demo subset)
- [ ] 4 Prefix skill .tres (match 4 prefix forge) 🔴
- [ ] 2 Suffix skill .tres (Hỏa, Gió) 🔴
- [ ] 3 Enemy .tres: Sói Đồng Cỏ T1, Bandit Trẻ T1, Sói Già T2 🔴

### UI
- [ ] `CombatScene.tscn` — side-view, player trái / enemy phải 🔴
- [ ] `CombatUI.tscn` — action menu, HP bars 🔴
- [ ] Win screen + loot display 🔴
- [ ] Lose → về xưởng, mất 20% gold 🔴

### Demo Milestone ✓
- [ ] Đánh được 1 trận T1, dùng được 2 skill
- [ ] Counter bonus hoạt động khi tấn công từ sau
- [ ] Lose → về xưởng đúng

---

## PHASE 3 — Shop System 🏪 `[DEMO]`

### Logic
- [ ] `shop_manager.gd` — customer queue, phase timer (buổi chiều) 🔴
- [ ] `customer_ai.gd` — walk in → browse → approach → bargain 🔴
- [ ] `bargaining_system.gd` — 4 vùng giá, Patience counter, resolve sale 🔴
- [ ] `shop_shelf.gd` — 3 slot kệ, đặt/lấy vũ khí 🔴

### Data (Demo subset)
- [ ] 4 Customer .tres (Kiếm Sĩ, Vệ Binh, Thợ Săn, Dân Làng) với preference tags 🔴

### UI
- [ ] `ShopScene.tscn` — 16×12 tile layout 🔴
- [ ] `BargainingUI.tscn` — 4-zone slider, input giá, customer reaction 🔴
- [ ] Shop timer HUD (buổi chiều) 🟡

### Demo Milestone ✓
- [ ] Bán 1 vũ khí, chốt giá đúng zone
- [ ] Patience = 0 → khách bỏ đi
- [ ] Gold cộng đúng

---

## PHASE 4 — Exploration 🗺️ `[DEMO]`

### Logic
- [ ] `player_controller.gd` — top-down movement + stamina travel drain 🔴
- [ ] `encounter_manager.gd` — patrol AI, vision cone, trigger combat 🔴
- [ ] `loot_system.gd` — enemy drop theo loot table (3 slot: 80%/20%/5%) 🔴

### Map
- [ ] `RegionDongMay.tscn` — V1 ~50×40 tile (simplified cho demo) 🔴
  - 4-6 enemy spawn points (T1 chủ yếu, 1-2 T2)
  - 1 Boss arena (Sói Trắng T4 — optional, không bắt buộc trong demo)
  - 1 NPC Cô Lộng Gió (gặp lần đầu, dialogue ngắn)
  - Không có gathering node (per Combat Bible — loot từ enemy)

### UI
- [ ] `ExplorationHUD.tscn` — stamina bar + gold + day/phase indicator 🔴

### Demo Milestone ✓
- [ ] Di chuyển được, trigger encounter, thắng combat, loot hiện đúng
- [ ] Stamina hết → force return về xưởng
- [ ] Cô Lộng Gió gặp được, dialogue ngắn hiện đúng

---

## PHASE 5 — Game Loop & Debt System 🔄 `[DEMO]`

### Core Loop
- [ ] `day_cycle.gd` — MORNING→NOON→AFTERNOON→NIGHT, 4-day cycle 🔴
- [ ] `inventory_system.gd` — hand limit 12, warehouse unlimited 🔴
- [ ] `InventoryUI.tscn` — grid, filter Material/Weapon/Consumable 🔴

### Debt System `[DEMO — C1 only]`
- [ ] `debt_system.gd` — load DebtCheckpoint[], check deadline mỗi đêm 🔴
- [ ] C1 data file (.tres): amount=3000, trigger=1, deadline=4, agent="nguoi_thu_no" 🔴
- [ ] C1 trigger scene: Ngày 1 sáng — Người Thu Nợ xuất hiện tại shop 🔴
- [ ] Debt tracker widget (Planning screen đêm): hiển thị còn thiếu bao nhiêu 🔴
- [ ] Payment flow: player xác nhận trả tiền → gold trừ → agent farewell scene 🔴
- [ ] Penalty logic nếu Ngày 4 qua mà chưa trả: +300G → 3,300G 🟡
- [ ] C2 tease: sau khi trả C1 → agent úp mở "tuần tới có người khác đến" 🟡

### Tutorial (4 ngày scripted)
- [x] Ngày 1: Bà Trùm intro cutscene → hướng dẫn Forge → 1 khách cố định → C1 agent scene 🔴
- [x] Ngày 2: Free play + tooltip mặc cả (lần đầu bargain) 🔴
- [x] Ngày 3: Free play + Cô Lộng Gió quest intro (tùy chọn) 🟡
- [x] Ngày 4: Deadline reminder (sáng) → trả nợ (chiều) → resolution scene 🔴

### Save/Load
- [ ] Chỉ lưu tại xưởng ban đêm (Planning phase)
- [ ] Load lại đúng ngày, gold, inventory, debt state

### Demo Milestone ✓ (Vertical Slice 4 ngày)
- [ ] Chơi được 4 ngày đầy đủ: Sáng → Trưa → Chiều → Đêm × 4
- [ ] C1 deadline hoạt động đúng (có thể trả hoặc để trễ)
- [ ] Save/Load hoạt động
- [ ] Không có crash trong 4-day loop

---

## PHASE 6 — Demo Polish ✨ `[DEMO]`

### Minimal Content
- [ ] Ngày 1 scripted hoàn chỉnh với dialogue Bà Trùm + Người Thu Nợ 🔴
- [ ] Bộ dialogue ngắn cho 4 customer types (~10 lines/type) 🔴
- [ ] Cô Lộng Gió dialogue V1 (~8 lines) 🟡
- [ ] C1 resolution scene (2 kết quả: đúng hạn / trễ) 🔴
- [ ] C2 tease scene (khi kết thúc demo) 🟡

### UX
- [ ] Main Menu + New Game 🔴
- [ ] Pause menu 🔴
- [ ] Game Over screen (nếu Day 3 gold = 0 liên tiếp) 🔴
- [ ] Fade transition giữa phases 🟡
- [ ] Contextual tooltip system (hiện 1 lần/mechanic mới) 🟡

### Audio Minimal
- [ ] Main theme (xưởng) 🟡
- [ ] Shop theme 🟡
- [ ] Combat theme 🟡
- [ ] ~20 SFX cơ bản: footstep, hammer hit, forge fire, sale success, coin 🟡

---

## PHASE 7 — Full Game (Post-Demo) `[FULL]`

> Chỉ bắt đầu sau khi demo playtest xong và nhận feedback.

### Systems cần thêm
- [ ] Add-ons system (6 add-ons, upsell flow)
- [ ] Services system (Mài Kiếm, Sửa Kiếm trước; Tẩy Curse, Reforge sau)
- [ ] Proof Grades / Chiến Chứng / Test Slot
- [ ] Route State machine (Locked/Dangerous/Cleared/Secured)
- [ ] Mercenary system (5 mercenaries, contract flow, report)
- [ ] Reputation 0-10 (gate NPC, recipe, discount)
- [ ] Di Vật system (18 artifacts, win condition)
- [ ] NPC Affinity 0-100
- [ ] C2/C3/C4 debt scenes

### Regions
- [ ] V2 Rừng Trăm Hồn
- [ ] V3 Núi Than Đỏ
- [ ] V4 Bãi Cát Thần Vàng
- [ ] V5 Thành Ngọc Bích
- [ ] V6 Làng Tổ Nghề
- [ ] 5 Corridor giữa các vùng

### Content
- [ ] Full 8 prefix + 6 suffix data
- [ ] 12 phôi data
- [ ] ~95 items total
- [ ] 25 skills cân bằng (spreadsheet test trước)
- [ ] 30+ NPC data + ~3,000 dialogue lines
- [ ] Quest system: 25 main + side quests
- [ ] 4 Endings (A/B/C/D)
- [ ] Tutorial đầy đủ 7 ngày

### Polish
- [ ] Difficulty selection (Story/Normal/Hardcore)
- [ ] Achievement system (50+)
- [ ] New Game+
- [ ] Full soundtrack (8-10 tracks)
- [ ] ~80 SFX

---

## DEPENDENCY MAP

```
Phase 0 (Foundation)
	│
	├── Phase 1 (Forge) ────────── USP #1, demo cần trước tiên
	│       │
	│       ├── Phase 2 (Combat) ── cần weapon skills
	│       │       │
	│       │       └── Phase 4 (Exploration) ── cần combat cho encounter
	│       │
	│       └── Phase 3 (Shop) ──── cần weapon để bán
	│
	└── Phase 5 (Game Loop + Debt) ── kết nối tất cả cho demo
			│
			└── Phase 6 (Demo Polish)
						│
						└── ✅ DEMO SHIP
								│
								└── Phase 7 (Full Game)
```

---

## DEMO MILESTONE — CHECKLIST CUỐI

```
Ngày 1 tutorial:
  ✅ Bà Trùm intro → học Forge → 1 khách scripted → C1 agent scene

Ngày 2 (free play):
  ✅ Vào V1 sáng → combat T1 → loot → về xưởng
  ✅ Forge 1-2 vũ khí Phase 1+2+3
  ✅ Mở shop chiều → bán 2-3 khách tự do

Ngày 3 (free play + pressure):
  ✅ Debt tracker nhắc nhở tối: "Còn X ngày, còn thiếu YG"
  ✅ Player quyết định chiến lược

Ngày 4 (deadline day):
  ✅ Sáng: reminder "Hôm nay là hạn chót"
  ✅ Chiều: bán hàng lần cuối
  ✅ Tối: payment scene — đủ tiền → trả → C2 tease | thiếu → penalty
```

---

## RESOURCE CLASS MỚI — DebtCheckpoint.gd

```gdscript
class_name DebtCheckpoint
extends Resource

@export var id: String                    # "c1_mat_bang", "c2_rung", ...
@export var title: String                 # "Tiền mặt bằng lò"
@export var agent_id: String              # NPC giao nhiệm vụ
@export var amount_gold: int              # 3000, 8000, 24000, 65000
@export var trigger_day: int             # Ngày trigger scene
@export var deadline_day: int            # Ngày phải trả
@export var penalty_gold: int            # Số phạt nếu trễ
@export var late_days_before_harass: int # Bao nhiêu ngày trễ thì bắt đầu harass
@export var on_time_reward: Dictionary   # { hint: "...", npc_affinity_bonus: 5 }
@export var agent_quote: String          # Câu thoại khi đến đòi
@export var is_paid: bool = false
@export var is_late: bool = false
```

---

## CURRENT STATUS
> Cập nhật sau mỗi session — copy vào CLAUDE.md

### Phase 0 — Foundation
- [ ] Project setup + Git
- [ ] Input Map
- [ ] Autoloads (GameManager, EventBus, SaveSystem, AudioManager)
- [ ] Resource classes (WeaponData, ItemData, NPCData, SkillData, DebtCheckpoint)
- [ ] Main scene + SceneManager

### Phase 1 — Forge
- [ ] forge_system.gd Phase 1 (heat bar)
- [ ] forge_system.gd Phase 2 (rhythm, 5 hits)
- [ ] forge_system.gd Phase 3 (auto + suffix)
- [ ] weapon_builder.gd
- [ ] 4 Prefix + 2 Suffix + 2 Phôi data
- [ ] Forge UI (Phase 1 + 2 + 3 + WeaponCard)

### Phase 2 — Combat
- [ ] combat_manager.gd + player/enemy units
- [ ] skill_executor.gd + counter mechanic
- [ ] 3 enemy data (T1×2, T2×1)
- [ ] Combat UI + Win/Lose screen

### Phase 3 — Shop
- [ ] shop_manager.gd + customer_ai.gd
- [ ] bargaining_system.gd
- [ ] 4 customer data
- [ ] Shop UI + BargainingUI

### Phase 4 — Exploration
- [ ] player_controller.gd + encounter_manager.gd
- [ ] RegionDongMay.tscn (V1 playable)

### Phase 5 — Game Loop + Debt
- [ ] day_cycle.gd (4-day loop)
- [ ] inventory_system.gd + UI
- [ ] debt_system.gd + C1 data
- [ ] C1 trigger scene + payment flow
- [ ] Tutorial 4 ngày (ngày 1 scripted)
- [ ] Save/Load

### Phase 6 — Demo Polish
- [ ] Dialogue content (Bà Trùm, C1 agent, 4 customers, Cô Lộng Gió)
- [ ] Main Menu + HUD + Pause + Game Over
- [ ] Audio minimal (3 tracks + 20 SFX)
- [ ] Bug fix + QA 4-day loop

---

## NGÀY 1 — SCRIPTED TUTORIAL PLAN `[DEMO]`

> Ngày 1 là ngày 100% scripted. Player không có free action ngoài những gì được hướng dẫn.
> Mỗi step đều có prompt / highlight / arrow chỉ dẫn. Tutorial kết thúc tự nhiên vào cuối Ngày 1.

---

### 1. Controls & Input Map

| Input Action | Key mặc định | Khi nào dùng |
|---|---|---|
| `move_up` | W / ↑ | Di chuyển (Exploration + Workshop) |
| `move_down` | S / ↓ | Di chuyển |
| `move_left` | A / ← | Di chuyển |
| `move_right` | D / → | Di chuyển |
| `interact` | E | Tương tác NPC / Object (Workshop) |
| `inventory` | I | Mở/đóng Inventory overlay |
| `confirm` | Enter | Xác nhận lựa chọn |
| `cancel` | Escape | Hủy / đóng UI |
| `pump_bellows` | Space (hold) | Bơm bễ lò — Phase 1 |
| `hammer_hit` | Space / Enter | Nhát búa — Phase 2 |
| `menu` | Escape | Pause menu (disabled trong cutscene) |

**Lưu ý implementation:**
- `pump_bellows` và `hammer_hit` dùng chung Space nhưng context khác nhau → kiểm tra `current_phase`
- `interact` E chỉ active khi player trong range 48px của object có `Interactable` component
- `cancel` Escape không hoạt động trong dialogue / cutscene (phải nhấn nút UI hoặc confirm)

---

### 2. Movement System

#### Workshop Hub (CharacterBody2D trong xưởng)
```
Speed:         100 px/s (đi bộ bình thường)
			   50 px/s (khi gần furniture/NPC — để không giật camera)
Direction:     8 hướng (normalize vector để không chạy xiên nhanh hơn)
Collision:     CharacterBody2D + move_and_slide()
Stamina cost:  KHÔNG tốn stamina khi ở xưởng
Camera:        Camera2D follow player, limit boundary theo room size
Tilemap:       16×16 tile, room ~20×15 tile
```

#### Exploration Scene (CharacterBody2D trên map ngoài)
```
Speed:         120 px/s (đường đồng bằng / tile thường)
			   70 px/s  (tile địa hình khó: cỏ cao, bùn — TileMap custom data "slow")
Direction:     8 hướng (cùng normalize)
Collision:     CharacterBody2D + move_and_slide()
Stamina cost:  -1 stamina mỗi 3 giây đang di chuyển (Timer chạy khi is_moving)
Stamina = 0:   Disable movement, show label "Hết thể lực!"
			   Force-show nút "Quay về xưởng" (không thể tiếp tục)
Camera:        Camera2D follow + smooth (drag 0.2), clamp theo map boundary
Tilemap:       ~50×40 tile (V1 Đồng Mây), mixed terrain
```

#### Stamina Drain Logic (Pseudo-code)
```gdscript
# Trong ExplorationScene._process(delta):
if velocity.length() > 0:
	_stamina_timer += delta
	if _stamina_timer >= STAMINA_DRAIN_INTERVAL:  # 3.0 giây
		_stamina_timer = 0.0
		GameManager.travel_stamina -= 1
		if GameManager.travel_stamina <= 0:
			_on_stamina_depleted()
```

---

### 3. Interaction System

#### Cách hoạt động
- Mỗi interactable object là Node2D có script `interactable.gd` + Area2D (radius 48px)
- Khi player vào range → emit `player_entered` → show icon "E" (Label hoặc Sprite) trên object
- Khi player ra khỏi range → ẩn icon
- Player nhấn `E` → gọi `interactable.interact(player)` trên object gần nhất theo priority

#### Priority (khi nhiều object cùng range)
```
1. NPC (cao nhất)
2. Lò rèn / Kệ hàng / Hòm đồ
3. Zone exit (cửa ra ngoài)
```

#### Interactable Objects trong Workshop Hub

| Object | Action khi interact |
|---|---|
| Lò rèn | Mở ForgeScene (nếu có nguyên liệu) |
| Kệ trưng bày (3 kệ) | Mở ShelfUI: chọn weapon đặt lên / lấy xuống |
| Hòm đồ / Kho | Mở InventoryUI overlay |
| Cửa ra ngoài | Mở RegionSelectUI → vào ExplorationScene |
| Sổ kế toán / Bàn | Mở PlanningScreen (chỉ active ban đêm) |
| NPC (khi có mặt) | Trigger dialogue |

#### Visual Feedback
- Icon "E" nổi nhấp nháy (AnimationPlayer, 0.5s loop) khi player trong range
- Khi tutorial lock (Ngày 1): object bị lock hiện icon mờ + tooltip "Chưa tới lúc"
- Object đang selected (cursor lên): viền highlight 1px màu vàng

---

### 4. Kịch Bản Ngày 1 — Từng Bước (Scripted Flow)

#### MORNING — Mở màn + Học Forge

**[B1] Màn đen → OpeningSequence.tscn**
```
Thứ tự hiển thị:
  1. Scene card: "Thành phố Thợ Rèn, năm thứ 3 sau Đại Chiến Phương Bắc..."
  2. Narration (text fade in): "Ngươi thừa hưởng lò rèn từ cha — kèm theo một món nợ..."
  3. Scene card: Hình ảnh lò rèn cũ kỹ, đêm tối
  4. Dialogue Bà Trùm Hắc Nguyệt (sprite trái, textbox dưới):
     "Con thừa hưởng được lò rèn của cha. Nhưng tiền mặt bằng thì không ai cho không."
     "4 ngày. 3,000 vàng. Đó là điều duy nhất ta cần từ con."
  5. Nút [Bắt đầu] → vào WorkshopHub (Ngày 1, MORNING)

Input bị lock: chỉ có nút [Tiếp] / [Bắt đầu]
Thời gian ước tính: ~90 giây đọc
```

**[B2] WorkshopHub MORNING — Tutorial Mode ON**
```
Trạng thái: Tutorial lock (chỉ lò rèn có thể interact)
Tất cả object khác: icon mờ, không phản hồi E

Overlay xuất hiện (không block gameplay):
  Arrow chỉ vào lò rèn + text: "Hãy đến lò rèn và rèn vũ khí đầu tiên của ngươi."

Player di chuyển đến lò rèn → nhấn E → vào ForgeScene
```

**[B3] ForgeScene — Phase 1: Nung**
```
Tooltip panel xuất hiện (góc trên phải, không block):
  Tiêu đề: "PHASE 1 — NUNG"
  Nội dung: "Giữ [Space] để bơm bễ. Đưa nhiệt độ vào vùng xanh (60–80%)."
  [Đã hiểu] button → đóng tooltip, bắt đầu mini-game

Heat Bar:
  - Thanh dọc bên trái, 0-100%
  - Sweet spot: 60-80% (viền xanh nhấp nháy)
  - Acceptable: 40-59% và 81-90% (màu vàng)
  - Bad: 0-39% và 91-100% (màu đỏ)
  - Timer: 15 giây (ngày 1 rộng hơn để học)
  - Player giữ Space: tăng +3%/giây; nhả: giảm -1.5%/giây

Kết quả:
  - 60-80% → "Hoàn hảo! (+20% chất lượng)"
  - 40-59% hoặc 81-90% → "Ổn (+0%)"  
  - Ngoài range → "Kém (-20%)"
  - Hiện kết quả 2 giây → Phase 2
```

**[B4] ForgeScene — Phase 2: Rèn búa**
```
Tooltip panel:
  Tiêu đề: "PHASE 2 — RÈN"
  Nội dung: "Nhấn [Space] khi thanh đến vùng PERFECT (xanh). 5 nhát búa quyết định chất lượng!"
  [Đã hiểu] → bắt đầu

Rhythm Bar (5 nhát):
  - Mỗi nhát: marker di chuyển từ trái sang phải (speed tăng dần nhát 1→5)
  - Zones: PERFECT (20% giữa), GOOD (30% hai bên), MISS (ngoài)
  - Score: PERFECT +2, GOOD +1, MISS -1
  - Visual feedback mỗi nhát: flash màu + âm thanh khác nhau
  - Ngày 1: speed marker chậm hơn 30% so với Ngày 2+

Kết quả điểm:
  ≥ 7 → Prefix Tier A ("Bén Ngọt" hoặc "Kiên Cố")
  4-6 → Prefix Tier B ("Nặng Tay")
  1-3 → Prefix Tier C ("Huyền Bí")
  ≤ 0 → Curse affix + Prefix Tier D
  → Advance Phase 3
```

**[B5] ForgeScene — Phase 3: Tôi luyện**
```
Auto-resolve (không input):
  - Animation: nhúng vũ khí vào nguyên tố (Hỏa hoặc Gió — random Ngày 1)
  - Particle effect lửa/gió bao quanh vũ khí
  - Duration: 3 giây animation

WeaponCardUI xuất hiện:
  - Tên vũ khí: "[Prefix] [Phôi] của [Suffix]" (vd: "Kiếm Bén Ngọt của Hỏa")
  - Stats: ATK / DEF / Speed
  - Skill 1 (từ prefix), Skill 2 (từ suffix)
  - Giá ước tính: X vàng
  - Curse badge (nếu có)
  - Nút [Cất vào kho] → weapon vào InventorySystem, về WorkshopHub
```

**[B6] WorkshopHub — C1 Trigger Scene**
```
Cutscene nhỏ (không vào scene khác):
  - Người Thu Nợ Chợ Ngoài xuất hiện ở cửa (sprite + footstep SFX)
  - Dialogue (textbox):
    "Tôi đại diện chủ nhà đất. Tiền thuê mặt bằng lò rèn: 3,000 vàng."
    "Hạn cuối: 4 ngày nữa. Trễ thì cộng thêm 300 vàng phạt."
  
DebtNoticeUI popup:
  - Tiêu đề: "Checkpoint C1 — Tiền Mặt Bằng Lò"
  - Số tiền: 3,000G | Hạn: Ngày 4 chiều | Phạt trễ: +300G
  - Nút [Đã hiểu] → đóng popup
  
Tutorial lock: giờ unlock thêm cửa ra ngoài (explore) và kệ hàng
Nhắc nhở: "Buổi trưa ngắn — Rèn thêm hoặc chờ đến chiều."
Phase advance hint: arrow chỉ vào khu "kệ hàng" + "cửa shop"
```

---

#### NOON — Tự do hạn chế

**[B7] WorkshopHub NOON**
```
Unlock: Lò rèn (rèn thêm nếu muốn)
Lock: Cửa ra ngoài (chưa mở vùng đất Ngày 1)

Hint box nhỏ (không blocking, góc dưới phải):
  "Buổi trưa: Có thể rèn thêm vũ khí. Bấm phím bất kỳ để chuyển sang Chiều."

  → Nếu player rèn thêm: cho phép (optional)
  → Nếu player đến kệ hàng: hint "Chiều mới mở cửa bán được!"
  → Sau 60 giây thực hoặc player tự advance: chuyển AFTERNOON

Advance trigger:
  - Nút [Sang buổi chiều] xuất hiện sau 30 giây (tutorial: không bắt ở lại lâu)
```

---

#### AFTERNOON — Mở shop lần đầu

**[B8] WorkshopHub AFTERNOON — Học đặt hàng lên kệ**
```
Tutorial overlay:
  Arrow chỉ vào kệ trưng bày + text:
  "Đặt vũ khí lên kệ trước khi mở cửa!"

Player đến kệ → nhấn E → ShelfUI:
  - Grid 3 slot (kệ A, B, C)
  - Inventory panel bên phải: danh sách vũ khí trong kho
  - Player kéo/click weapon vào slot kệ
  - Tooltip: "Weapon đặt trên kệ mới được bán. Có thể đặt tối đa 3 vũ khí."
  - Nút [Xong] → đóng ShelfUI

Sau khi đặt ≥ 1 weapon → nút [Mở cửa] xuất hiện (highlight màu vàng)
```

**[B9] ShopScene — Bán hàng lần đầu (khách scripted)**
```
Cảnh shop:
  - Layout 16×12 tile: 3 kệ, quầy thu ngân, cửa ra vào
  - Player đứng sau quầy (vị trí cố định Ngày 1)
  
Hiệp Khách Lang Bạt bước vào (scripted, không random):
  - Animation đi vào từ cửa
  - Browse: nhìn lần lượt các kệ (3 giây/kệ)
  - Tiến đến quầy

Dialogue scripted:
  Hiệp Khách: "Cửa hàng mới à. Kiếm đó giá bao nhiêu?"
  → NegotiationUI xuất hiện

NegotiationUI Tutorial:
  Tooltip: "Kéo slider để đặt giá. 4 vùng: Quá Cao / Hơi Cao / Vừa / Quá Thấp."
  Tooltip nhỏ: "Đặt vào vùng 'Vừa' để chốt deal ngay. 'Hơi Cao' có thể thương lượng."
  [Đã hiểu] → bắt đầu

4-zone slider:
  - Quá Cao (đỏ): khách từ chối ngay
  - Hơi Cao (vàng): khách mặc cả (còn 1-2 lần)
  - Vừa (xanh): khách đồng ý ngay
  - Quá Thấp (xám): bán lỗ, khách vui nhưng player thiệt

Kết quả Ngày 1 (scripted):
  - Nếu player chọn "Vừa": Hiệp Khách đồng ý, gold +X, dialogue "Tốt lắm, sẽ trở lại."
  - Nếu "Hơi Cao": Hiệp Khách mặc cả 1 lần, player điều chỉnh → chốt
  - Nếu "Quá Cao": Hiệp Khách từ chối, dialogue "Đắt quá." → tutorial note xuất hiện

Sau khi bán xong:
  - Sale SFX + gold animation +X
  - Nút [Đóng cửa] xuất hiện
  - Ngày 1 chỉ có 1 khách scripted → không spawn thêm
```

**[B10] Kết thúc Shop → về WorkshopHub**
```
- Fade transition về WorkshopHub (NIGHT phase tự động sau khi đóng cửa)
```

---

#### NIGHT — Kế hoạch + Ngủ

**[B11] Night Phase — Day Summary + Debt Tracker**
```
DaySummaryUI xuất hiện tự động:
  ┌─────────────────────────────┐
  │  KẾT THÚC NGÀY 1            │
  │                             │
  │  Vũ khí bán được: 1         │
  │  Gold kiếm được: +X vàng    │
  │  Gold hiện có: Y vàng       │
  │                             │
  │  📋 Checkpoint C1           │
  │  Cần: 3,000G | Còn: Z ngày  │
  │  Hiện có: Y vàng            │
  │  Còn thiếu: W vàng          │
  │                             │
  │  [Nghỉ ngơi → Sang Ngày 2]  │
  └─────────────────────────────┘

Hint nếu còn thiếu nhiều (W > 2,500G):
  "Ngày mai hãy thử ra ngoài kiếm nguyên liệu và rèn thêm!"

Player nhấn [Nghỉ ngơi]:
  - Save game tự động (SaveSystem.save())
  - Fade to black
  - DayCycle.advance_to_next_day() → Ngày 2 MORNING
  - Travel stamina restore về 14
  - Tutorial lock TẮT → Ngày 2 là free play
```

---

### 5. Tutorial Tooltip System

#### Rules
- Mỗi tooltip chỉ hiện **đúng 1 lần** per mechanic mới
- Theo dõi bằng Dictionary trong GameManager: `tutorial_flags`
- Tooltip **không block toàn màn hình** — chỉ block input liên quan đến mechanic đó
- Luôn có nút **[Đã hiểu]** (không có auto-close timer trừ scene card)
- Tooltip xuất hiện **trước** khi player cần dùng mechanic (preemptive, không reactive)

#### Flags cần implement trong GameManager
```gdscript
var tutorial_flags := {
	"opening_seen":       false,  # Intro cutscene
	"forge_phase1_shown": false,  # Heat bar tooltip
	"forge_phase2_shown": false,  # Rhythm tooltip
	"debt_notice_shown":  false,  # C1 trigger popup
	"shelf_shown":        false,  # Đặt hàng lên kệ
	"bargain_shown":      false,  # NegotiationUI 4 zone
	"inventory_shown":    false,  # Mở inventory (I key)
	"explore_shown":      false,  # Tutorial vùng đất (Ngày 2)
	"combat_shown":       false,  # Combat action menu (Ngày 2)
	"stamina_shown":      false,  # Cảnh báo stamina thấp
}
```

#### Vị trí hiển thị tooltip
```
Forge Phase 1/2:  Góc trên phải màn hình, 300×120px panel
NegotiationUI:    Bên trái slider, 280×100px
Explore/Combat:   Góc dưới giữa, không che action menu
Shelf/Inventory:  Góc trên trái, 280×80px
```

---

### 6. Implementation Checklist — Ngày 1 Tutorial

#### Scripts cần viết / bổ sung
- [ ] `opening_debt_scene.gd` — đủ 3 scene_card + 2 Ba_Trum dialogue + nút Bắt đầu 🔴
- [ ] `workshop_hub.gd` — `tutorial_step` variable, lock/unlock object theo step 🔴
- [ ] `forge_session_ui.gd` — hiện tooltip Phase 1 trước khi bắt đầu heat bar 🔴
- [ ] `forge_session_ui.gd` — hiện tooltip Phase 2 trước khi bắt đầu rhythm 🔴
- [ ] `shop_scene.gd` — Ngày 1 spawn Hiệp Khách scripted thay vì random 🔴
- [ ] `negotiation_ui.gd` — hiện tooltip 4-zone lần đầu (check `tutorial_flags.bargain_shown`) 🔴
- [ ] `day_cycle.gd` — morning_tutorial_done flag để advance NOON đúng lúc 🔴
- [ ] `game_manager.gd` — `tutorial_flags` dict, save/load cùng game state 🔴
- [ ] `interactable.gd` — component dùng chung: Area2D 48px, show/hide icon E, priority 🔴
- [ ] `player_controller.gd` — CharacterBody2D 8-direction, normalize velocity 🔴
- [ ] `player_controller.gd` — stamina timer drain (exploration mode) 🔴
- [ ] `day_summary_ui.gd` — hiện gold earned, weapon count, debt tracker widget 🔴

#### Data cần tạo
- [ ] Lời thoại Bà Trùm intro (5 dòng) trong `GuideBook.gd` hoặc resource 🔴
- [ ] Lời thoại Người Thu Nợ C1 (3 dòng) 🔴
- [ ] Lời thoại Hiệp Khách scripted Ngày 1 (3 dòng) 🔴
- [ ] Tutorial tooltip texts (8 tooltips) — String constants hoặc resource 🟡

#### Scenes / UI cần tạo
- [ ] Tutorial arrow indicator (Node2D + AnimationPlayer) — reusable 🟡
- [ ] Tooltip panel (reusable Control node) — tiêu đề + body + nút Đã hiểu 🟡
- [ ] `ShelfUI.tscn` — 3 slot grid + inventory panel bên phải 🔴
- [ ] `DaySummaryUI.tscn` — gold earned + weapons sold + debt tracker 🔴

#### Input Map (Project Settings → Input Map)
- [ ] Thêm action `pump_bellows` → Space 🔴
- [ ] Thêm action `hammer_hit` → Space, Enter 🔴
- [ ] Thêm action `interact` → E 🔴
- [ ] Thêm action `inventory` → I 🔴
- [ ] Thêm action `confirm` → Enter, Space 🔴
- [ ] Thêm action `cancel` → Escape 🔴
- [ ] Thêm action `move_up/down/left/right` → WASD + Arrow keys 🔴

---

### 7. Ngày 2-4 — Tutorial Fade-out Plan

> Từ Ngày 2, tutorial chuyển sang contextual hints (chỉ hiện khi mechanic xuất hiện lần đầu).

| Ngày | Tutorial Level | Mechanic mới giới thiệu |
|---|---|---|
| Ngày 1 | 100% scripted | Forge 3 phase, Shop cơ bản, Debt C1 |
| Ngày 2 | Hint-only (lần đầu) | Exploration + Combat + Mặc cả nâng cao |
| Ngày 3 | Hint-only (lần đầu) | NPC dialogue, Inventory filter |
| Ngày 4 | Không có tutorial | Free play + Debt deadline pressure |

**Ngày 2 contextual hints (chỉ hiện 1 lần):**
- Khi vào ExplorationScene lần đầu: "Di chuyển bằng WASD. Stamina sẽ giảm theo thời gian."
- Khi gặp enemy lần đầu: "Tấn công từ phía sau để đánh trước với +30% damage!"
- Khi vào CombatScene lần đầu: "Mỗi lượt chọn 1 action: Tấn công / Skill / Chạy."
- Khi mặc cả lần đầu với khách random: "Hãy quan sát loại khách — mỗi loại có ngưỡng giá khác nhau."

---

*GDD Reference: LO_THIENG_PC_GDD.md + GDD_v1.1 + COMBAT_BIBLE_v2*
*Engine: Godot 4 | Solo Dev | Demo: 4 ngày / Full: 52 ngày*
