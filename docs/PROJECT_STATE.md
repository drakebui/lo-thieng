# 📋 TRẠNG THÁI DỰ ÁN — LÒ THIÊNG: TIẾNG GỌI TỔ NGHỀ
> **Nguồn Sự Thật Duy Nhất về Tiến Độ (Single Source of Truth for Progress)**
> **Tài liệu Thiết kế Game:** Xem tại [GAME_DESIGN_MASTER.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/docs/GAME_DESIGN_MASTER.md)
> **Sổ tay Kỹ thuật:** Xem tại [AGENTS.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/AGENTS.md)
> **Cập nhật gần nhất:** Session 136 (2026-11-24)

---

## 1. MỤC TIÊU HIỆN TẠI
- **Mục tiêu cốt lõi:** Hoàn thiện trọn gói bản **Demo Chơi Thử 4 Ngày Đầu (Vertical Slice)** — Trải nghiệm đầy đủ vòng lặp Trinity Hook (Explore $\to$ Forge $\to$ Sell), cảm nhận áp lực thanh toán Checkpoint C1 (3,000G hạn chót Ngày 4).
- **Stack & Quy chuẩn:** Godot 4.x (GDScript), 32-bit Hoả Tâm Pixel Art (`640×360` nền phóng to `1920×1080`, `64×64` spritesheet, bảng màu 96 màu), kiểm tra liên tục bằng `gdlint` và `scripts/tools/static_check.py`.

---

## 2. TIẾN ĐỘ ĐÃ HOÀN THÀNH (SESSIONS 123–136)

### ✅ Đại Tu & Khắc Phục Lỗi Cốt Lõi Toàn Hệ Thống (Session 136 — Swarm Repo-Audit & Optimize)
- **Hệ thống Lưu & Dữ liệu (`SaveSystem.gd`, `InventorySystem.gd`, `DebtSystem.gd`, `GameManager.gd`):**
  - Khắc phục triệt để lỗi mất vũ khí trên kệ sau khi Save/Load: `SaveSystem` lưu trữ và khôi phục đồng bộ `shelf_weapons`.
  - Thêm lính gác an toàn (guard clause) khi mở file và parse JSON nhằm chống crash `Nil` khi file bị lỗi phân quyền / antivirus quét.
  - Chống trừ tiền nợ lặp lại (`pay_checkpoint` chặn double-payment khi click đúp nhanh).
  - Khắc phục rò rỉ bộ nhớ & nhân bản vũ khí cũ: `GameManager.remove_weapon()` được gọi đồng bộ khi bán vũ khí tại `InventorySystem`.
  - Bổ sung trao thưởng đầy đủ Vàng, Danh tiếng, Di vật trong `_grant_quest_reward()` và bổ sung 2 wrapper API `advance_day()`, `consume_travel_stamina()` theo chuẩn `AGENTS.md`.
- **Hệ thống Thám hiểm, Rèn & Chiến đấu (`exploration_scene.gd`, `weapon_data.gd`, `forge_system.gd`, `combat_manager.gd`, `combatant.gd`):**
  - Khắc phục soft-lock trong ExplorationScene: Nới rộng vùng Exit và biên giới kẹp nhân vật, đảm bảo người chơi luôn chạm được vùng chuyển cảnh / quay về Xưởng.
  - Chuyển toàn bộ túi dã ngoại `hand_inventory` (kể cả vật phẩm Quest, Dược phẩm, Linh lực) vào kho trước khi dọn túi, chống mất vật phẩm nhiệm vụ.
  - Chống chia cho 0 (`% 0`) khi sinh quặng thám hiểm; bảo toàn chỉ số thưởng độ bền (+15 Bền) từ Tôi Hoàn Hảo Phase 3 sang `WeaponData`.
  - Chống exploit nung thép Phase 1: Bắt buộc `cook_progress >= 1.0` mới xét bậc Đỏ Rực và tự động ngắt hỏng phôi khi chạm ngưỡng cháy.
  - Cân chỉnh combat: Sửa công thức tính Giáp `attacker.def_bonus` tránh bị làm tròn về 0, chuyển nhịp Đóng Băng về đầu lượt và kiểm tra người chơi tử trận trước tránh lỗi thắng giả khi cả hai cùng chết.
