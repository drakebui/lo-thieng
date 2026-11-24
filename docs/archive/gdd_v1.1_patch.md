# 🔥 LÒ THIÊNG: TIẾNG GỌI TỔ NGHỀ
## GAME DESIGN DOCUMENT v1.1 — FINAL PATCH

**Phiên bản:** 1.1 — Production-ready Refactor
**Ngày:** 13/05/2026
**Phiên bản trước:** v1.0 (Pre-production GDD, 05/2026)
**Tác giả:** Solo dev
**Engine:** Godot 4
**Status:** ✅ Chốt — bắt đầu prototype được

---

## 📖 CÁCH ĐỌC TÀI LIỆU NÀY

Đây là **patch document**, không phải full rewrite. Đọc song song với GDD v1.0.

| Marker | Ý nghĩa |
|---|---|
| `[REPLACE §X]` | Section này thay thế hoàn toàn section X trong v1.0 |
| `[NEW §X]` | Section mới, bổ sung vào v1.0 |
| `[MODIFY §X]` | Tweak nhỏ trong section X, chỉ ghi phần thay đổi |
| `[DEPRECATED §X]` | Section X trong v1.0 bị bỏ |

Các section v1.0 KHÔNG được đề cập ở đây (ví dụ Combat, Forge, Quest, Tutorial) **giữ nguyên**.

---

## MỤC LỤC v1.1

0. Quyết định thiết kế đã chốt
1. Tóm tắt thay đổi từ v1.0
2. [REPLACE §8] Dungeon & Exploration — Đại Lâm Lò Thiêng
3. [NEW §8B] Route State & Mercenary
4. [REPLACE §7] Shop & Commerce — Sword-first
5. [REPLACE §10] NPC System
6. [REPLACE §6.5] Hệ Kiểm Chứng Kiếm (Chiến Chứng)
7. [REPLACE §13] Items & Add-ons
8. [NEW §15B] Economy Guardrails
9. [MODIFY §15.3] Progression Gates
10. Audit Combat Bible v2 — Impact Analysis
11. Open Questions
12. Appendix A — Data Schemas

---

# 0. QUYẾT ĐỊNH THIẾT KẾ ĐÃ CHỐT

| # | Quyết định | Lý do |
|---|---|---|
| D1 | 6 vùng = 6 segment của "Đại Lâm Lò Thiêng" nối tuyến tính | Progression rõ, narrative dễ kể |
| D2 | V1-V2 giữ semi-open (tutorial), V3-V6 dùng Corridor + Pockets | Cân bằng giữa "feel exploration" và scope production |
| D3 | Route State 4-state (Locked/Dangerous/ClearedByPlayer/SecuredByMercenary) | Engineering rigor, support mercenary system |
| D4 | Giữ Bà Trùm Hắc Nguyệt là chủ nợ chính, thêm 6 Debt Agent địa phương | Giữ flavor mà không có 6 debt bar riêng |
| D5 | Shop có 4 lớp: Core Sword 70% / Add-ons 15-25% / Services 5-10% / Conditional <5% | Sword-first identity vẫn nguyên |
| D6 | Services MVP: Mài + Sửa. Post-MVP: Khắc/Tẩy curse/Reforge | Reuse forge pipeline, không thêm mini-game mới |
| D7 | Test Slot tách Combat Slot (early 1, mid 2, late 3) | Buộc player decide chiến thuật, chống exploit |
| D8 | 5 Proof Grades: Untested → Field-Tested → Route-Proven → Elite-Proven → Mastery | Granular pricing curve |
| D9 | Mastery 2-bước: Boss win (dungeon) + Ritual ở xưởng (Phase 2 mini-game) | Dramatic + reuse mini-game đã có |
| D10 | Fast-travel từ xưởng đến vùng đã mở: −2 stamina | Giảm tedium mà vẫn tốn chi phí |
| D11 | Niche Buyer kiosk: 4 NPC, cap 5 items/ngày | Off-load junk nhưng không thành income chính |
| D12 | Giữ 4 phase ngày: Sáng/Trưa/Chiều/Đêm | Consistent với v1.0 |
| D13 | Mercenary: 1 contract/ngày, thuê Tối → xong Tối hôm sau | Đơn giản, dễ code |

---

# 1. TÓM TẮT THAY ĐỔI TỪ v1.0

| Hệ thống | v1.0 (cũ) | v1.1 (mới) | Impact |
|---|---|---|---|
| Exploration | 6 vùng map rời rạc, mở khoá random | 6 segment tuyến tính của Đại Lâm Lò Thiêng | 🟡 Vừa |
| Map format | Open 50×40 (mọi vùng) | V1-V2 semi-open, V3-V6 Corridor + Pockets | 🔴 Lớn |
| Mở vùng mới | Reputation gate (Rep 3/5/7) | Vượt corridor + một số gate phụ | 🟡 Vừa |
| Route memory | Không có (mọi ngày như mới) | Route State machine + Mercenary | 🟢 Mới |
| Bà Trùm | Chủ nợ duy nhất | Chủ nợ chính + 6 Debt Agent địa phương | 🟢 Nhỏ |
| Shop products | Chỉ kiếm | Sword + Add-ons + Services + Conditional | 🔴 Lớn |
| Customer pool | Toàn kiếm sĩ | 8 role xã hội | 🟡 Vừa |
| Sword test | Boss test scripted, "1 lần 3 kiếm" | Test Slot + Chiến Chứng tích lũy + Shrine seal | 🔴 Lớn |
| Mastery | Win 1 boss test = Mastery | Boss win (gate) + Ritual ở xưởng (skill check) | 🟡 Vừa |
| Reputation | Gate vùng | Gate NPC + recipe + discount (NOT vùng) | 🟡 Vừa |

---

# 2. [REPLACE §8] HỆ THỐNG DUNGEON & EXPLORATION

## 2.1. Vision: Đại Lâm Lò Thiêng

Toàn bộ thế giới exploration được gom thành **một chuỗi 6 phân khu nối tiếp** mang tên *Đại Lâm Lò Thiêng* — không phải một map liền mạch, mà là **6 vùng riêng biệt nối bằng corridor**. Player càng mạnh càng đi sâu được, mở vật liệu mới, thuộc tính rèn mới, NPC mới, cốt truyện mới.

```
[Xưởng + Làng Trung Tâm]
		│  (fast-travel hub)
		▼
[V1: Đồng Mây Trắng]   ◀── semi-open, tutorial-friendly
		▼  Corridor 1-2
[V2: Rừng Trăm Hồn]    ◀── semi-open
		▼  Corridor 2-3
[V3: Núi Than Đỏ]      ◀── Corridor + Pockets
		▼  Corridor 3-4
[V4: Bãi Cát Thần Vàng]◀── Corridor + Pockets
		▼  Corridor 4-5
[V5: Thành Ngọc Bích]  ◀── Corridor + Pockets (indoor)
		▼  Corridor 5-6
[V6: Làng Tổ Nghề]     ◀── Hub nhỏ + Lò Thiêng Cổ (corridor 4 node)
```

