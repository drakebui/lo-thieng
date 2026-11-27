# Trạng Thái Dự Án — Lò Thiêng: Tiếng Gọi Tổ Nghề

- **Mục tiêu trọng tâm hiện tại:** Hoàn thiện **Chương 1 Hoàn Chỉnh (~2 giờ chơi | Ngày 0 → Ngày 12 | 2 Vùng Đất | 2 Mốc Nợ C1 & C2)** với bản sắc lối chơi độc nhất (**Rèn Có Ý Đồ Cương/Nhu + Tôi Luyện Linh Lực**, **Mặc Cả Đọc Vị + Tiếng Vọng Vũ Khí**, **6 Phôi Cốt Lõi có Kỹ Năng Bẩm Sinh Thật**) trên nền đồ họa **100% 32-Bit Hoả Tâm Pixel Art (`res://assets/pixel/`)**.
- **Stack & Chuẩn kỹ thuật:** Godot 4.x (GDScript), 32-bit Hoả Tâm Pixel Art (`640×360` BG ×3 = `1920×1080`, `64×64` sprite sheet kế thừa `BaseCharacter.gd`, bảng màu 96 màu Hoả Tâm, viền `#120C10`).
- **Thứ tự thi công bất biến:** **Khóa chặt Gameplay & UI tương tác (Chặng 1 → 2 → 3) → Hoàn thiện 100% Pixel Art 32-bit còn thiếu của Chương 1 (Chặng 4) → Đánh bóng cảm giác tay & Kiểm thử trọn vẹn 12 ngày (Chặng 5)**.
- **⚠️ LUẬT SỐNG CÒN VỀ ASSETS & THẾ GIỚI QUAN (Xem [docs/PITFALLS.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/docs/PITFALLS.md)):**
  1. **ZERO LEGACY ASSET REUSE:** Tuyệt đối không dùng lại, không giữ `FALLBACK_PATH`, không bọc khung mới quanh ảnh cũ từ `assets/weapons/`, `assets/UI/`, `assets/sprites/`, `assets/characters/`. Đã khóa tự động bằng **CHECK 9** trong [static_check.py](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/tools/static_check.py).
  2. **100% ANIMAL FOLK (KHÔNG CÓ LOÀI NGƯỜI):** Toàn bộ nhân vật, khách hàng, kẻ địch người/thú trong thế giới Lò Thiêng là **Động Vật Nhân Hóa** (Nấm = Mèo vàng cam; Bà Trùm Hắc Nguyệt = Báo đen/Cáo quý tộc; Cô Lộng Gió = Cò/Sếu trắng; Người Thu Nợ / Tay Sai Rừng = Lửng Mật/Chồn đen; Tướng Nai Bóng Rừng = Hươu/Nai sừng cổ thụ).
  3. **KHÔNG SỬA FILE `.tscn` BẰNG TEXT EDITOR:** Mọi thay đổi UI/layout thực hiện an toàn qua GDScript hoặc Godot Editor.

---

## 1. Các hạng mục đã hoàn thành gần nhất (Session 123–134)
- [x] Hệ thống Đơn đặt hàng (Commission Phase A/B/C), Phòng Xưởng (`WorkshopHub`: Y-Sort, ánh sáng 4 buổi, 10 SFX `.wav` mới).
- [x] Tái cấu trúc UI 3 Pha Rèn ([forge_session_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_session_ui.gd), [forge_visual_stage.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_visual_stage.gd)): Sân khấu 32-bit phóng to ~65%, Thẻ Công Thức góc phải trên, Cụm Đồng Hồ Đôi gọn ở Phase 1, 5 Huy hiệu Nhát Búa + chữ nổi trên Đe ở Phase 2, bỏ Popup chặn chuột & chuyển pha mượt bằng `[SPACE]`.
- [x] **Đợt 1 — 12 Vũ Khí 32-bit (`64×64`) & 24 Icon Nguyên Liệu 32-bit (`48×48`):** Tạo mới 100% trong `assets/pixel/sprites/weapons/` và `assets/pixel/ui/materials/`; đấu nối vào `forge_prep_ui.gd`, `forge_book_ui.gd`, `forge_session_ui.gd`.
- [x] **Đợt 2 — Nền Cửa Tiệm 32-bit (`640×360`):** Tạo mới `assets/pixel/backgrounds/shop_bg_640x360.png`; đấu nối vào `shop_scene.gd` và cập nhật chân dung 32-bit trong `negotiation_ui.gd`.
- [x] **Đợt 3 — Chân Dung Hội Thoại Hi-Bit (`256×256`) & Hộp Thoại Hoả Tâm:** Tạo mới và tách nền sạch trọn bộ 5 chân dung Hi-Bit `256×256` đồng bộ (`portrait_nam_256.png`, `portrait_cuc_than_256.png`, `portrait_nguoi_thu_no_c1_256.png`, `portrait_ba_hac_nguyet_256.png`, `portrait_co_long_gio_256.png`) đấu nối vào `tutorial_overlay_ui.gd`, `opening_debt_scene.gd`, `shop_scene.gd`, `negotiation_ui.gd` với `TEXTURE_FILTER_NEAREST` + kích thước khóa nguyên `2×` (`512×512` trên `1920×1080`) và ẩn khung NPC khi Nấm độc thoại.
  - *Ghi chú bảo lưu:* Giữ nguyên các file `portrait_nam_128.png`, `portrait_ba_hac_nguyet_128.png`, `portrait_co_long_gio_128.png`, `portrait_nguoi_thu_no_128.png` trong `assets/pixel/ui/portraits/` làm **tài nguyên dự trữ cho phát triển sau này** (không xóa, không gán nhầm vào Bà Hắc Nguyệt / Cô Lộng Gió).
- [x] **Đợt 4 — Main Menu 32-bit (`640×360`), Exploration & Khóa Tự Động:** Tạo mới `assets/pixel/backgrounds/main_menu_bg_640x360.png`; viết lại `main_menu_ui.gd` sạch 100%, tắt ảnh tạm trong `exploration_scene.gd`, bổ sung **CHECK 9** vào `scripts/tools/static_check.py`.

---

## 2. Khung Phạm Vi Đã Chốt Cho Chương 1 Hoàn Chỉnh (~2 Giờ Chơi)

| Hạng mục | Thông số khóa chặt cho Chương 1 |
|---|---|
| **Thời lượng ngày** | **Ngày 0 (Hướng dẫn mở đầu) → Ngày 12** (13 ngày chơi liên tục; mở trần tiến trình lên `CHAPTER1_LAST_DAY = 12`). |
| **Vùng khám phá** | **2 Vùng hoàn chỉnh (6 phân cảnh/vùng):** `DongMay` (*V1. Đồng Mây Trắng*) + `RungTramHon` (*V2. Rừng Trăm Hồn*). Các vùng V3–V6 hiển thị trạng thái khóa Chương 2+. |
| **Áp lực Nợ kép** | **Mốc C1 (`c1_mat_bang`):** Thông báo Ngày 1 → Hạn tối Ngày 4 (**`3,000G`**, phạt trễ `+300G`).<br>**Mốc C2 (`c2_dan_duong`):** Tay Sai Rừng thông báo sáng Ngày 5 → Hạn tối Ngày 12 (**`8,000G`**, phạt trễ `+800G`). |
| **Kho phôi mở khóa** | **6 Phôi Cốt Lõi Chương 1:** `kiem_don` (Kiếm Đơn), `song_dao` (Song Đao), `giao_dai` (Giáo Dài), `bua_chien` (Búa Chiến), `khien_dong` (Khiên Đồng), `gay_phep` (Gậy Phép).<br>**6 Phôi Bậc Cao (niêm phong ở Tab III cho Chương 2+):** `cung_truong`, `quyen_cu`, `con_nhi_khuc`, `dao_phat`, `liem_song`, `phoi_no_ban`. |
| **Đỉnh cao cốt truyện** | Trả xong C1 tối Ngày 4 → mở đường vào `RungTramHon` → gặp **Cô Lộng Gió** & **Tướng Nai Bóng Rừng** → thu hồi **Mảnh Cổ Khí Tổ Nghề đầu tiên** (`first_artifact_shard.tres`) → vượt qua kỳ thu nợ C2 tối Ngày 12 → mở phân cảnh kết Chương 1 & thư cảnh báo của Bà Trùm Hắc Nguyệt dẫn sang Chương 2 (*Núi Than Đỏ*). |

