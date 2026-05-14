# EL_PROMPTS.md — Bảng Prompt Nhanh
> Giữ file này mở khi làm việc trong Godot.
> Copy đúng block cần dùng → paste vào Claude chat.

---

## 🟢 BẮT ĐẦU SESSION MỚI

```
Đọc AGENTS.md, NOTES.md và CheckListDev.md
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

*Dự án: Lò Thiêng | Kiến trúc sư: Claude | Kỹ sư: Codex*