## 2.2. Tổng quan 6 vùng

| Vùng | Theme | Format | Mở khoá | NL chủ | NPC VIP | Thuộc tính rèn mở |
|---|---|---|---|---|---|---|
| V1 Đồng Mây Trắng | Thảo nguyên gió | Semi-open 50×40 | Default | Sắt, da, bạc | Cô Lộng Gió | Gió/Nhẹ/Tốc độ |
| V2 Rừng Trăm Hồn | Rừng linh khí | Semi-open 50×40 | Vượt Corridor 1-2 | Gỗ, pha lê | Tướng Bóng Rừng | Mộc/Linh/Hồi phục |
| V3 Núi Than Đỏ | Núi lửa ngủ | Corridor + Pockets | Vượt Corridor 2-3 | Quặng, mithril | Gã Khét Lửa | Hỏa/Nung/Damage |
| V4 Bãi Cát Thần Vàng | Sa mạc cổ | Corridor + Pockets | Vượt Corridor 3-4 | Cát, hổ phách | Ông Cát Thần | Thổ/Cát/Phòng thủ |
| V5 Thành Ngọc Bích | Thành cung điện | Corridor + Pockets (indoor) | Vượt Corridor 4-5 | Thép trắng, ngọc | Bà Thiên Kim | Ngọc/Phản đòn/Chính xác |
| V6 Làng Tổ Nghề | Endgame Lò Thiêng | Hub nhỏ + Corridor 4 node | Vượt Corridor 5-6 + 8 Di Vật | Di vật, công thức | Lão Thôi Cổ | Tổ Nghề/Di Vật |

## 2.3. Format A — V1-V2 Semi-Open (tutorial)

V1 và V2 giữ format gần với GDD v1.0 — map ~50×40 tile dạng open, có:

- 8–12 gathering nodes (respawn 2–3 ngày)
- 1 gathering node hiếm (R1, respawn 5–7 ngày)
- 5–8 enemy spawn point (random encounter)
- 1 boss arena cuối map
- 1 làng nhỏ (NPC VIP + 2 background NPC)
- 1 Shrine
- 1 cổng vào Corridor đến vùng kế tiếp

**Tại sao giữ format open ở V1-V2:**
- Player mới cần không gian học cơ chế, lạc một chút không sao.
- Tutorial diegetic dễ thực hiện trong open map.
- 2/6 map open vẫn manageable cho solo dev.

## 2.4. Format B — V3-V6 Corridor + Optional Pockets

Từ V3 trở đi, mỗi vùng dùng template tuyến tính nhưng có nhánh:

```
[ENTER vùng]
   │
   ├── Node 1: Required Encounter
   │       • Enemy fixed theo vùng (T2 hoặc T3)
   │       • Drop R2/R1 phù hợp tier
   │       • Gathering node nhỏ (3-5 NL)
   │
   ├── Optional Pocket A: Puzzle / Key-door Cache
   │       • Không block boss
   │       • Reward: R1 cache, recipe, lore fragment phụ
   │
   ├── Node 2: Shrine + Lore
   │       • Hồi +2 stamina (1 lần/ngày)
   │       • Seal Chiến Chứng (xem §6)
   │       • Lore tablet / NPC ngoài chợ
   │
   ├── Optional Pocket B: Elite / Risk Branch
   │       • Quái T3 Champion hoặc puzzle khó
   │       • Reward: R1 exclusive, fragment Di Vật
   │
   └── Node 3: Boss Arena / Progression Gate
		   • Boss T4
		   • Reward: Di Vật chính, unlock corridor đến vùng sau
```

**Production note:** Mỗi vùng format này cần ~25×40 tile cho main corridor + 2 pocket ~10×10 mỗi pocket. Tổng ~1200 tile/vùng — **nhẹ hơn ~40% so với open 50×40 (2000 tile)**.

**Reward rule:**

| Node | Reward nên cho | Không nên cho |
|---|---|---|
| Required Encounter | R2/R1, proof thấp/trung | Di Vật chính nếu encounter quá dễ |
| Optional Pocket | R1 cache, recipe, lore phụ | Progression bắt buộc, Di Vật ending duy nhất |
| Shrine | Stamina nhỏ, seal proof, hint | Full rescue (phá tension) |
| Boss | Di Vật chính, unlock vùng sau, Mastery proof opportunity | Reward quá nhỏ |

## 2.5. Corridor giữa các vùng

Giữa 2 vùng có corridor ~15×10 tile chứa:

- Quái tier cao hơn vùng vừa rời (ép player đủ mạnh)
- Không có gathering node (không phải nơi farm)
- 1 checkpoint giữa corridor (Shrine nhỏ)
- Khi chưa clear lần đầu: Locked state, không bypass được

**Quy tắc qua corridor:**

| Trạng thái Corridor | Cách qua | Cost |
|---|---|---|
| Locked (chưa đủ điều kiện) | Không qua được | — |
| Dangerous (vừa unlock) | Đánh quái | −3 stamina + risk combat |
| Cleared by Player (đã qua ≥1 lần) | Đánh quái nhẹ hơn | −2 stamina |
| Secured by Mercenary | Đi tự do | −1 stamina, không encounter |

## 2.6. Stamina Travel + Fast-Travel

Giữ cơ chế Stamina Travel của v1.0. Bổ sung:

| Hành động | Stamina cost |
|---|---|
| Đi qua corridor Dangerous | −3 |
| Đi qua corridor Cleared | −2 |
| Đi qua corridor Secured | −1 |
| **Fast-travel từ Xưởng đến vùng đã mở** | **−2** (mỗi lần) |
| Fast-travel từ Shrine bất kỳ về Xưởng | 0 (free retreat, end day) |

**Quy tắc Fast-Travel:**
- Mở khoá sau khi clear V2 (ngày 5-6 game time).
- Chỉ về được vùng đã clear corridor vào.
- Không fast-travel giữa 2 vùng (phải qua Xưởng).
- Mỗi ngày tối đa 3 lần fast-travel (chống skip pacing).

---

# 3. [NEW §8B] HỆ THỐNG ROUTE STATE & MERCENARY

## 3.1. Route State Machine

Mỗi tuyến (corridor giữa 2 vùng + internal corridor trong V3-V6) là một **Route** có state machine:

```
				  ┌──────────────────────────────────┐
				  │                                  │
				  ▼                                  │
   [Locked] ──► [Dangerous] ──► [ClearedByPlayer] ──┴► [SecuredByMercenary]
   Chưa đủ      Vừa mở,         Đã qua ≥1 lần           Mercenary đã dọn
   điều kiện    tự đi qua       Có thể thuê mercenary    (1 ngày)
```