---

## 3. Lộ Trình Thi Công Siêu Chi Tiết — 5 Chặng (Không Bỏ Sót Bất Kỳ Chi Tiết Nào)

### 🔥 CHẶNG 1: Bàn Chuẩn Bị Hữu Cơ (`ForgePrepUI`) & Lò Rèn 3 Pha "Rèn Có Ý Đồ" ✅
> **Mục tiêu:** Biến quá trình chuẩn bị và rèn vũ khí thành một nghi thức thủ công có chiều sâu quyết định thật sự — người chơi điều khiển được hướng phẩm chất vũ khí bằng tay nghề và ý đồ thay vì quay xổ số ngẫu nhiên.

#### [x] Bước 1.1 — Hoàn thiện Mặt Bàn Thợ Rèn 32-Bit Hữu Cơ (`ForgePrepUI`)
- **File tác động:** [forge_prep_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_prep_ui.gd), `assets/fonts/`.
- **Thông số vật lý khóa cứng trên canvas gốc `640×360` (`× WB_SCALE = 3.0 → 1920×1080`), bóng tiếp xúc mặt gỗ `RGB(18, 10, 12)`:**
  1. `forge_workbench_bg_640x360.png` (`640×360`) — mặt bàn gỗ thợ rèn.
  2. `forge_cloth_mat.png` (`204×136`, tâm `(468, 196)`, xoay `+1.8°`) — tấm vải lanh trải riêng, tách rời với Túi Da.
  3. `forge_grimoire_open.png` (`304×176`, tâm `(186, 206)`, xoay `-1.6°`) — bắt buộc áp dụng Shader uốn cong vòm trang sách (`PAGE_WARP_SHADER_CODE`) + đổ bóng gáy sách; chữ mực cổ (`COL_INK`, `COL_INK_ACCENT`) in trực tiếp trên thớ giấy (**0 hộp `StyleBoxFlat`, 0 `weapon_pedestal`**).
  4. `forge_commission_note.png` (`144×56`, đã xóa đinh, tâm `(294, 66)`, xoay `+3.8°`, ẩn `ForgePhaseIndicator` để không chồng lấp).
  5. `forge_leather_pouch.png` (`100×96`, tâm `(514, 114)`, xoay `+28.0°` đặt lệch góc trên-phải tấm vải, miệng chĩa vào đống quặng).
  6. `forge_wax_seal_btn.png` (`168×54`, tâm `(492, 306)`, xoay `-0.8°`) — nút đóng dấu sáp đỏ khởi lò.
- **Kiến trúc Camera Cúi Nhìn 2 Vùng (`Focus Pan & Zoom`, tween mượt `0.25s`, phóng đồng bộ cả mặt bàn lẫn đồ vật để đạt `0% mixel`):**
  - **Vùng 1 (`~1.55×` — Cúi đọc Sổ Cẩm Nang & Tờ Đơn Hàng):** Rìa phải vẫn lấp ló mép Tấm Vải Lanh để click trượt sang Vùng 2 (hoặc bấm phím `Tab` / `E`).
  - **Vùng 2 (`~1.50×` — Bốc quặng trên Vải Lanh & Đóng Ấn Sáp):** Rìa trái vẫn lấp ló mép Cuốn Sổ để click trượt về Vùng 1 (hoặc bấm `Tab` / `Q`).
- **6 bước con thực thi & chụp ảnh `1920×1080` nghiệm thu từng bước:**
  - [x] **1.1a — Font tiếng Việt cho Sách & Giấy:** Nạp font đọc rõ dấu tiếng Việt từ `assets/fonts/` (`PixelifySans.ttf` cho tên phôi/chỉ số khắc in, `Lora-Regular.ttf` & `Lora-Italic.ttf` cho chữ viết tay trên giấy đơn hàng & lời tựa cổ).
  - [x] **1.1b — Cuốn Sổ Cẩm Nang chuẩn sách thật (Vùng 1):**
    - Mỗi cặp trang mở (Trái + Phải) trình bày **duy nhất 1 phôi vũ khí**:
      - *Trang Trái:* Hình vẽ phác thảo 32-bit lớn của phôi + Tên vũ khí + đôi dòng truyền thuyết tổ nghề.
      - *Trang Phải:* Số phần nguyên liệu cần dùng, chỉ số gốc (`ATK / DEF / MAG / SPD / Độ bền 50`), **Chiêu bẩm sinh `[0 STA]`**, **Đặc tính nhiệt nung** (*Phôi Nặng cần lửa Đỏ Rực 80–92%* vs *Phôi Thanh/Phép cần lửa Chuẩn 65–80%*), và dòng kiểm kê thật: `"Trong túi có: X phần đủ bậc"`.
    - Lật trang bằng nút góc giấy `‹ / ›`, cuộn chuột, phím `← / →`, và **3 thẻ kẹp trang nhô ở mép bìa**:
      - *Kẹp `I`:* `kiem_don`, `song_dao`, `giao_dai` (3 phôi cận chiến linh hoạt).
      - *Kẹp `II`:* `bua_chien`, `khien_dong`, `gay_phep` (3 phôi hạng nặng & huyền thuật).
      - *Kẹp `III`:* 6 phôi bí truyền Chương 2+ (`cung_truong`, `quyen_cu`, `con_nhi_khuc`, `dao_phat`, `liem_song`, `phoi_no_ban`) — hiển thị bản vẽ mờ đóng dấu niêm phong *"Bí truyền Chương 2 — Mở khi đặt chân tới Núi Than Đỏ"*, không cho bấm rèn ở Chương 1.
    - **Cấm tuyệt đối:** Không đặt nút filter phân loại lên mặt giấy, không đặt ô slot quặng lên mặt giấy.
  - [x] **1.1c — Tờ Giấy Đơn Hàng (`+3.8°`) phía trên đầu Sổ:**
    - Đọc đơn hàng đang nhận từ [CommissionSystem.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/CommissionSystem.gd); hiển thị ngắn gọn bằng nét mực tay: Tên khách, Phôi yêu cầu, Hệ Linh Lực, Bậc tối thiểu, Thưởng vàng.
    - Click vào tờ đơn tự động lật Sổ tới đúng trang phôi khách đặt. Nếu hiện không có đơn nào đang nhận, hiển thị dòng chữ nhạt *"Chưa có đơn đặt rèn"*.
  - [x] **1.1d — Túi Da (`-18.0°`) & Quặng Bày Hữu Cơ Trên Vải Lanh (Vùng 2):**
    - Đọc danh sách nguyên liệu thực tế có số lượng `> 0` trong [InventorySystem.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/InventorySystem.gd) và bày trực tiếp các viên quặng/gỗ/tinh thạch `48×48` theo cụm tự nhiên trên mặt vải ngay trước miệng túi da (**0 bảng lưới 24 ô, 0 khung hộp đen, 0 nút `Hiện tất cả`**).
    - Nguyên liệu không đủ số lượng hoặc chưa đủ bậc yêu cầu của phôi đang mở sẽ hạ độ sáng nhẹ và báo rõ khi rê chuột; click chọn nguyên liệu đủ chuẩn sẽ sáng viền hổ phách và ghi nhận `selected_material`.
  - [x] **1.1e — Nút Dấu Sáp Đỏ (`-0.8°`) khởi lò:**
    - Chỉ sáng rõ khi đã chọn phôi Chương 1 hợp lệ + chọn đủ nguyên liệu trên tấm vải.
    - Bấm vào phát âm thanh đóng ấn sáp, ghi `GameManager.selected_blank`, `GameManager.selected_material`, đặt `GameManager.selected_element = ""` (để chọn ở Phase 3), trừ đúng định lượng nguyên liệu trong kho và chuyển sang `ForgeSession.tscn`.
  - [x] **1.1f — Chụp ảnh Godot `1920×1080` kiểm tra trực quan:** Đảm bảo 0 đè chữ, 0 vỡ hạt (`0% mixel`), thao tác chuyển Vùng 1 ↔ Vùng 2 mượt mà bằng cả chuột lẫn phím tắt.

