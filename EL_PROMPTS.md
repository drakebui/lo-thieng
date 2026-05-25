# EL_PROMPTS.md — Bảng Prompt Nhanh
> Giữ file này mở khi làm việc trong Godot.
> Copy đúng block cần dùng → paste vào Claude chat.

---

## 🟢 BẮT ĐẦU SESSION MỚI

```
Đọc AGENTS.md, NOTES.md và CheckListDev.md/CheckListDev2.md
Task tiếp theo Codex nên làm là gì?
Cho tôi chỉ thị chính xác để tôi paste thẳng cho Codex.
```

---

## 🔵 REVIEW SAU KHI CODEX XONG

```
Đọc AGENTS.md và REVIEW_PROTOCOL.md.
Review output sau của Codex và chỉ báo lỗi. Không tự sửa.

NOTES.md:
[paste nội dung NOTES.md]

DIFF:
[paste output của: git diff HEAD~1 --unified=5]
```

---

## 🟡 CODEX BỊ BLOCKED

```
Đọc AGENTS.md.
Codex đang bị blocked ở [tên task] với vấn đề sau:
[mô tả vấn đề]

Codex nên làm gì? Cho tôi chỉ thị chính xác để gửi cho Codex.
```

---

## 🔴 CODEX LÀM SAI / CẦN SỬA

```
Đọc AGENTS.md và REVIEW_PROTOCOL.md.
Codex đã làm sai spec ở [tên task].
Vấn đề: [mô tả ngắn]
Chỉ thị chính xác nào tôi nên gửi cho Codex để sửa?
```

---

## ⚪ KIỂM TRA TRẠNG THÁI DỰ ÁN

```
Đọc AGENTS.md và NOTES.md.
Tóm tắt trạng thái dự án trong 5 dòng hoặc ít hơn.
Phần nào đang có rủi ro? Phần nào đang đúng tiến độ?
```

---

## ⚙️ LỆNH TERMINAL SAU MỖI SESSION CODEX

```bash
# 1. Commit lên GitHub
git add .
git commit -m "[PhaseX] tên task ngắn"
git push origin main

# 2. Xuất diff để paste cho EL review
git diff HEAD~1 --unified=5
```

---

## 📋 NGÀY 1 TUTORIAL — CODEX ACTION PLAN

> Thứ tự thực hiện: T1 → T2 → T3 → T4 → T5 → T6 → T7 → T8
> Mỗi session là một prompt độc lập. Copy nguyên block → paste cho Codex.

---

### [T1] Input Map + Tutorial Flags

```
Đọc AGENTS.md, CheckListDev2.md (phần "NGÀY 1 — SCRIPTED TUTORIAL PLAN", mục 1 và mục 6).
Đọc scripts/autoload/GameManager.gd.

Làm 2 việc:

1. Trong project.godot, tìm section [input] và thêm các input action sau nếu chưa có:
   - pump_bellows → key scancode Space (hold)
   - hammer_hit   → key scancode Space + Enter
   - interact     → key scancode E
   - inventory    → key scancode I
   (move_up/down/left/right + confirm/cancel đã có → kiểm tra trước khi thêm)

2. Trong scripts/autoload/GameManager.gd, thêm biến:
   var tutorial_flags: Dictionary = {
	   "opening_seen":       false,
	   "forge_phase1_shown": false,
	   "forge_phase2_shown": false,
	   "debt_notice_shown":  false,
	   "shelf_shown":        false,
	   "bargain_shown":      false,
	   "inventory_shown":    false,
	   "explore_shown":      false,
	   "combat_shown":       false,
	   "stamina_shown":      false,
   }
   Thêm hàm: func mark_tutorial(key: String) -> void: tutorial_flags[key] = true
   Thêm tutorial_flags vào save_state dict (nếu có hàm get_save_state) và load_state (nếu có).

Sau mỗi file sửa: chạy gdlint <file>.
Cập nhật NOTES.md theo template (session number tăng dần, ngày hôm nay).
```

---

### [T2] Interactable Component