| State | Ý nghĩa | Gameplay effect |
|---|---|---|
| Locked | Chưa đủ điều kiện vào | Hiện gate + lore hint, không vào được |
| Dangerous | Vừa unlock | Full enemy spawn, stamina drain ×1.0 |
| ClearedByPlayer | Đã tự vượt qua ≥1 lần | Quái respawn nhưng ít hơn, mở quyền thuê mercenary |
| SecuredByMercenary | Mercenary đã dọn | Quái không spawn 1 ngày, stamina drain ×0.5, shortcut mở |

**Lưu ý:** SecuredByMercenary chỉ valid trong **1 ngày in-game**. Hôm sau quái respawn → quay về ClearedByPlayer.

## 3.2. Mercenary Rules (Do / Don't)

| Mercenary ĐƯỢC làm | Mercenary KHÔNG được làm |
|---|---|
| Clear enemy yếu (T1-T2) ở tuyến đã ClearedByPlayer | Đánh boss (T4) |
| Giảm stamina drain khi đi qua vùng cũ | Lấy Di Vật chính |
| Mở shortcut đến checkpoint sâu hơn | Clear vùng mới thay player |
| Mang về 1-2 item phụ nhỏ (R3, không R1) | Farm R1 exclusive |
| Báo cáo enemy intel + 1 lore hint | Giải puzzle chính trong pocket |
| Clear corridor (giữa các vùng) | Clear node main (Node 1, 2, 3) trong vùng |

**Rule vàng:** *Mercenary giảm repetition. Mercenary không thay progression.*

## 3.3. Mercenary unlock flow

1. **Gặp kiếm sĩ trong vùng** (random friendly encounter hoặc tại làng nhỏ).
2. **Đối thoại** → biết weapon preference của họ.
3. **Rèn kiếm matching tag** → mang đến shop hoặc gặp họ.
4. **Bán thành công** với satisfaction ≥ 70 (mặc cả đẹp, không lừa giá).
5. **Affinity tăng → ≥ 30 → unlock "Mercenary Contract" option**.

## 3.4. Mercenary Contract — timing & cost

| Thời điểm thuê | Khi xong |
|---|---|
| Tối hôm trước | Tối hôm sau (24h in-game) |

**Quy trình:**

1. Đi đến quầy Mercenary tại Làng Trung Tâm (mở sau khi unlock kiếm sĩ đầu).
2. Chọn Route cần dọn (chỉ Route đã ClearedByPlayer).
3. Chọn Kiếm sĩ (đã unlock).
4. Trả phí.
5. Buổi Tối hôm sau → nhận báo cáo + state change.

**Giới hạn:**
- Chỉ thuê 1 mercenary/ngày.
- Mercenary V5-V6 không thể thuê (endgame phải tự đi).
- Mercenary đã đi không thể recall.

## 3.5. Danh sách 6 Mercenary

| Vùng | Kiếm sĩ | Tag weapon ưa thích | Phí thuê (G) |
|---|---|---|---|
| V1 | Hiệp Khách Tóc Bạc | Kiếm Đơn / Bén Ngọt | 300 |
| V2 | Thợ Săn Mắt Cú | Cung Trường / Thần Tốc | 400 |
| V3 | Võ Tăng Lửa | Quyền/Búa / Nặng Tay | 500 |
| V4 | Thích Khách Sa Mạc | Song Đao / Độc | 600 |
| V5 | Vệ Binh Hoàng Gia | Giáo Dài / Kiệt Tác | 700 |
| V6 | — (không có) | — | — |

## 3.6. Mercenary Report

Sau mỗi contract, player nhận một report (text-based, 3-4 dòng) chứa:

- State change của route (visual update trên map)
- 1-3 item phụ nhỏ (R3 hoặc R2 tier cũ)
- 1 enemy intel hoặc lore hint

**Ví dụ report:**

```
═══════════════════════════════════════
BÁO CÁO TỪ HIỆP KHÁCH TÓC BẠC
─────────────────────────────
Route: Corridor 1-2 (Đồng Mây → Rừng Trăm Hồn)
Trạng thái: ✅ Secured

"Đã dẹp được 6 con Sói Bóng trên đường, không khó.
 Tìm thấy một mảnh giáp cũ — chắc của thợ săn nào đó.
 À, có dấu vết Ma Rừng ở phía bắc rừng — coi chừng."

Thu được:
• Da Sói ×3 (R3)
• Mảnh Giáp Cũ ×1 (lore item)
• Intel: Ma Rừng tuần tra phía bắc V2 ban đêm

[Đóng]
═══════════════════════════════════════
```

---

# 4. [REPLACE §7] HỆ THỐNG SHOP & COMMERCE

## 4.1. Triết lý: Sword-First Commerce

> **Lò Thiêng KHÔNG phải general store. Đây là game bán kiếm.**
> Add-ons, services, và conditional sellables tồn tại để TĂNG variety, không thay thế bán kiếm.

## 4.2. Product Hierarchy

| Lớp sản phẩm | Mô tả | % doanh thu mục tiêu |
|---|---|---|
| **Core: Kiếm/Vũ Khí** | Sản phẩm chính, quyết định progression | **70–80%** |
| **Add-ons** | Phụ kiện bán kèm khi khách đã chọn kiếm | **15–25%** |
| **Services** | Mài, sửa, khắc, tẩy curse, reforge | **5–10%** |
| **Conditional Sellables** | Trophy, relic fragment, cursed weapon (chỉ qua NPC request hoặc Niche kiosk) | **<5%** |

## 4.3. Layout Cửa Hàng (cập nhật)

Phòng 16×12 tile (giữ nguyên v1.0) với:

- 3 kệ trưng bày kiếm (như cũ)
- **1 kệ "Add-ons" (mới)** — hiện 4-6 phụ kiện cùng lúc
- **1 bảng "Services" (mới)** — danh sách services available
- Quầy thu ngân (như cũ)
- Cửa ra vào (như cũ)

## 4.4. Flow Bán Hàng v1.1

```
Khách vào shop
    │
    ▼
Khách ngắm kệ → chọn kiếm (như v1.0)
    │
    ▼
Khách đến quầy thu ngân
    │
    ▼
[BƯỚC MỚI] Game check: khách có nhu cầu add-on hoặc service?
    │
    ├── Có → Show upsell prompt: "Bán kèm Bao Kiếm Da (+150G)?"
    │           Player chọn Có/Không
    │
    └── Không → bỏ qua
    │
    ▼
Tính giá tổng (kiếm + add-on/service)
    │
    ▼
Mặc cả mini-game (như v1.0)
    │
    ▼
Sale result: tiền, satisfaction, affinity, reputation
```

**Logic upsell:**
- Mỗi customer role có `preferred_add_ons` và `preferred_services` tags.
- Match ≥ 1 tag → trigger upsell prompt.
- Add-on không bán độc lập (chỉ khi có kiếm trong sale).

## 4.5. Add-ons System

### 4.5.1. Danh sách Add-ons (6 items)

