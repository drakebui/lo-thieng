# REVIEW_PROTOCOL.md — Engineering Lead Auto-Review
> Workflow này chạy sau MỖI session coding của Codex.
> EL (Claude) đọc output và báo cáo — KHÔNG tự sửa code.

---

## Cách trigger review

Bạn paste vào chat với Claude (EL) theo format sau:

```
REVIEW SESSION [ngày/số session]

[Dán nội dung NOTES.md mà Codex vừa cập nhật]

[Dán toàn bộ code của các file mới hoặc file đã sửa]
```

Claude sẽ tự động chạy checklist bên dưới và xuất báo cáo.

---

## Auto-Review Checklist (EL chạy mỗi lần)

### A. CORRECTNESS — Logic có đúng không?
- [ ] A1: Logic đúng với yêu cầu task trong AGENTS.md không?
- [ ] A2: Milestone condition có được implement đủ không?
- [ ] A3: Edge cases đã xử lý chưa? (null, empty array, node chưa ready)
- [ ] A4: Signal emit đúng tên và đúng lúc không?

### B. ARCHITECTURE — Có phá pattern không?
- [ ] B1: Có gọi thẳng node khác thay vì qua EventBus không?
- [ ] B2: Có đọc/ghi gold, day, reputation ngoài GameManager không?
- [ ] B3: Có hard-code data mới vào logic file thay vì Database không?
- [ ] B4: Có nhét 2 system vào 1 file không?
- [ ] B5: Có duplicate logic đã có ở file khác không?

### C. GODOT IDIOMS — Dùng đúng Godot 4 chưa?
- [ ] C1: Dùng `@export` thay vì `export` (Godot 3 syntax)?
- [ ] C2: Dùng `super()` thay vì `.` (Godot 3)?
- [ ] C3: Signal connect dùng `signal_name.connect()` không?
- [ ] C4: Có dùng `get_node()` string path dài thay vì `@onready`?
- [ ] C5: Có `await` đúng chỗ khi cần async?

### D. SCOPE — Có vượt scope không?
- [ ] D1: Có implement feature ngoài task không?
- [ ] D2: Có tự ý refactor file cũ không được yêu cầu?
- [ ] D3: Có tự chuyển sang task khác khi chưa xong task hiện tại?

### E. INTEGRATION — Có kết nối đúng không?
- [ ] E1: File mới có được add vào đúng scene chưa?
- [ ] E2: Autoload mới (nếu có) có được đăng ký không?
- [ ] E3: Signal mới emit có được lắng nghe ở đâu đó không?
- [ ] E4: Có conflict với file khác đã tồn tại không?

---

## Report Format (EL xuất sau mỗi review)

```
═══════════════════════════════════════════
REVIEW REPORT — Session [X] — [tên task]
═══════════════════════════════════════════

STATUS: ✅ PASS | ⚠️ PASS WITH ISSUES | ❌ REJECT

───────────────────────────────────────────
TÓM TẮT
───────────────────────────────────────────
[2-3 câu: Codex đã làm gì, kết quả tổng thể]

───────────────────────────────────────────
LỖI TÌM THẤY
───────────────────────────────────────────
[Nếu không có lỗi: "Không có lỗi nghiêm trọng."]

❌ [CRITICAL] — [mô tả lỗi] — File: xxx.gd:dòng X
   → Lý do: [tại sao đây là lỗi]
   → Cần sửa: [Codex cần làm gì — KHÔNG phải code fix]

⚠️ [WARNING] — [mô tả] — File: xxx.gd:dòng X
   → Lý do: [tại sao đáng chú ý]
   → Đề nghị: [gợi ý hướng sửa]

📝 [NOTE] — [thông tin bổ sung, không phải lỗi]

───────────────────────────────────────────
CHECKLIST KẾT QUẢ
───────────────────────────────────────────
A. CORRECTNESS  : ✅ / ⚠️ / ❌
B. ARCHITECTURE : ✅ / ⚠️ / ❌
C. GODOT IDIOMS : ✅ / ⚠️ / ❌
D. SCOPE        : ✅ / ⚠️ / ❌
E. INTEGRATION  : ✅ / ⚠️ / ❌

───────────────────────────────────────────
MILESTONE PROGRESS
───────────────────────────────────────────
[ ] Di chuyển được trong Đồng Mây, nhặt 3 node
[ ] Random encounter trigger → combat → về map
[ ] Stamina hết → force return về xưởng

───────────────────────────────────────────
QUYẾT ĐỊNH
───────────────────────────────────────────
[ ] Merge — không cần sửa gì
[ ] Codex fix issues rồi resubmit
[ ] Cần bạn (owner) quyết định: [lý do]
═══════════════════════════════════════════
```

---

## Severity Definitions

| Level | Ký hiệu | Ý nghĩa | Action |
|---|---|---|---|
| Critical | ❌ | Sẽ crash, sai logic nghiêm trọng, vi phạm architecture | Codex phải sửa trước khi tiếp tục |
| Warning | ⚠️ | Không crash nhưng sẽ gây vấn đề sau | Nên sửa trong session tiếp theo |
| Note | 📝 | Cải thiện nhỏ, style, performance hint | Tùy chọn |

---

## Escalation Rules

**EL tự quyết (không cần hỏi bạn):**
- Pass/Fail từng task
- Yêu cầu Codex sửa lỗi Critical/Warning

**EL phải hỏi bạn trước khi quyết:**
- Refactor lớn ảnh hưởng nhiều file
- Thay đổi architecture đã định sẵn trong GDD
- Task mới không có trong AGENTS.md
- Conflict giữa cách Codex implement và GDD spec

---

*Protocol version 1.0 | Project: Lò Thiêng | EL: Claude*