```
Đọc AGENTS.md, CheckListDev2.md (phần "NGÀY 1", mục 3 — Interaction System).
Đọc scripts/main/workshop_hub.gd để hiểu cấu trúc hiện tại.

Tạo file mới: scripts/ui/interactable.gd
Đây là component gắn lên bất kỳ Node2D nào có thể interact (lò rèn, kệ, cửa, NPC).

Yêu cầu:
- extends Node
- @export var priority: int = 0   # NPC=2, Object=1, Zone=0
- @export var is_locked: bool = false
- signal interacted(interactor: Node)

- Khi _ready(): tạo Area2D con với CollisionShape2D hình tròn radius=48px, monitoring=true
- Khi player_body vào Area2D: emit signal player_entered nếu không bị lock → hiện icon E
- Khi player_body ra: ẩn icon E
- Hàm public: func try_interact(player: Node) -> bool
  - Nếu is_locked: không làm gì, return false
  - Else: emit interacted(player), return true
- Hàm: func set_locked(value: bool): is_locked = value  → ẩn/hiện icon theo trạng thái

Icon E: dùng Label node con ("E"), ẩn mặc định, hiện khi player trong range và không bị lock.
Không cần AnimationPlayer ở phase này.

Chạy gdlint scripts/ui/interactable.gd.
Cập nhật NOTES.md theo template.
```

---

### [T3] Opening Sequence — Hoàn thiện 3 bước mở đầu

```
Đọc AGENTS.md.
Đọc scripts/intro/opening_debt_scene.gd (toàn bộ).
Đọc scenes/intro/OpeningSequence.tscn nếu cần hiểu node tree (CHỈ đọc, không sửa .tscn).

Yêu cầu: opening_debt_scene.gd phải thực hiện đúng thứ tự sau khi _ready():

STEP 1 — Scene card "Thành phố Thợ Rèn":
  - Hiện Label với text: "Thành phố Thợ Rèn\nNăm thứ 3 sau Đại Chiến Phương Bắc..."
  - Style: chữ trắng, nền đen mờ, căn giữa màn hình
  - Sau 3 giây (hoặc nút [Tiếp]): chuyển step 2

STEP 2 — Narration:
  - Text: "Ngươi thừa hưởng lò rèn từ cha — kèm theo một món nợ chưa bao giờ được trả..."
  - Style: chữ nghiêng, nhỏ hơn, fade in 0.8 giây
  - Sau 3 giây hoặc nút [Tiếp]: chuyển step 3

STEP 3 — Scene card lò rèn cũ:
  - Text: "[Hình ảnh lò rèn — placeholder]" (Label hoặc ColorRect màu xám tối thay sprite)
  - Sau 2 giây: chuyển step 4

STEP 4 — Dialogue Bà Trùm Hắc Nguyệt:
  - Label tên: "Bà Trùm Hắc Nguyệt" (góc dưới trái textbox)
  - Dòng 1: "Con thừa hưởng được lò rèn của cha. Nhưng tiền mặt bằng thì không ai cho không."
  - Nút [Tiếp] → dòng 2
  - Dòng 2: "4 ngày. 3,000 vàng. Đó là điều duy nhất ta cần từ con."
  - Nút [Bắt đầu] → STEP 5

STEP 5 — Kết thúc:
  - Set GameManager.tutorial_flags["opening_seen"] = true
  - GameManager.mark_tutorial("opening_seen")
  - SceneManager.go_to("res://scenes/main/WorkshopHub.tscn") hoặc emit signal để hub load

Nếu GameManager.tutorial_flags["opening_seen"] đã true khi _ready() → skip thẳng step 5.

Dùng các node đã có trong scene nếu phù hợp, thêm node mới chỉ khi cần thiết logic.
Không tạo .tscn mới.
Chạy gdlint scripts/intro/opening_debt_scene.gd.
Cập nhật NOTES.md theo template.
```

---

### [T4] Workshop Hub — Tutorial Mode Lock/Unlock

```
Đọc AGENTS.md.
Đọc scripts/main/workshop_hub.gd (toàn bộ).
Đọc CheckListDev2.md phần "NGÀY 1", mục 4 — steps B2, B6, B7, B8.

Yêu cầu: thêm tutorial mode vào workshop_hub.gd.

1. Thêm biến:
   var tutorial_step: int = 0
   # 0 = chờ rèn lần đầu | 1 = rèn xong, chờ C1 scene | 2 = sau C1, NOON | 3+ = free

2. Hàm _on_scene_ready() hoặc _ready():
   - Nếu GameManager.current_day == 1 và tutorial_flags["opening_seen"] == true:
	 → gọi _set_tutorial_step(0)

3. Hàm _set_tutorial_step(step):
   step = 0 (chờ rèn):
	 - Lock tất cả interactable ngoài lò rèn (gọi interactable.set_locked(true) trên kệ, cửa, bàn)
	 - Hiện hint label: "Đến lò rèn và rèn vũ khí đầu tiên của ngươi."

   step = 1 (sau forge xong, trước C1):
	 - Trigger C1 scene: spawn Người Thu Nợ vào scene (ẩn đi nếu không có sprite)
	 - Hiện DebtNoticeUI (emit EventBus signal hoặc gọi trực tiếp nếu là child node)
	 - Khi player đóng DebtNoticeUI → gọi _set_tutorial_step(2)

   step = 2 (NOON):
	 - Unlock lò rèn (để rèn thêm tùy chọn)
	 - Hiện hint: "Buổi trưa: Rèn thêm hoặc chờ đến chiều."
	 - Sau 60 giây hoặc player nhấn nút [Sang chiều]: DayCycle.advance_phase()

   step = 3 (AFTERNOON):
	 - Unlock kệ trưng bày
	 - Hiện hint: "Đặt vũ khí lên kệ trước khi mở cửa!"
	 - Nút [Mở cửa] chỉ xuất hiện khi ≥ 1 weapon đặt trên kệ

   step >= 4 hoặc day > 1:
	 - Tắt mọi tutorial lock, ẩn hint

4. Lắng nghe signal từ EventBus:
   - weapon_forged → nếu tutorial_step == 0: _set_tutorial_step(1)

Chạy gdlint scripts/main/workshop_hub.gd.
Cập nhật NOTES.md theo template.
```

