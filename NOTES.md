# NOTES.md — Codex Session Log
> Codex cập nhật file này sau MỖI session.
> Engineering Lead (Claude) đọc file này khi review.

---

## Template — copy và điền sau mỗi session:

```
## Session [số] — [ngày]

### Task đã làm
- [P4-X] tên task — DONE / IN PROGRESS / BLOCKED

### Files tạo mới
- path/to/file.gd — [mô tả 1 dòng]

### Files đã sửa
- path/to/file.gd — [dòng X-Y, lý do sửa]

### Vấn đề gặp phải
- [mô tả nếu có, hoặc "Không có"]

### Chưa làm được (nếu BLOCKED)
- [lý do blocked]

### Cần Engineering Lead chú ý
- [file cụ thể hoặc logic cụ thể cần review kỹ]
```

---

<!-- Codex bắt đầu ghi từ đây -->

## Session 1 — 2026-05-13

### Task đã làm
- [P4-Encounter] Fix quái không trigger khi player vào vùng — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/regions/exploration_scene.gd — dòng 27-28, chỉnh nhịp encounter về 4.0 giây và 40% để tránh combat quá dày
- scripts/regions/exploration_scene.gd — dòng 346-363, gắn Area2D trước khi set collision/mask, bật monitoring rõ ràng, thêm grace period 2 giây khi vào zone
- scripts/regions/exploration_scene.gd — dòng 380-383, giữ player trong encounter zone khi hết thể lực và hiển thị feedback rõ ràng
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Review pacing `ENC_INTERVAL = 4.0`, `ENC_CHANCE = 0.40`, grace period 2 giây trong scripts/regions/exploration_scene.gd để xác nhận nhịp encounter phù hợp với thiết kế.

## Session 2 — 2026-05-13

### Task đã làm
- [P4-Encounter] Trigger quái ngay khi player bước vào zone — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/regions/exploration_scene.gd — dòng 367-388, bỏ grace period/chance cho lần body_entered đầu tiên và gọi encounter ngay
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Review cảm giác gameplay vì lần đầu bước vào zone giờ luôn vào combat nếu còn thể lực và zone chưa clear.

## Session 3 — 2026-05-13

### Task đã làm
- [P4-Combat] Bỏ chạy tốn stamina tổng — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/combat/combat_manager.gd — nhánh player chọn run, trừ 1 GameManager.travel_stamina và truyền số stamina đã tốn vào reward data
- scripts/combat/combat_scene.gd — result overlay của bỏ chạy hiển thị số thể lực đã tốn
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Review rule khi travel_stamina đã bằng 0: hiện tại vẫn cho bỏ chạy, nhưng không trừ thêm và không hiển thị dòng tốn thể lực.

## Session 4 — 2026-05-13

### Task đã làm
- [P4-Stamina] Refactor travel stamina sang entry cost theo Phương án B — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/autoload/GameManager.gd — thêm `REGION_ENTRY_COST`, tăng stamina lên 14, thay `consume_travel_stamina()` bằng API entry-cost
- scripts/regions/exploration_scene.gd — trừ stamina khi enter region, bỏ stamina cost khỏi gather/combat, thêm `entry_paid`, cập nhật HUD cost
- scripts/combat/combat_manager.gd — bỏ call cũ tới `consume_travel_stamina()` để project không gọi API đã xóa và combat không tốn stamina tổng
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- `scripts/combat/combat_manager.gd` còn gọi `GameManager.consume_travel_stamina()` từ task trước; phải bỏ call này vì API đã bị xóa theo refactor.
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Màn chọn vùng vẫn chưa check `GameManager.can_enter_region(region_id)` trước khi navigate; đây là task riêng theo scope.

## Session 5 — 2026-05-13

### Task đã làm
- [P4-Combat] Sau khi thắng, bỏ option đánh lại và hiển thị bảng chiến lợi phẩm — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/combat/combat_scene.gd — ẩn nút đánh lại khi thắng, chặn phím R sau win, đổi result body sang bảng chiến lợi phẩm nhận được
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Review nội dung result body khi loot table rỗng: hiện hiển thị `Vật phẩm: Không có`.

## Session 6 — 2026-05-13

### Task đã làm
- [P4-Exploration] Restore vị trí player sau khi quay lại khám phá từ combat — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/regions/exploration_scene.gd — lưu `player_position` trước khi vào combat và restore vị trí đó khi reload ExplorationScene
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Review trường hợp player đứng trong zone vừa clear: zone được hide/disable sau khi build nên không nên re-trigger.

## Session 7 — 2026-05-13