#### [x] Bước 1.2 — Phase 1: Nung Phôi Theo Đặc Tính Vật Lý (2 Hồ Sơ Nhiệt)
- **File tác động:** [forge_system.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_system.gd), [heat_bar.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/heat_bar.gd), [forge_session_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_session_ui.gd).
- **Chi tiết cơ chế:**
  1. Phân tách `HEAT_PROFILES` theo `blank_id` của phôi đang rèn:
     - **Nhóm Phôi Nặng (`bua_chien`, `giao_dai`, `khien_dong`):** Khối kim loại dày cần nung thật già lửa — Vùng `lanh` `< 55%`, Vùng `cam` `55% – 79%`, Vùng Đỉnh `do_ruc` **`80% – 92%`**, Quá nhiệt `> 92%` (`burn_limit = 4.5s`), tốc độ nguội tự nhiên chậm (`decay_mult = 0.85`).
     - **Nhóm Phôi Thanh & Phép (`kiem_don`, `song_dao`, `gay_phep`):** Lưỡi mảnh hoặc lõi gỗ/ngọc dẫn linh lực dễ giòn nếu quá lửa — Vùng `lanh` `< 48%`, Vùng `cam` `48% – 64%`, Vùng Đỉnh `do_ruc` **`65% – 80%`**, Quá nhiệt `> 80%` bắt đầu đếm `burn_timer` nhanh hơn (`burn_limit = 3.0s`), mỗi nhát bơm bễ lên nhiệt nhạy hơn (`bellows_mult = 1.12`).
  2. Cập nhật `heat_bar.gd` tự động co giãn vạch màu vùng `cam` / `do_ruc` / `chay` khớp chính xác với hồ sơ của phôi hiện tại, kèm nhãn ngắn trên Thẻ Công Thức góc phải trên (`"Lửa chuẩn: 80–92%"` hoặc `"Lửa chuẩn: 65–80%"`).
  3. Giữ nguyên hệ số nhân sang chỉ số gốc (`do_ruc = 1.4×` + thưởng `+15%` độ rộng vùng `PERFECT` cho Phase 2; `cam = 1.2×`; `lanh = 0.7×`; `chay = 0.5×`).

#### [x] Bước 1.3 — Phase 2: Đập Búa 2 Hướng "Cương / Nhu" Tất Định (Xóa Bỏ Ngẫu Nhiên)
- **File tác động:** [forge_phase2.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_phase2.gd), [beat_bar.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/beat_bar.gd), [forge_session_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_session_ui.gd), [weapon_data.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/weapon_data.gd), [weapon_card_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/ui/weapon_card_ui.gd).
- **Chi tiết cơ chế:**
  1. **Xóa sạch `.pick_random()`** trong `_score_to_prefix()` của `forge_phase2.gd`.
  2. Tách thao tác gõ 5 nhịp trên đe thành **2 phím chủ động định hướng tính chất thép**:
     - **Búa Nặng — Hướng CƯƠNG (`[Space]` hoặc `Chuột Trái`):** Dồn lực đập sâu vào sống thép (`style = "cuong"`), tăng `cuong_hits += 1`. Rung sân khấu `4px`, nổ tia lửa Đỏ Cam, ô huy hiệu nhát búa sáng màu Hổ Phách Đỏ.
     - **Búa Khéo — Hướng NHU (`[Enter]` hoặc `Chuột Phải`):** Gõ dẻo vuốt mép lưỡi & mạch linh khí (`style = "nhu"`), tăng `nhu_hits += 1`. Rung sân khấu `2px`, tia lửa Lam Vàng thanh mảnh, ô huy hiệu nhát búa sáng màu Lam Ngọc.
  3. Điểm chuẩn xác mỗi nhịp giữ nguyên (`PERFECT = +1`, `GOOD = 0`, `MISS = -1`), áp trần nguyên liệu `MATERIAL_PREFIX_CAP` (Nguyên liệu Bậc 1 tối đa `capped_score = 1`, Bậc 2 tối đa `3`, Bậc 3 tối đa `5`).
  4. **Bảng Ánh Xạ Tiền Tố Tất Định 100% (`_resolve_deterministic_prefix`):**
     - `capped_score <= -4` → `phan_chu` (*Phản Chủ*)
     - `capped_score in [-3, -2]` → `curse_nang` (*Lời Nguyền*)
     - `capped_score == -1` → `curse_nhe` (*Nguyền Nhẹ*)
     - `capped_score == 0` → `thuong` (*Bén Ngọt* — chiêu `Slash`)
     - `capped_score == 1`:
       - Thuần Cương (`cuong_hits >= 4`) → `nang_tay` (*Nặng Tay* — `Crushing Blow` 2.0× sát thương)
       - Thuần Nhu (`nhu_hits >= 4`) → `than_toc` (*Thần Tốc* — `Double Strike` đánh 2 nhát)
       - Dung hòa (`cuong_hits` 2–3 và `nhu_hits` 2–3) → `tot` (*Kiên Cố* — `Iron Wall` +5 DEF)
     - `capped_score == 2`:
       - Nghiêng Cương (`cuong_hits > nhu_hits`) → `kiet_tac` (*Kiệt Tác*)
       - Nghiêng Nhu (`nhu_hits >= cuong_hits`) → `can_bang` (*Cân Bằng*)
     - `capped_score == 3`:
       - Nghiêng Cương (`cuong_hits > nhu_hits`) → `to_nghe` (*Tổ Nghề* — `Master Form` + thưởng thắng trận `+50G`)
       - Nghiêng Nhu (`nhu_hits >= cuong_hits`) → `huyen_bi` (*Huyền Bí*)
     - `capped_score == 4`:
       - Nghiêng Cương (`cuong_hits > nhu_hits`) → `cung_nhu_da` (*Cứng Như Đá*)
       - Nghiêng Nhu (`nhu_hits >= cuong_hits`) → `khi_phach` (*Khí Phách*)
     - `capped_score == 5`:
       - Nghiêng Cương (`cuong_hits > nhu_hits`) → `perfect` (*Hào Kiệt* — đỉnh sát thương + thắng trận `+1 Reputation`)
       - Nghiêng Nhu (`nhu_hits >= cuong_hits`) → `truong_sinh` (*Trường Sinh*)
  5. Hiển thị gợi ý siêu gọn ngay dưới thanh `BeatBar`: `[Space/Trái] Búa Cương (Công/Thủ)  ·  [Enter/Phải] Búa Nhu (Tốc/Linh)`.
  6. **Chuẩn hóa 1 nguồn tính chỉ số duy nhất:** Cho `weapon_card_ui.gd` đọc trực tiếp `ForgeConverter.P1_MULTIPLIERS`, `ForgeConverter.PHASE2_BONUS` và `ForgeConverter.weapon_sell_value()` từ `scripts/forge/weapon_data.gd` để xóa triệt để lệch chỉ số/giá bán giữa màn hình rèn, túi đồ, quầy tiệm và trận đánh.

