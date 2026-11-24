# LÒ THIÊNG — COMBAT & EXPLORATION BIBLE
## Tài Liệu Tham Chiếu Duy Nhất · Phiên Bản Hợp Nhất

```
VERSION      : 2.0 (merged từ v1.0 + patch v1.1)
PROJECT      : Lò Thiêng — Tiếng Gọi Tổ Nghề
ENGINE       : Godot 4
SCOPE        : Solo dev
GENRE        : Shop Management + Crafting + Turn-based RPG
COVERS       : Encounter System, Stamina, Monster Tiers, Map Design,
			   Loot System, Difficulty Scaling, Puzzle System
LAST UPDATED : Tháng 5/2026
```

---

## MỤC LỤC

1. [Triết Lý Thiết Kế Combat](#1-triết-lý-thiết-kế-combat)
2. [Hệ Thống Encounter & Stamina Overworld](#2-hệ-thống-encounter--stamina-overworld)
   - 2.1 Patrol AI
   - 2.2 Negotiation System
   - 2.3 Hành Động Player Khi Gặp Quái
   - 2.4 Exploration Stamina System ← MỚI
3. [Phân Cấp Quái Vật](#3-phân-cấp-quái-vật)
4. [6 Vùng Đất — Map & Loot Bible](#4-6-vùng-đất--map--loot-bible)
5. [Hệ Thống Độ Khó Tăng Dần](#5-hệ-thống-độ-khó-tăng-dần)
6. [Hệ Thống Câu Đố](#6-hệ-thống-câu-đố)
7. [Puzzle Mechanics Reference](#7-puzzle-mechanics-reference)
8. [Cam Kết Scope](#8-cam-kết-scope)

---

## QUYẾT ĐỊNH THIẾT KẾ CỐT LÕI (đọc trước)

```
LOOT RULE    : Items CHỈ drop từ enemy sau khi giết. Không còn
			   gathering node nhặt trực tiếp trên map.
			   → R3 (phổ thông) : drop T1/T2, cũng mua được từ vendor
			   → R2 (hiếm)      : drop T2/T3, KHÔNG mua được
			   → R1 (cực hiếm)  : drop T3/T4 boss, KHÔNG mua được

STAMINA RULE : Mọi hành động exploration tốn stamina cụ thể.
			   Hết stamina = force return workshop, không game over.
			   Base stamina = 14. Full restore mỗi đêm.

COMBAT RULE  : Turn-based, 3-5 lượt/trận.
			   Counter từ sau lưng = player đánh trước + 30% bonus damage.
			   Weapon = 2 active skills (Prefix + Suffix).
```

---

# 1. TRIẾT LÝ THIẾT KẾ COMBAT

## 1.1 Học Từ Hai Game Tham Khảo

**Từ Persona 5:**

| Yếu tố | Lò Thiêng áp dụng |
|---|---|
| Overworld encounter | Quái tuần tra có vision cone, đuổi khi thấy player |
| Counter advantage | Tấn công lưng quái → player đánh trước + Phủ Đầu +30% damage |
| Weakness exploit | Đúng nguyên tố → enemy stunned 1 lượt |
| All-Out Attack | "Đòn Kết Liễu" khi enemy stunned + player HP > 50% |
| Negotiation | Một số quái có tag NEGOTIABLE — player chọn đàm phán thay vì đánh |

**Từ Tales of Phantasia:**

| Yếu tố | Lò Thiêng áp dụng |
|---|---|
| Transition nhanh | Scene combat load không có màn hình chờ dài |
| Enemy personality | Mỗi loại quái có pattern rõ, player học theo thời gian |
| Combo flow | Basic Attack → Skill 1 → Skill 2 tạo chuỗi có momentum |
| Weapon = identity | Đổi vũ khí = đổi bộ 2 skill hoàn toàn = đổi playstyle |

## 1.2 Core Design Pillars

```
PILLAR 1 — "Nhìn thấy = Chủ động"
  Player luôn thấy quái trước khi bị tấn công.
  Mọi combat do player quyết định: đánh, tránh, hoặc counter.

PILLAR 2 — "Chuẩn Bị = Phần Thưởng"
  Counter từ sau lưng → bonus rõ ràng.
  Đúng nguyên tố → trận đấu ngắn hơn hẳn.
  Vũ khí phù hợp → cảm giác "làm chủ".

PILLAR 3 — "Mỗi Vùng = Một Ngôn Ngữ"
  V1 Đồng Mây   : dạy basic encounter
  V2 Rừng       : dạy terrain awareness + visibility
  V3 Núi        : dạy weakness system
  V4 Cát        : dạy hidden hazard + negotiation
  V5 Thành      : dạy indoor layout + key-door
  V6 Làng       : tổng hợp tất cả

PILLAR 4 — "Combat = Con Đường Duy Nhất Đến Nguyên Liệu"
  Không có gathering node trên map.
  Muốn nguyên liệu → phải đánh quái.
  R1/R2 hoàn toàn locked sau combat, không mua được.
```

---

# 2. HỆ THỐNG ENCOUNTER & STAMINA OVERWORLD

## 2.1 Patrol AI

### State Machine Quái Overworld

```
[IDLE] ──── Player vào vision cone ──→ [ALERT] ──── Player trong range ──→ [CHASE]
  ↑                                        │                                     │
  └─── Player thoát chase zone ────────────┘        Player va chạm ──────────→ [ENCOUNTER]
																				   │
							  Player tấn công từ PHÍA SAU ─────────────────────→ [COUNTER_ENCOUNTER]
```

### Vùng Nhận Thức

```
				▲ PHÍA TRƯỚC
			   /│\
		   Vision Cone (60°, 5 tiles)
		  /         \
[QUÁI] ──────────────── ← Hearing range (radius 3 tiles, mọi hướng)
		  \         /
		   PHÍA SAU = Blindspot
```

**Noise Events:**

| Hành động | Noise level | Hệ quả |
|---|---|---|
| Chạy trên tile cát/đá | +1 | Quái trong hearing range alert |
| Dùng skill trong vùng | +2 | Attract quái gần đó vào combat |
| Đánh quái khác gần đó | +3 | Quái trong 5 tile có thể join trận |
| Đi bộ bình thường | 0 | Không effect |

### Cooldown Sau Khi Thoát

```
Quái bị thoát → COOLDOWN 30 giây → icon "?" xuất hiện → quay về patrol
Trong cooldown: không chase, không alert
```

### Đặc Điểm Patrol Theo Tier

| Tier | Vision Cone | Chase Range | Chase Speed | Mất dấu player |
|---|---|---|---|---|
| T1 | 60°, 4 tiles | 6 tiles | Chậm hơn player | Dừng, quay về vị trí |
| T2 | 90°, 5 tiles | 8 tiles | Bằng player | Zigzag 5 giây rồi về |
| T3 | 120°, 6 tiles | Toàn phòng | Nhanh hơn player | Không bỏ cuộc, canh cửa |
| T4 | Arena-wide | N/A | N/A | Không tuần tra, trigger khi enter |

---

## 2.2 Negotiation System

Chỉ áp dụng với enemy có tag `NEGOTIABLE` — khoảng 3-4 loại per vùng.

```
Action Menu (khi NEGOTIABLE):
  [ Tấn công thường ]
  [ Skill 1         ]
  [ Skill 2         ]
  [ Vật phẩm        ]
  [ Đàm Phán ▼      ] ← chỉ hiện với NEGOTIABLE enemy
```

**Kết quả đàm phán (3 option ngẫu nhiên mỗi lần):**

| Option | Xác suất thành công | Kết quả thất bại |
|---|---|---|
| Dọa nạt | 50% enemy bỏ chạy + drop item | 50% enemy ATK +20% |
| Cầu xin | 70% nhận 1 material R3 | 30% không có gì |
| Hỏi thông tin | 100% reveal weakness + 1 lore hint | — |

**Trường hợp đặc biệt — Thương Nhân Mất Hồn (V4):**
Đàm phán thành công → player CHỌN loot từ menu 3 items thay vì random drop.

**Trường hợp đặc biệt — Hồn Ma Thợ Rèn (V6):**
Đàm phán luôn thành công → nhận lore dialogue + hint về Di Vật.

---

## 2.3 Hành Động Player Khi Gặp Quái

| Tình huống | Cách thực hiện | Kết quả combat | Stamina |
|---|---|---|---|
| Counter (lưng quái) | Đứng sau + nhấn Interact | Player đánh trước + Phủ Đầu +30% | −1 (giảm từ 2 xuống 1) |
| Bị đuổi (quái tấn công) | Quái va chạm player | Enemy đánh trước | −2 |
| Va chạm trực diện | Hai bên đụng nhau | Speed quyết định ai trước | −2 |
| Bỏ chạy pre-combat | Cancel + đủ khoảng cách | Không vào combat | 0 |
| Bỏ chạy in-combat | Smoke Bomb / skill Bóng Tối | Thoát về vị trí spawn | 0 thêm (đã trả 2 khi vào) |
| Thua combat (KO) | HP = 0 | Về workshop, mất 20% gold | −4 thêm (total −6 từ trận) |

---

## 2.4 Exploration Stamina System

### Triết Lý

Stamina là **ngân sách thời gian hữu hình**. Player thấy sức lực cạn dần theo từng quyết định cụ thể. Hết stamina không kill player — chỉ force return về workshop.

### Stamina Pool

| Stat | Giá trị | Ghi chú |
|---|---|---|
| Base stamina | 14 | Khởi đầu game |
| Max stamina | 14 → 20 | +1 mỗi 2 Reputation tăng |
| Restore | Full | Qua đêm tại workshop |
| Hiển thị | Icon trái tim ×N trên HUD | Tối dần khi giảm |

### Chi Phí Stamina — Di Chuyển

| Hành động | Chi phí | Ghi chú |
|---|---|---|
| Đi bộ terrain thường | 1 / 12 tile | Drain ngầm, tự động |
| Terrain khó (cát lún, bụi rậm, dốc leo) | 1 / 6 tile | Visual: nhân vật đi chậm hơn |
| Đứng cạnh hazard tile (dung nham, bẫy) | 1 / 3 tile | Cộng thêm vào movement drain |
| Chạy (giữ Shift) | ×2 drain | Đổi lại: tốc độ ×1.7 |
| Đứng yên | 0 | Nghỉ an toàn |

### Chi Phí Stamina — Combat

| Hành động | Chi phí |
|---|---|
| Vào encounter (bất kỳ) | −2 |
| Counter (tấn công lưng) | −1 thay vì −2 |
| Thắng combat | +0 (không hoàn trả) |
| Thua combat / KO | −4 thêm (total trận = −6) |
| Bỏ chạy in-combat | +0 thêm |

### Chi Phí Stamina — Tương Tác

| Hành động | Chi phí |
|---|---|
| Loot enemy sau khi giết | 0 (tự động) |
| Nói chuyện NPC | 0 |
| Giải puzzle | 0 |
| Khám phá vùng ẩn / lối bí mật | −1 |
| Tương tác Shrine (nghỉ chân) | **+3 recover** (1 lần/ngày/shrine) |

### Drain Đặc Biệt Theo Vùng

| Vùng | Terrain đặc biệt | Drain thêm |
|---|---|---|
| V2 Rừng | Khu tối dưới tán dày | ×1.5 khi trong bóng tối |
| V3 Núi | Leo dốc | +1 per 4 tile leo lên |
| V4 Cát | Dẫm phải cát lún | −2 ngay lập tức rồi về normal |
| V5 Thành | Kích hoạt bẫy hành lang | −1 dù không bị damage |
| V6 Làng | Khu dungeon Lò Thiêng | ×1.3 toàn bộ drain |

### Trạng Thái Stamina & Warning

| Mức | Màu HUD | Visual | Effect |
|---|---|---|---|
| 14–8 | Xanh | Bình thường | Không có |
| 7–4 | Vàng | Icon HUD vàng, thở nặng nhẹ | Không có |
| 3–1 | Cam | Icon nhấp nháy | Tốc độ đi bộ −15% |
| 0 | Đỏ | Fade màn hình nhẹ | Force return workshop ngay |

### Stamina Theo Difficulty

| Difficulty | Base stamina | Penalty KO | Terrain drain |
|---|---|---|---|
| Story | 18 | −2 | ×0.7 |
| Normal | 14 | −4 | ×1.0 |
| Hardcore | 12 | −6 | ×1.3 |

### Stamina Và Consumable

| Item | Effect | Nguồn |
|---|---|---|
| Bánh Mật | +3 stamina | Mua từ vendor, 100G |
| Trà Thảo Mộc | +2 stamina + cleanse 1 debuff | Mua từ vendor, 200G |
| Tương tác Shrine | +3 stamina | Trong map, 1 lần/ngày |

### Ước Tính Stamina Tiêu Thụ Một Buổi Sáng (Normal)

| Vùng | Stamina dùng trung bình | Còn lại khi về |
|---|---|---|
| V1 Đồng Mây | 6–8 | 6–8 |
| V2 Rừng | 8–10 | 4–6 |
| V3 Núi | 9–11 | 3–5 |
| V4 Cát | 8–10 | 4–6 |
| V5 Thành | 10–12 | 2–4 |
| V6 Làng | 11–14 | 0–3 |

---

# 3. PHÂN CẤP QUÁI VẬT

## 3.1 Bốn Tier

| Tier | Tên | Icon màu | HP | AI | Loot | Spawn |
|---|---|---|---|---|---|---|
| T1 | Thường | ⚪ Xám | ×1 base | Đơn giản, 1 pattern | R3 chủ yếu | Random, respawn mỗi ngày |
| T2 | Tinh Nhuệ | 🔵 Xanh | ×2 | 1 special move | R2-R3 | Fixed + thỉnh thoảng random |
| T3 | Thủ Lĩnh | 🟣 Tím | ×4 | 2 special moves + Aura | R1-R2 | Fixed, không respawn trong ngày |
| T4 | Boss | 🟡 Vàng | ×10+ | 3 HP phase, telegraph | R1 guaranteed + Di Vật | Scripted, gắn quest |

## 3.2 Aura Của T3 Champion (bán kính 4 tile)

| Aura | Effect |
|---|---|
| Kích Thích | T1/T2 xung quanh chase speed +50% |
| Phòng Thủ | T1/T2 trong combat cùng Champion +2 DEF |
| Hồi Phục | Champion hồi 5 HP/lượt nếu còn T1 sống trong trận |
| Bóng Tối | Vision cone của player −30% khi trong vùng aura |

## 3.3 Loot Drop Mechanics

```
CÁCH TÍNH DROP:
  Mỗi enemy có 3 slot loot:
	Slot 1 (80% trigger): Drop thường
	Slot 2 (20% trigger): Drop hiếm
	Slot 3 (5% trigger) : Drop đặc biệt / exclusive

  Boss T4: Slot 1+2 guaranteed, Slot 3 = Di Vật quest item (guaranteed)

HAND INVENTORY LIMIT: 12 slot
  Đầy → phải về workshop hoặc bỏ item cũ
  Stamina thường hết trước hand limit ở V1-V3
  V4-V6: hand limit bắt đầu thành constraint thật sự
```

---

# 4. SÁU VÙNG ĐẤT — MAP & LOOT BIBLE

## LEGEND CHUNG CHO TẤT CẢ MAP

```
T = Decoration (cây, bụi, vật trang trí — không tương tác)
R = Navigation guide (đá dẫn đường, cột mốc — không tương tác)
E = Enemy T1 spawn point
2 = Enemy T2 spawn point
C = Champion T3 spawn point
B = Boss arena entrance
N = NPC ngoài trời
S = Shrine (recover +3 stamina, 1 lần/ngày)
P = Puzzle zone
. = Terrain trống đi được
```

> **Lưu ý:** Không còn ký hiệu G (Gathering Node) trong bất kỳ map nào.
> Toàn bộ materials chỉ đến từ loot sau khi giết enemy.

---

## 🌾 VÙNG 1: ĐỒNG MÂY TRẮNG

```
Kích thước  : 50 × 40 tiles
Mở          : Mặc định từ đầu game
Mục đích    : Tutorial — dạy encounter basics, không surprise
Stamina/ngày: 6–8 (Normal)
Tier chủ yếu: T1
Loot quality: R3 chủ yếu, R2 từ T2
```

### Layout Map

```
┌─────────────────────────────────────────────────────────┐
│  T T T T T  R R R . . . . . . . E . . T T T T T T T T  │
│  T T T T . . . . . . . . . . . . . . . . . T T T T T   │
│  T T T . . R . . . . . . . . . E . . . . . . T T T T   │
│  T T . . . R . . . . . . . . . . . . . . . . . T T T   │
│  T T . . . . . . . . . . S . . . . . . . . . . . T T   │
│  T . . . . . . . . . E . . . . . . . . . . . . . . T   │
│ [SPAWN]. . . . . . . . . . . . . C . . . . . E . . .   │
│  T . . . R . . . . . . . . . . . . . . . . . . . . T   │
│  T T . . R . . . . . . . . . E . . . . . . . T T T T   │
│  T T T . . . . . . . . . N . . . . . . . . . T T T T   │
│  T T T T T . . . R R R . . . . . . . . . [BOSS]. T T   │
└─────────────────────────────────────────────────────────┘
```

### Objects Theo Loại

**Trang Trí (Decoration):**
- Bụi cỏ cao: 40–60 cụm
- Hoa dại trắng/vàng: 20–30
- Mây thấp trôi qua (animated background): 5–8
- Xương động vật nhỏ rải rác: 3–5 (subtle danger hint)

**Dẫn Đường (Navigation):**
- Đá tảng nhỏ cluster 2–3 viên: 8–10 cluster → tạo "hành lang tự nhiên"
- Cột gỗ cũ từ thời Lò Thiêng cổ: 4–5 → đánh dấu ngã tư
- Cỏ dẫm nát (trail texture): dọc path chính → "người khác đã đi qua đây"
- Clearing sáng hơn xung quanh: hướng player về phía clearing

**Clearing Combat (Enemy Loot Anchor):**
- T3 Champion đứng tại clearing trống 5×5 tile
- Clearing đủ rộng để combat không bị kẹt terrain

### Loot Drop Table

| Enemy | Tier | Drop 80% | Drop 20% | Drop 5% |
|---|---|---|---|---|
| Sói Đồng Cỏ | T1 | Lông Sói (R3), Nanh Sói Nhỏ (R3) | Da Sói Dày (R2) | — |
| Bandit Trẻ | T1 | Vải Rách (R3), Đồng Xu Gãy (R3) | Dao Cũ (R2, quest item) | — |
| Sói Già | T2 | Nanh Sói Cứng (R2) ×2, Lông Sói Dày (R2) | Da Sói Xám (R1) | Tủy Xương Sói (R1, Forge bonus) |
| Thủ Lĩnh Sói | T3 | Da Sói Xám (R1), Nanh Sói Bạc (R1) | — | Lông Sói Thiêng (R1, exclusive) |
| Boss Sói Trắng | T4 | Da Sói Trắng (R1) ×2, Nanh Sói Vua (R1) ×2 | Mắt Sói Trắng (Di Vật hint) | **Di Vật #141 — Búa Tổ Đồng Cỏ (guaranteed)** |

**Lượng loot trung bình một buổi sáng V1 (Normal):**
~4 T1 + 1 T2 = 6–8 materials R3, 1–2 R2. Đủ 1–2 lần forge cơ bản.

### Enemy Spawn Chi Tiết

| Enemy | Số fixed | Số random | Patrol pattern |
|---|---|---|---|
| Sói Đồng Cỏ | 3 | 2–4 | Vòng tròn bán kính 4 tile |
| Bandit Trẻ | 2 | 1–3 | Đi thẳng A→B rồi quay |
| Sói Già (T2) | 2 | 0 | Patrol khu vực phía Đông |
| Thủ Lĩnh Sói (T3) | 1 | 0 | Đứng tại clearing trung tâm |

---

## 🌲 VÙNG 2: RỪNG TRĂM HỒN

```
Kích thước  : 60 × 50 tiles
Mở          : Khi trả Stage Nợ 1 (ngày 3–5)
Mục đích    : Dạy terrain awareness + visibility reduced
Stamina/ngày: 8–10 (bụi rậm drain ×1.5)
Tier chủ yếu: T1–T2
Loot quality: R3–R2, R1 từ T3/T4
```

### Layout Map

```
┌────────────────────────────────────────────────────────────────┐
│ TTTTTTTTT T T T . . . T T . E . T T T T T TTTTTTTTT           │
│ TTTTTTTT T . . T . . . . T . . . T . . T T T T TTTTTT         │
│ TTTTTTT . . R . T . . . E . . . . . . . . T TTTTTTTTT         │
│ TTTTTT . . . . T T T . . . . C . . . T T . . TTTTTTTT         │
│ TTTTT . . . . . . T T T . . . . . . . . . . . T TTTTT         │
│ TTT . . . . . . . . . T T . . P1. . . E . . . . . TTT         │
│ TT . . . . . . . . . . . T T T . . . . . . . . . . TT         │
│ [SPAWN] . . N . . . . . . . . T . T . . . . . . . . .         │
│ TT . . . R . . . . . . . . . T . T T . . . S . . . TT         │
│ TTT . . . . . . . . E . . . . . . T T T . . . . . TTT         │
│ TTTTT . . . . . . . . . . C . . . . T T T . . TTTTTTT         │
│ TTTTTTT . . . . . . . . . . . . . . . . . [BOSS] TTTTT        │
└────────────────────────────────────────────────────────────────┘
```

### Objects Theo Loại

**Trang Trí:**
- Cây cổ thụ lớn (block movement): 30–40 → tạo hành lang tự nhiên, KHÔNG đi qua được
- Bụi rậm + cây nhỏ: 60+ → làm chậm camera, không block
- Ánh sáng lọc qua tán lá (particle): ambient
- Nấm phát sáng nhỏ: 15–20 (ánh sáng yếu ban đêm)
- Xác cây mục: 8–10 (partial block)

**Dẫn Đường:**
- Đá có khắc rune (thời Tổ Nghề): tại ngã ba quan trọng
- Clearing sáng giữa rừng: an toàn hơn, player hướng về
- Khe hở trong dây leo: lối đi; bít kín = tường
- Dòng suối nhỏ (visual only): dọc suối dẫn đến Shrine hoặc NPC

**Terrain Đặc Biệt:**
- Vùng tối dưới tán dày: visibility giảm, drain stamina ×1.5
- Ma Rừng T1 ẩn trong bụi → chỉ thấy "glow" trước khi thấy body

### Loot Drop Table

| Enemy | Tier | Drop 80% | Drop 20% | Drop 5% |
|---|---|---|---|---|
| Ma Rừng | T1 | Tinh Thể Nhỏ (R3), Khói Linh (R3) | Tinh Thể Màu (R2) | — |
| Nhện Rừng | T1 | Tơ Nhện Thô (R3), Nọc Nhện Yếu (R3) | Túi Nọc Nhện (R2) | — |
| Hổ Rừng | T2 | Móng Hổ (R2) ×2, Lông Hổ Đen (R2) | Răng Hổ (R1) | Mật Hổ (R1, Forge suffix bonus) |
| Ma Rừng Già | T3 | Tinh Thể Rừng (R1), Linh Khí Cô Đọng (R1) | — | **Hồn Thảo Mộc (R1, Suffix Dark/Poison exclusive)** |
| Boss Hổ Trắng | T4 | Móng Hổ Trắng (R1) ×2, Da Hổ Thiêng (R1) | Mắt Hổ Trắng (R1) | **Di Vật #145 — Ống Thổi Hồn (guaranteed)** |

> **Hồn Thảo Mộc** chỉ drop từ T3 Ma Rừng Già → là lý do player quay lại V2 kể cả khi đã lên V3–V4.

---

## 🌋 VÙNG 3: NÚI THAN ĐỎ

```
Kích thước  : 65 × 55 tiles
Mở          : Reputation 3 + Quest "Tin Đồn Núi Lửa"
Mục đích    : Dạy Weakness System — tất cả quái yếu với Băng hoặc Thánh
Stamina/ngày: 9–11 (leo dốc +1/4 tile)
Tier chủ yếu: T2
Loot quality: R2–R1
```

### Layout Map (tiết diện đứng — lên cao từ trái sang phải)

```
[SPAWN]──Đường leo──[Khu nền]──Hang đá 1──[Cầu đá treo]──Hang đá 2──[BOSS CRATER]
			 │              │                                │
		 Enemy E         Shrine S                     2 (T2 mạnh)
		 (Thạch Quỷ)   (hint weakness)              (Quỷ Đá Lớn)
```

```
┌──────────────────────────────────────────────────────────────────┐
│ RRRRR R R . . E . . R R R . . . . . . . R R R . . . . . . R R  │
│ R R R . . . . . . E . . . . . . . . . . . R . . C . . . . R R  │
│ R R . . . . . . . . . . . . . . E . . . . . . . . . . . . R R  │
│ R . . . . . . . . . . . S . . . . . . R . . E . . . . R R R R  │
│ . . . . . . E . . . . . . . . . . P2. . . . . . . . . R R R R  │
│ [SPAWN]. . . . . . . . . . . . . . . . . . . . . . . . . R R   │
│ . . . . . . . . C . . . . . . . . . . . . . . . . . R R R R R  │
│ R . . . . . . . . . . . . . . . . . . . . . . . . R R BOSS  R  │
└──────────────────────────────────────────────────────────────────┘
```

### Objects Theo Loại

**Trang Trí:**
- Dung nham đông cứng (floor texture): visual only
- Dung nham chảy nhẹ: **HAZARD TILE** — 3 damage/giây khi đứng trên
- Khói phun từ khe núi (particle): visibility giảm nhẹ
- Than hồng lấp lánh (ambient): không tắt được
- Xác giáp trụ cũ: interact được, đọc 1 dòng flavour text

**Dẫn Đường:**
- Dung nham tạo ranh giới tự nhiên → player đi dọc bờ đến cầu đá
- Cầu đá tự nhiên: bottleneck — con đường duy nhất qua khe
- Ánh sáng đỏ từ miệng hang: hang = nguy hiểm/reward rõ ràng

**Hazard Rule:**
- Enemy KHÔNG đứng trên hazard tile
- Loot từ enemy rơi trên safe tile kế bên
- Player không bao giờ bị ép đứng trên hazard để nhặt loot

**Shrine Vùng Này:** Hint "Hỏa không hiệu quả → dùng Băng hoặc Thánh" — giải thích Weakness System lần đầu tiên.

### Loot Drop Table

| Enemy | Tier | Weakness | Drop 80% | Drop 20% | Drop 5% |
|---|---|---|---|---|---|
| Thạch Quỷ Nhỏ | T1 | Băng | Mảnh Đá Lửa (R3), Bụi Than Đỏ (R3) | Đá Nham Thạch (R2) | — |
| Rắn Lửa | T1 | Thánh+Băng, IMMUNE Hỏa | Vảy Rắn Hỏa (R3), Nọc Rắn (R3) | Nọc Rắn Cô Đặc (R2) | — |
| Quỷ Đá Lớn | T2 | Băng | Lõi Đá Lửa (R2) ×2, Nham Thạch Cứng (R2) | Thép Hỏa Sơn Thô (R1) | **Lõi Hỏa Nguyên (R1)** |
| Thần Lửa Cổ | T3 | Thánh | Than Thiêng (R1) ×2 | Cánh Bễ Fragment (R1) | **Than Hồng Ngàn Năm (R1, Di Vật #148 component)** |
| Boss Rồng Lửa Nhỏ | T4 | Băng+Sét | Vảy Rồng (R1) ×2, Lõi Rồng (R1) | Răng Rồng Lửa (R1) | **Di Vật #149 — Móng Rồng Lửa (guaranteed)** |

> **Lõi Hỏa Nguyên** (5% T2): Khi dùng trong Forge Phase 1 → tự động kết quả Vàng Kim (+40%). Incentive mạnh để farm T2 Quỷ Đá.

---

## 🏜️ VÙNG 4: BÃI CÁT THẦN VÀNG

```
Kích thước  : 70 × 60 tiles
Mở          : Reputation 5
Mục đích    : Hidden hazard (cát lún), negotiation combat, không gian mở
Stamina/ngày: 8–10 (cát lún −2 khi dẫm phải)
Tier chủ yếu: T2
Loot quality: R2–R1
```

### Mechanics Đặc Biệt Vùng Này

**Cát Lún:**
- Tile trông giống cát thường nhưng có ripple animation tinh tế
- Bước vào: bị slow 50% trong 3 giây + tốn −2 stamina ngay lập tức
- Quái biết tránh cát lún → quan sát đường quái đi = biết đường an toàn
- Player học: "nhìn kỹ mặt đất trước khi bước"

**Bão Cát Cục Bộ** (random 1 lần/ngày):
- Vùng ~10×10 tile bị phủ bởi bão cát
- Cả player lẫn quái đều giảm visibility trong bão
- Player có thể dùng bão để thoát hoặc counter ambush

**Bóng Mát Dưới Đá Lớn = Safe Zone:**
- Quái T1 không vào bóng mát → player biết đây là "refuge"
- Player có thể regather stamina mentality tại đây (không restore thật, chỉ visual safe)

### Loot Drop Table

| Enemy | Tier | Drop 80% | Drop 20% | Drop 5% |
|---|---|---|---|---|
| Bọ Cạp Cát | T1 | Vỏ Bọ Cạp (R3), Nọc Cát (R3) | Vỏ Bọ Cạp Cứng (R2) | — |
| Nhện Cát Vàng | T1 | Tơ Cát (R3), Mắt Nhện (R3) | Tuyến Độc Nhện Cát (R2) | — |
| Thương Nhân Mất Hồn | T2 NEGOTIABLE | Hổ Phách Thô (R2), Đồng Vàng Cát (R2) | Hổ Phách Tinh (R1) | Đồ Cổ Sa Mạc (R1, quest item) |
| Khổng Tước Cát | T3 | Lông Khổng Tước Cát (R1) ×2 | Mắt Khổng Tước (R1) | **Ấn Triện Fragment (Di Vật #152 component)** |
| Boss Ông Cát Thần | T4 | Cát Thần (R1) ×3, Ấn Vàng (R1) | Mắt Cát Thần (R1) | **Di Vật #152 — Ấn Triện Cát Thần (guaranteed)** |

> **Thương Nhân Mất Hồn Negotiation**: Đàm phán thành công → player chọn 1 trong 3 items từ loot table thay vì random. Đây là giá trị thực tế duy nhất của Negotiation system.

---

## 🏯 VÙNG 5: THÀNH NGỌC BÍCH

```
Kích thước  : 80 × 65 tiles (indoor map duy nhất có 2 tầng)
Mở          : Reputation 7 + Quest VIP
Mục đích    : Indoor hành lang + tầng + key-door puzzle
Stamina/ngày: 10–12
Tier chủ yếu: T2–T3
Loot quality: R1 chủ yếu
```

### Cấu Trúc Tầng

```
TẦNG 1 (Ground): Cổng vào → Chợ bỏ hoang → Khu dân cư cũ
TẦNG 2 (Upper) : Cung điện → Kho vũ khí → Boss Room

Hành lang rộng: 2–3 tile → quái có thể block hoàn toàn
Phòng lớn: combat arena tự nhiên khi vào
Cầu thang: nối 2 tầng, bottleneck quan trọng
Cửa khóa: cần Key từ enemy hoặc puzzle
```

### Objects Theo Loại

**Trang Trí:**
- Tranh ngọc khảm trên tường (interact = đọc lore)
- Đèn lồng: sáng = tương đối an toàn, tối = cẩn thận
- Biểu ngữ Hoàng Gia rách (decay lore)
- Bàn thờ nhỏ (interact = đọc history + đôi khi consumable ẩn)

**Dẫn Đường:**
- Đèn sáng trên hành lang chính = đường quái tuần tra (double-edged guide)
- Mũi tên khắc sàn đá = quest marker in-world
- Cửa sổ vỡ nhìn ra ngoài = player orient được mình đang ở phía nào

### Loot Drop Table

| Enemy | Tier | Drop 80% | Drop 20% | Drop 5% |
|---|---|---|---|---|
| Cận Vệ Ngọc Bích | T2 | Thép Trắng Thô (R2), Mảnh Giáp Ngọc (R2) | Thép Ngọc Tinh (R1) | — |
| Cận Vệ Ngọc Bích | T2 | **Ngọc Thành Key (LUÔN DROP)** | — | — |
| Pháp Sư Cung Điện | T2 | Pha Lê Ma Pháp (R2), Tàn Tích Phép (R2) | Ngọc Phép Thuật (R1) | Bản Ghi Phép (R1, mở recipe) |
| Tướng Ngọc Bích | T3 | Thép Ngọc (R1) ×2, Mảnh Khiên Tướng (R1) | Huy Hiệu Tướng (R1) | **Kéo Cắt Fragment (Di Vật #153 component)** |
| Boss Rồng Ngọc | T4 | Vảy Ngọc (R1) ×3, Lõi Ngọc Rồng (R1) | Răng Rồng Ngọc (R1) ×2 | **Di Vật #153 — Kéo Cắt Ngọc Thành (guaranteed)** |

> **Ngọc Thành Key luôn drop**: Key-door puzzle không bị blocked bởi RNG. Drop guaranteed đảm bảo player focus vào spatial puzzle chứ không phải item hunting.

---

## 🏚️ VÙNG 6: LÀNG TỔ NGHỀ

```
Kích thước  : 90 × 75 tiles (lớn nhất, mixed indoor/outdoor)
Mở          : 8 Di Vật + Reputation 8
Mục đích    : Endgame — tổng hợp tất cả mechanics từ V1–V5
Stamina/ngày: 11–14 (drain ×1.3 trong dungeon cuối)
Tier chủ yếu: T3
Loot quality: R1 exclusive
```

### Cấu Trúc

```
Ngoại vi làng   : Open field (quái T2-T3)
Khu nhà cũ      : Indoor rooms (quái T3, puzzle)
Lò Thiêng cổ    : Mini-dungeon 3 phòng → Di Vật #156, #157, #158
```

### Aura Tổ Nghề (khi player có ≥ 10 Di Vật)

```
Visual: Aura nhẹ quanh nhân vật
Effect: T1 enemies tự flee thay vì attack
		T3 Champion vẫn tấn công bình thường
```

### Loot Drop Table

| Enemy | Tier | Drop 80% | Drop 20% | Drop 5% |
|---|---|---|---|---|
| Hồn Ma Thợ Rèn | T1 NEGOTIABLE | Mảnh Ký Ức (R3), Phôi Cũ (R3) | Ký Ức Nguyên Vẹn (R2) | Kỹ Năng Cổ (R1, mở Universal Skill) |
| Quỷ Hắc Nguyệt | T2 | Thép Hắc (R2), Nọc Hắc Nguyệt (R2) | Lõi Hắc Nguyệt (R1) | Lệnh Bà Trùm (quest lore item) |
| Lính Canh Cổ | T3 | Di Tích Rèn (R1) ×2, Phôi Tổ Nghề (R1) | Bí Kíp Rèn Cổ (R1, recipe) | **Nhật Ký Tổ Rèn Fragment (Di Vật #156 component)** |
| Boss Hắc Long Tổ Nghề | T4 | Di Vật Energy ×3 | Vảy Hắc Long (R1) ×2 | **Di Vật #157 + trigger cutscene final** |

> **Hồn Ma Thợ Rèn Negotiation**: Đàm phán luôn thành công → lore dialogue quan trọng + 1 hint Di Vật. Mỗi Hồn Ma cho hint khác nhau → player tìm đủ để hoàn thiện lore.

---

# 5. HỆ THỐNG ĐỘ KHÓ TĂNG DẦN

## 5.1 Ma Trận Độ Khó 6 Vùng

| Yếu Tố | V1 Đồng Mây | V2 Rừng | V3 Núi | V4 Cát | V5 Thành | V6 Làng |
|---|---|---|---|---|---|---|
| Kích thước map | 50×40 | 60×50 | 65×55 | 70×60 | 80×65 | 90×75 |
| Path complexity | ★☆☆☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★★☆☆ | ★★★★☆ | ★★★★★ |
| Mật độ enemy | ★★☆☆☆ | ★★★☆☆ | ★★★★☆ | ★★★☆☆ | ★★★★☆ | ★★★★★ |
| Loot density | Thấp (T1) | Trung bình | Cao (T2 nhiều) | Trung bình | Cao (T2) | Rất cao (T3) |
| Loot quality | R3 chủ yếu | R3–R2 | R2–R1 | R2–R1 | R1 chủ yếu | R1 exclusive |
| Visibility | ★★★★★ | ★★★☆☆ | ★★★☆☆ | ★★☆☆☆ | ★★★☆☆ | ★★☆☆☆ |
| Hazard tiles | Không | Không | Dung nham | Cát lún | Bẫy kích hoạt | Cả hai |
| Stamina drain | ×1.0 | ×1.2 | ×1.3 | ×1.2 | ×1.0 | ×1.3 |
| Puzzle count | 0 | 2 | 3 | 3 | 4 | 5 |
| Enemy tier chủ yếu | T1 | T1–T2 | T2 | T2 | T2–T3 | T3 |
| Stamina/buổi (est.) | 6–8 | 8–10 | 9–11 | 8–10 | 10–12 | 11–14 |

## 5.2 Năm Trục Độ Khó (Không Inflate Số)

```
TRỤC 1 — Path Complexity
  V1: 1 đường, không dead end
  V2: Ngã ba xuất hiện, cả hai dẫn đến đích khác nhau
  V3: Có dead end — nhưng dead end = loot T3 tốt (player học: dead end = reward)
  V5: Nhiều phòng giống nhau → dễ lạc → cần landmark
  V6: Non-linear hoàn toàn

TRỤC 2 — Visibility
  V1: Open field, nhìn xa, không surprise
  V2: Tán cây che, quái ẩn trong bụi
  V4: Bão cát + cát lún không phân biệt được bằng mắt thường

TRỤC 3 — Enemy Complexity
  T1: Basic → học encounter basics
  T2: Cần weapon strategy → dùng đúng weapon
  T3: Cần area awareness → kiểm soát map
  T4: Cần build chuẩn bị từ xưởng trước

TRỤC 4 — Hazard Tiles
  V3: Dung nham — visual rõ ràng → học concept
  V4: Cát lún — khó phân biệt → apply concept khó hơn
  V6: Cả hai + bẫy dungeon

TRỤC 5 — Puzzle Depth
  V2: 1 mechanic, 1 bước → tutorial puzzle
  V3-V4: 1-2 mechanics, 2-3 bước
  V5: 2 mechanics kết hợp
  V6: 3 mechanics combo
```

## 5.3 Quy Tắc Loot Theo Rarity

```
Rarity 3 (phổ thông) : Drop T1/T2 → MUA được từ MaterialVendor bằng gold
Rarity 2 (hiếm)      : Drop T2/T3 → KHÔNG mua được
Rarity 1 (cực hiếm)  : Drop T3/T4 → KHÔNG mua được

→ R3 tạo safety net cho player thiếu nguyên liệu
→ R2/R1 tạo mandatory combat incentive
→ Ba tier = ba mức cam kết với combat
```

---

# 6. HỆ THỐNG CÂU ĐỐ

## 6.1 Quyết Định: Có Puzzle Không?

**Có — với 3 điều kiện bắt buộc:**
1. Tối đa 4 mechanic duy nhất (không thêm sau M6)
2. Mỗi puzzle giải trong 1–3 phút
3. Puzzle là **optional reward path** — không block main progress, ngoại trừ 2–3 Di Vật cụ thể

## 6.2 Sơ Đồ Puzzle System

```
Player tiếp cận vùng puzzle
		↓
  [TRIGGER ZONE] (proximity)
		↓
  [PUZZLE ACTIVE] → UI hint xuất hiện
		↓
	┌───┴───┐
  SOLVED    FAILED
	↓          ↓
[REWARD]   [PUZZLE RESET ngay]
  - Cửa mở
  - Loot cache accessible (R1-R2 items)
  - Di Vật unlock
  - Recipe unlock
  - Lore tablet hiện
```

## 6.3 Phân Bố Puzzle Theo Vùng

| Vùng | Số Puzzle | Mechanic | Reward |
|---|---|---|---|
| V1 Đồng Mây | 0 | — | — |
| V2 Rừng | 2 | Push | Loot cache R2 ×1, Item Linh Lực ×1 |
| V3 Núi | 3 | Push + Plate | Di Vật #147 (1 puzzle), Recipe Hỏa ×1, Loot R1 ×1 |
| V4 Cát | 3 | Plate + Torch | Di Vật #151 (1 puzzle), Gold cache 2000G ×1, Loot R1 ×1 |
| V5 Thành | 4 | Push + Plate + Key-Door | Di Vật #153 (1 puzzle), Recipe ×1, Lore ×2 |
| V6 Làng | 5 | Tất cả 4 mechanics | Di Vật #156, #157 (2 puzzle), Boss pre-req ×1, Lore ×2 |
| **Tổng** | **17** | | |

## 6.4 Hint System (QoL)

```
Player kẹt > 2 phút
	→ Lần 1: Nhân vật độc thoại gợi ý chung
			  VD: "Hm... đá này có vẻ đẩy được?"

Player kẹt > 5 phút
	→ Lần 2: Tooltip góc màn hình "Nhấn [H] để xem gợi ý"

Player nhấn [H]
	→ Overlay mờ hiện partial solution (chỉ bước đầu tiên, không spoil toàn bộ)
```

---

# 7. PUZZLE MECHANICS REFERENCE

## 7.1 Mechanic A — PUSH (Đẩy)

**Quy tắc:**
```
✓ Player chỉ ĐẨY, không kéo
✓ Đẩy 1 ô mỗi lần nhấn direction
✗ Không đẩy qua tường, quái, hazard tile
✗ Rơi qua mép cliff → vật reset, player phải làm lại
R = Reset toàn puzzle (có confirm dialog)
```

**Visual Cues:**
```
Đứng cạnh vật đẩy được  → viền xanh nhạt hiện
Target ô                 → nhấp nháy chậm khi player nhìn vào puzzle zone
Vật đúng vị trí         → phát sáng xanh lá + âm thanh "click"
```

**Tutorial Puzzle PUSH_01 — V2 (1 block, 1 target):**
```
┌───────────────────────┐
│  W  W  W  W  W  W  W │    W = Wall
│  W  .  .  .  .  .  W │    🧱 = Block (đẩy được)
│  W  .  🧱 .  .  .  W │    🎯 = Target
│  W  .  .  .  🎯  .  W │
│  W  .  .  .  .  🪨  W │    🪨 = Đá cố định
│  W  W  W  W  W  W  W │
│       [ENTER]         │
└───────────────────────┘
Solution: Đẩy 🧱 xuống 1, phải 1 → lên 🎯 → cổng mở
Reward: Loot cache R2 accessible
```

**Advanced Puzzle PUSH_04 — V5 (2 blocks, 2 targets):**
```
┌────────────────────────────┐
│ W  W  W  W  W  W  W  W  W │
│ W  .  .  🧱 .  .  .  .  W │    🧱 = Block A
│ W  .  W  .  .  W  .  .  W │
│ W  .  .  .  🎯A .  🧱  W │    🎯A = Target A, 🧱 = Block B
│ W  W  .  .  .  .  .  .  W │
│ W  .  .  .  .  🎯B .  W │    🎯B = Target B
│ W  W  W  W  W  W  W  W  W │
│          [ENTER]           │
└────────────────────────────┘
Solution: Block B → 🎯B trước, Block A → 🎯A sau
Reward: Di Vật #153 + Recipe
```

---

## 7.2 Mechanic B — PRESSURE PLATE (Tấm Áp Lực)

**Quy tắc:**
```
✓ ACTIVE khi: vật Push đặt trên, hoặc player đứng trên
✓ INACTIVE khi: vật bị đẩy đi hoặc player rời
✓ Plate "Toggle" (V4-): nhấn 1 lần = toggle, không cần giữ
✓ Plate "Hold" (V5+): cần giữ liên tục → bắt buộc kết hợp với Push
```

**Puzzle PLATE_01 — V3 (2 plates, 2 blocks):**
```
┌──────────────────────────────┐
│ W  W  W  W  W  W  W  W  W   │
│ W [GATE: ĐÓNG]  .  .  .  W  │    Mở khi P1 + P2 đều active
│ W  W  W  W  .  W  W  W  W   │
│ W  .  P1  🧱 .  .  .  .  W  │
│ W  .  .  .  .  P2  .  .  W  │
│ W  .  🧱 .  .  .  .  .  W   │
│ W  W  W  W  W  W  W  W  W   │
│        [PLAYER STARTS]       │
└──────────────────────────────┘
Insight: 2 blocks, 2 plates, phải giữ CẢ HAI cùng lúc → không thể tự đứng
Solution: Đẩy 2 blocks lên đúng plate tương ứng
Reward: Loot cache R1 (Than Thiêng ×2)
```

**Timed Plate — V5 (optional, harder):**
```
[PLATE] ──(5 giây)──→ [GATE OPEN] ──→ [GATE CLOSE]
Player phải chạy qua trong 5 giây
Priority: 🟡 Should — thêm sau khi core puzzle done
```

---

## 7.3 Mechanic C — TORCH SEQUENCE (Thắp Đuốc Theo Thứ Tự)

**Quy tắc:**
```
✓ Đứng cạnh đuốc + Interact = thắp/tắt
✗ Sai thứ tự = tất cả đuốc tắt, reset
✓ Clue LUÔN có trong phòng, không guess mò
✓ Âm thanh tăng cao dần khi đúng thứ tự
```

**Loại Clue Theo Vùng:**

| Vùng | Loại Clue |
|---|---|
| V4 (tutorial) | Số khắc mờ gần đuốc (1, 2, 3) |
| V4 | Màu sắc theo nguyên tố từ Shrine |
| V5 | Hướng shadow của object đặc biệt |
| V6 | Pattern rune trong Nhật Ký Tổ Rèn |

**Puzzle TORCH_01 — V4:**
```
┌──────────────────────────────────────────┐
│                                          │
│   [3]🔦        [DI VẬT — LOCKED]        │
│                                          │
│   [1]🔦                    [2]🔦         │
│                                          │
│   CLUE TƯỜNG: Rune "I → III → II"       │
│                                          │
│              [ENTER]                     │
└──────────────────────────────────────────┘
Solution: [1] → [3] → [2]
Reward: Di Vật #151 — Mảnh Cổ Vật Sa Mạc
```

**Puzzle TORCH_ADVANCED — V6 (Torch + Plate combo):**
```
Step 1: Giải torch sequence (3 đuốc) → mở cửa phòng trong
Step 2: Trong phòng: 2 pressure plate + 1 block → đẩy block → mở cửa tiếp
Step 3: Di Vật #157 trên bệ
Thời gian giải: ~3-4 phút lần đầu
```

---

## 7.4 Mechanic D — KEY-DOOR (Chìa Khóa — Cửa Khóa)

**Quy tắc:**
```
✓ Key specific: Key A chỉ mở Door A
✓ Key giữ trong inventory sau khi dùng (trừ door đặc biệt)
✓ Visual: Cửa có icon khóa, màu icon = màu key tương ứng
```

| Loại Key | Nguồn | Vùng |
|---|---|---|
| Simple | Enemy T2 drop | V5 |
| Hidden | Chest ẩn sau Push puzzle | V5–V6 |
| Conditional | Chỉ hiện sau khi puzzle khác xong | V6 |

**Flow Key-Door — V5 Tầng 2:**
```
[Phòng A]──(Cửa Đỏ 🔴)──[Phòng B]──(Cửa Vàng 🟡)──[Boss Room]
	│                        │
[Cận Vệ T2             [Chest ẩn sau
 rớt 🔑 Đỏ]            Push puzzle
						 → 🔑 Vàng]

1. Kill Cận Vệ T2 → 🔑 Đỏ (guaranteed drop)
2. Mở Cửa Đỏ → Phòng B
3. Giải Push puzzle → Chest → 🔑 Vàng
4. Mở Cửa Vàng → Boss Room
```

---

## 7.5 Build Priority (Solo Dev)

| Mechanic | Code Complexity | Priority | Vùng bắt đầu |
|---|---|---|---|
| Push | ★★☆☆☆ | 🔴 Must | V2 |
| Pressure Plate | ★★★☆☆ | 🔴 Must | V3 |
| Torch Sequence | ★★★☆☆ | 🟡 Should | V4 |
| Key-Door | ★★☆☆☆ | 🟡 Should | V5 |

---

## 7.6 Puzzle → Reward Dependencies

```
V2 Rừng
├── PUSH_01     → Loot Cache R2 (Tinh Thể Rừng)
└── PUSH_02     → Linh Lực Băng đặc biệt

V3 Núi
├── PLATE_01    → Loot Cache R1 (Than Thiêng ×2)
├── PLATE_02    → Recipe Rèn Hỏa
└── PUSH+PLATE  → Di Vật #147 — Cánh Bễ Hỏa Sơn

V4 Cát
├── TORCH_01    → Di Vật #151 — Mảnh Cổ Vật Sa Mạc
├── PLATE_03    → Gold Cache 2000G
└── PUSH+TORCH  → Di Vật #150 hint + Loot R1

V5 Thành
├── KEY+PUSH    → Di Vật #153 — Kéo Cắt Ngọc Thành
├── PLATE_TIMED → Recipe đặc biệt (locked tier)
└── TORCH+PLATE → Lore Thành Ngọc (2 tablets)

V6 Làng
├── ALL mechanics → Di Vật #156 — Nhật Ký Tổ Rèn
├── ALL mechanics → Di Vật #157 — Bếp Lò Tổ Nghề
└── Boss Pre-req  → Mở cửa Boss Hắc Long Tổ Nghề
```

---

# 8. CAM KẾT SCOPE

## Đã Định Nghĩa — Không Thay Đổi Sau M3

```
✅ Loot-only system — không còn gathering node trên map
✅ 4 mechanic stamina: Movement / Combat / Interaction / Terrain đặc biệt
✅ 17 puzzle phân bố cố định theo 6 vùng
✅ 4 loại puzzle mechanic duy nhất (Push, Plate, Torch, Key-Door)
✅ Hệ thống encounter overworld với counter + flee + negotiation
✅ 4 tier quái với behavior và loot khác nhau
✅ 6 bảng Loot Drop Table cố định theo vùng
✅ 5 trục độ khó tăng dần — không inflate số
✅ Rarity gate: R3 mua được, R2/R1 chỉ từ combat
```

## Có Thể Mở Rộng Post v1.0

```
🟢 Puzzle mechanic thứ 5 (Mirror/Light beam)
🟢 Procedural loot variation nhỏ trong enemy drop
🟢 Loot notify animation khi drop R1
🟢 Combo loot bonus (kill 3 T1 liên tiếp không bị hit = +1 drop slot)
```

## Những Thứ KHÔNG Làm Để Tăng Khó

```
✗ Chỉ inflate HP/ATK của quái
✗ Spawn thêm quái random không có pattern
✗ Map quá lớn không có landmark
✗ Puzzle yêu cầu thông tin bên ngoài phòng puzzle
✗ Stamina drain ẩn không hiển thị rõ
```

---

```
COMBAT BIBLE v2.0 — Lò Thiêng: Tiếng Gọi Tổ Nghề
File này là nguồn sự thật duy nhất cho combat & exploration system.
Mọi thay đổi cần ghi rõ lý do và cập nhật VERSION ở đầu file.
"Build trong scope. Polish tốt hơn thêm nhiều. Ship trước, iterate sau."
```