- **Tiệm, Khách hàng, Hướng dẫn & UI (`customer_ai.gd`, `shop_scene.gd`, `workshop_tutorial_controller.gd`, `inventory_panel.gd`, `opening_debt_scene.gd`):**
  - Tạm dừng bộ đếm kiên nhẫn khi mở bảng đàm phán; không trừ vũ khí khỏi kho nếu giao dịch thất bại hoặc khách bỏ đi.
  - Tích hợp giao diện trả đơn hàng `CommissionDeliveryUI` bằng GDScript động trong `shop_scene.gd` (tuyệt đối không sửa file `.tscn`).
  - Sửa lỗi nhảy cóc hướng dẫn Buổi Trưa Ngày 1 (`elif NOON`) và đồng bộ thoại hướng dẫn chu trình 4 buổi.
  - Khóa trùng lặp ô kệ trong `inventory_panel.gd` và chuẩn hóa toàn bộ đường dẫn ảnh chân dung NPC Bà Trùm sang Unicode NFC chuẩn.
- **Nghiệm thu Swarm Verifier:** 100% pass qua `exhaustive_class_audit.js` (0 collision), `check_scenes_and_scripts.js` (0 broken preloads/extends) và bảo toàn tính toàn vẹn của 19 scenes `.tscn`.

### ✅ Hệ Thống Lò Rèn 3 Pha (`ForgeSession`) — Đạt Chuẩn 100%
- **Phase 1 Nung Thép (`forge_system.gd`):** Cơ chế nhịp bơm bễ rút gọn ~3.5s (`cook_progress` 0..1.0), quán tính nhiệt tăng/giảm nhịp nhàng (`HEAT_DECAY_RATE = 16.0/s`), cảnh báo quá nhiệt 1.2s tránh cháy phôi thép, thưởng +15% vùng PERFECT cho Phase 2 (`get_perfect_bonus_for_phase2()`).
- **Phase 2 Rèn Búa (`forge_phase2.gd`):** Con lắc dao động 0.0 $\leftrightarrow$ 1.0 với nhịp thở `BREATH_DURATION = 0.22s` khi đổi chiều / sau nhát đập, tâm mục tiêu nảy đổi bên hợp lý, tích lũy chuỗi PERFECT kích hoạt Combo Búa Vàng, giữ nghiêm ngặt trần Prefix Gate theo cấp nguyên liệu (`MATERIAL_PREFIX_CAP`).
- **Phase 3 Tôi Luyện (`forge_phase3.gd`):** Cơ chế canh thời điểm nhúng cổ ngữ `try_quench_press()` trong khoảng hội tụ vàng `0.70 ± 0.08`, kích hoạt thành công `perfect_quench` thưởng +10% giá bán (`price_mult = 1.10`) và +10 độ bền tối đa.
- **Thẻ Vũ Khí & Kệ Tiệm (`weapon_card_ui.gd`):** Hiển thị nhãn Hoàn Mỹ (`perfect_quench`), kiểm tra `CommissionSystem.get_active()` gắn nhãn Khớp Đơn Hàng, hỗ trợ `save_and_shelf()` nối với `InventorySystem.move_to_shelf()` (tự động kiểm tra trần kệ 3/3).
- **Đồng bộ Giao diện (`forge_session_ui.gd`):** Nền 32-bit Hoả Tâm `640×360` (`forge_scene_bg_640x360.png`), phôi thép đổi màu Xám $\to$ Cam $\to$ Đỏ Rực $\to$ Đen Cháy.

### ✅ Phòng Xưởng Hub (`WorkshopHub`) & Nhân Vật Nấm 32-bit
- **Tái tạo 100% Nấm Fresh Generation:** Mèo thợ rèn lông cam, khăn đỏ, áo xanh, tạp dề da nâu, quần cộc xanh chàm đầy đủ ở cả 4 hướng (Front, Back, Right, Left); spritesheet chuẩn 32-bit `assets/pixel/sprites/player/nam_4dir_sheet_64.png`.
- **Kiến trúc Lớp Cơ Sở `BaseCharacter` (`scripts/characters/base_character.gd`):** Neo điểm chân (32, 60), va chạm chân capsule, bóng sàn dẹp oval, âm thanh bước chân `AudioManager`, điểm neo bong bóng `EmoteAnchor` (0, -56).
- **Quy chuẩn tỷ lệ hiển thị RPG 3/4:** Nấm scale `3.0×` (~170px), NPCs scale `2.75×` (~162px), khắc phục triệt để lỗi phóng to ở Exploration.
- **Ánh sáng 4 Buổi & Tương tác Xưởng:** Bầu không khí đổi theo buổi (Sáng nắng ấm, Trưa sáng rõ, Chiều hoàng hôn cam, Đêm tối ấm ánh lửa). Bảng tên pixel kèm huy hiệu `[E]` nổi mượt trên NPC/vật thể tương tác.
- **Bộ 10 SFX Xưởng & Lò Rèn:** Bước chân sàn gỗ, mở sách, mở rương, mở cửa, bơm bễ, cảnh báo nhiệt, nhúng thép xèo hơi nước, hoàn thành vũ khí.