#### [x] Bước 1.4 — Phase 3: Khắc 6 Ấn Linh Lực Tại Bể Tôi & Căn Nhịp Nhúng Nước
- **File tác động:** [forge_phase3.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_phase3.gd), [forge_session_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_session_ui.gd), [forge_visual_stage.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_visual_stage.gd).
- **Chi tiết cơ chế 2 nhịp liền mạch tại Bể Tôi Luyện:**
  1. **Nhịp 3A — Chọn Ấn Linh Lực nổi trên nền Bể Tôi:**
     - Ngay khi vào Phase 3, phủ lớp tối mờ (`alpha = 0.68`) lên background Bể Tôi hiện tại và bung 6 Ấn Linh Lực từ `assets/pixel/ui/forge/element_seals_sheet_64.png` (`hoa`, `bang`, `set`, `tho`, `phong`, `hu_khong`) xếp vòng cung giữa màn hình kèm animation nhịp sáng nhẹ, cộng nút nhỏ bên dưới `[0 / Space] Tôi Nước Thuần (Không khắc hệ)`.
     - Lọc theo `allowed_elements` của `GameManager.selected_material`: Ấn hợp lệ sáng rực, cho phép click chuột hoặc bấm phím `[1..6]`; Ấn trái tính chất nguyên liệu chuyển xám khóa.
  2. **Nhịp 3B — Căn Thời Điểm Nhúng Nước (`try_quench_press()`):**
     - Chọn Ấn xong, lớp tối mờ tan đi, mặt nước trong `forge_quench_tub_144x112.png` nhuộm ánh sáng màu nguyên tố đã chọn.
     - Kẹp sắt đưa phôi nóng đỏ lơ lửng trên miệng bể; vòng Cổ Ngữ thu nhỏ dần trong `QUENCH_DURATION = 2.4s` hội tụ về vòng tâm vàng tại `TARGET_PROGRESS = 0.70` (biên độ chuẩn `±0.08`, tức `0.62 .. 0.78`).
     - Người chơi nhấn `[Space]` hoặc `Chuột Trái` gọi `forge_phase3.try_quench_press()`:
       - **Trúng cửa sổ Vàng (`perfect_quench = true`):** Nổ cột hơi nước trắng + chớp sáng nguyên tố + chữ nổi `★ TÔI HOÀN HẢO (+10% Giá · +10 Bền)` ngay trên miệng bể; nhân `price_mult *= 1.10` và cộng `durability_bonus = 10` (`60/60` độ bền).
       - **Lệch nhịp hoặc hết `2.4s` tự nhúng (`perfect_quench = false`):** Tắt lửa xèo tiêu chuẩn, giữ nguyên thành phẩm (`50/50` độ bền, **không bao giờ phá hủy vũ khí**).
  3. Hiện Thẻ Thành Phẩm ngay giữa sân khấu với 3 hành động tức thì: **[Trang Bị Ngay]**, **[Bày Lên Kệ Tiệm]** (nếu kệ còn chỗ trống `< 3`), **[Cất Vào Kho]**.

#### [x] Bước 1.5 — Đại Tu Nền Cận Trạm 32-Bit (Option B), UI Hữu Cơ & Animation 3 Gu Cho 3 Pha Rèn
- **File tác động:** [forge_visual_stage.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_visual_stage.gd), [forge_session_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_session_ui.gd), `assets/pixel/backgrounds/forge_p1_hearth_bg_640x360.png`, `forge_p2_anvil_bg_640x360.png`, `forge_p3_quench_bg_640x360.png`.
- **Chi tiết đã hoàn thiện:**
  - Chuẩn hóa 3 bức nền cận trạm góc Straight-on Front 3/4 (Lò Than / Mặt Đe / Bể Tôi) đồng nhất chất liệu gỗ đá & ánh lửa cam với Bàn Chuẩn Bị (`640×360`, 96 màu Hoả Tâm, 0 watermark), vẽ liền khối đồ vật thay vì dán 5 sprite tĩnh rời.
  - Phủ `ForgeVisualStage` toàn màn hình 16:9 (0% mixel), dọn thanh đo nhiệt & nhịp búa gọn sát mép dưới (~18%), bỏ hộp gợi ý đen thô và giảm tối overlay chọn 6 Ấn để lộ rõ miệng thùng gỗ, thêm fade chuyển pha `0.22s`.
  - Cài đủ 3 gu Animation: P1 (co bóp bễ cục bộ + luồng gió + lửa bập bùng + hoa văn sen hắt sáng theo nhiệt), P2 (phôi biến hình 5 bước trên mặt đe + hitstop & rung + tia lửa Cương/Nhu + ấn hoa sen mặt/thân đe chớp sáng), P3 (mặt nước nhuộm màu nguyên tố + vòng cổ ngữ elip thu nhỏ + vũ khí chìm cắt đúng đường mặt nước + bọt sóng + luồng sáng nguyên tố quét dọc thân khi nhấc lên).

---

### 🏪 CHẶNG 2: Cửa Tiệm Sống Động — Mặc Cả Đọc Vị & Tiếng Vọng Vũ Khí (`Weapon Echo`)
> **Mục tiêu:** Biến quầy tiệm từ bài toán kéo thanh trượt nhìn vạch màu lộ sẵn thành nghệ thuật đọc sắc mặt khách hàng Thú Nhân, xây dựng mối thân tình khách quen và chứng kiến hệ quả thật từ từng thanh vũ khí mình bán ra.

