# 🔥 LÒ THIÊNG — KẾ HOẠCH CODE CHI TIẾT

> **Cách dùng:** Tick `[x]` khi hoàn thành. Copy phần Current Status vào CLAUDE.md sau mỗi session.
> **Priority:** 🔴 Must → 🟡 Should → 🟢 Nice-to-have

---

## PHASE 0 — Foundation
> Mục tiêu: Project chạy được, autoloads hoạt động, data layer sẵn sàng

### Project Setup
- [x] Tạo Godot 4 project, đặt tên `lo_thieng`
- [x] Tạo cấu trúc thư mục đầy đủ (assets, data, scenes, scripts, resources)
- [x] Git init + commit đầu tiên
- [x] Tạo `CLAUDE.md` ở root

### Input Map (Project → Input Map)
- [x] `pump_bellows` — giữ để bơm bễ (Phase 1)
- [x] `hammer_hit` — nhấn theo nhịp (Phase 2)
- [x] `confirm` — xác nhận
- [ ] `cancel` — hủy / quay lại
- [ ] `menu` — mở menu chính
- [ ] `move_up/down/left/right` — di chuyển nhân vật

### Autoloads (scripts/autoload/)
- [x] `GameManager.gd` — game state, day/phase, gold, reputation
- [x] `EventBus.gd` — tất cả signals toàn cục
- [x] `SaveSystem.gd` — read/write JSON save file
- [x] `AudioManager.gd` — music + sfx player
- [x] Đăng ký 4 autoloads trong `Project → Autoload`

### Custom Resource Classes (resources/)
- [x] `WeaponData.gd` — weapon stats, prefix, suffix, mastery, durability
- [x] `ItemData.gd` — material, consumable, quest item
- [x] `NPCData.gd` — NPC info, budget, patience, preferences, schedule
- [x] `SkillData.gd` — skill name, effect type, cost, value, unlock condition
- [x] `QuestData.gd` — quest id, objectives, rewards, giver, trigger

### Scene Skeleton
- [x] `Main.tscn` — root scene, chỉ test autoloads chạy được
- [x] `SceneManager.gd` — chuyển scene có transition

---

## PHASE 1 — Forge System ⚒️
> USP số 1 — ưu tiên cao nhất, polish nhất

### Logic (scripts/systems/)
- [x] `forge_system.gd` — Phase 1: heat bar, pump logic, tier evaluation 🔴
- [x] `forge_system.gd` — Phase 2: rhythm timing, 5 hits, score → prefix tier 🔴
- [x] `forge_system.gd` — Phase 3: auto resolve, apply suffix element 🔴
- [x] `weapon_builder.gd` — combine (phôi + NL + prefix + suffix) → WeaponData 🔴

### Data Files (data/skills/, data/weapons/)
- [x] 12 Prefix data files (.tres) — Bén Ngọt, Kiên Cố, Nặng Tay... 🔴
- [x] 6 Suffix/Element data files (.tres) — Hỏa, Băng, Sét, Độc, Thánh, Bóng Tối 🔴
- [x] 12 Phôi data files (.tres) — Kiếm Đơn, Song Đao, Giáo Dài... 🔴
- [x] Curse affix list (có thể là Array trong forge_system, không cần .tres riêng) 🟡

### UI (scenes/forge/)
- [x] `ForgeScene.tscn` — container scene cho cả 3 phase 🔴
- [x] `ForgePhase1UI.tscn` — heat bar, visual feedback (Lạnh/Cam/Vàng/Quá Nóng) 🔴
- [x] `ForgePhase2UI.tscn` — rhythm bar, 5 hit indicators, Perfect/Good/Miss 🔴
- [x] `ForgePhase3UI.tscn` — animation nhúng nguyên tố, reveal vũ khí 🟡
- [x] `WeaponCardUI.tscn` — hiển thị kết quả vũ khí hoàn chỉnh 🟡

### Kiểm Tra Milestone
- [x] Rèn được 1 vũ khí hoàn chỉnh từ đầu đến cuối
- [x] Prefix thay đổi theo kỹ năng Phase 2
- [x] WeaponData đúng stats sau khi apply multiplier Phase 1

---

## PHASE 2 — Combat System ⚔️
> Cần Forge xong để có weapon skills

### Logic (scripts/systems/)
- [x] `combat_manager.gd` — state machine: PLAYER_TURN → ENEMY_TURN → RESOLVE 🔴
- [x] `player_combat_unit.gd` — HP, Stamina, 3 weapon slots, equip/switch 🔴
- [x] `enemy_combat_unit.gd` — stats, AI archetype field 🔴
- [x] `enemy_ai.gd` — 4 archetypes: Aggressive, Defensive, Caster, Boss 🔴
- [x] `skill_executor.gd` — nhận SkillData, resolve effect lên target 🔴
- [x] `status_effect.gd` — Burn/Freeze/Poison/... tick mỗi turn 🔴