---

### [T5] Forge Tooltips — Phase 1 & Phase 2

```
Đọc AGENTS.md.
Đọc scripts/forge/forge_session_ui.gd (toàn bộ).
Đọc scripts/forge/forge_phase2.gd và forge_phase2_ui.gd nếu Phase 2 tách file riêng.

Yêu cầu: hiện tooltip hướng dẫn 1 lần trước khi bắt đầu mỗi phase.

TOOLTIP PHASE 1 (trước heat bar bắt đầu):
  - Kiểm tra: if not GameManager.tutorial_flags["forge_phase1_shown"]
  - Hiện panel (Control node con hoặc tạo nội tuyến):
	Tiêu đề: "PHASE 1 — NUNG"
	Nội dung: "Giữ [Space] để bơm bễ. Đưa nhiệt độ vào vùng xanh (60–80%)."
	Nút [Đã hiểu] → đóng panel, GameManager.mark_tutorial("forge_phase1_shown"), bắt đầu heat bar
  - Nếu flag đã true: bắt đầu heat bar ngay (không hiện tooltip)

TOOLTIP PHASE 2 (trước rhythm mini-game bắt đầu):
  - Kiểm tra: if not GameManager.tutorial_flags["forge_phase2_shown"]
  - Hiện panel:
	Tiêu đề: "PHASE 2 — RÈN"
	Nội dung: "Nhấn [Space] khi thanh đến vùng PERFECT (xanh). 5 nhát búa quyết định chất lượng!"
	Nút [Đã hiểu] → đóng panel, GameManager.mark_tutorial("forge_phase2_shown"), bắt đầu rhythm
  - Nếu flag đã true: bắt đầu rhythm ngay

Tooltip panel: dùng PanelContainer + VBoxContainer + Label + Button.
Đặt tên node: "Phase1Tooltip" và "Phase2Tooltip" (visible = false mặc định).
Không tạo file .tscn mới — thêm node vào scene hiện có trong code (add_child) hoặc dùng node đã có trong .tscn.

Chạy gdlint trên từng file đã sửa.
Cập nhật NOTES.md theo template.
```

---

### [T6] Shop — Khách Scripted Ngày 1 + Tooltip Mặc Cả

```
Đọc AGENTS.md.
Đọc scripts/shop/shop_scene.gd hoặc shop_manager.gd (toàn bộ, xác định file nào quản lý spawn).
Đọc scripts/shop/negotiation_ui.gd (toàn bộ).
Đọc CheckListDev2.md phần "NGÀY 1", bước B9.

Task 1 — Shop Day 1 scripted customer:
  Trong shop_scene.gd hoặc shop_manager.gd, tìm chỗ spawn customer.
  Thêm điều kiện:
	if GameManager.current_day == 1:
		_spawn_scripted_customer("hiep_khach_lang_bat")
		# Chỉ 1 khách scripted, không spawn thêm ngày 1
	else:
		_spawn_random_customers()  # logic hiện tại

  Hàm _spawn_scripted_customer(customer_id: String):
	- Load customer data từ resources/customers/ (tìm file .tres có id = customer_id)
	- Nếu không có file → dùng NPCData mặc định với tên "Hiệp Khách Lang Bạt"
	- Spawn customer vào vị trí cửa, chạy CustomerAI bình thường
	- Sau khi sale hoàn tất: không spawn thêm (set max_customers = 0 cho phiên này)

Task 2 — Negotiation tooltip lần đầu:
  Trong negotiation_ui.gd, tìm hàm khởi tạo UI (thường là _show() hoặc open()).
  Thêm ngay đầu hàm:
	if not GameManager.tutorial_flags["bargain_shown"]:
		_show_bargain_tooltip()
		return  # chờ player nhấn [Đã hiểu] rồi mới mở UI thật

  Hàm _show_bargain_tooltip():
	- Hiện panel (tương tự Forge tooltip):
	  Tiêu đề: "MẶC CẢ"
	  Nội dung: "Kéo slider để đặt giá. 4 vùng: Quá Cao / Hơi Cao / Vừa / Quá Thấp.\nĐừng đặt quá cao — khách sẽ bỏ đi!"
	  Nút [Đã hiểu] → GameManager.mark_tutorial("bargain_shown"), gọi lại hàm open()

Chạy gdlint trên từng file đã sửa.
Cập nhật NOTES.md theo template.
```