### Task đã làm
- [P4-RegionSelect] Hiển thị chi phí stamina và khóa nút Xuất Phát khi không đủ thể lực — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/ui/region_select_ui.gd — trong `_build_card()`, thêm cost label, check `GameManager.can_enter_region()`, disable nút khi thiếu thể lực và hiển thị lý do
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- `gdlint` không có trong shell nên chưa chạy được lint theo yêu cầu.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Review layout card nếu text cost + lý do làm card quá chật ở độ phân giải thấp.

## Session 8 — 2026-05-13

### Task đã làm
- [P4-RegionSelect] Fix layout card chật ở độ phân giải thấp — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/ui/region_select_ui.gd — trong `_build_card()`: margin 18→12, separation 10→6, font name 38→32, desc 24→20, status 26→22, cost 22→20, btn 30→26; gộp `no_sta_lbl` vào text button disabled (bỏ 1 row thừa khi không đủ thể lực)
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Kiểm tra visual thực tế trên màn 1280×720: card giờ có tối đa 5 rows (name + desc + status + cost + btn), cần xác nhận vừa vặn và font vẫn đọc được.

## Session 9 — 2026-05-13

### Task đã làm
- [P4-Exploration] Randomize vị trí enemy trigger cho mỗi lượt exploration — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/regions/exploration_scene.gd — thay 3 trigger zone cố định bằng vị trí random theo session, lưu `enemy_zone_grids` vào exploration_state để restore ổn định sau combat
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Review khả năng trigger zone random overlap với obstacle vì hiện chỉ tránh spawn player, exit, và tránh các trigger quá gần nhau.

## Session 10 — 2026-05-13

### Task đã làm
- [P4-Inventory/Forge] Nối loop exploration loot → kho vật liệu → forge consume material → weapon bán được — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/autoload/InventorySystem.gd — thêm kho `materials`, signal `material_added`, API add/remove/get/has material
- scripts/regions/exploration_scene.gd — chuyển material/blank từ `GameManager.hand_inventory` vào `InventorySystem` khi rời vùng, sau đó `clear_hand()`
- scripts/forge/material_picker_ui.gd — đọc material từ `InventorySystem.get_materials()` và hiển thị empty-state khi kho trống
- scripts/forge/forge_session_ui.gd — consume material đã chọn sau khi weapon được lưu vào kho
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Finalize forge thực tế nằm ở `forge_session_ui.gd::_on_save_pressed()`, không nằm trong `forge_system.gd`.
- Không có Godot CLI trong shell nên chưa chạy được validation bằng engine.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- `InventorySystem.materials` chưa được đưa vào SaveSystem theo đúng constraint; cần task riêng nếu muốn persist kho vật liệu qua save/load.

## Session 11 — 2026-05-13

### Task đã làm
- [P4-Save] Persist kho vật liệu qua SaveSystem — DONE
- [P4-Exploration] Không spawn enemy encounter zone trên obstacle — DONE
- [P4-Validation] Thiết lập gdtoolkit/gdlint và lint các file đã sửa qua 10 session — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/autoload/SaveSystem.gd — thêm key `materials` khi save và restore `InventorySystem.materials` khi load
- scripts/regions/exploration_scene.gd — thêm `ENEMY_SPAWN_RETRIES`, validate grid spawn bằng physics query mask obstacle layer 4, fallback gần trung tâm map nếu hết retry
- scripts/autoload/InventorySystem.gd — reorder signal/const/var để pass `class-definitions-order`, giữ nguyên API materials hiện có
- scripts/combat/combat_manager.gd — reorder top-level definitions và giảm số return trong `_enter_enemy_turn()` để pass gdlint, không đổi flow combat
- scripts/combat/combat_scene.gd — reorder `_ENEMY_CYCLE` lên vùng const để pass gdlint
- scripts/forge/forge_session_ui.gd — reorder enum `Phase` lên trước const để pass gdlint
- scripts/ui/region_select_ui.gd — tách các dòng dài trong `REGIONS`, stamina label và border color để pass gdlint
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Shell không có lệnh `pip`; đã cài gdtoolkit bằng `python3 -m pip install gdtoolkit --quiet`.
- `gdlint` được cài ở `/Users/minhchau/Library/Python/3.9/bin`, chưa nằm trong PATH mặc định; validation dùng full path hoặc PATH prefix.
- `InventorySystem.materials` trong code hiện tại là `Array[Dictionary]`, không phải dict quantity như mô tả prompt; SaveSystem persist đúng cấu trúc thực tế để không phá material picker/forge flow.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Obstacle detection trong `exploration_scene.gd` dùng `PhysicsDirectSpaceState2D.intersect_shape()` vì scene không dùng TileMap; obstacle/tường hiện là `StaticBody2D` layer 4.
- `gdlint 4.5.0` đã pass cho: `scripts/regions/exploration_scene.gd`, `scripts/combat/combat_scene.gd`, `scripts/combat/combat_manager.gd`, `scripts/autoload/GameManager.gd`, `scripts/autoload/InventorySystem.gd`, `scripts/ui/region_select_ui.gd`, `scripts/forge/material_picker_ui.gd`, `scripts/forge/forge_session_ui.gd`, và thêm `scripts/autoload/SaveSystem.gd`.