### Data Files (data/skills/)
- [x] 12 Prefix skill .tres files 🔴
- [x] 6 Suffix skill .tres files 🔴
- [ ] 7 Universal skill .tres files 🔴
- [x] ~30 Enemy data files (.tres) 🟡

### UI (scenes/combat/)
- [x] `CombatScene.tscn` — side-view layout, player trái / enemy phải 🔴
- [x] `CombatUI.tscn` — action menu (Attack/Skill1/Skill2/Item), HP bars, Stamina 🔴
- [ ] Turn order indicator 🟡
- [ ] Boss telegraph icon (hiện trước lượt boss) 🟡
- [x] Win/Lose screen + reward display 🔴

### Kiểm Tra Milestone
- [x] Đánh được 1 trận 3-5 lượt, dùng được cả 2 skill từ vũ khí
- [x] Enemy AI hành động đúng archetype
- [x] Lose → về xưởng, mất 30% gold

---

## PHASE 3 — Shop System 🏪
> Cần Weapon để có thứ bán

### Logic (scripts/systems/)
- [x] `shop_manager.gd` — timer buổi chiều, customer queue, open/close 🔴
- [x] `customer_ai.gd` — walk in, browse shelf, approach counter 🔴
- [x] `negotiation_ui.gd` — 4 vùng giá, Patience counter, resolve sale 🔴
- [X] `shop_shelf.gd` — 3 slot kệ, đặt/lấy vũ khí 🔴 (đã tích hợp vào Shopscene.gf)

### Data Files
- [x] Customer preference tags cho NPCData (preferred_weapon_tags) 🔴
- [ ] 30+ Regular customer .tres files 🟡

### UI (scenes/shop/)
- [x] `ShopScene.tscn` — layout 16×12 tile: kệ, quầy, cửa 🔴
- [x] `BargainingUI.tscn` — khách đề xuất giá, player input giá, phản ứng khách 🔴
- [ ] Shop timer HUD 🟡
- [ ] Shop decoration unlock theo Reputation 🟢

### Kiểm Tra Milestone
- [x] Bán được 1 vũ khí cho 1 khách qua mặc cả
- [x] Patience về 0 → khách bỏ đi đúng
- [ ] Gold cộng đúng sau sale

---

## PHASE 4 — Exploration 🗺️
> Cần Combat để test random encounter

### Logic (scripts/)
- [ ] `player_controller.gd` — top-down movement, stamina travel 🔴
- [ ] `gathering_node.gd` — loot table, respawn timer (2-3 ngày) 🔴
- [ ] `encounter_manager.gd` — trigger rate, transition vào CombatScene 🔴

### Maps (scenes/world/)
- [ ] `RegionDongMay.tscn` — Đồng Mây Trắng (region 1, default open) 🔴
- [ ] `RegionRungTramHon.tscn` — Rừng Trăm Hồn (mở ngày 3) 🟡
- [ ] `RegionNuiThanDo.tscn` — Núi Than Đỏ (Reputation 3) 🟡
- [ ] `RegionBaiCat.tscn` — Bãi Cát Thần Vàng (Reputation 5) 🟡
- [ ] `RegionThanhNgoc.tscn` — Thành Ngọc Bích (Reputation 7) 🟡
- [ ] `RegionLangTo.tscn` — Làng Tổ Nghề (Quest cuối) 🟡

### UI
- [ ] `ExplorationHUD.tscn` — stamina bar, minimap, compass 🟡

### Kiểm Tra Milestone
- [ ] Di chuyển được trong Đồng Mây, nhặt được 3 node nguyên liệu
- [ ] Random encounter trigger → vào combat → thắng → về map
- [ ] Stamina hết → force return về xưởng

---

## PHASE 5 — Game Loop & Systems 🔄
> Kết nối tất cả các system lại

### Core Loop
- [ ] `day_cycle.gd` — chuyển MORNING→NOON→AFTERNOON→NIGHT, events mỗi phase 🔴
- [ ] `economy_system.gd` — debt stages (5k/15k/30k), repayment, game over check 🔴
- [ ] `inventory_system.gd` — hand limit 12, warehouse unlimited, filter by type 🔴
- [ ] `InventoryUI.tscn` — grid 6 cột, filter tabs, item tooltip 🔴

### NPC & Quest
- [ ] `npc_schedule.gd` — NPC chỉ xuất hiện đúng vùng/thời gian 🔴
- [ ] `npc_affinity.gd` — 0-100, tăng/giảm theo actions, unlock quest/recipe 🔴
- [ ] `quest_system.gd` — load QuestData, track objectives, complete/fail 🔴
- [ ] `QuestJournal.tscn` — tabs: Main/Side/Daily/Hidden 🔴
- [ ] `artifact_system.gd` — track 18 artifacts, trigger win condition 🟡

