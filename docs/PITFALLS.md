# ⚠️ SỔ TAY CẠM BẪY KỸ THUẬT (PITFALLS & LESSONS LEARNED)
> **Ghi lại các lỗi phi hiển nhiên đã gặp phải và quy tắc phòng tránh lặp lại cho Lò Thiêng.**

1. **Mất dữ liệu sau Save/Load khi tách mảng trạng thái:**
   - *Gốc rễ:* Khi đưa vũ khí từ túi lên kệ tiệm (`shelf_weapons`), `SaveSystem` chỉ lưu `InventorySystem.get_weapons()`.
   - *Quy tắc:* Mọi container chứa vật phẩm sở hữu (túi, rương, kệ tiệm) đều phải được đăng ký đầy đủ vào `save_game()` và `load_game()`.

2. **Kẹt nhân vật (Soft-lock) do mâu thuẫn giữa Clamp Bounds và Area2D:**
   - *Gốc rễ:* `_clamp_player_in_bounds` kẹp toạ độ nhỏ hơn toạ độ đặt vùng `Area2D` của cửa chuyển cảnh.
   - *Quy tắc:* Luôn kiểm tra vùng va chạm kích hoạt (`Area2D`) nằm trọn vẹn trong khoảng di chuyển cho phép của người chơi (`min_x + margin`, `max_x - margin`).

3. **Lỗi đường dẫn tài nguyên tiếng Việt trên Windows/Godot:**
   - *Gốc rễ:* Tệp trên ổ cứng lưu theo Unicode dựng sẵn (NFC), nhưng chuỗi trong code bị gõ tổ hợp (NFD) dẫn đến `load()` trả về `null`.
   - *Quy tắc:* Luôn chuẩn hóa đường dẫn có dấu tiếng Việt về chuẩn NFC trước khi tham chiếu trong GDScript.

4. **Tuyệt đối không sửa tệp Scene `.tscn` bằng Text Editor:**
   - *Gốc rễ:* Trình soạn thảo văn bản dễ làm hỏng UID, định dạng node con và cache scene của Godot 4.
   - *Quy tắc:* Chỉ sửa scene bằng Godot Editor; nếu cần thêm UI bổ trợ, hãy dùng `preload().instantiate()` và `add_child()` trong GDScript.