| Add-on | NL gốc | Tác dụng | Time craft | Hợp với |
|---|---|---|---|---|
| Bao Kiếm Da | Da × 2 + Chỉ × 1 | Giá kiếm ×1.10 | 30s | Hunter, Merchant |
| Bao Kiếm Khắc Hoa | Da × 2 + Bạc × 1 + Chỉ × 2 | Giá kiếm ×1.20 | 60s | Merchant, Noble |
| Dầu Mài | Mỡ quái × 1 + Thảo mộc × 1 + Than × 1 | Giá ×1.10 + Durability ×1.2 | 20s | Mercenary, Hunter |
| Dây Quấn Chuôi | Da × 1 + Sợi × 1 | Giá ×1.05 | 15s | Guard, Villager |
| Khắc Ấn | Tinh thể × 1 + Ngọc nhỏ × 1 | Giá ×1.15, Affinity NPC +5 | 45s | Đạo sĩ, VIP |
| Hộp Kiếm Trưng | Gỗ quý × 3 + Sơn × 1 + Ngọc vụn × 2 | Giá ×1.25 (chỉ với Noble/Collector) | 90s | Noble, Collector |

**Đặc điểm thiết kế:**
- Toàn bộ NL là byproduct của gathering hiện tại — KHÔNG thêm node mới.
- Craft trong tab "Phụ Kiện" mới của Forge UI — không có mini-game (auto craft).
- Không bán độc lập trên kệ (chỉ upsell).

### 4.5.2. Cấp 2 — Add-ons có Service trộn

Một số add-ons cần Service đi kèm (xem §4.6):

- Khắc Ấn → cần Service "Khắc tên/ấn" để apply lên kiếm.
- Hộp Kiếm Trưng → ngoài craft, cần Service "Hộp đóng gói".

## 4.6. Services System

### 4.6.1. Danh sách Services

| Service | MVP/Post-MVP | Tác dụng | Phí | Dùng khi |
|---|---|---|---|---|
| **Mài Kiếm** | ✅ MVP | Restore performance + giá ×1.05 | 50G | Kiếm cũ, upsell sau mua |
| **Sửa Kiếm** | ✅ MVP | Restore Durability (50%–100%) | 200G + NL gốc | Kiếm broken, request |
| Khắc tên/ấn | 🟡 Post-MVP | Personal tag → Affinity +10 | 300G | VIP, ritualist |
| Tẩy Curse | 🟡 Post-MVP | Xử lý cursed weapon, mở lore | 500G + 1 Linh Lực | Cursed weapon, debt event |
| Reforge | 🟡 Post-MVP | Re-roll Prefix kiếm cũ (chi phí cao) | 1000G + NL Rarity 2 | Mid-late game |

### 4.6.2. Tại sao Services không phình scope

- **Reuse forge pipeline:** Mài/Sửa = subset của Phase 2 forge. Khắc = mini Phase 3. Reforge = full Phase 1+2.
- **Không thêm mini-game mới:** mỗi service là một biến thể của existing mini-game (slowed down, easier).
- **Data-driven:** chỉ cần 5 ServiceData files + 1 ServiceUI scene.

### 4.6.3. Service UI

Khi khách yêu cầu service (qua dialogue) hoặc player click "Bảng Services":

```
─────────────────────────────
DỊCH VỤ LÒ THIÊNG
─────────────────────────────
□ Mài Kiếm        50G  [Chọn]
□ Sửa Kiếm       200G  [Chọn]
□ Khắc Tên       300G  [Chọn] (cần Affinity ≥ 30)
□ Tẩy Curse      500G  [Chọn] (cần Cursed weapon)
□ Reforge       1000G  [Chọn] (cần Mastery hoặc Lão Luyện)
─────────────────────────────
[Đóng]
```

## 4.7. Niche Buyer Kiosk (off-load junk)

Để xử lý nguyên liệu thừa và tránh inventory bloat, làng có **4 kiosk fixed-price** (KHÔNG mặc cả):

| NPC Kiosk | Mua gì | Giá | Cap/ngày |
|---|---|---|---|
| Bà Lão Thảo Mộc | Linh Lực thừa (Hỏa/Băng/Sét/Độc/Thánh/Bóng) | 80–150G/cái | 5 |
| Lão Tài Tử | NL R3 thừa (Phôi cũ, Mảnh ký ức) | 30–60G/cái | 5 |
| Thợ Đúc Đồng Hoang | Quặng thô không dùng | 40–80G/cái | 5 |
| Bà Bán Bánh | Da thú, lông thú dư | 20–50G/cái | 5 |

**Đặc điểm:**
- KHÔNG có mặc cả → UI chỉ "Bán" / "Hủy".
- KHÔNG có queue/timer → vào lúc nào cũng được trong Sáng/Chiều.
- Cap 5 items/NPC/ngày → tổng tối đa 20 items off-load/ngày.
- Thu nhập kỳ vọng: ~500–1000G/ngày (≤ 10% income tổng).

## 4.8. Quy tắc chống lệch genre

1. **Add-ons KHÔNG bán độc lập** trên kệ ở MVP. Chỉ upsell.
2. **Services doanh thu thấp hơn bán kiếm.** Balance để player chọn services thấy đáng nhưng không thay sword income.
3. **Monster Trophy** (Conditional) chỉ bán theo NPC request, không spam.
4. **Di Vật KHÔNG bán.** Dùng cho progression/story.
5. **Niche Buyer cap thấp.** Không thành income chính.

---

# 5. [REPLACE §10] HỆ THỐNG NPC

## 5.1. Phân loại NPC v1.1

| Loại | Số lượng | Vai trò | Note |
|---|---|---|---|
| VIP (boss/quest givers) | 6 | 1/vùng (như v1.0) | Giữ nguyên |
| **Mercenary (kiếm sĩ thuê)** | 5 | 1/vùng V1-V5 | 🟢 Mới |
| **Debt Agent** | 6 | 1/vùng, đại diện Bà Trùm | 🟢 Mới |
| Antagonist | 2 | Bà Trùm Hắc Nguyệt, Lão Gà Chọi | Giữ nguyên |
| **Niche Buyer Kiosk** | 4 | Off-load junk | 🟢 Mới |
| Recurring customers | 12 | Khách quen có quest line | Giữ nguyên |
| Regular customers | 30+ | Random pool | Giữ nguyên |
| Background NPC | 10-15 | Talk-only | Giữ nguyên |

**Tổng NPC v1.1:** ~75-80 (tăng từ ~60 ở v1.0, nhưng 9 NPC mới là role-based, dialogue lines ngắn ~5-10/NPC).

## 5.2. 8 Customer Role Archetypes

Mỗi customer (Recurring + Regular) thuộc 1 trong 8 role. Tag system này quyết định preferred_weapons, preferred_add_ons, preferred_services.

