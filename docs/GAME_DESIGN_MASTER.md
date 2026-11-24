# 🔥 LÒ THIÊNG: TIẾNG GỌI TỔ NGHỀ — MASTER GAME DESIGN BIBLE
> **Tài liệu Tham chiếu Thiết kế Duy nhất (Single Source of Truth)**
> **Engine:** Godot 4.x (GDScript) | **Artstyle:** 32-bit Hoả Tâm Pixel Art | **Universe:** Animal Folk
> **Thể loại:** Shop Management + Crafting + Turn-based RPG
> **Phiên bản:** v2.5 Master Merged (Hợp nhất toàn bộ GDD v1.0, v1.1, v1.2, Combat Bible v2.0 và Scene Map System)

---

## MỤC LỤC

1. [TỔNG QUAN DỰ ÁN & VÒNG LẶP CỐT LÕI (CORE LOOP)](#1-tổng-quan-dự-án--vòng-lặp-cốt-lõi-core-loop)
2. [QUY TẮC THẾ GIỚI & NHÂN VẬT (ANIMAL FOLK UNIVERSE)](#2-quy-tắc-thế-giới--nhân-vật-animal-folk-universe)
3. [HỆ THỐNG LÒ RÈN 3 PHA (FORGE SYSTEM — USP CỐT LÕI)](#3-hệ-thống-lò-rèn-3-pha-forge-system--usp-cốt-lõi)
4. [HỆ THỐNG TIỆM & NỢ 4 CHECKPOINT (SHOP & DEBT SYSTEM)](#4-hệ-thống-tiệm--nợ-4-checkpoint-shop--debt-system)
5. [HỆ THỐNG KHÁM PHÁ & CHIẾN ĐẤU (EXPLORATION & COMBAT BIBLE)](#5-hệ-thống-khám-phá--chiến-đấu-exploration--combat-bible)
6. [HỆ THỐNG BẢN ĐỒ 6 VÙNG & SCENE MAP SYSTEM](#6-hệ-thống-bản-đồ-6-vùng--scene-map-system)
7. [CÔNG TRÌNH ĐẶC BIỆT & DỊCH VỤ NGOÀI](#7-công-trình-đặc-biệt--dịch-vụ-ngoài)
8. [CỐT TRUYỆN, NHIỆM VỤ & CÁC KẾT THÚC (ENDINGS)](#8-cốt-truyện-nhiệm-vụ--các-kết-thúc-endings)

---

# 1. TỔNG QUAN DỰ ÁN & VÒNG LẶP CỐT LÕI (CORE LOOP)

## 1.1. Triết lý Thiết kế
- **Cốt lõi độc đáo (USP):** Rèn vũ khí thủ công 3 pha có chiều sâu xúc giác (Tactile Mini-games), không phải bấm nút thanh loading thụ động.
- **Vòng lặp Trinity Hook:** 
  $$\text{Khám Phá (Explore)} \longrightarrow \text{Chế Tác (Forge)} \longrightarrow \text{Bán Hàng & Trả Nợ (Sell \& Debt)}$$
- **Áp lực sinh tồn:** Nợ nần dồn dập với các mốc siết nợ cụ thể buộc người chơi phải cân đối giữa kiếm tiền trả nợ và nâng cấp trang bị.

## 1.2. Vòng Lặp 4 Buổi Trong Ngày
Mỗi ngày trong thế giới Lò Thiêng được chia làm 4 buổi rõ ràng:
1. **SÁNG (MORNING) — Khám Phá & Thu Thập:**
   - Người chơi rời Xưởng bước vào 1 trong 6 vùng đất (tiêu hao Thể lực Du hành / Travel Stamina).
   - Khai thác quặng, hái thảo mộc linh lực, đối mặt quái vật tuần tra, giải đố tàn tích.
2. **TRƯA (NOON) — Lò Rèn Nổi Lửa:**
   - Trở về Xưởng Hub (`WorkshopHub`). Sử dụng nguyên liệu thu thập được để rèn vũ khí mới.
   - Trải qua 3 pha rèn: Nung Phôi $\to$ Rèn Búa $\to$ Tôi Luyện Khắc Cổ Ngữ.
3. **CHIỀU (AFTERNOON) — Mở Tiệm Bán Hàng:**
   - Trưng bày tối đa 3 vũ khí lên kệ tiệm (`ShopScene`).
   - Đón khách hàng theo lượt, đọc tâm lý khách, thương lượng giá cả (Negotiation Mini-game) hoặc nhận Đơn đặt hàng lớn (Commissions).
4. **ĐÊM (NIGHT) — Kế Hoạch & Chiêm Nghiệm:**
   - Kiểm tra sổ sách, tích lũy vàng chuẩn bị trả nợ Checkpoint.
   - Nghiên cứu công thức đúc rèn mới, nâng cấp bễ rèn/đe rèn, chuẩn bị cho ngày tiếp theo.
   - Đi ngủ để lưu tiến trình và chuyển sang ngày mới.

---

# 2. QUY TẮC THẾ GIỚI & NHÂN VẬT (ANIMAL FOLK UNIVERSE)

## 2.1. Quy Tắc Thế Giới
- **100% Động vật Nhân hóa (Animal Folk):** Thế giới không có loài người thuần túy. Toàn bộ cư dân mang hình thái động vật đứng thẳng (Anthropomorphic), mặc trang phục truyền thống Á Đông kết hợp phong cách thợ rèn cổ trang.
- **Tỷ lệ nhân vật:** Chuẩn RPG 3/4 chiều cao ~160–170px trên màn hình (scale ~2.75×–3.0× từ sprite frame 64×64).

## 2.2. Nhân Vật Chính (Protagonist)
- **Nấm (The Smith):**
  - **Loài:** Mèo thợ rèn lông vàng cam, tai vểnh lanh lợi, mắt ngọc bích.
  - **Trang phục:** Khăn quàng đỏ rực, áo xanh chàm, tạp dề da nâu thô ráp rủ ngang hông, quần cộc xanh chàm, chân đệm thịt digitigrade tự nhiên.
  - **Tính cách:** Kiên cường, kiệm lời nhưng tỉ mỉ, gánh vác món nợ khổng lồ do biến cố gia đình để lại.

## 2.3. Dàn Phản Diện (Antagonists & Debt Agents)
- **Bà Trùm Hắc Nguyệt (Bà Trùm Trịnh — Final Boss):** Báo hoa mai đen quý tộc. Chủ nợ lớn nhất của vùng đất, thao túng kinh tế ngầm, lạnh lùng, tàn nhẫn.
- **Lão Kê Tổ (Lão Kim Tổ Nghề):** Gà chọi cổ đại lông bờm đỏ hung, cưỡi Chim Phượng Già. Từng là đồng môn của sư phụ Nấm, nay sa ngã đi theo thế lực hắc ám.
- **Đao Phủ Mù (Lửng Mật Siết Nợ):** Lửng mật to lớn, bịt mắt vải đen, mang song đao nặng. Kẻ trực tiếp đến tiệm đe dọa khi người chơi trễ hạn nợ.

## 2.4. Khách Hàng Thân Thiết & VIP NPCs 6 Vùng
| Vùng | NPC Tiêu Biểu | Loài Đại Diện | Đặc Điểm & Nhu Cầu Mua Sắm |
|---|---|---|---|
| **V1. Đồng Mây Trắng** | **Cô Sếu Lộng Gió** | Sếu Trắng mảnh mai | Di chuyển lanh lợi, thích đoản kiếm nhẹ, kiếm phong linh hoạt, trả tiền sòng phẳng |
| **V2. Rừng Trăm Hồn** | **Tướng Nai Bóng Rừng** | Hươu Đực sừng lớn | Trầm tĩnh, mang kiếm bản rộng, ưu tiên vũ khí có thuộc tính Phòng Thủ & Độc Tố |
| **V3. Núi Than Đỏ** | **Gã Lợn Rừng Khét Lửa** | Lợn Rừng hộ pháp | Cộc cằn, cơ bắp, chuộng đại chùy, đại kiếm nặng, lực đập bộc phá cực mạnh |
| **V4. Cát Thần Vàng** | **Ông Tê Tê Cát Thần** | Tê Tê giáp vảy | Cẩn trọng, thích thương kích dài xuyên giáp, chuộng vũ khí chống bào mòn cát bụi |
| **V5. Thành Ngọc Bích** | **Bà Công Thiên Kim** | Khổng Tước kiêu sa | Quý tộc giàu có, mua vũ khí quý hiếm đính ngọc tinh xảo, trả giá cực cao nếu đúng gu |
| **V6. Làng Tổ Nghề** | **Ông Trâu Thôi Cổ** | Trâu Thần cổ phong | Trưởng lão thợ rèn huyền thoại, nắm giữ bí mật cuối cùng về Ngọn Lửa Tổ |
| **Bạn Đồng Hành** | **Triệu Hoài** | Vượn Đen nhanh nhẹn | Bạn tri kỷ của Nấm, hỗ trợ thám thính và báo tin thị trường |

---

# 3. HỆ THỐNG LÒ RÈN 3 PHA (FORGE SYSTEM — USP CỐT LÕI)

Quá trình rèn một vũ khí diễn ra tuần tự qua 3 mini-game đòi hỏi sự khéo léo của người chơi:

```
[Nguyên Liệu + Phôi] 
         │
         ▼
[Phase 1: Nung Thép] ──(Tích lũy nhiệt Đỏ Rực)──► Thưởng +15% Vùng PERFECT
         │
         ▼
[Phase 2: Rèn Búa]   ──(5 nhịp đập liên hoàn)───► Xác định Phẩm Cấp (Tier C/B/A/S)
         │
         ▼
[Phase 3: Tôi Luyện] ──(Nhúng nước + Cổ ngữ)───► Thưởng +10% Giá & +10 Độ Bền
         │
         ▼
[Vũ Khí Hoàn Thiện] (Lên kệ bán hoặc trang bị đi săn)
```

## 3.1. Phase 1: Nung Phôi (Heating)
- **Mục tiêu:** Bơm bễ giữ nhiệt độ thanh phôi thép nằm trọn trong **Vùng Lý Tưởng (Đỏ Rực)** trong khoảng thời gian nấu ~3.5 giây (`cook_progress` đạt 1.0).
- **Cơ chế:**
  - Giữ phím Space/Click chuột để bơm bễ làm tăng nhiệt độ.
  - Quán tính nhiệt rơi tự nhiên (`HEAT_DECAY_RATE = 16.0/s`).
  - **Cảnh báo quá nhiệt (Overheat):** Nếu thanh nhiệt vượt quá 90% quá 1.2 giây, phôi thép sẽ bị cháy xém, giảm phẩm cấp.
  - **Phần thưởng Nung Xuất Sắc:** Duy trì nhiệt trong vùng vàng trên 70% thời gian nấu sẽ kích hoạt `get_perfect_bonus_for_phase2()`, mở rộng thêm **+15% độ rộng vùng PERFECT** cho Phase 2.

## 3.2. Phase 2: Rèn Búa Theo Nhịp (Hammering Rhythm)
- **Mục tiêu:** Canh nhịp con lắc dao động đập búa 5 nhát chuẩn xác vào tâm phôi.
- **Cơ chế:**
  - Con lắc chạy qua lại liên tục 0.0 $\leftrightarrow$ 1.0 với nhịp thở `BREATH_DURATION = 0.22s` mỗi khi đổi chiều.
  - Người chơi nhấn phím đập búa khi con lắc đi qua vùng Mục Tiêu:
    - **PERFECT (★):** Trúng tâm vàng $\to$ +100 điểm, tích lũy `combo_count`. Nếu đạt 3 nhát PERFECT liên tiếp sẽ kích hoạt **Combo Búa Vàng**.
    - **GOOD (◆):** Trúng rìa xanh $\to$ +60 điểm.
    - **MISS (✕):** Trượt $\to$ 0 điểm, ngắt chuỗi combo.
  - Tốc độ con lắc tăng nhẹ sau mỗi nhát đập (`-7%` thời gian mỗi nhát).
  - **Trần Phẩm Cấp (Material Prefix Cap):** Điểm số quyết định tiền tố của vũ khí nhưng bị giới hạn bởi chất lượng phôi thép ban đầu:
    - Phôi Sắt Thô $\to$ Tối đa Bậc C (Chắc Chắn / Sắc Bén).
    - Phôi Thép Than $\to$ Tối đa Bậc B (Cường Lực / Tinh Luyện).
    - Phôi Hắc Kim $\to$ Mở khóa Bậc A & S (Huyền Thoại / Tổ Truyền).

## 3.3. Phase 3: Tôi Luyện & Khắc Cổ Ngữ (Quenching & Runes)
- **Mục tiêu:** Nhúng thanh vũ khí đang nóng đỏ vào bể nước khoáng linh lực đúng thời điểm giao thoa tinh chất.
- **Cơ chế:**
  - Vòng sóng linh lực co lại về tâm. Người chơi bấm tương tác (`try_quench_press()`) trong khoảng hội tụ vàng `0.70 ± 0.08`.
  - **Perfect Quench:** Vũ khí phát sáng hào quang nguyên tố, nhận danh hiệu Hoàn Mỹ, tăng **+10% giá trị bán thực tế** (`price_mult = 1.10`) và **+10 Độ Bền tối đa**.
  - Không có hình phạt gãy vỡ vũ khí nếu trượt (chỉ không nhận được chỉ số thưởng).

---

# 4. HỆ THỐNG TIỆM & NỢ 4 CHECKPOINT (SHOP & DEBT SYSTEM)

## 4.1. Hệ Thống Nợ 4 Checkpoint (Tổng Nợ 100,000G — 52 Ngày)
Toàn bộ cốt truyện xoay quanh việc thanh toán 4 đợt siết nợ ngặt nghèo của Băng Hắc Nguyệt:

```
C1: 3,000G   ──► Hạn: Ngày 4  (Mặt bằng Lò Rèn)
C2: 8,000G   ──► Hạn: Ngày 12 (Phí bảo kê đường vào Rừng)
C3: 24,000G  ──► Hạn: Ngày 28 (Thuế khoáng sản sa mạc)
C4: 65,000G  ──► Hạn: Ngày 52 (Khoản nợ gốc gia tộc — Quyết đấu)
```

| Checkpoint | Số Tiền | Kích Hoạt | Hạn Chót | Thời Gian | Tên Khoản Nợ & Đại Diện Thu Nợ |
|---|---|---|---|---|---|
| **C1** | **3,000G** | Ngày 1 | **Ngày 4** | 4 ngày | Tiền mặt bằng Lò — Người Thu Nợ Chợ Ngoài |
| **C2** | **8,000G** | Ngày 5 | **Ngày 12** | 8 ngày | Tiền dẫn đường rừng — Tay Sai Rừng |
| **C3** | **24,000G** | Ngày 13 | **Ngày 28** | 16 ngày | Thuế lớn giữa mùa — Thương Nhân Sa Mạc |
| **C4** | **65,000G** | Ngày 29 | **Ngày 52** | 24 ngày | Nợ gốc gia tộc — Bà Trùm Hắc Nguyệt |

### Quy Tắc Phạt Trễ Hạn (Penalty Rules):
- **Trễ 1–2 ngày:** Phạt cộng dồn +10% số nợ (C1 $\to$ 3,300G, C2 $\to$ 8,800G, C3 $\to$ 26,400G).
- **Trễ 3+ ngày:** Phạt +20% + Đao Phủ Mù xuất hiện chặn cửa tiệm (mỗi ngày cản bớt 1 khách VIP).
- **Trượt 2 Checkpoint liên tiếp:** Kích hoạt ngay lập tức **Ending C (Phá sản / Game Over)**.
- **Thưởng trả đúng hạn:** Mở khóa 1 manh mối Cổ Khí Tổ Nghề và tăng danh tiếng tiệm (+5 Reputation).

## 4.2. Cơ Chế Quản Lý Tiệm (Shop Gameplay)
- **Kệ Trưng Bày:** Tối đa 3 vũ khí trên kệ cùng lúc (`InventorySystem.move_to_shelf()`).
- **Khách Hàng (Customer AI):**
  - Mỗi khách hàng có: **Ngân sách (Budget)**, **Độ kiên nhẫn (Patience)**, và **Gu vũ khí ưa thích** (ví dụ: Nông dân thích dao rựa rẻ, Hiệp khách thích trường kiếm sắc, Võ tăng thích côn/đại đao nặng).
- **Đàm Phán Giá (Negotiation Mini-game):**
  - Người chơi ra giá bán dựa trên giá trị gốc của vũ khí.
  - Khách sẽ phản hồi: Đồng ý ngay (nếu giá mềm), Mặc cả trả giá (nếu giá hơi cao), hoặc Giận dữ bỏ đi (nếu hét giá quá ngân sách, làm tụt độ kiên nhẫn).
- **Đơn Hàng Đặt Trước (Commissions):**
  - NPC giao nhiệm vụ rèn vũ khí với yêu cầu cụ thể (ví dụ: Kiếm Sắt có tiền tố Cường Lực, độ bền trên 80).
  - Hoàn thành giao đúng hạn nhận tiền thưởng gấp 1.5× và điểm Thân Thiết (Affinity).

---

# 5. HỆ THỐNG KHÁM PHÁ & CHIẾN ĐẤU (EXPLORATION & COMBAT BIBLE)

## 5.1. Thể Lực Khám Phá (Exploration Stamina System)
- Người chơi có **10 điểm Thể lực Du hành (Travel Stamina)** mỗi buổi sáng.
- **Hao tổn thể lực:**
  - Di chuyển giữa các Scene trong vùng: -1 Stamina.
  - Đào khoáng sản / Thu hoạch linh thảo đặc biệt: -1 Stamina.
  - Bỏ chạy khỏi trận chiến: -1 Stamina (nếu hết thể lực, không được phép bỏ chạy).
- **Hết thể lực:** Tầm nhìn thu hẹp, không thể vào sâu hơn các Scene kế tiếp, bắt buộc phải chọn đường quay về Xưởng.

## 5.2. Hệ Thống Gặp Quái (Encounter & Patrol AI)
- Quái vật di chuyển tuần tra trên Overworld (Patrol AI).
- Khi chạm trán quái, người chơi có 3 lựa chọn hành động:
  1. **Chiến Đấu (Fight):** Vào màn hình Combat theo lượt.
  2. **Bỏ Chạy (Flee):** Tốn 1 Stamina, quay lùi về Scene trước an toàn.
  3. **Thương Lượng / Hối Lộ (Negotiate):** Cho quái ăn thức ăn hoặc ném nguyên liệu phế phẩm để quái bỏ đi mà không tốn máu.

## 5.3. Chiến Đấu Theo Lượt (Turn-based Combat)
- **Góc nhìn:** Khung cảnh 2D màn hình ngang cổ điển (Side-view RPG). Nấm bên trái, quái vật bên phải.
- **Tốc độ:** Nhịp độ nhanh gọn, chỉ kéo dài **3–5 lượt/trận**.
- **Kỹ Năng Từ Vũ Khí Tự Rèn:** Nấm không có cấp độ nhân vật (No Level Grinding). Toàn bộ sức mạnh, lượng máu giáp và bộ kỹ năng (Skill Pool) đều đến từ **vũ khí mà Nấm đang cầm trên tay**:
  - Đoản kiếm $\to$ Kỹ năng Chém Nhanh (Slash), Phản Xạ.
  - Trọng kiếm $\to$ Kỹ năng Bổ Búa (Heavy Smash), Thiết Bích (Iron Wall).
  - Thương kích $\to$ Kỹ năng Đâm Xuyên (Pierce), Quét Đám Đông.
  - Vũ khí có cổ ngữ Lửa/Băng/Sét $\to$ Kỹ năng Thiêu Đốt, Đóng Băng, Giật Sét lan.

## 5.4. Phân Cấp Quái Vật (Monster Tiers) & Danh Mục 6 Vùng
- **Tier 1 (Quái Thường):** Máu 30–60, sát thương 5–10, xuất hiện theo bầy 1–2 con.
- **Tier 2 (Tinh Anh):** Máu 80–150, có giáp hoặc kỹ năng khống chế (làm chậm, độc).
- **Tier 3 (Quái Lớn / Mini-boss):** Máu 200–350, miễn nhiễm khống chế nhẹ, đòn đánh AOE.
- **Tier 4 (Chúa Tể Vùng / Area Boss):** Độc nhất tại Scene cuối của mỗi vùng, có 2 giai đoạn chiến đấu.

| Vùng Đất | Quái Vật Tiêu Biểu | Tier | Nguyên Liệu Rơi Ra (Loot) |
|---|---|---|---|
| **V1. Đồng Mây** | Sói Đồng Cỏ, Rắn Cát, Heo Rừng Nhỏ | T1 | Sắt Thô, Da Thú Nhẹ, Lông Sói |
| **V2. Rừng Trăm Hồn** | Hồn Rừng Lạc, Sói Già Độc, Thú Cảnh Lăng | T1–T2 | Gỗ Mun Linh Khí, Rễ Cây Ngàn Năm, Tinh Thể Xanh |
| **V3. Núi Than Đỏ** | Linh Hoả Thô, Bọ Cạp Vàng, Quỷ Rừng Lửa | T2–T3 | Than Đỏ, Quặng Đồng Cổ, Lõi Lửa Nóng |
| **V4. Cát Thần Vàng** | Linh Sai Ngọc Bích, Thỏ Thần Đỏ, Bọ Cát | T2–T3 | Cát Vàng Tinh Khiết, Mảnh Giáp Bọ Cát, Hoàng Ngọc |
| **V5. Thành Ngọc Bích** | Vệ Binh Biến Chất, Sát Thủ Bóng Đêm | T3 | Ngọc Bích Vụn, Thép Bách Luyện, Vải Lụa Đen |
| **V6. Làng Tổ Nghề** | Hồn Tổ Canh Cửa, Quái Rèn Cổ Đại | T3–T4 | Quặng Thiên Thạch, Lửa Cổ Vô Tận, Mảnh Cổ Khí |

---

# 6. HỆ THỐNG BẢN ĐỒ 6 VÙNG & SCENE MAP SYSTEM

## 6.1. Quy Chuẩn Màn Hình Scene (Visual Language)
Mỗi Scene khám phá được thiết kế theo tỷ lệ chuẩn `640×360` (phóng to `1920×1080`):
- **Zone Trái (Trang trí & Kể chuyện):** Nhà cửa, tàn tích, NPC đứng xa, cấm player đi vào.
- **Zone Giữa (Playable Area):** Con đường mòn trung tâm nơi Nấm di chuyển, tương tác vật thể và kích hoạt chạm trán quái.
- **Zone Phải (Cảnh nền trang trí):** Khung cảnh thiên nhiên vươn xa tạo chiều sâu thị giác.

```
┌─────────────────────────────────────────────────────────────┐
│  [ZONE TRÁI: CỐT TRUYỆN]               [ZONE PHẢI: PHONG CẢNH]│
│  Tàn tích, Đền thờ, NPC đứng quan sát   Núi xa, Mây trôi, Rừng sâu│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│          [ZONE GIỮA: VÙNG CHƠI CHÍNH (PLAYABLE)]            │
│          Đường mòn, Mỏ quặng [E], Bụi cỏ gặp quái           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 6.2. 6 Loại Scene Chuẩn Trong Mỗi Vùng
Mỗi vùng đất bao gồm một tuyến đường 6 Scene liên hoàn:
1. **Story Scene 1 — Dân Cư (S1):** Điểm đặt chân đầu tiên. Có lều trại thương nhân, NPC bản địa cung cấp thông tin vùng đất.
2. **Normal Combat Scene 1 (C1):** Bãi đất mở, gặp quái vật Tier 1 cản đường.
3. **Resource Point (R):** Bãi khai thác tài nguyên trù phú (quặng quý, thảo dược, rương kho báu ẩn).
4. **Story Scene 2 — Linh Thiêng (S2):** Tàn tích cổ, bệ đá khắc chữ hoặc đền thờ phong ấn. Có câu đố môi trường (Puzzle).
5. **Normal Combat Scene 2 (C2):** Vùng nguy hiểm sát hang ổ quái, gặp quái vật Tier 2 Tinh Anh.
6. **Boss Scene (B):** Sào huyệt trùm vùng đất, chặn giữ Mảnh Cổ Khí Tổ Nghề.

## 6.3. Cơ Chế Before / After Clear
- **Trước khi hạ Boss (Before Clear):** Cảnh quan u ám, quái vật tuần tra dày đặc, tài nguyên bị phong ấn.
- **Sau khi hạ Boss (After Clear):** Bầu trời quang đãng, hoa nở, quái vật dạt vào rừng sâu, mở đường tắt di chuyển nhanh và NPC bản địa quay lại lập trạm buôn bán trao đổi nguyên liệu hiếm.

---

# 7. CÔNG TRÌNH ĐẶC BIỆT & DỊCH VỤ NGOÀI

Nhằm tạo chiều sâu cho lối sống trong game, thế giới Lò Thiêng bố trí 4 địa điểm giải trí và thư giãn đặc biệt:

## 7.1. Quán Rượu (Taverns — 2 Địa điểm)
1. 🍺 **Quán "Ván Cờ Chưa Xong" (Vùng 2 — Rừng Trăm Hồn):**
   - Không gian sương khói mờ ảo trong thân cây đại thụ rỗng.
   - Nơi gặp gỡ lính đánh thuê, nghe ngóng tin đồn về vị trí xuất hiện của quái Tinh Anh và vị trí mỏ quặng hiếm.
2. 🍺 **Quán "Giữa Gió Và Cát" (Vùng 4 — Bãi Cát Thần Vàng):**
   - Trạm dừng chân của các đoàn lữ hành lạc đà.
   - Nơi mua bán các loại hương liệu nung thép độc lạ và thuê người dẫn đường giảm tiêu hao Stamina.

## 7.2. Khu Vui Chơi & Giải Trí (Mini-games — 2 Địa điểm)
1. 🎮 **Khu "Vòng Sắt" (Vùng 3 — Núi Than Đỏ):**
   - Sới đấu cược sức mạnh của thợ mỏ lợn rừng.
   - Nấm có thể tham gia trò ném vòng sắt hoặc thi lực búa đập đe để kiếm thêm tiền vàng trả nợ khẩn cấp.
2. 🎮 **Khu "Ngọc Vụn" (Vùng 5 — Thành Ngọc Bích):**
   - Phố cờ bạc cao cấp của giới quý tộc chim chóc.
   - Trò chơi gieo xúc xắc ngọc bích đỏ đen giúp người chơi lật ngược tình thế nợ nần hoặc mất trắng nếu tham lam.

---

# 8. CỐT TRUYỆN, NHIỆM VỤ & CÁC KẾT THÚC (ENDINGS)

## 8.1. Cốt Truyện Trọng Tâm
Nấm là người thừa kế duy nhất của Lò Rèn Hoả Tâm danh tiếng lẫy lừng một thời. Sau sự biến mất bí ẩn của người cha và sự sụp đổ của phường thợ, tiệm rèn ngập trong khoản nợ khổng lồ 100,000G do Băng Hắc Nguyệt thao túng. Để giữ lại lò rèn tổ truyền, Nấm phải vừa rèn vũ khí kiếm tiền trả nợ theo từng hạn chót, vừa dấn thân vào 6 vùng đất hiểm trở để tìm kiếm **6 Mảnh Vỡ Của Thanh Cổ Khí Tổ Nghề** — bảo vật phong ấn bí mật diệt vong của các bậc thầy rèn xưa.

## 8.2. Hệ Thống 3 Kết Thúc (The Three Endings)

```
                       [Cột Mốc Ngày 52 - Hạn Cuối C4]
                                      │
           ┌──────────────────────────┴──────────────────────────┐
           │ Trả đủ 100,000G Nợ?                                 │
          YES                                                    NO
           │                                                     │
 ┌─────────┴─────────┐                                      [ENDING C]
 │ Thu đủ 6 Mảnh     │                                      Phá Sản / Lưu Lạc
 │ Cổ Khí Tổ Nghề?   │                                      (Trượt 2 Checkpoint)
YES                  NO
 │                   │
[ENDING A]       [ENDING B]
Hồi Sinh Lò      Trọc Phú Buôn Bán
Thiêng Tổ Nghề   (Mất Lửa Tổ Nghề)
```

1. 🌟 **ENDING A (Chân Tướng & Vinh Quang — True Ending):**
   - **Điều kiện:** Thanh toán đầy đủ 4 Checkpoint nợ đúng hạn + Tìm đủ 6 Mảnh Vỡ Cổ Khí.
   - **Kết quả:** Nấm nung chảy và phục nguyên Thanh Cổ Khí Tổ Nghề ngay trước mặt Bà Trùm Hắc Nguyệt. Sức mạnh ngọn lửa thiêng đánh thức lòng tự tôn của giới thợ rèn khắp 6 vùng đất, xóa sạch ách đô hộ của Hắc Nguyệt. Lò Thiêng trở thành Thánh đường Rèn tối thượng của cả đại lục.

2. 💰 **ENDING B (Trọc Phú Thương Nhân — Neutral Ending):**
   - **Điều kiện:** Thanh toán đủ 100,000G nợ nhưng KHÔNG thu thập đủ 6 Mảnh Cổ Khí (chỉ tập trung buôn bán rèn đồ thường).
   - **Kết quả:** Nấm trả hết nợ sạch sẽ, tiệm rèn trở thành chuỗi cửa hàng buôn bán vũ khí đại trà giàu có bậc nhất Thành Ngọc Bích. Tuy nhiên, ngọn lửa thiêng tổ truyền vĩnh viễn lụi tàn, Nấm trở thành một thương nhân thực dụng, đánh mất linh hồn của người thợ rèn chân chính.

3. 💀 **ENDING C (Xiết Nợ & Tha Phương — Bad Ending):**
   - **Điều kiện:** Trượt 2 Checkpoint nợ liên tiếp hoặc không trả nổi 65,000G tại Ngày 52.
   - **Kết quả:** Đao Phủ Mù và quân Hắc Nguyệt phong tỏa Xưởng Hub. Đe rèn ngàn năm bị đập nát, Nấm bị tước quyền thợ rèn và bị đày vào hầm mỏ Núi Than làm nô dịch rèn thuê suốt đời. Tiếng gọi tổ nghề vĩnh viễn chìm vào quên lãng.

---
*(Xem chi tiết lời thoại từng phân cảnh tại [STORY_AND_DIALOGUE.md](file:///c:/Users/builo/.gemini/antigravity/scratch/lo-thieng/docs/STORY_AND_DIALOGUE.md))*