#### [x] Bước 2.1 — Mặc Cả Đọc Vị Biểu Cảm & Đặc Quyền Khách Quen
- **File tác động:** [negotiation_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/shop/negotiation_ui.gd), [GameManager.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/GameManager.gd), [SaveSystem.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/SaveSystem.gd).
- **Chi tiết cơ chế:**
  1. **Ẩn vạch màu gợi ý từ Ngày 1 trở đi:**
     - Ngày `0` (khách hướng dẫn đầu tiên): Giữ nguyên 3 vùng màu (`_zone_low_rect`, `_zone_good_rect`, `_zone_high_rect`) để dạy khái niệm ngân sách & kiên nhẫn.
     - Từ Ngày `1+`: Đặt `visible = false` cho cả 3 dải màu trên thanh kéo và ẩn con số trần ngân sách `~XG – YG`. Người chơi chỉ biết **Giá gốc định giá của Xưởng (`sell_value`)** và **Giá đề nghị ban đầu của khách (`_offer_gold`)**.
  2. **4 Tầng Phản Ứng Sắc Mặt & Ngôn Ngữ Cơ Thể Thời Gian Thực (cập nhật ngay khi kéo `_price_slider`):**
     - **Tầng 1 — Giá Hời (`proposed <= _offer_gold * 1.05`):** Chân dung khách sáng bừng, nhún nhẹ hào hứng — *"Mắt vị khách sáng rực, tay đã mở sẵn dây rút túi vàng!"*
     - **Tầng 2 — Giá Thuận Mua Vừa Bán (`_offer_gold * 1.05 < proposed <= _npc_max_price * 0.88`):** Khách gật gù ngắm lưỡi gươm — *"Khách ướm thử sức nặng thanh binh khí, sắc mặt khá hài lòng."*
     - **Tầng 3 — Sát Trần Túi Tiền (`_npc_max_price * 0.88 < proposed <= _npc_max_price`):** Chân dung rung nhẹ, hiện giọt mồ hôi — *"Khách nhíu mày đếm nhẩm từng đồng bạc lẻ cuối cùng trong túi..."*
     - **Tầng 4 — Vượt Khả Năng Chi Trả (`proposed > _npc_max_price`):** Chân dung tối sầm, khoanh tay lùi lại — *"Khách cau mày lạnh nhạt — ra giá này chắc chắn làm khách phật ý!"*
  3. **Hệ thống Thân Thiết Khách Hàng (`GameManager.npc_affinities: Dictionary`, lưu bền vững trong `SaveSystem`):**
     - Chốt đơn thuận lợi: `+5 Affinity` (nếu vũ khí trúng `preferred_tags` hoặc `preferred_element` của khách: cộng thêm `+3 Affinity` + câu khen riêng); mặc cả thất bại bỏ về: `-3 Affinity`. Phát `EventBus.npc_affinity_changed(npc_id, new_value)`.
     - **Mốc Thân Thiết mở khóa lợi thế:**
       - `Affinity >= 15` (*Khách Quen*): Hiện huy hiệu nhỏ cạnh tên khách + dòng sổ tay Nấm nhớ mang máng túi tiền khách (`"Khách quen: túi tiền thường tầm ~X–YG"`).
       - `Affinity >= 35` (*Tri Kỷ Nhà Nghề*): Cộng `+1` Kiên nhẫn khi mặc cả và khách sẵn lòng trả cao hơn `+10%` trần mặc định cho vũ khí đúng sở trường.

#### [x] Bước 2.2 — Hệ Thống "Tiếng Vọng Vũ Khí" (`Weapon Echo`) & Vá Chuỗi Kho – Kệ – Đơn Hàng
- **File tác động:** [GameManager.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/GameManager.gd), [SaveSystem.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/SaveSystem.gd), [shop_manager.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/shop/shop_manager.gd), [shop_scene.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/shop/shop_scene.gd), [commission_delivery_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/ui/commission_delivery_ui.gd), `resources/commissions/commission_001..006.tres`.
- **Chi tiết cơ chế `Weapon Echo`:**
  1. Thêm mảng `sold_weapons_history: Array[Dictionary]` vào `GameManager` (giữ tối đa 6 món bán gần nhất, serialize đầy đủ qua `SaveSystem`): lưu `npc_id`, `npc_name`, `weapon_name`, `blank_id`, `phase2_prefix`, `rarity_tier`, `perfect_quench`, `is_cursed`, `matched_pref`, `sold_price`, `sold_day`, `echo_resolved`.
  2. Khi mở cửa tiệm mỗi ngày, kiểm tra các bản ghi có `current_day >= sold_day + 2` và `not echo_resolved`. Với tỷ lệ `35%` (giới hạn tối đa **1 sự kiện Echo mỗi phiên mở tiệm**), vị khách đó bước vào đầu tiên mang theo câu chuyện hậu chiến:
     - **Echo Vinh Quang** (`not is_cursed` và (`rarity_tier >= 3` hoặc `perfect_quench` hoặc `matched_pref`)): Khách hào hứng kể lại trận đánh sinh tử nhờ thanh vũ khí Nấm rèn → tặng lại **1–2 nguyên liệu quý hiếm từ vùng sâu** (`da_ngoc`, `pha_le_rung`, `la_hon`, `nhua_linh`, `go_co_thu` lấy chuẩn từ [ItemDatabase.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/data/ItemDatabase.gd)), cộng **`+1 Reputation`** và **`+10 Affinity`**.
     - **Echo Phản Chủ** (`is_cursed == true` — bán vũ khí dính `curse_nhe`, `curse_nang`, `phan_chu` ra ngoài): Khách băng bó đầy mình quay lại đập thanh sắt gãy nguyền rủa lên quầy → buộc Nấm chọn 1 trong 2 phương án:
       - **[Hoàn trả 50% tiền bán để đền bù]:** Trừ `min(gold, int(sold_price * 0.5))`, bảo toàn Danh tiếng của tiệm.
       - **[Phủi tay từ chối]:** Không tốn vàng nhưng mang tiếng xấu tức khắc → **`-2 Reputation`**, **`-15 Affinity`**, và **1 khách trong hàng chờ hôm đó lập tức quay lưng bỏ đi**.
  3. **Vá triệt để lỗi đồng bộ Kho – Kệ – Đơn hàng:**
     - Sửa `shop_manager.gd` hàm `_get_scripted_customer_id()` trả về đúng `"hiep_khach"` khớp với `resources/customers/hiep_khach.tres` (xóa lỗi lệch tên `"hiep_khach_lang_bat"`).
     - Khi giao vũ khí hoàn thành Đơn đặt hàng trong `commission_delivery_ui.gd` / `CommissionSystem.gd`: tự động gỡ vũ khí đó khỏi cả `InventorySystem.weapons`, `InventorySystem.shelf_weapons` và `GameManager.equipped_weapons` để tuyệt đối không sinh bản sao ma.
     - Tạo thêm 4 file đơn hàng mới (`commission_003.tres` → `commission_006.tres`) trải đều cho 6 phôi Chương 1 và yêu cầu rõ hướng rèn (ví dụ: Thợ Săn Cáo đặt `giao_dai` Thần Tốc/Cân Bằng hệ Phong; Thủ Vệ Lợn Rừng đặt `khien_dong` Kiên Cố/Cứng Như Đá hệ Thổ; Đạo Sĩ Hạc đặt `gay_phep` Huyền Bí hệ Băng; Võ Tăng Gấu đặt `bua_chien` Nặng Tay/Tổ Nghề hệ Hỏa).

---

### ⚔️ CHẶNG 3: Chiến Đấu 6 Phôi Thật, Kinh Tế 12 Ngày & Cốt Truyện Chương 1
> **Mục tiêu:** Làm cho việc tự tay rèn vũ khí để mang đi đánh quái có ý nghĩa chiến thuật rõ rệt trên từng loại phôi, đồng thời khép kín vòng lặp kinh tế – cốt truyện căng thẳng suốt 12 ngày của Chương 1.

#### [ ] Bước 3.1 — Hiện Thực Hóa 6 Kỹ Năng Bẩm Sinh `[0 STA]` & Thưởng Chiến Thắng Theo Tiền Tố
- **File tác động:** [player_combat_unit.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/combat/player_combat_unit.gd), [combat_manager.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/combat/combat_manager.gd), [combat_scene.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/combat/combat_scene.gd), [weapon_data.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/weapon_data.gd).
- **Bảng 6 Kỹ Năng Bẩm Sinh `[0 STA]` gắn liền với 6 Phôi Chương 1 (thay thế hoàn toàn đòn đánh thường vô vị):**

