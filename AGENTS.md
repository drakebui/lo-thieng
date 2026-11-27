# 🔥 AGENTS.md — LÒ THIÊNG: CHỈ DẪN KỸ THUẬT CHO AI AGENTS
> **Tài liệu tham chiếu kỹ thuật và chuẩn code bắt buộc cho mọi AI Agent (Antigravity, Codex, Claude).**
> **Game Design Bible:** Xem tại [docs/GAME_DESIGN_MASTER.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/docs/GAME_DESIGN_MASTER.md)
> **Trạng thái & Tiến độ:** Xem tại [docs/PROJECT_STATE.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/docs/PROJECT_STATE.md)

---

## 1. MÔI TRƯỜNG & CÔNG CỤ XÁC THỰC

- **Engine:** Godot 4.x (GDScript)
- **Khởi động Editor nhanh:** Chạy file `open_godot.bat` ở thư mục gốc để mở Godot Editor.
- **Công cụ kiểm tra cú pháp (Syntax Validation):**
  ```bash
  gdlint <đường_dẫn_file.gd>
  ```
- **Bộ kiểm tra tĩnh toàn dự án (Static Integrity Check):**
  ```bash
  python scripts/tools/static_check.py
  ```
  *(Quét toàn bộ 8 hạng mục: Dead code, Broken signals, Node paths, Missing resources...)*

---

## 2. CẤU TRÚC THƯ MỤC CHUẨN

```
scripts/autoload/     — 6 Singletons: GameManager, EventBus, SaveSystem, AudioManager, InventorySystem, SceneManager
scripts/characters/   — BaseCharacter.gd (Lớp cơ sở kế thừa cho Player, NPC, Enemy)
scripts/forge/        — forge_system.gd, forge_phase*.gd, weapon_builder_ui.gd
scripts/combat/       — combat_manager.gd, combatant.gd, skill_executor.gd, enemy_ai.gd, status_effect.gd
scripts/shop/         — shop_manager.gd, customer_ai.gd, negotiation_ui.gd, player_shop.gd
scripts/regions/      — exploration_scene.gd
scripts/main/         — workshop_hub.gd
scripts/ui/           — day_summary_ui.gd, inventory_ui.gd, weapon_card_ui.gd, region_select_ui.gd
scripts/tools/        — static_check.py, smoke_test.gd
resources/            — WeaponData.gd, itemData.gd, NPCData.gd, SkillData.gd, QuestData.gd
data/                 — ItemDatabase.gd, EnemyDatabase.gd
scenes/               — .tscn scenes (TUYỆT ĐỐI KHÔNG sửa file .tscn bằng text editor)
assets/pixel/         — Sprites 32-bit Hoả Tâm, Spritesheets 64×64, Backgrounds 640×360
assets/audio/         — Nhạc nền (.ogg) và SFX (.wav)
docs/                 — GAME_DESIGN_MASTER.md, PROJECT_STATE.md, STORY_AND_DIALOGUE.md, archive/
```

---

## 3. 6 AUTOLOADS (SINGLETONS TOÀN GAME)

| Tên | Vai trò chính |
|-----|---------------|
| `GameManager` | Quản lý vàng (`gold`), danh tiếng (`reputation`), buổi trong ngày (`GamePhase`), ngày (`day`), thể lực (`travel_stamina`), kho vũ khí đã rèn |
| `EventBus` | Trung tâm kết nối Signals liên hệ thống (Cross-system communication) |
| `SaveSystem` | Lưu / Đọc file JSON (`save_game(dict)`, `load_game()`, `has_save()`) |
| `AudioManager` | Quản lý nhạc nền và hiệu ứng âm thanh (`play_music()`, `play_sfx()`) |
| `InventorySystem` | Quản lý túi đồ, rương kho và kệ tiệm 3 ô (`move_to_shelf()`) |
| `SceneManager` | Quản lý chuyển scene có hiệu ứng transition (`go_to(path)`) |

> ⚠️ **Quy tắc vàng:** Các Scene và Controller giao tiếp với nhau **100% qua EventBus Signals**, không gọi trực tiếp node của nhau bằng path tuyệt đối!

---

## 4. SIGNALS CHUẨN TRONG EVENTBUS

```gdscript
# Lò rèn 3 Phase
signal phase1_completed(result_tier: String)
signal phase2_completed(score: int, prefix_tier: String)
signal phase3_completed(weapon_result: Dictionary)
signal weapon_forged(weapon_data)
signal weapon_sold(weapon_data, price: int)

# Khám phá & Chiến đấu
signal region_entered(region_id: String)
signal region_exited(region_id: String)
signal gathering_node_collected(material: Dictionary)
signal travel_stamina_depleted()
signal encounter_triggered(enemy_data: Dictionary)
signal combat_started(enemy_data)
signal combat_ended(result: String)          # "win" | "lose" | "run"

# Tiệm & Khách hàng
signal shop_opened
signal shop_closed(session_stats: Dictionary) # {gold_earned, customers_served, customers_visited}
signal customer_served(customer_id: String, gold: int)
signal npc_affinity_changed(npc_id: String, new_value: int)

# Nhiệm vụ & Cổ khí
signal quest_completed(quest_id: String)
signal artifact_collected(artifact_id: int)
```