---

### [T7] Day Summary — Thêm Debt Tracker Widget

```
Đọc AGENTS.md.
Đọc scripts/ui/day_summary_ui.gd (toàn bộ).
Đọc scripts/autoload/DebtSystem.gd để biết cách lấy C1 data.
Đọc CheckListDev2.md phần "NGÀY 1", bước B11.

Yêu cầu: trong DaySummaryUI, bên cạnh gold earned + weapons sold, thêm widget Debt Tracker:

Hàm _populate_summary() hoặc tương đương, thêm logic:
  var c1 = DebtSystem.get_checkpoint("c1_mat_bang")  # hoặc DebtSystem.checkpoints[0]
  if c1 and not c1.is_paid:
	  var days_left = c1.deadline_day - GameManager.current_day
	  var still_need = max(0, c1.amount_gold - GameManager.gold)
	  _debt_label.text = (
		  "📋 Checkpoint C1: %dG\n" % c1.amount_gold +
		  "Còn %d ngày | Hiện có: %dG\n" % [days_left, GameManager.gold] +
		  ("✅ Đủ tiền!" if still_need == 0 else "Còn thiếu: %dG" % still_need)
	  )
	  _debt_label.visible = true
  else:
	  _debt_label.visible = false

Thêm hint nếu still_need > 2000:
  _hint_label.text = "Ngày mai hãy ra ngoài kiếm nguyên liệu và rèn thêm!"
  _hint_label.visible = true

_debt_label và _hint_label: nếu chưa có → thêm Label node vào scene bằng code (add_child).
Đặt tên node "DebtTrackerLabel" và "HintLabel" để dễ tìm sau.

Chạy gdlint scripts/ui/day_summary_ui.gd.
Cập nhật NOTES.md theo template.
```

---

### [T8] Save/Load Tutorial Flags + Kiểm tra Toàn Bộ Flow

```
Đọc AGENTS.md.
Đọc scripts/autoload/SaveSystem.gd (toàn bộ).
Đọc scripts/autoload/GameManager.gd (phần save/load nếu có).

Task 1 — Persist tutorial_flags:
  Trong SaveSystem.gd, tìm hàm save_game(dict) hoặc tương đương.
  Đảm bảo tutorial_flags được đưa vào dict khi save:
	state["tutorial_flags"] = GameManager.tutorial_flags
  
  Trong load_game() hoặc apply_save_state():
	if "tutorial_flags" in data:
		for key in data["tutorial_flags"]:
			if key in GameManager.tutorial_flags:
				GameManager.tutorial_flags[key] = data["tutorial_flags"][key]

Task 2 — EventBus signals còn thiếu:
  Đọc scripts/autoload/EventBus.gd.
  Kiểm tra xem các signal sau đã có chưa, nếu chưa thêm vào:
	signal tutorial_step_changed(step: int)
	signal debt_notice_closed()
  (Chỉ thêm nếu workshop_hub.gd hoặc opening_debt_scene.gd cần dùng)

Task 3 — Smoke test logic (đọc code, không chạy engine):
  Đọc lại theo thứ tự: opening_debt_scene.gd → workshop_hub.gd → forge_session_ui.gd → shop_scene.gd → negotiation_ui.gd → day_summary_ui.gd.
  Xác nhận:
  - tutorial_flags["opening_seen"] được set đúng chỗ
  - tutorial_step 0→1→2→3 advance đúng điều kiện
  - Ngày 2+ không bị tutorial lock (kiểm tra điều kiện current_day == 1)
  - Không có circular dependency giữa các file

Chạy gdlint trên mọi file đã sửa trong task này.
Cập nhật NOTES.md theo template (ghi rõ kết quả smoke test).
```

---

*Dự án: Lò Thiêng | Kiến trúc sư: Claude | Kỹ sư: Codex*