| Role | Nhu cầu mua | Add-on quan tâm | Service quan tâm | Reward unlock |
|---|---|---|---|---|
| **Kiếm sĩ / Mercenary** | Kiếm chiến đấu, có Chiến Chứng | Dầu Mài | Mài, Sửa | Mercenary contract |
| **Vệ binh làng** | Kiếm bền, rẻ | Dây Quấn Chuôi | Sửa | Reputation sớm |
| **Thợ săn / dẫn đường** | Kiếm nhẹ, chống thú | Bao Kiếm Da, Dầu Mài | Mài | Monster intel, route hint |
| **Thương nhân / đoàn buôn** | Kiếm đẹp, kiếm làm quà | Bao Kiếm Khắc Hoa, Hộp Kiếm | — | Market discount |
| **Đạo sĩ / giữ miếu** | Kiếm linh, khắc ấn, hộ kiếm | Khắc Ấn | Khắc, Tẩy Curse | Recipe linh, lore |
| **Dân làng / thợ thủ công** | Utility blade, kiếm rẻ | Dây Quấn Chuôi | Sửa | Tiền nhỏ, local affinity |
| **Collector / học giả** | Trophy, relic, cursed weapon | Hộp Kiếm Trưng | Tẩy Curse | Lore, sink item |
| **Debt Agent / quý tộc** | Kiếm xa xỉ, kiếm ngọc | Hộp Kiếm Trưng, Khắc Ấn | Khắc, Reforge | Debt pressure, story |

## 5.3. Debt Agent (mới)

**Bà Trùm Hắc Nguyệt vẫn là chủ nợ chính.** 6 vùng mỗi vùng có 1 Debt Agent là **đại diện địa phương** của Bà Trùm — không phải chủ nợ độc lập.

| Vùng | Debt Agent | Vai trò |
|---|---|---|
| V1 | Người Thu Nợ Chợ Ngoài | Tutorial debt pressure |
| V2 | Tay Sai Rừng | Giới thiệu phí dọn đường + route pressure |
| V3 | Chủ Lò Than | Gắn debt với NL Hỏa |
| V4 | Thương Nhân Sa Mạc | Gắn debt với trade scarcity |
| V5 | Quản Khố Thành Ngọc | Gắn debt với luxury sword |
| V6 | Sứ Giả Hắc Nguyệt | Final pressure (endgame) |

**Cơ chế Debt Agent:**

- KHÔNG có thanh debt riêng. Họ là đại diện cho Bà Trùm.
- Xuất hiện random 1-2 lần/tuần tại shop khi player có nợ Stage 1+.
- Gây pressure qua dialogue (đe dọa nhẹ, nhắc nợ).
- Có thể "mua" sword đặc biệt (kiếm ngọc, luxury) — buộc player làm hài lòng.
- Mua thành công → giảm 5-15% nợ Stage hiện tại.

**Vì sao thiết kế này tốt:**

- Giữ flavor "vùng nào cũng có áp lực nợ" mà không cần code 6 debt bar.
- Tạo customer drama theo vùng (mỗi vùng có 1 antagonist NPC nhỏ).
- Đa dạng dialogue cho shop phase.

## 5.4. NPC Schedule (giữ nguyên §10.2 v1.0)

NPC VIP có schedule cố định theo vùng/giờ. Mercenary cũng có schedule (chỉ ở vùng họ thuộc).

**Bổ sung:** Debt Agent có schedule **shop-only** — chỉ xuất hiện tại shop Sáng/Chiều, không ở vùng.

## 5.5. Affinity (giữ nguyên §10.3 v1.0)

Mỗi recurring NPC + Mercenary + VIP có Affinity 0-100. Cách tăng và unlock như v1.0.

**Bổ sung:** Bán đúng add-on/service phù hợp = bonus +2 Affinity (nhỏ nhưng tích lũy).

---

# 6. [REPLACE §6.5] HỆ KIỂM CHỨNG KIẾM (CHIẾN CHỨNG)

## 6.1. Triết lý

Kiếm đắt hơn vì **có lai lịch** — đã vượt tuyến nào, hạ quái nào, sống sót trở về ra sao. Không phải "đã được mang đi một lần".

## 6.2. Combat Slot vs Test Slot

Đây là refactor lớn so với v1.0.

| Loại slot | Mục đích | Rule |
|---|---|---|
| **Combat Slots** | Cho player mang vũ khí để đánh | 3 slot (như v1.0) → 6 skill active |
| **Test Slots** | Đăng ký kiếm nào nhận Chiến Chứng | Early 1 slot → Mid 2 → Late 3 |

**Quan trọng:**

> Bỏ rule cũ "1 lần test 3 kiếm". Player vẫn mang 3 kiếm combat, NHƯNG chỉ kiếm đã đăng ký vào Test Slot mới nhận proof tăng giá.

**Test Slot unlock progression:**

| Test Slot # | Unlock condition |
|---|---|
| 1 | Default |
| 2 | Sau khi rèn Mastery đầu tiên (~ngày 10-12) |
| 3 | Sau khi rèn Mastery thứ 3 hoặc Reputation 7 (~ngày 18+) |

## 6.3. 5 Proof Grades

| Grade | Tên | Điều kiện | Multiplier giá |
|---|---|---|---|
| 0 | **Untested** | Kiếm mới rèn, chưa có combat proof | ×1.00 |
| 1 | **Field-Tested** | Win 1 combat phù hợp tier với kiếm này (Test Slot) | ×1.10–1.20 |
| 2 | **Route-Proven** | Clear 1 route/node chính với kiếm này | ×1.30–1.50 |
| 3 | **Elite-Proven** | Góp công lớn khi hạ T3 Champion với kiếm này | ×1.60–2.00 |
| 4 | **Mastery / Boss-Proven** | Góp công lớn trong boss T4 + ritual ở xưởng | ×2.50–3.00 |

**Quy tắc tăng grade:**
- Mỗi grade phải đạt threshold riêng (xem §6.4).
- Không skip grade (phải đi tuần tự).
- Mỗi sword chỉ có 1 grade tại một thời điểm.

## 6.4. Điều kiện nhận Chiến Chứng

Để 1 encounter tính proof cho 1 Test Candidate, phải thoả mãn:

1. **Sword đã đăng ký Test Slot trước khi vào dungeon.**
2. **Encounter phù hợp tier/vùng** — quái quá yếu (T1 ở vùng V5) không tạo proof.
3. **Contribution check:** sword phải gây damage đáng kể (≥ 25% total damage), dùng ≥ 1 skill, hoặc có ≥ 3 lượt sử dụng.
4. **Player thắng encounter.**
5. **Sword KHÔNG broken khi kết thúc combat** (Durability > 0).

**Bonus:** Nếu sword đóng góp ≥ 50% damage → +1 grade tăng nhanh hơn.

## 6.5. Shrine Seal Mechanic (mới)

Đây là cơ chế quan trọng tạo tension trong dungeon:

```
Player thắng encounter với Test Candidate
    │
    ▼
Proof ở trạng thái TẠM (pending)
    │
    ├── Chạm Shrine/Checkpoint hoặc về Xưởng an toàn
    │       ↓
    │   Proof ĐƯỢC ĐÓNG DẤU vào kiếm vĩnh viễn
    │   Grade cập nhật, giá tăng
    │
    └── Player bị KO trước Shrine/Checkpoint
            ↓
        Proof KHÔNG được xác nhận (mất)
        Durability −20%
        30% chance nhận Curse Affix
```