---

## 5. QUY CHUẨN ĐỒ HỌA 32-BIT & BASE CHARACTER

Tất cả nhân vật có thể di chuyển (Player Nấm, NPCs, Quái Overworld) **phải kế thừa từ `BaseCharacter`** (`scripts/characters/base_character.gd`):
- **Khung hình Spritesheet:** Ô lưới `64×64 px`, bảng màu Hoả Tâm 96 màu.
- **Điểm neo bàn chân (Foot Baseline):** Tọa độ `(32, 60)` trong frame $\to$ ánh xạ về `(0, 0)` trong local coordinates với `sprite.offset = Vector2(0.0, -28.0)`.
- **Va chạm bàn chân (`CollisionShape2D`):** Dạng nằm ngang `CapsuleShape2D(34×18 px)` neo tại chân `y = 0.0`.
- **Bóng tiếp đất (`ContactShadow`):** Hình oval `Polygon2D` màu `SHADOW_COLOR = Color(0.06, 0.03, 0.04, 0.42)` tại `(0, 0)`.
- **Điều khiển 4 hướng chuẩn:** `down`, `up`, `right`, `left` (tự động `flip_h` khi hướng trái).
- **Điểm neo Bong bóng Thoại (`EmoteAnchor`):** Neo tại `(0, -56)`.
- **Tỷ lệ hiển thị trong Scene:** Nấm scale `3.0×` (~170px), NPCs scale `2.75×` (~162px).

---

## 6. QUY ƯỚC LẬP TRÌNH & ĐẶT TÊN (CODING DISCIPLINE)

| Đối tượng | Quy ước | Ví dụ |
|-----------|---------|-------|
| Tệp Script | `snake_case.gd` | `forge_system.gd`, `customer_ai.gd` |
| Tệp Scene | `PascalCase.tscn` | `WorkshopHub.tscn`, `ShopScene.tscn` |
| Biến / Hàm | `snake_case` | `travel_stamina`, `calculate_price()` |
| Hằng số | `SCREAMING_SNAKE_CASE` | `MAX_STAMINA`, `HEAT_DECAY_RATE` |
| Signal | `snake_case` dạng quá khứ | `weapon_forged`, `customer_served` |
| Hàm private | Bắt đầu dấu `_` | `_update_heat()`, `_apply_discount()` |
| Ngôn ngữ Comment | **Tiếng Việt** rõ nghĩa | `# Bơm bễ tăng nhiệt` |
| Tên biến & code | **Tiếng Anh chuẩn** | `is_running`, `heat_level` |

---

## 7. ĐIỀU TUYỆT ĐỐI KHÔNG LÀM (NEVER DO)

1. ❌ **Không sửa trực tiếp file `.tscn`** bằng trình soạn thảo văn bản — rất dễ làm hỏng cấu trúc UID và cây node của Godot. Chỉ chỉnh sửa scene qua Godot Editor.
2. ❌ **Không tạo thêm Autoload mới** ngoài 6 cái đã có.
3. ❌ **Không hard-code dữ liệu** (chỉ số vũ khí, quái vật, giá bán) trực tiếp trong script — dữ liệu phải nằm trong `.tres` Resource hoặc Database.
4. ❌ **Không dùng `get_node()` đường dẫn tuyệt đối** giữa các Scene khác nhau.
5. ❌ **Không xóa hoặc đổi tên file tùy tiện** mà không cập nhật các nơi tham chiếu.
6. ❌ **TUYỆT ĐỐI KHÔNG DÙNG LẠI HOẶC VẼ ART MỚI BỌC XUNG QUANH ASSETS CŨ (ZERO LEGACY ASSET REUSE):** Toàn bộ thư mục cũ (`assets/weapons/`, `assets/UI/`, `assets/sprites/`, `assets/characters/`) **chỉ dùng để đọc ý tưởng / danh sách vật phẩm (concept reference)**, không được load hiển thị trong game, không giữ `FALLBACK_PATH` về ảnh cũ, và không lấy khung/bục/lò 32-bit mới bọc bên ngoài icon vũ khí hay nguyên liệu cũ. Mọi hình ảnh hiển thị phải thuộc bộ **32-bit Hoả Tâm tạo mới 100% trong `res://assets/pixel/`** (xem thêm [docs/PITFALLS.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/docs/PITFALLS.md)).

---

## 8. QUY TRÌNH KHI THỰC HIỆN TASK DÀNH CHO AGENT

1. Đọc kỹ yêu cầu task và kiểm tra [docs/PROJECT_STATE.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/docs/PROJECT_STATE.md) để nắm tiến độ và cạm bẫy cần tránh.
2. Đọc các file liên quan trước khi sửa; kiểm tra Signals và APIs đã tồn tại hay chưa.
3. Thực hiện sửa đổi nhỏ nhất, an toàn nhất (Smallest complete & safe change).
4. Sau khi sửa:
   - Chạy `gdlint <file.gd>` kiểm tra cú pháp.
   - Chạy `python scripts/tools/static_check.py` để đảm bảo không gãy liên kết toàn dự án.
5. Báo cáo ngắn gọn, rõ ràng bằng tiếng Việt cho người dùng (kèm link file mở được `file://...`).