| Mã Phôi (`blank_id`) | Tên Chiêu `[0 STA]` | Cơ chế thực thi trong `combat_manager.gd` | Vai trò chiến thuật |
|---|---|---|---|
| `kiem_don` | **Trảm Chuẩn** | Gây **`1.15× ATK`** sát thương vật lý ổn định. | Vũ khí chuẩn mực, sát thương đều mọi tình huống. |
| `song_dao` | **Song Nha** | Chém **2 nhát liên hoàn**, mỗi nhát **`0.65× ATK`** (kiểm tra chí mạng/hiệu ứng 2 lần). | Tối ưu phá quái giáp mỏng, kích nổ chí mạng. |
| `giao_dai` | **Trường Thương Tiên Phong** | Gây **`1.00× ATK`** + cờ **`always_first_strike = true`** (luôn đánh trước quái trong lượt đó trừ khi quái Defend). | Kết liễu quái sắp hết máu trước khi kịp ra đòn. |
| `bua_chien` | **Chấn Sơn Chùy** | Gây **`1.10× ATK`** + làm mềm giáp địch **`-2 DEF` trong 2 lượt** (tối đa `-4 DEF`). | Mở màn phá giáp quái cứng V2 rồi đổi vũ khí dứt điểm. |
| `khien_dong` | **Thuẫn Kích** | Gây **`0.80× ATK`** + dựng khiên cộng **`+3 DEF` cho Nấm trong 1 lượt**. | Vừa gây sát thương vừa đỡ đòn báo hiệu mạnh của quái. |
| `gay_phep` | **Linh Đạn** | Tính sát thương theo **`1.15× Magic`** (thay vì `ATK`) và **bỏ qua 50% DEF vật lý** của địch. | Khắc tinh của quái da sắt/vỏ cây cứng nhưng kháng phép thấp. |

- Cập nhật `combat_scene.gd`: Nút hành động cơ bản `[0 STA]` đổi tên & tooltip động theo đúng phôi đang cầm ở `active_slot` mỗi khi vào trận hoặc chuyển đổi giữa 3 ô vũ khí.
- Bổ sung thưởng hậu chiến trong `combat_manager.gd` khi kết thúc trận thắng (`"win"`): nếu vũ khí đang cầm mang tiền tố `"to_nghe"` → cộng thêm **`+50G`**; nếu mang tiền tố `"perfect"` (*Hào Kiệt*) → cộng thêm **`+1 Reputation`**.

#### [ ] Bước 3.2 — Mở Trần 12 Ngày, Khám Phá V1–V2, Thu Nợ C2 & Đoạn Kết Chương 1
- **File tác động:** [GameManager.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/GameManager.gd), [DebtSystem.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/DebtSystem.gd), [SaveSystem.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/autoload/SaveSystem.gd), [workshop_debt_controller.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/main/workshop_debt_controller.gd), [exploration_scene.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/regions/exploration_scene.gd), [day_summary_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/ui/day_summary_ui.gd), [region_select_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/ui/region_select_ui.gd), [smoke_test.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/tools/smoke_test.gd), `resources/enemies/*.tres`.
- **Chi tiết thực thi:**
  1. **Mở tiến trình từ Demo 4 ngày lên Chương 1 12 ngày (`CHAPTER1_LAST_DAY = 12`):**
     - Thêm `const CHAPTER1_LAST_DAY := 12` vào `GameManager.gd` (giữ `DEMO_LAST_DAY := 4` riêng cho logic lọc tập khách nhẹ nhàng 4 ngày đầu trong `shop_manager.gd` để người chơi không bị ngợp, sang Ngày 5 tự động mở toàn bộ 9 lớp khách hàng Thú Nhân).
     - Sửa `workshop_debt_controller.gd`: gỡ rào cản `_is_demo_runtime()` khỏi mốc `DEBT_C2_ID` (`c2_dan_duong`), chỉ chặn `C3` và `C4` ngoài Chương 1 (`day > GameManager.CHAPTER1_LAST_DAY`). Sáng Ngày 5, **Tay Sai Rừng** xuất hiện tại Xưởng giao hạn nợ **`8,000G` (hạn tối Ngày 12)** đúng kịch bản `GuideBook.get_tay_sai_rung_dialogue()`.
     - Trong `region_select_ui.gd`: chỉ cho phép vào `DongMay` và `RungTramHon` (khi đã mở khóa); các vùng `NuiThanDo`, `BaiCat`, `ThanhNgoc`, `LangTo` hiển thị rõ nhãn *"Mở khóa ở Chương 2+"*.
  2. **Nâng cấp `day_summary_ui.gd` & Sự kiện Khép Lại Chương 1 (Tối Ngày 12):**
     - Tự động theo dõi mốc nợ hiện hành (`c1_mat_bang` trong Ngày 1–4; chuyển sang `c2_dan_duong` từ Ngày 5–12 với số tiền còn thiếu & số ngày đếm ngược chính xác).
     - Tối Ngày 4 (sau khi thanh toán C1): hiện bảng chuyển cảnh mở đường vào **Rừng Trăm Hồn (`RungTramHon`)** và manh mối từ **Cô Lộng Gió**.
     - Tối Ngày 12 (sau khi thanh toán C2 `8,000G`): kích hoạt **Màn Hình Kết Chương 1 — "Lửa Hồng Giữa Rừng Sâu"** tổng kết thành tựu 12 ngày (tổng vũ khí đã rèn, danh tiếng đạt được, Mảnh Cổ Khí đầu tiên đã thu hồi, bức mật thư đóng ấn Hắc Nguyệt báo hiệu Chương 2 tại Núi Than Đỏ), lưu file an toàn và cho phép người chơi chọn về Menu Chính hoặc tiếp tục rèn tự do.
  3. **Vá dứt điểm luồng Rút Lui Khám Phá & Đồng Bộ Lưu Trữ:**
     - Trong `exploration_scene.gd`: bấm nút HUD `← Về Xưởng` ở **bất kỳ phân cảnh nào (`0..5`)** cũng chuyển toàn bộ chiến lợi phẩm trong `GameManager.hand_inventory` về `InventorySystem` trước khi chuyển cảnh về `WorkshopHub.tscn` (xóa bẫy mất đồ nếu rút lui ở phân cảnh giữa).
     - Trong `GameManager.gd` & `SaveSystem.gd`: khi khôi phục file save (`restore_save_state`), ánh xạ lại 3 slot `equipped_weapons` trỏ đúng vào object vũ khí tương ứng bên trong `InventorySystem.weapons` để độ bền và trạng thái trang bị luôn đồng nhất.
     - Đấu nối hoàn chỉnh sự kiện tại phân cảnh cuối `LANDMARK` của `RungTramHon`: gặp **Tướng Nai Bóng Rừng**, hoàn thành nhiệm vụ `first_artifact_shard.tres`, nhận **Mảnh Cổ Khí số 1** (`GameManager.artifact_count = 1`, phát `EventBus.artifact_collected(1)` & `EventBus.quest_completed("first_artifact_shard")`).
  4. **Cân bằng Kinh tế & Chỉ số 6 Quái V1–V2:**
     - Tinh chỉnh chỉ số 3 quái V1 (`soi_dong_co_t1.tres`, `bandit_tre_t1.tres`, `soi_gia_t2.tres`) và 3 quái V2 (`hon_rung_t1.tres`, `quy_rung_t1.tres`, `thu_ma_rung_t2.tres`):
       - V1 vừa sức với vũ khí Bậc 1 (`ATK 10–16`), thu nhập trung bình `750G – 1,000G/ngày` → đủ trả `3,000G` C1 nếu quản lý thể lực hợp lý.
       - V2 tăng rõ rệt máu/giáp/sát thương (`thu_ma_rung_t2` đòi hỏi vũ khí Bậc 2 rèn tốt + phối hợp Phá Giáp / Đỡ Khiên / Linh Đạn). Vũ khí Bậc 2 chất lượng cao định giá `1,100G – 1,800G` — tạo thế giằng co chiến lược thật sự giữa **giữ lại thanh vũ khí mạnh nhất để vượt Rừng Trăm Hồn** hay **bán đi để kịp gom đủ `8,000G` trả nợ C2**.

