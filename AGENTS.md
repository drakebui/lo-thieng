# AGENTS.md — Lò Thiêng: Hướng dẫn cho Codex

## Môi trường

- **Engine:** Godot 4.x — KHÔNG có binary `godot` / `godot4` trong shell
- **Ngôn ngữ:** GDScript (`.gd`)
- **Validation:** Dùng `gdtoolkit` thay thế Godot engine

## Setup (chạy một lần đầu session)

```bash
pip install gdtoolkit --quiet
```

## Quy trình sau mỗi lần sửa / tạo file `.gd`

```bash
gdlint <đường_dẫn_file.gd>
```

Nếu `gdlint` pass (không có ERROR) → coi như hợp lệ về syntax.
`gdlint` không bắt được lỗi runtime — tự review logic bằng cách đọc lại file.

---

## Cấu trúc thư mục quan trọng

```
scripts/autoload/     — GameManager.gd, EventBus.gd, SaveSystem.gd, AudioManager.gd, InventorySystem.gd, SceneManager.gd
scripts/forge/        — forge_system.gd, forge_phase*.gd, weapon_builder_ui.gd
scripts/combat/       — combat_manager.gd, combatant.gd, skill_executor.gd, enemy_ai.gd, status_effect.gd
scripts/shop/         — shop_manager.gd, customer_ai.gd, negotiation_ui.gd, player_shop.gd
scripts/regions/      — exploration_scene.gd
scripts/main/         — workshop_hub.gd
scripts/ui/           — day_summary_ui.gd, inventory_ui.gd, weapon_card_ui.gd, region_select_ui.gd
resources/            — WeaponData.gd, itemData.gd, NPCData.gd, SkillData.gd, QuestData.gd (Resource classes)
data/                 — ItemDatabase.gd, EnemyDatabase.gd, NPCDatabase.gd, SkillDatabase.gd
scenes/               — .tscn files (KHÔNG sửa trực tiếp bằng text editor)
```

---

## Autoloads — singleton toàn game

| Tên | Vai trò |
|-----|---------|
| `GameManager` | gold, reputation, phase, day, stamina, weapons |
| `EventBus` | tất cả signals cross-system |
| `SaveSystem` | `save_game(dict)` / `load_game()` → JSON |
| `AudioManager` | music + sfx |
| `InventorySystem` | kho + túi đồ |
| `SceneManager` | `go_to(path)` chuyển scene có transition |

Giao tiếp giữa các system: **dùng EventBus signal**, không gọi trực tiếp node của nhau.

---

## Quy ước bắt buộc

| Đối tượng | Quy ước |
|-----------|---------|
| File script | `snake_case.gd` |
| File scene | `PascalCase.tscn` |
| Biến / hàm | `snake_case` |
| Hằng số | `SCREAMING_SNAKE_CASE` |
| Signal | `snake_case` dạng quá khứ (`weapon_forged`, `sale_completed`) |
| Hàm private | bắt đầu `_` (`_calculate_damage()`) |
| Comment | tiếng Việt |
| Tên biến/hàm | tiếng Anh |

---

## Signals đã có trong EventBus

```gdscript
signal phase1_completed(result_tier: String)
signal phase2_completed(score: int, prefix_tier: String)
signal phase3_completed(weapon_result: Dictionary)
signal weapon_forged(weapon_data)
signal weapon_sold(weapon_data, price: int)
signal quest_completed(quest_id: String)
signal artifact_collected(artifact_id: int)
signal combat_started(enemy_data)
signal combat_ended(result: String)          # "win" | "lose" | "run"
signal npc_affinity_changed(npc_id: String, new_value: int)
signal shop_opened
signal shop_closed(session_stats: Dictionary) # {gold_earned, customers_served, customers_visited}
signal customer_served(customer_id: String, gold: int)
signal region_entered(region_id: String)
signal region_exited(region_id: String)
signal gathering_node_collected(material: Dictionary)
signal travel_stamina_depleted()
signal encounter_triggered(enemy_data: Dictionary)
```

Khi cần signal mới: khai báo trong `EventBus.gd` trước, sau đó dùng.

---

## Các lệnh API thông dụng

```gdscript
# Gold
GameManager.add_gold(amount)
GameManager.gold                         # đọc

# Phase / Day
GameManager.change_phase(GameManager.GamePhase.NOON)
GameManager.advance_day()

# Stamina
GameManager.consume_travel_stamina(1)    # trả false nếu hết
GameManager.travel_stamina

# Weapon
GameManager.add_weapon(weapon_dict)
GameManager.forged_weapons

# Scene
SceneManager.go_to("res://scenes/forge/MaterialPicker.tscn")

# Save
SaveSystem.save_game(state_dict)
SaveSystem.load_game()                   # trả Dictionary
SaveSystem.has_save()                    # trả bool
```

---

## Những điều KHÔNG làm

- **Không sửa file `.tscn`** bằng text editor — dễ corrupt, chỉ sửa qua Godot Editor
- **Không tạo autoload mới** ngoài 6 cái đã có
- **Không hard-code data** (tên NPC, stats item) trực tiếp trong script — dữ liệu phải ở `.tres` resource hoặc Database
- **Không dùng `get_node()` absolute path** giữa các scene khác nhau — dùng EventBus
- **Không xóa hoặc rename** file đang tồn tại nếu task không yêu cầu rõ ràng

---

## Khi nhận task

1. Đọc task, xác định file cần sửa / tạo
2. Đọc file hiện tại trước khi sửa
3. Kiểm tra xem signal / method đã có chưa trước khi thêm mới
4. Sau khi sửa: chạy `gdlint <file.gd>`
5. Nếu gdlint có ERROR → sửa trước khi báo xong
6. Báo cáo: file nào đã sửa, thay đổi gì, gdlint kết quả ra sao