## Session 12 — 2026-05-13

### Task đã làm
- [P4-Save] Gọi load save khi vào WorkshopHub và restore state vào GameManager — DONE
- [P4-Exploration] Defer enemy spawn để physics obstacle query thấy StaticBody2D mới add — DONE
- [P4-RegionSelect] Kiểm tra/rút gọn chiều cao card vùng ở 1280×720 — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/autoload/GameManager.gd — thêm `save_restored` và `restore_from_save(data)` để restore day/gold/reputation/mastery/artifact/stamina/unlocked_regions/forged_weapons, clamp stamina và emit signal state
- scripts/main/workshop_hub.gd — gọi `SaveSystem.load_game()` + `GameManager.restore_from_save()` trong `_ready()` trước khi build UI, có guard chỉ restore một lần; đồng thời rename biến layout động sang `snake_case` để pass gdlint
- scripts/regions/exploration_scene.gd — thêm `_pending_meta` và chuyển `_build_enemies()` sang `call_deferred()` sau `_build_map()` để physics state có obstacle bodies trước khi query
- scripts/ui/region_select_ui.gd — giới hạn desc label còn 1 dòng ellipsis; card 1280×720 ước tính giảm từ ~225px xuống ~202px
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- `workshop_hub.gd` có lỗi gdlint sẵn từ biến class-scope viết hoa như const; đã đổi sang `snake_case` mà không đổi logic layout.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Restore save được guard bằng `GameManager.save_restored` để tránh reload save mỗi lần quay lại WorkshopHub và overwrite state runtime chưa save.
- `SaveSystem.load_game()` vẫn giữ behavior restore `InventorySystem.materials`; task này không đổi `SaveSystem.gd`.

## Session 13 — 2026-05-13

### Task đã làm
- [P4-Shop] Xác nhận/fix gold cộng đúng sau sale completion — DONE
- [P4-DayLoop] Implement Day Summary + Advance Day sau shop close — DONE

### Files tạo mới
- Không có

### Files đã sửa
- scripts/shop/shop_manager.gd — trong `complete_sale()`, gọi `GameManager.add_gold(gold)` ngay khi sale hoàn tất; reorder `class_name`/`extends` để pass gdlint
- scripts/autoload/GameManager.gd — thêm `day_start_gold`, `pending_day_summary_stats`; `shop_closed` giờ lưu stats chờ Day Summary và đổi phase NIGHT, không cộng gold lần hai; `advance_day()` reset mốc gold đầu ngày và emit phase/day
- scripts/ui/day_summary_ui.gd — thêm `show_summary(stats)`, hiển thị ngày hiện tại, vàng kiếm được so với đầu ngày, số vũ khí đã bán; nút `Sang Ngày Mới` gọi `advance_day()`, save full state rồi quay về WorkshopHub
- scripts/main/workshop_hub.gd — mở Day Summary nếu có `pending_day_summary_stats` khi quay về hub; connect `EventBus.shop_closed` để mở summary nếu signal xảy ra lúc hub active
- NOTES.md — thêm log session theo template

### Vấn đề gặp phải
- Trước session này gold chỉ được cộng gián tiếp khi `EventBus.shop_closed` phát stats, không phải ngay lúc sale hoàn thành. Đã chuyển cộng gold sang `ShopManager.complete_sale()` và tránh double-count bằng cách bỏ cộng gold khỏi listener `shop_closed` trong GameManager.

### Chưa làm được (nếu BLOCKED)
- Không có

### Cần Engineering Lead chú ý
- Day Summary khi mở từ shop close dùng `customers_served` làm số vũ khí đã bán; trade accepted hiện gọi `complete_sale(id, 0)` nên vẫn được tính là giao dịch thành công/vũ khí đã bán.
- Save state có thêm `day_start_gold` để tính gold earned theo ngày sau reload; `SaveSystem` vẫn tự thêm `materials`.
> ⚠️ SESSION KẾT THÚC KHÔNG CÓ BÁO CÁO — 2026-05-13 14:48
> ⚠️ SESSION KẾT THÚC KHÔNG CÓ BÁO CÁO — 2026-05-13 16:22
> ⚠️ SESSION KẾT THÚC KHÔNG CÓ BÁO CÁO — 2026-05-14 08:45