### ✅ Hệ Thống Đơn Hàng (Commission System) & Phụ Trợ
- Tích hợp Đơn đặt hàng (Commission Phase A/B/C) + đồng bộ kệ tiệm & kho đồ.
- Tách `WorkshopTutorialController` và `WorkshopDebtController` khỏi `workshop_hub.gd`.
- Dọn sạch dead code, mở rộng `static_check.py` lên 8 CHECK (0 lỗi cú pháp và liên kết).

---

## 3. LỘ TRÌNH KẾ TIẾP (DEMO TARGET: NGÀY 1–4 & CHECKPOINT C1)

### 🔴 Ưu Tiên Cao (Must-have cho Demo)
- [ ] **Hoàn thiện Vòng Lặp Bán Hàng Chiều (`ShopScene`):**
  - Kết nối dữ liệu 3 vũ khí trên kệ tiệm hiển thị đúng visual và thông số.
  - Vận hành Customer AI: Khách vào tiệm theo lượt, đọc ngân sách và thể hiện độ kiên nhẫn.
  - Vận hành Negotiation UI: Người chơi ra giá, mặc cả 1–2 lượt, chốt đơn hoặc từ chối.
- [ ] **Kịch Bản Ngày 1 Tutorial & Giới Thiệu Nợ C1:**
  - Ngày 1: Chuỗi hướng dẫn Nấm làm quen Xưởng, rèn thanh kiếm đầu tiên, đón Người Thu Nợ Chợ Ngoài giao giấy báo nợ C1 (3,000G — hạn Ngày 4).
  - Tích hợp thông báo nợ nổi (`debt_notice_ui.gd`) và giao diện trả nợ (`debt_payment_ui.gd`).
- [ ] **Tích Hợp Khám Phá Vùng 1 Đồng Mây (`ExplorationScene`):**
  - Kiểm tra hệ thống tiêu hao Thể lực Du hành (10 Stamina/ngày).
  - Kiểm tra bãi khai thác Sắt Thô và hoa thảo dược.
  - Đảm bảo va chạm, tỷ lệ nhân vật Nấm và quái vật Tier 1 (Sói Đồng Cỏ, Rắn Cát) hiển thị chuẩn xác.
- [ ] **Đóng Vòng Lặp Ngày & Chuyển Buổi (`DayCycle` & `DaySummaryUI`):**
  - Kiểm tra luân chuyển mượt mà: Sáng (Explore) $\to$ Trưa (Forge) $\to$ Chiều (Shop) $\to$ Đêm (Summary/Save).
  - Màn hình tổng kết ngày: Báo cáo doanh thu vàng kiếm được, tiến độ nợ C1 còn lại.

### 🟡 Ưu Tiên Trung Bình (Should-have)
- [ ] Thêm hội thoại ngắn cho NPC VIP Vùng 1 (Cô Sếu Lộng Gió).
- [ ] Cân bằng kinh tế Ngày 1–4 để người chơi chơi cẩn thận có thể kiếm vừa đủ ~3,200–3,500G trả nợ C1 đúng hạn.

---

## 4. BÀI HỌC KINH NGHIỆM & CẠM BẪY CẦN TRÁNH (PITFALLS)

1. **Tuyệt đối không sửa file `.tscn` bằng text editor:** Sửa tay trực tiếp file `.tscn` rất dễ gây gãy định dạng parser, làm mất UID hoặc corrupt cả scene. Luôn chỉnh sửa scene qua Godot Editor hoặc can thiệp thông qua GDScript.
2. **Kế thừa nhân vật qua `BaseCharacter`:** Khi tạo NPC hoặc quái vật di chuyển mới, luôn kế thừa `BaseCharacter` để được tự động cấu hình va chạm bàn chân, bóng đổ, điều khiển 4 hướng và âm thanh bước chân mà không viết lặp code.
3. **Giao tiếp liên Scene bằng EventBus:** Không dùng `get_node("/root/...")` xuyên scene. Bắn Signal qua `EventBus` để đảm bảo các Scene có thể chạy độc lập khi test (F6).
4. **Trần phẩm cấp vũ khí (`MATERIAL_PREFIX_CAP`):** Khi rèn vũ khí, điểm mini-game cao đến đâu cũng không được vượt qua giới hạn của cấp nguyên liệu ban đầu.