**Hệ quả gameplay:**
- Player phải quyết định: đẩy thêm proof hay rút về Shrine seal?
- Risk vs Reward thực tế trong dungeon — tạo tension không cần boss test scripted.
- Shrine ở Node 2 trở thành **strategic landmark**, không phải free refill.

## 6.6. Mastery Ritual (2 bước)

Khác với v1.0 (1 boss test), v1.1 Mastery có 2 bước:

### Bước 1 — Boss Win (Gate)

- Sword phải có grade **Elite-Proven** trở lên.
- Sword phải là Test Candidate trong boss fight đó.
- Sword đóng góp ≥ 40% damage trong boss fight.
- Boss thuộc vùng matching element của sword (e.g. Suffix Hỏa → boss Rồng Lửa V3).

→ Nếu đạt: sword chuyển sang state "Boss-Proven (chờ Ritual)".

### Bước 2 — Ritual ở Xưởng

- Mở "Mastery Ritual" tab tại Forge.
- Chi phí: 1000G + 1 Linh Lực matching Suffix sword.
- Mini-game: **Phase 2 Rhythm** (reuse), nhưng khó hơn 30% (timing window hẹp).
- **Win →** Sword lên Mastery, stats ×1.5, giá ×2.5–3.0, max Durability +20.
- **Lose →** Sword giữ grade Elite-Proven, mất 30% Durability, có thể thử lại sau (không destroy).

**Tại sao 2 bước:**
- Boss win = drama (dungeon moment).
- Ritual = skill check (reuse forge mini-game).
- Player có second chance ở ritual → ít frustrating.
- Solo dev: không cần code boss test scripted riêng — reuse boss vùng + reuse Phase 2 UI.

## 6.7. UI hiển thị

Card weapon mới hiển thị grade + lai lịch:

```
═══════════════════════════════════════
KIẾM HUYỀN BÍ THIÊU ĐỐT
★ Elite-Proven (Grade 3)
─────────────────────────────
ATK: 16  DEF: 0  Magic: 6
Skill 1 (Prefix Huyền Bí): Arcane Blade
Skill 2 (Suffix Hỏa): Burn
Durability: 42/50
─────────────────────────────
LAI LỊCH:
✓ Vượt Corridor 2-3 (V2→V3)
✓ Hạ 8 Ma Rừng, 3 Hổ Rừng
✓ Đối đầu Tướng Núi Than (sống sót)
─────────────────────────────
Giá thị trường: 2,600–3,250G (×1.7)
[Đăng ký Test Slot]  [Mastery Ritual (chưa đủ điều kiện)]
═══════════════════════════════════════
```

**"Lai lịch" auto-generate** từ kill log + route log. Không cần viết tay.

---

# 7. [REPLACE §13] ITEMS & ADD-ONS

## 7.1. Phân loại Item v1.1

| Loại | Số lượng | Source | Use |
|---|---|---|---|
| Material (NL gốc) | ~30 | Gathering nodes | Forge, add-ons |
| Linh Lực (Forces) | 6 | Enemy drop + altar | Forge Phase 3 |
| Weapon (Phôi) | 12 | Forge result | Combat, bán |
| **Add-on items** | 6 | Craft tại Forge tab Phụ Kiện | Bán kèm sword |
| **Service items** | 5 | Service request | Service application |
| Consumable | ~10 | Mua + drop | Stamina, healing |
| Quest items | 18 + ~10 | Quest reward | Quest, story |
| **Conditional Sellables** | ~8 | Enemy drop + dismantle | Sell to specific NPC |

**Total:** ~95 items (gần v1.0 ~80, tăng do add-ons + conditional).

## 7.2. Conditional Sellables (mới)

Đây là items không bán kiosk, không bán shop chính — chỉ bán khi có **NPC request**:

| Item | Source | Mua bởi | Giá |
|---|---|---|---|
| Trophy Hổ Trắng | Boss V2 drop | Collector, Đạo sĩ | 500–800G |
| Vảy Hắc Long | Boss V6 drop | Collector | 1500–3000G |
| Phôi Cursed | Dismantle cursed weapon | Đạo sĩ, Collector | 200–400G |
| Mảnh Lò Cũ | Lore drop | Lão Thôi Cổ (V6) | 600G (quest) |
| Tinh Thể Linh Khí | Pocket cache | Đạo sĩ | 300–600G |
| Bí Kíp Rèn (copy) | Pocket cache | Hội Đồng Thợ Rèn | 1000G (quest) |
| Mảnh Khắc Cổ | Pocket cache | Bà Thiên Kim | 500G |
| Phôi Tổ Nghề | T3 drop | Lão Thôi Cổ | 1500G (quest) |

**Quy tắc:**
- Không hiện trên kệ shop.
- NPC chứa quest tự request khi gặp.
- Cap: 1-3 transactions/tuần (tránh income chính).

## 7.3. Dismantle System (mới — light)

Để xử lý kiếm lỗi (Curse, failed forge), thêm cơ chế nhẹ:

- Tại Forge, có button "Dismantle Weapon".
- Cost: 0G.
- Recover: 30-50% materials của sword + có chance 10% drop Cursed Phôi (conditional sellable).
- KHÔNG dismantle được Mastery weapon.

**Tại sao tốt:**
- Player không bị kẹt với cursed weapon.
- Cursed weapon thành tài nguyên có giá trị (bán Đạo sĩ/Collector).
- Khuyến khích thử Reforge service (Post-MVP).

---

# 8. [NEW §15B] ECONOMY GUARDRAILS

## 8.1. Revenue Split Target

Cân bằng game balance để doanh thu player tuân theo tỉ lệ này (trung bình theo tuần):

| Source | Target % | Hard cap |
|---|---|---|
| Bán Kiếm (Core) | 70–80% | ≥ 65% (nếu thấp hơn → buff sword price) |
| Add-ons (Upsell) | 15–25% | ≤ 30% (nếu cao hơn → cap add-on multiplier) |
| Services | 5–10% | ≤ 15% |
| Conditional + Niche Kiosk | <5% | ≤ 10% |

**Nếu test cho thấy player thu nhập từ Niche Kiosk + Services > 30% → phải nerf.**

## 8.2. Công Thức Giá (Final Sale Price)

```
Final Sale Price = (
    Base Craft Value
    × Quality Multiplier (Forge Phase 2 result)
    × Proof Multiplier (Chiến Chứng grade)
    × Condition Multiplier (Durability %)
    × Customer Match Bonus (tag match)
) + Add-on Value + Service Value + Negotiation Result
```

**Range guardrail:**

| Yếu tố | Min | Max |
|---|---|---|
| Quality Multiplier | 0.7 (Curse) | 1.5 (Trường Sinh/Hào Kiệt) |
| Proof Multiplier | 1.0 (Untested) | 3.0 (Mastery) |
| Condition Multiplier | 0.5 (Durability < 30%) | 1.0 (Full Durability) |
| Customer Match Bonus | 1.0 (no match) | 1.5 (perfect match + VIP) |

