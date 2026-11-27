# ⚠️ PITFALLS.md — Cạm Bẫy Cần Tránh Khi Phát Triển Lò Thiêng
> **Mọi AI Agent (Antigravity, Claude, Codex) BẮT BUỘC đọc file này trước khi bắt đầu bất kỳ task nào.**

---

## 1. CẠM BẪY NGHIÊM TRỌNG NHẤT: Tái sử dụng hoặc vẽ art mới "bọc xung quanh" Assets cũ
- **Lỗi đã xảy ra:** Tạo khung UI, bục đá, lò than, đe sắt, bể tôi luyện 32-bit mới tinh trong `assets/pixel/`, nhưng lại nạp icon vũ khí cũ (`res://assets/weapons/Nguyên mẫu/...`), icon nguyên liệu cũ (`res://assets/UI/forge/nguyen_lieu/...`), hoặc giữ đường dẫn fallback nền cũ (`res://assets/sprites/...`) đè lên trên. Kết quả là hình ảnh 2D vẽ tay/HD cũ bị trộn lẫn kệch cỡm với pixel art 32-bit mới.
- **Quy tắc bắt buộc (Zero Legacy Asset Reuse):**
  1. **Toàn bộ thư mục cũ** (`assets/weapons/`, `assets/UI/`, `assets/sprites/`, `assets/characters/`) **CHỈ DÙNG ĐỂ LẤY Ý TƯỞNG (Concept / Tên vật phẩm / Phân loại)** — **TUYỆT ĐỐI KHÔNG DÙNG LẠI TRONG GAME**.
  2. **KHÔNG** vẽ khung, bục, hay sân khấu 32-bit để "bọc" xung quanh ảnh `.png` cũ.
  3. **KHÔNG** giữ `FALLBACK_PATH` trỏ về thư mục assets cũ.
  4. **KHÔNG** lấy ảnh cũ đem thu nhỏ (downscale) làm pixel art; phải sinh mới hoàn toàn theo chuẩn **32-bit Hoả Tâm Pixel Art (96 màu)** và lưu trong `res://assets/pixel/`.
  5. Khi nâng cấp bất kỳ màn hình nào, nếu nhóm icon/sprite của màn hình đó chưa có bản 32-bit trong `assets/pixel/`, phải **tạo mới bộ sprite 32-bit trong `assets/pixel/`** (hoặc vẽ procedural pixel art 32-bit đồng bộ) chứ tuyệt đối không load file từ thư mục cũ.

---

## 2. Cạm bẫy UI: Nhồi quá nhiều chữ và lặp thông tin trên 1 màn hình

## 3. Cạm bẫy Thiết kế Nhân vật: Vẽ nhầm sang Loài Người (Quên luật 100% Animal Folk trong GDD)
- **Lỗi đã xảy ra:** Không đọc Mục 2.1–2.4 của `docs/GAME_DESIGN_MASTER.md` trước khi sinh chân dung hội thoại, dẫn đến vẽ Bà Trùm Hắc Nguyệt, Cô Lộng Gió và Người Thu Nợ thành **người** thay vì động vật nhân hóa.
- **Quy tắc bắt buộc (100% Animal Folk — KHÔNG CÓ LOÀI NGƯỜI):**
  1. **Thế giới Lò Thiêng 100% là Động Vật Nhân Hóa (Anthropomorphic Animal Folk)** — tuyệt đối không bao giờ vẽ nhân vật mặt người.
  2. Luôn đối chiếu đúng loài trong `docs/GAME_DESIGN_MASTER.md` + sprite concept gốc trước khi viết prompt:
     - **Nấm:** Mèo thợ rèn lông vàng cam.
     - **Bà Trùm Hắc Nguyệt:** **Cáo đen quý tộc** đại tỷ thế giới ngầm (trâm trăng lưỡi liềm, khăn lông đen, quạt xếp đen vẽ trăng vàng — KHÔNG vẽ báo hay thủ thư).
     - **Cô Lộng Gió:** **Cò / Sếu Trắng** nhân hóa (mỏ dài thanh thoát, lông trắng).
     - **Đao Phủ / Người Thu Nợ:** **Lửng Mật / Thú nhân** (tuyệt đối không vẽ người trùm mũ).
     - **Mọi khách hàng tiệm & NPC vùng:** 100% Động vật nhân hóa (Hươu, Lợn Rừng, Trâu, Gà Chọi, Vượn, Cáo, Sói, Mèo, Cò...).

- **Lỗi đã xảy ra:** Xếp 12–14 dòng `Label` dọc từ trên xuống dưới (Tiêu đề 64px, Nhiệt độ X/100, Vùng hiện tại, 2 hàng chú thích %, dòng hướng dẫn dài, hộp popup chặn chuột), khiến sân khấu đồ họa 32-bit bị ép nhỏ lại và người chơi bị ngợp chữ.
- **Quy tắc bắt buộc:**
  1. **Sân khấu 32-bit là nhân vật chính (~65% diện tích giữa màn hình).**
  2. Mỗi thông tin chỉ hiển thị ở **1 nơi duy nhất** (ví dụ: đã có thanh `ForgePhaseIndicator` 6 bước ở đỉnh thì bỏ tiêu đề 64px; đã có 5 ô huy hiệu nhát búa thì bỏ dòng `"Nhát 1/5"`).
  3. Phản hồi tương tác (`★ PERFECT`, `COMBO x3`, `+40% Stats`) phải nổ trực tiếp tại điểm hành động (mặt đe, lò than, bể tôi), không tạo dòng trống cố định bên dưới.

## 4. Cạm bẫy Theme toàn cục: Đặt `outline_size` tối ở `project.godot` / `hoa_tam_pixel_theme.tres`
- **Lỗi đã xảy ra:** Ép `outline_size = 5` màu tối vào theme mặc định toàn dự án khiến toàn bộ chữ mực tối trên nền giấy sáng (Cuốn Sổ Cẩm Nang, Tờ Đơn Hàng ở `ForgePrepUI`) bị nở đen bết dính vào nhau.
- **Quy tắc bắt buộc:** `hoa_tam_pixel_theme.tres` chỉ cấu hình font (`PixelifySans.ttf`) và cỡ chữ nền; tuyệt đối không đặt `outline_size` hay `shadow` toàn cục. Viền tối chỉ thêm cục bộ trên từng `Label` chữ sáng nằm trực tiếp trên nền tối.