---

### 🎨 CHẶNG 4: Đồng Bộ 100% Pixel Art 32-Bit Hoả Tâm Cho Trọn Bộ Chương 1 ✅
> **Mục tiêu:** Mọi khung hình, nhân vật, khách hàng, quái vật và điểm thu thập xuất hiện từ Ngày 0 đến Ngày 12 đều đạt chuẩn 32-bit Hoả Tâm sắc nét, di chuyển sống động, không còn bất kỳ khối màu tạm hay hình tĩnh chắp vá nào.
> **Công cụ bắt buộc:** Chạy qua script chuẩn hóa bảng màu 96 màu & viền `#120C10` tại [hoa_tam_32bit_pipeline.ps1](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/.agents/skills/lo-thieng-pixel-assets/scripts/hoa_tam_32bit_pipeline.ps1) theo đúng quy trình trong [SKILL.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/.agents/skills/lo-thieng-pixel-assets/SKILL.md).

#### [x] Bước 4.1 — Bối Cảnh Chiến Đấu & Khám Phá V1 – V2 (`640×360 px` ×3 = `1920×1080`)
- *Đã hoàn thành sẵn:* `combat_v1_dong_may_640x360.png`, `workshop_hub_bg_640x360.png`, `shop_bg_640x360.png`, `forge_workbench_bg_640x360.png`, `forge_hearth_bg_640x360.png`, `main_menu_bg_640x360.png`.
- *Đã tạo mới & đấu nối vào `combat_scene.gd` & `exploration_scene.gd`:*
  1. `assets/pixel/backgrounds/combat_v2_rung_tram_hon_640x360.png` — Đấu trường Rừng Trăm Hồn sương lam, rễ đại thụ uốn lượn, đom đóm linh hồn, khoảng đất phẳng trái/phải rõ ràng cho Nấm và quái.
  2. `assets/pixel/backgrounds/explore_v1_dong_may_640x360.png` + bộ prop thu thập 32-bit (`assets/pixel/tilesets/explore/v1_props_sheet.png`).
  3. `assets/pixel/backgrounds/explore_v2_rung_tram_hon_640x360.png` + bộ prop thu thập 32-bit (`assets/pixel/tilesets/explore/v2_props_sheet.png`).

#### [x] Bước 4.2 — Sprite Sheet Quái Vật V2 Rừng Trăm Hồn (`256×256 px` — Lưới 4×4 ô `64×64`, neo chân `(32, 60)`)
- *Đã hoàn thành sẵn (V1):* `soi_dong_co_t1_sheet_64.png`, `bandit_tre_t1_sheet_64.png`, `soi_gia_t2_sheet_64.png`.
- *Đã tạo mới & đấu nối cho V2 (`combat_scene.gd` & `exploration_scene.gd` + sửa `BaseCharacter.get_or_build_frames` hỗ trợ sheet 4×4):*
  1. `assets/pixel/sprites/enemies/hon_rung_t1_sheet_64.png` — Cáo Sương / Linh Thú Đom Đóm Hồn Rừng.
  2. `assets/pixel/sprites/enemies/quy_rung_t1_sheet_64.png` — Quỷ Rừng Thú Nhân khoác giáp vỏ cây sừng rêu.
  3. `assets/pixel/sprites/enemies/thu_ma_rung_t2_sheet_64.png` — Thú Ma Rừng (Mãnh thú Hắc Ám tinh anh canh giữ rừng sâu).

#### [x] Bước 4.3 — NPC Cốt Truyện Chương 1 & 9 Khách Hàng Thú Nhân (`64×64` / cell, kế thừa `BaseCharacter`)
- *Đã hoàn thành sẵn:* `nam_4dir_sheet_64.png` (`1024×896`, 16×14 4 hướng).
- *Đợt nâng cấp 5 NPC Cốt Truyện (chuẩn hướng phải & hỗ trợ 4 hướng trong code):*
  - `ba_hac_nguyet_sheet_64.png`, `co_long_gio_sheet_64.png`: Hoàn thiện **full 4 hướng (`1024×896`, 16×14)** dựng từ 3 strip đi bộ vẽ tay 4 dáng thật (`walk_down`, `walk_up`, `walk_right` trong `assets/pixel/sprites/npcs/raw/`).
  - `nguoi_thu_no_c1_sheet_64.png`: `1024×256` (16×4) dựng từ strip đi bộ vẽ tay ngang 4 dáng thật (`assets/pixel/sprites/npcs/raw/nguoi_thu_no_c1_walk_right_strip.png`).
  - `tay_sai_rung_c2_sheet_64.png`, `tuong_nai_bong_rung_sheet_64.png`: Nâng cấp lên `1024×256` (16×4 đa pha mượt) từ bản 32-bit sẵn có (`-Mode upgradeSide16FromSprite`).
  - Đấu nối di chuyển/hoạt ảnh mượt & hỗ trợ 4 hướng tại [base_character.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/characters/base_character.gd), [debt_agent_node.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/ui/debt_agent_node.gd), [workshop_hub.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/main/workshop_hub.gd), [exploration_scene.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/regions/exploration_scene.gd).
  - *Hạng mục nối tiếp (Đợt sau khi quota sinh ảnh mở lại):* Sinh thêm strip hướng trước/sau cho 5 NPC cốt truyện lên `1024×896` (`-Mode char4Dir`) + nâng cấp Đợt 2 cho **9 Khách Hàng Thú Nhân** (`assets/pixel/sprites/customers/`) & `customer_ai.gd`.
- *Hiện có cho 9 Lớp Khách Hàng Thú Nhân vào `customer_ai.gd` & `negotiation_ui.gd` (`assets/pixel/sprites/customers/`):*
  - 5/9 bản vẽ chi tiết cao qua `image-generator` + pipeline (`4×4`): `nong_dan_sheet_64.png`, `ve_binh_sheet_64.png`, `tho_san_sheet_64.png`, `hiep_khach_sheet_64.png`, `thuong_nhan_sheet_64.png`.
  - 4/9 bản 32-bit vẽ script qua pipeline (`4×4`, chờ nâng cấp khi quota mở lại): `thich_khach_sheet_64.png`, `dao_si_sheet_64.png`, `vo_tang_sheet_64.png`, `thu_ve_sheet_64.png`.

#### [x] Bước 4.4 — Huy Hiệu & Hiệu Ứng UI 32-Bit Bổ Trợ Lối Chơi Mới (`assets/pixel/ui/`)
1. `assets/pixel/ui/forge/hammer_cuong_nhu_sheet_32.png` + bộ UI 3 pha lò rèn 32-bit (`forge_heat_frame_9s.png`, `forge_heat_needle.png`, `forge_heat_divider.png`, `forge_cook_fill_9s.png`, `forge_beat_cursor.png`, `forge_element_card.png`, `forge_card_glow.png`).
2. `assets/pixel/ui/forge/quench_rune_ring_128.png` — đấu nối vào `forge_visual_stage.gd`.
3. `assets/pixel/ui/shop/customer_mood_emotes_32.png` — đấu nối vào `negotiation_ui.gd`.

