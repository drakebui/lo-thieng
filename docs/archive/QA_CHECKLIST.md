# LÒ THIÊNG — QA Checklist Demo 4 Ngày

> **Cách dùng:** Chạy game từ Main Menu, tick từng mục khi xác nhận.
> Mọi mục phải PASS trước khi release demo.

---

## PRE-GAME

- [ ] **Chạy static_check.py** → `0 FAIL, 0 WARN`
- [ ] **Chạy smoke_test.gd** (Ctrl+Shift+X trong Godot) → `X/X checks passed`
- [ ] **Main Menu hiện** → title, nút New Game và Load Game
- [ ] **New Game → Workshop Hub tải** → không crash, không lỗi console

---

## NGÀY 0 — TUTORIAL

- [ ] **Bà Trùm intro scene trigger** khi vào hub lần đầu → cutscene 6 step xuất hiện
- [ ] **Day 0 intro steps** hiện sau Bà Trùm scene → hướng dẫn Lò Rèn
- [ ] **Sticky hint "→ Lò Rèn đang chờ"** hiển thị ở ZONE_FORGE
- [ ] **Vào Lò Rèn → WeaponBuilder tải** → không crash
- [ ] **Chọn vũ khí + vật liệu → ElementPicker** → chỉ hiện nguyên tố phù hợp (không hiện đủ 6 nếu vật liệu tier 1)
- [ ] **Hoàn thành Phase 1** (heat bar) → tier xuất hiện (Lanh/Cam/Đỏ Rực/Vàng Kim)
- [ ] **Hoàn thành Phase 2** (5 nhát búa) → prefix xác định (Bén Ngọt / Kiên Cố / Nặng Tay / Huyền Bí)
- [ ] **Phase 3 hoàn thành** → weapon card hiện đúng stats + skill 1 + skill 2
- [ ] **Vũ khí vào kho** → xuất hiện trong inventory tab Weapons
- [ ] **Mở Tiệm (AFTERNOON)** → shop scene tải, vũ khí bày được lên kệ
- [ ] **Khách vào, mặc cả, chốt giá** → gold tăng đúng
- [ ] **Kết thúc ngày, chọn Ngủ** → màn tổng kết đêm hiển thị stats ngày

---

## NGÀY 1 — SCRIPTED + NỢ C1

- [ ] **Người Thu Nợ xuất hiện sáng ngày 1** → dialogue NTN day 1 trigger
- [ ] **Debt Notice hiện 3,000G** → số tiền đúng, deadline "Ngày 4"
- [ ] **Đi khám phá V1 (Đồng Mây Trắng)** → map tải, player di chuyển được
- [ ] **Gặp quái (Sói/Bandit)** → combat transition xảy ra
- [ ] **Combat: dùng skill 1 + skill 2** → damage tính đúng, turn alternating
- [ ] **Thắng combat** → loot drop vào Túi Khám Phá
- [ ] **Rời vùng** → vật liệu chuyển vào kho xưởng
- [ ] **Mở shop chiều** → 3-5 khách ngẫu nhiên trong buổi
- [ ] **Tổng kết đêm** → Debt tracker hiện "Còn thiếu X G cho C1"

---

## NGÀY 2–3 — FREE PLAY

- [ ] **Ngày 2 tutorial** → "Ngày 2 — Tự do khám phá" hint hiện sáng
- [ ] **Stamina giảm khi đi khám phá** → drain theo terrain
- [ ] **Stamina restore qua đêm** → sáng hôm sau đầy lại
- [ ] **Ngày 3: Cô Lộng Gió spawn tại tảng đá DongMay** → nhân vật màu xanh xuất hiện
- [ ] **E gần Cô Lộng Gió** → first_dialogue 8 step hiện đúng
- [ ] **Quay lại DongMay ngày khác** → second_dialogue 7 step hiện (tease Di Vật)
- [ ] **Lần 3 gặp Cô Lộng Gió** → không có dialogue, im lặng (guard hoạt động)
- [ ] **Counter mechanic** → tấn công từ sau lưng quái → "Phục Kích!" + +30% dmg
- [ ] **Losing combat** → về xưởng, mất 20% gold

---

## NGÀY 4 — DEADLINE

- [ ] **Hint ngày 4 sáng** → "Hôm nay là ngày cuối trả nợ 3,000G"
- [ ] **Debt Notice tự trigger nếu chưa đọc** → số tiền đúng
- [ ] **[HAPPY PATH] Có đủ ≥ 3,000G → mở màn Trả Nợ** → chọn trả, gold giảm đúng
- [ ] **[HAPPY PATH] Trả đúng hạn** → Agent farewell scene + tease C2
- [ ] **[LATE PATH] Chưa trả qua chiều Ngày 4** → penalty 300G tự áp
- [ ] **[GAME OVER] 3 ngày liên tiếp gold = 0** → Ending D screen xuất hiện
- [ ] **Save tại xưởng ban đêm** → file lưu được
- [ ] **Load game** → state khôi phục đúng (ngày, gold, inventory, debt status)

---

## EDGE CASES

- [ ] **Pause menu (ESC)** → overlay hiện, Resume hoạt động
- [ ] **Vào shop khi chưa có vũ khí trên kệ** → không crash, khách không tiếp cận
- [ ] **Rèn khi hết vật liệu** → WeaponBuilder không cho confirm (nút disabled)
- [ ] **Mặc cả vượt patience** → khách bỏ đi với đúng dialogue HAGGLE_TOO_HIGH
- [ ] **Đe dọa thành công** → THREAT_SUCCESS line hiện, gold đúng
- [ ] **Đe dọa thất bại** → THREAT_FAIL line hiện, khách bỏ đi
- [ ] **Kiếm bị Curse** → prefix "Phản Chủ/Lời Nguyền", giá bán thấp