**Compound max:** 1.5 × 3.0 × 1.0 × 1.5 = **6.75×** Base Craft Value.

Một kiếm rèn 500G base, full Mastery + Perfect VIP match → tối đa 3,375G. Đây là ceiling cho calculations.

## 8.3. Anti-Exploit Rules

| Exploit potential | Mitigation |
|---|---|
| Register sword rẻ → farm quái yếu để get proof | Tier check + contribution check |
| Save scum trước Shrine seal | Save chỉ ở Xưởng (no mid-dungeon save) |
| Spam dismantle để gen Cursed Phôi | Dismantle cost 0 nhưng Cursed Phôi drop chỉ 10%; cap conditional purchase |
| Mercenary clear corridor → bypass boss | Mercenary KHÔNG được clear node main, KHÔNG được clear boss |
| Niche Kiosk spam off-load | Cap 5 items/NPC/ngày, total 20 |
| Service spam reforge | Reforge cost 1000G + NL R2, chỉ Mid-late game unlock |

## 8.4. Sink & Source v1.1

**Sources (mới + cũ):**
- Bán kiếm (chính, như v1.0)
- Bán add-ons kèm kiếm (mới)
- Services (mới)
- Niche kiosk (mới, capped)
- Conditional sellables (mới, occasional)
- Quest reward (như v1.0)
- Monster drop (như v1.0)
- Mercenary report items (mới, nhỏ)

**Sinks (mới + cũ):**
- Mua NL (như v1.0)
- Trả nợ Bà Trùm (như v1.0)
- **Thuê Mercenary (mới): 300–700G/contract**
- **Service phí player tự dùng (mới)**: Mài/Sửa kiếm của chính player để repair Test Candidate.
- **Mastery Ritual (mới): 1000G + Linh Lực**
- **Fast-travel cost (gián tiếp): −2 stamina = thời gian/tài nguyên**

---

# 9. [MODIFY §15.3] PROGRESSION GATES (CẬP NHẬT)

| Gate | v1.0 (cũ) | v1.1 (mới) |
|---|---|---|
| Vùng 2 (Rừng) | Trả Stage 1 nợ | Vượt Corridor 1-2 (Dangerous) |
| Vùng 3 (Núi) | Reputation 3 + Quest | Vượt Corridor 2-3 + Quest "Tin Đồn Núi Lửa" |
| Vùng 4 (Cát) | Reputation 5 | Vượt Corridor 3-4 + Reputation 4 |
| Vùng 5 (Thành Ngọc) | Reputation 7 + Quest VIP | Vượt Corridor 4-5 + Reputation 6 + Quest VIP |
| Vùng 6 (Làng Tổ) | 8 Di Vật + Reputation 8 | 8 Di Vật + Reputation 8 + Vượt Corridor 5-6 |

**Reputation vai trò mới:**
- KHÔNG còn gate vùng chính.
- Gate NPC VIP advanced dialogue (Rep 3, 5, 7, 9).
- Gate recipe đặc biệt.
- Gate discount mua NL.
- Gate Quest VIP cuối vùng (Di Vật quest).
- Gate Test Slot #3 (Rep 7).

---

# 10. AUDIT COMBAT BIBLE v2 — IMPACT ANALYSIS

Quan trọng: spec từ Combat Bible v2 nào throw away, giữ, hay cần revision.

## 10.1. ✅ GIỮ NGUYÊN

| Hệ thống Combat Bible | Status |
|---|---|
| Stamina rules (base 14 Normal, drain by terrain) | ✅ Giữ |
| Phân cấp quái T1-T4 + colors | ✅ Giữ |
| Loot Drop Table cho từng enemy | ✅ Giữ |
| Aura T3 Champion mechanics | ✅ Giữ |
| 4 Mechanic Puzzle (Push/Pressure/Torch/Key-door) | ✅ Giữ |
| Boss design per region | ✅ Giữ |
| Hồn Ma Thợ Rèn negotiation | ✅ Giữ (V6 only) |

## 10.2. 🟡 CẦN REVISION

| Hệ thống Combat Bible | Action |
|---|---|
| Map size V5 (80×65, 2 tầng) | **Revise:** Giảm còn 1 tầng + corridor format (~25×40 chính + 2 pockets) |
| Map size V6 (90×75, hub + Lò Thiêng Cổ) | **Revise:** Hub V6 nhỏ ~30×25, Lò Thiêng Cổ giữ format corridor 4 node như Combat Bible đã spec (✅ aligns với v1.1) |
| Map size V3 Núi (chưa spec rõ size) | **Revise:** Apply Corridor + Pockets template |
| Map size V4 Cát (70×60) | **Revise:** Giảm còn ~25×40 corridor + 2 pockets |
| Stamina drain V5 "kích hoạt bẫy hành lang" | **Revise:** Convert thành Optional Pocket Risk |
| Key-door V5 (Ngọc Thành Key luôn drop) | ✅ Giữ logic, nhưng đặt trong Pocket — không block boss |

## 10.3. ❌ DEPRECATED

| Hệ thống v1.0/Combat Bible | Lý do |
|---|---|
| "Test kiếm 1 lần 3 kiếm" rule | Thay bằng Test Slot system |
| Boss Test Arena scripted riêng cho Mastery | Thay bằng Boss vùng + Ritual ở xưởng |
| Reputation-only gate vùng | Thay bằng Corridor + Reputation hybrid gate |

## 10.4. 🟢 BỔ SUNG MỚI

Cần spec thêm vào Combat Bible v3 (sẽ làm sau):

- Layout corridor giữa V1-V2, V2-V3, ..., V5-V6 (5 corridor × ~15×10 tile)
- Layout Optional Pocket cho V3, V4, V5 (3 vùng × 2 pocket × ~10×10 tile)
- Shrine + Checkpoint placement (Node 2 trong mỗi vùng Corridor format)
- Enemy spawn pattern cho corridor (T+1 tier so với vùng vừa rời)

**Total new tiles cần design:** ~5 corridor (750 tile) + 6 pocket (600 tile) = **1,350 tile** mới.

**Total tiles tiết kiệm:** V3+V4+V5 chuyển từ ~50×40 (6000) sang ~25×40 + 2 pocket (1300) = save **~3,500 tile/vùng × 3 vùng = 10,500 tile**.

**Net: tiết kiệm ~9,150 tile** so với GDD v1.0 spec.

---

# 11. OPEN QUESTIONS

Cần resolve trước M2 prototype:

1. **Mastery Ritual mini-game** dùng Phase 2 difficulty +30% — có cần thêm visual cue đặc biệt (anvil glow, particle riêng) để player biết "đây là ritual quan trọng"?

2. **Test Slot UI** — đăng ký sword vào Test Slot ở đâu? Ở Forge tab "Test"? Hay ở Inventory menu? Cần wireframe.