### Progression
- [ ] Reputation gates (mở region, NPC, recipe) trong GameManager 🔴
- [ ] Smithing Mastery tăng mỗi lần forge xong 🔴
- [ ] Universal skill unlock theo Reputation/Mastery 🟡

### Kiểm Tra Milestone (Vertical Slice ✅)
- [ ] Chơi được 1 ngày đầy đủ: Sáng → Trưa → Chiều → Đêm
- [ ] Save/Load hoạt động
- [ ] Nợ Stage 1 tick đếm đúng

---

## PHASE 6 — Content & Polish ✨

### Data Content
- [ ] 80 items data hoàn chỉnh 🔴
- [ ] 25 Skills balance (spreadsheet test trước) 🔴
- [ ] 30 NPC data + dialogue ~3,000 lines 🔴
- [ ] 25 main + side quests 🔴
- [ ] 18 Artifact quests 🔴
- [ ] 10 NPC personal quests 🟡
- [ ] 5 Hidden quests 🟡

### Tutorial
- [ ] Ngày 1 scripted (Bà Trùm intro, combat hình nộm, khách cố định) 🔴
- [ ] Ngày 2 (mặc cả thật, combat thật, Curse có thể xảy ra) 🔴
- [ ] Ngày 3 (Lão Gà Chọi, Quest Journal, Di Vật hint) 🔴
- [ ] Contextual tooltips (new mechanic lần đầu) 🟡
- [ ] "Bí Kíp Rèn" book object — advanced tutorial 🟡

### Endings & Meta
- [ ] Ending A — True Ending (12 Di Vật + #158 + Reputation 10) 🔴
- [ ] Ending B — Người Thợ Tự Do (trả hết nợ, thiếu Di Vật) 🔴
- [ ] Ending C — Bóng Đêm Lò Cũ (nợ 2 lần → route ngầm) 🟡
- [ ] Ending D — Phá Sản (3 ngày tiền = 0) 🔴
- [ ] Epilogue cutscene x4 🟡
- [ ] New Game+ 🟢

### UI/UX Polish
- [ ] Main Menu + Settings 🔴
- [ ] Difficulty selection screen (Story/Normal/Hardcore) 🔴
- [ ] Pause menu 🔴
- [ ] Game Over screen 🔴
- [ ] Achievement system (50+) 🟢
- [ ] Photo Mode 🟢

### Audio
- [ ] 8-10 music tracks tích hợp 🟡
- [ ] ~80 SFX 🟡
- [ ] Ambient sounds per region 🟢

---

## DEPENDENCY MAP

```
Phase 0 (Foundation)
	↓
Phase 1 (Forge) ──────── USP #1, test sớm nhất
	↓
Phase 2 (Combat) ──────── cần weapon skills từ Forge
	↓
Phase 4 (Exploration) ─── cần Combat cho random encounter
	↓
Phase 3 (Shop) ─────────── cần Weapon để bán
	↓
Phase 5 (Game Loop) ────── kết nối tất cả
	↓
Phase 6 (Content) ──────── điền data, balance, polish
```

---

## VERTICAL SLICE TARGET (Milestone M5)

> Chơi được 1 ngày đầy đủ trước khi mở rộng content

```
✅ Sáng  : Vào Đồng Mây, nhặt 3 nguyên liệu, thắng 1 combat
✅ Trưa  : Forge 3 phase, ra 1 vũ khí có prefix + suffix
✅ Chiều : Mở shop, 3 khách, 1 lần mặc cả thành công
✅ Đêm   : Xem tổng kết, lưu game, sang ngày 2
```

---

## CURRENT STATUS
> Cập nhật sau mỗi session — copy vào CLAUDE.md

### Phase 0
- [ ] Project setup
- [ ] Input Map
- [ ] Autoloads
- [ ] Resource classes (WeaponData, ItemData, NPCData, SkillData, QuestData)
- [ ] Main scene + SceneManager

### Phase 1
- [ ] forge_system.gd Phase 1
- [ ] forge_system.gd Phase 2
- [ ] forge_system.gd Phase 3
- [ ] weapon_builder.gd
- [ ] Forge UI

### Phase 2
- [ ] Combat Manager + Units
- [ ] Skill Executor + Status Effects
- [ ] Combat UI + Scene

### Phase 3
- [ ] Shop Manager + Customer AI
- [ ] Bargaining System + UI

### Phase 4
- [ ] Player Controller + Gathering
- [ ] Region 1 (Đồng Mây) playable

### Phase 5
- [ ] Day Cycle
- [ ] Inventory System
- [ ] Quest System
- [ ] Economy/Debt System

### Phase 6
- [ ] Content complete
- [ ] Tutorial complete
- [ ] 4 Endings
- [ ] Polish done

---

*GDD Reference: LO_THIENG_PC_GDD.md | Engine: Godot 4 | Solo Dev*