---

### ✨ CHẶNG 5: Đánh Bóng Cảm Giác Tay (Tactile Juice) & Kiểm Thử Toàn Diện 12 Ngày
> **Mục tiêu:** Chốt chất lượng xuất xưởng cho Chương 1 — mỗi cú đập búa, nhát chém, tiếng xèo tôi thép và giao dịch vàng đều "đã tay", mượt mà và sạch lỗi 100%.

#### [ ] Bước 5.1 — Đánh Bóng Xúc Giác & Âm Thanh Tương Tác
- **Tại Lò Rèn (`ForgePrepUI` & `ForgeSession`):**
  - Hiệu ứng lật trang giấy uốn mượt + SFX sột soạt giấy cổ; hiệu ứng ấn con dấu sáp đỏ lún nhẹ trước khi chuyển cảnh.
  - Khác biệt rõ rệt cảm giác tay ở Phase 2: **Búa Cương** trầm nặng (pitch SFX `0.92`, rung `4px`, hạt lửa cam văng rộng) vs **Búa Nhu** thanh sắc (pitch SFX `1.12`, rung `2px`, tia lửa lam vàng chụm gọn).
  - Phase 3 `Perfect Quench`: cột khói hơi nước trắng bốc lên từ miệng bể + quầng sáng màu nguyên tố lan trên lưỡi vũ khí mới rèn.
- **Tại Cửa Tiệm & Chiến Đấu:**
  - Hiệu ứng chữ số vàng nảy giòn khi chốt đơn thành công; hiệu ứng rung thẻ khách hàng khi ép giá quá trần.
  - Vệt sáng đòn đánh riêng biệt cho 6 chiêu bẩm sinh `[0 STA]` (vệt chém chéo đơn, vệt song đao chữ X, mũi giáo xuyên ngang, chấn động mặt đất của búa, vầng khiên đồng ánh kim, tia linh đạn phát sáng).

#### [ ] Bước 5.2 — Kiểm Định Tĩnh, Smoke Test & Chơi Thử Xuyên Suốt Ngày 0 → Ngày 12
- [ ] Chạy `gdlint` trên toàn bộ các tệp `.gd` đã chỉnh sửa (**0 lỗi cú pháp / quy chuẩn đặt tên**).
- [ ] Chạy `python scripts/tools/static_check.py` đạt **PASS tuyệt đối cả 9 CHECK** (0 dead signal, 0 missing resource, **CHECK 9 = 0 tham chiếu tới assets cũ**).
- [ ] Cập nhật & chạy [smoke_test.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/tools/smoke_test.gd) phủ đủ các bài test tự động:
  1. Bảng ánh xạ tất định `(score, cuong_hits, nhu_hits)` luôn trả về đúng Prefix cố định (0 ngẫu nhiên).
  2. `ForgeConverter` và `WeaponCardUI` cho kết quả `ATK / DEF / MAG / sell_value` trùng khớp 100%.
  3. Lưu và đọc lại `SaveSystem` bảo toàn nguyên vẹn `npc_affinities`, `sold_weapons_history`, trạng thái nợ `C1/C2` và liên kết `equipped_weapons`.
  4. Giao đơn đặt hàng gỡ sạch vũ khí khỏi cả Kho, Kệ 3 ô và Ô trang bị.
- [ ] Playtest thực tế vòng lặp hoàn chỉnh **Ngày 0 → Tối Ngày 12**: xác nhận trả nợ C1 (`3,000G`), mở khóa `RungTramHon`, kích hoạt ít nhất 1 sự kiện `Weapon Echo`, thu hồi Mảnh Cổ Khí đầu tiên, trả nợ C2 (`8,000G`) và xem trọn vẹn màn hình khép lại Chương 1.

---

## 🔍 NHẬT KÝ RÀ SOÁT TOÀN BỘ NỀN TẢNG CODE (`/repo-audit`)

- **Phạm vi đã sửa ngay:**
  - **Lõi & Save/Load:** Đồng bộ `SceneManager` khi pause & bảo vệ click-through, sửa thứ tự pha/ngày `DayCycle` & tránh nuốt thông báo nợ C2/C3/C4, dọn sạch runtime state khi `restore_from_save` / `init_new_game`, lưu `hand_inventory` và `commissions_completed`, gán `uid` duy nhất cho vũ khí rèn, sửa `collect_artifact` + `_grant_quest_reward`.
  - **Database & Rèn:** Chuẩn hóa key nguyên tố chữ thường & tag `phoi_con_nhi_khuc` / `phoi_no_ban` / nguyên liệu thô, chặn double-consume nguyên liệu và exploit Enter sớm trong Lò Rèn, mở khóa phôi Kẹp III theo `NuiThanDo`, đồng bộ `rarity_tier` và tên hiển thị trên `WeaponCardUI`.
  - **Chiến đấu & Thám hiểm:** Sửa đóng băng (`freeze_turns`), bỏ qua phòng thủ chiêu phép, counter bonus của `DAMAGE_HEAL`, điều kiện áp hiệu ứng `DAMAGE_STATUS`, hủy timer treo qua `_combat_session_id`, sửa thu thập Tướng Nai `RungTramHon` & node hái lượm + respawn cổng vào `ExplorationScene`.
  - **Tiệm, Thương lượng, Workshop & UI:** Bảo vệ vũ khí khởi đầu khi bán/đổi, đồng bộ `InventoryUI` visibility, sửa `PauseMenuUI` z-order, chặn input xuyên modal trong `WorkshopHub` & `ShopScene`, sửa tính toán gợi ý/đe dọa/ghi nhận giao dịch trong `NegotiationUI`, cập nhật `DaySummaryUI` đa mốc nợ, sửa lệch index `InventoryPanel`, thêm `refresh()` cho `RegionSelectUI`.
  - **Smoke Test:** Bổ sung hàm `_check_audit_regressions()` trong [smoke_test.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/tools/smoke_test.gd) và sửa leak node `ForgePhase3.new()`.
- **Hạng mục cần xử lý thủ công / chờ xác nhận:**
  1. **Godot Editor:** Sửa 8 đường dẫn legacy `res://assets/indicator/...` trong [ForgePhaseIndicator.tscn](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scenes/forge/ForgePhaseIndicator.tscn) (không sửa `.tscn` bằng text editor).
  2. **File cũ đã dọn dẹp:** Đã xóa `scenes/forge/ElementPicker.tscn`, `scripts/forge/element_picker_ui.gd` (+ `.uid`), `scripts/tools/commission_smoke_test.gd` (+ `.uid`) và tinh gọn [forge_book_ui.gd](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scripts/forge/forge_book_ui.gd) còn stub 5 dòng; chỉ còn mở [ForgeSession.tscn](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/scenes/forge/ForgeSession.tscn) trong Godot Editor để gỡ node `ForgeBookUI`, sau đó có thể xóa hẳn file stub `forge_book_ui.gd`.
  3. **Kiểm tra thực tế trong Godot Editor:** Chạy `gdlint`, `static_check.py` (nếu có Python ngoài sandbox) và `smoke_test.gd` trong Godot Editor.