3. **Mercenary report content** — auto-generate từ pre-written templates (50-100 templates) hay procedural từ NPC personality? MVP: template recommend.

4. **Debt Agent triggers** — spawn random Sáng/Chiều, hay scripted theo nợ Stage? MVP: 50% random + 50% scripted.

5. **Conditional Sellable quest hooks** — NPC chủ động request, hay player phải initiate dialogue? MVP: NPC sẽ "ping" có icon "!" khi có request.

6. **Niche Kiosk visual/UX** — physical kiosk trong làng (4 stalls), hay menu thống nhất? MVP: 4 stalls vật lý (immersion + spatial memory).

7. **Tutorial cho Test Slot + Chiến Chứng** — ngày nào trong tutorial 3 ngày? Đề xuất: ngày 4-5 (sau khi đã rèn 2-3 kiếm và đi dungeon vài lần).

---

# 12. APPENDIX A — DATA SCHEMAS

## A.1. RouteState

```gd
class_name RouteState
extends Resource

@export var id: String                           # "corridor_1_2", "v3_internal_corridor"
@export var region_id: String                    # "v1", "corridor_v1_v2"
@export var state: RouteStateEnum                # Locked | Dangerous | ClearedByPlayer | SecuredByMercenary
@export var stamina_cost_base: int = 3           # Cost khi Dangerous
@export var stamina_cost_cleared: int = 2        # Cost khi ClearedByPlayer
@export var stamina_cost_secured: int = 1        # Cost khi SecuredByMercenary
@export var required_unlocks: Array[String]      # Conditions to enter (quests, items, reputation)
@export var secured_effects: Dictionary          # { enemy_spawn_rate: 0, drop_quality: -1 }
@export var secured_expiry_day: int = -1         # Game day khi Secured expires; -1 = không Secured
```

## A.2. MercenaryContract

```gd
class_name MercenaryContract
extends Resource

@export var id: String                           # "merc_v1_hiep_khach"
@export var npc_id: String                       # NPC reference
@export var route_id: String                     # Which route to secure
@export var cost_gold: int                       # 300-700G
@export var duration_phases: int = 4             # 1 ngày = 4 phases
@export var requirements: Dictionary             # { affinity_min: 30, sword_sold_tag: "ben_ngot" }
@export var result_state: RouteStateEnum         # SecuredByMercenary
@export var report_rewards: Array[Dictionary]    # [{ item_id: "da_soi", qty: 3, chance: 0.8 }]
@export var report_intel: Array[String]          # ["Ma Rừng tuần tra phía bắc V2 ban đêm"]
```

## A.3. NPCBuyer (mở rộng v1.0)

```gd
class_name NPCBuyer
extends Resource

# v1.0 fields (giữ nguyên)
@export var id: String
@export var name: String
@export var portrait: Texture2D
@export var budget_max: int
@export var patience_max: int
@export var preferred_weapon_tags: Array[String]
@export var disliked_weapon_tags: Array[String]
@export var affinity: int = 0

# v1.1 fields (mới)
@export var role: BuyerRoleEnum                  # KIEM_SI | VE_BINH | THO_SAN | THUONG_NHAN | DAO_SI | DAN_LANG | COLLECTOR | DEBT_AGENT
@export var preferred_add_ons: Array[String]     # ["bao_kiem_da", "dau_mai"]
@export var preferred_services: Array[String]    # ["mai_kiem", "sua_kiem"]
@export var conditional_buys: Array[String]      # ["trophy_ho_trang", "phoi_cursed"]
@export var unlock_rewards: Dictionary           # { mercenary_contract: "merc_v1_hiep_khach" }
@export var is_kiosk: bool = false               # True nếu là Niche Buyer Kiosk
@export var daily_buy_cap: int = -1              # Cap items/day cho Kiosk; -1 = unlimited
```

## A.4. SwordItem (mở rộng v1.0)

```gd
class_name SwordItem
extends Resource

# v1.0 fields
@export var id: String
@export var base_value: int
@export var quality_multiplier: float = 1.0      # From Phase 2 result
@export var tags: Array[String]
@export var prefix: String                       # "ben_ngot", "huyen_bi"
@export var suffix: String                       # "hoa", "bang"
@export var durability_current: int
@export var durability_max: int

# v1.1 fields (mới)
@export var proof_grade: int = 0                 # 0-4 (Untested → Mastery)
@export var proof_region: String = ""            # Which region last proved
@export var proof_history: Array[String]         # ["killed_ma_rung_v2", "passed_corridor_2_3"]
@export var is_test_candidate: bool = false      # Đang trong Test Slot?
@export var pending_proof: int = -1              # Proof chờ Shrine seal; -1 = no pending
@export var add_ons_attached: Array[String]      # ["bao_kiem_da"] — bán kèm tự động
@export var curse_state: String = "none"         # "none", "minor", "major"
```

## A.5. ServiceData

```gd
class_name ServiceData
extends Resource

@export var id: String                           # "mai_kiem", "sua_kiem"
@export var name: String
@export var description: String
@export var cost_gold: int
@export var cost_materials: Dictionary           # { "linh_luc_hoa": 1 }
@export var duration_seconds: int                # In-game time
@export var requirements: Dictionary             # { sword_grade_min: 0, affinity_min: 0 }
@export var effects: Dictionary                  # { durability_restore: 0.5, price_bonus: 1.05 }
@export var unlock_phase: String                 # "mvp", "post_mvp"
```

## A.6. AddOnData

```gd
class_name AddOnData
extends Resource

@export var id: String                           # "bao_kiem_da"
@export var name: String
@export var description: String
@export var craft_materials: Dictionary          # { "da": 2, "chi": 1 }
@export var craft_time_seconds: int = 30
@export var price_multiplier_base: float = 1.10  # Apply to sword price
@export var price_multiplier_vip: float = 1.15   # If sold to VIP/matching role
@export var preferred_by_roles: Array[BuyerRoleEnum]
@export var extra_effects: Dictionary            # { durability_bonus: 1.2, affinity_bonus: 5 }
```

---

# 🔥 CAM KẾT GDD v1.1

GDD này là contract giữa solo dev với chính mình. Mọi feature mới sau khi prototype cần:

1. Cut feature khác có scope tương đương, **HOẶC**
2. Dời sang post-launch DLC, **HOẶC**
3. Reject.

**GDD review schedule:** Mỗi 2 tuần trong M1-M5, mỗi tháng từ M6.

**Mantra:** Đầu tiên xây MVP, sau đó polish. Đầu tiên ship, sau đó iterate.

---

🔥 *Lò Thiêng đang chờ được phục dựng. Tiếng Gọi Tổ Nghề sẽ vang.*

*Hết GDD v1.1 — Final Patch*

---

**File này được tạo ngày 13/05/2026. Tham khảo song song với:**
- `LO_THIENG_PC_GDD.md` (v1.0)
- `LO_THIENG_COMBAT_BIBLE_v2.pdf`
- `LO_THIENG_DEV_PLAN_v1.1_SYNC.md` (sync với patch này)
