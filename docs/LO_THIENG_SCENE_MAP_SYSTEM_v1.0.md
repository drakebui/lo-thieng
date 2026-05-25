# LÒ THIÊNG — SCENE MAP SYSTEM
## Hệ thống cảnh chiến đấu 6 vùng: Story, Assets, NPC Unlock
**Version 1.0 | Game Design + Art Brief tích hợp**

---

# PHẦN 0 — HIỂU HỆ THỐNG TRƯỚC KHI ĐỌC

## Cấu trúc một màn hình chơi

```
┌──────────────────────────────────────────────────────────────┐
│  [ZONE TRÁI — TRANG TRÍ & KỂ CHUYỆN]  [ZONE PHẢI — TRANG TRÍ]  │
│  Nhà cửa, NPC, công trình, lore objects    ←  Player không vào  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│          [ZONE GIỮA — PLAYABLE AREA]                        │
│          Cỏ / đất / đường mòn → Player đi và chiến đấu      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Player chỉ đi được zone giữa.** Zone 2 bên = canvas kể chuyện, thay đổi theo:
- Vùng nào đang ở
- Scene nào trong vùng đó
- Trạng thái BEFORE / AFTER CLEAR

---

## 6 Loại Scene — Ngôn Ngữ Hình Ảnh (Visual Language Rules)

Player nhận ra ngay mục đích của scene chỉ qua art, không cần text:

| Loại Scene | Số lượng/vùng | Dấu hiệu nhận biết qua art | Mục đích |
|---|---|---|---|
| **LOOP A — Hoang dã** | 1 | Chỉ cây cỏ, không dấu người, thú hoang đi lại | Combat + gathering thuần |
| **LOOP B — Biên giới** | 1 | Hàng rào cũ, biển cảnh báo gãy nát, cổng bỏ hoang | Transition + combat nhẹ |
| **LOOP C — Sâu thẳm** | 1 | Địa hình khắc nghiệt nhất vùng, quái mạnh hơn | Combat + rare loot |
| **STORY 1 — Dân cư** | 1 | Nhà cửa, khói bếp, bóng người sau cửa sổ | Đọc story, ít combat |
| **STORY 2 — Linh thiêng** | 1 | Miếu/đền/công trình tâm linh, không có người | Quest hint, Di Vật |
| **LANDMARK** | 1 | Công trình độc đáo chiếm toàn bộ background | Boss / event / milestone |

**Tổng: 6 scene × 6 vùng = 36 scenes**

---

## BEFORE / AFTER CLEAR — Visual State Changes

Mỗi scene thay đổi hoàn toàn sau khi player clear vùng:

### Story Scene 1 — Dân cư
| Element | BEFORE Clear | AFTER Clear |
|---|---|---|
| Cửa nhà | Đóng chặt, thanh chắn gỗ | Mở, có người đứng ngưỡng cửa |
| Cửa sổ | Tối, vải che | Sáng, có bóng người |
| Sân | Trống hoặc đồ bỏ lại vội | Quần áo phơi, đồ vật dùng thường ngày |
| Người | Không thấy (trốn trong nhà) | Ra ngoài, ngồi, nói chuyện |
| Khói bếp | Không có | Có — dấu hiệu sống bình thường |
| Âm thanh (art cue) | Cửa đóng → silence | Giỏ hàng, con trẻ, chó — đời thường |

### Story Scene 2 — Linh thiêng
| Element | BEFORE Clear | AFTER Clear |
|---|---|---|
| Miếu/đền | Cổng khóa, cỏ mọc đầy sân | Cổng mở, sân quét sạch |
| Đèn | Tắt | Thắp đèn dầu / hương |
| Vật phẩm cúng | Không có hoặc đã thối | Hoa tươi, trái cây mới |
| Người | Không có | Người dân đến cúng bái |

### Loop Scenes
| Element | BEFORE Clear | AFTER Clear |
|---|---|---|
| Quái vật spawn | Dày đặc, aggressive | Thưa hơn, passive (respawn chậm) |
| Gathering node | Có nhưng nguy hiểm | Dễ lấy hơn (quái đã giảm) |
| Background detail | Dấu vết phá hoại của quái | Dấu vết phục hồi nhỏ (cây mới mọc, v.v.) |

---

## NPC UNLOCK SYSTEM — Cơ Chế Mở Khóa Khách Hàng

```
Player vào vùng → gặp quái → clear boss / điều kiện → [FLAG: REGION_CLEARED]
		   ↓
Người dân trong Story Scene mở cửa đi ra
		   ↓
Loại người dân + kiếm sĩ của vùng đó join pool khách hàng shop
		   ↓
Họ mua vũ khí phù hợp với nhu cầu của vùng họ ở
```

**Rule thiết kế:**
- Người dân thường → mua vũ khí bình dân, giá thấp, mua nhiều
- Kiếm sĩ / chiến binh vùng → mua vũ khí đặc thù, giá cao, mua ít hơn
- Mỗi vùng unlock ~5-8 loại khách mới

---

# PHẦN I — VÙNG 1: ĐỒNG MÂY TRẮNG

## Tổng quan

| | |
|---|---|
| Theme | Thảo nguyên gió, tự do, trách nhiệm |
| Câu hỏi narrative | Tự do có cần trách nhiệm không? |
| Tình trạng trước Clear | Người dân không thể ra đồng — Phong Quái (quái gió) tấn công bất cứ ai ra ngoài |
| Lý do quái xuất hiện | Khi Lò tắt, các ngọn gió linh trong vùng mất neo — hóa thành quái lang thang |
| Tình trạng sau Clear | Người dân ra đồng, chăn thả, buôn bán, trẻ em chạy nhảy ngoài trời |
| Palette | Xanh nhạt + vàng nhạt + trắng sữa |
| NPC VIP | Cô Lộng Gió |

## Câu Chuyện Tổng Quát

Làng Đồng Mây từng sống bằng chăn thả và buôn gió — nghĩa là bán sức gió để kéo cối xay, để căng buồm thuyền nội địa. Người dân vùng này thích tự do, ghét rào cản, cửa nhà thường mở.

Nhưng từ khi Lò tắt, các luồng gió linh trong đồng biến thành Phong Quái — vô hình, tấn công bất ngờ, bắt người bay lên rồi thả xuống. Người dân không dám ra đồng. Cửa đóng lại. Hàng rào dựng lên. Tự do biến thành cái bẫy ngược.

Cô Lộng Gió — người duy nhất đủ nhanh để tránh Phong Quái — vẫn roam ngoài đồng một mình, nhưng cô cô đơn. Và cô hiểu hơn ai hết: tự do không có ích gì khi chỉ một mình hưởng.

## 6 Scene Breakdown

---

### SCENE V1-L1 — "ĐỒNG CỎ RỖNG" *(Loop A — Hoang dã)*

**Truyện ngắn:**
Đây là trung tâm Đồng Mây — cánh đồng cỏ lau rộng, không một bóng người. Gió thổi mạnh, cỏ ngả theo làn sóng. Đây đó có dấu vết của đời sống cũ bị bỏ lại: một cái cày bị gió cuốn vào bụi cỏ, một cái mũ cói nằm giữa đường. Phong Quái xuất hiện như một cơn lốc nhỏ di chuyển trên mặt cỏ — mắt không thấy thân hình, chỉ thấy cỏ vẽ hình xoáy tròn xung quanh.

**🎨 Background Assets:**
- Cỏ lau cao ngang người, lay sóng mạnh về một hướng
- Cái cày cũ nằm nghiêng trong cỏ (không ai thu)
- Mũ cói rơi giữa đường mòn
- Bầu trời: mây trắng di chuyển nhanh
- Xa phía horizon: dãy đồi thấp xanh tím

**Quái vật:**
- Phong Quái T1: cơn lốc nhỏ, mắt vàng, cỏ xoáy xung quanh

**Loop seamless cues:** Cỏ lau không có landmark — chỉ cỏ và gió, dễ loop.

---

### SCENE V1-L2 — "RÌA ĐỒNG" *(Loop B — Biên giới)*

**Truyện ngắn:**
Ranh giới giữa đồng mở và khu dân cư cũ. Hàng rào gỗ đổ nát chạy ngang — người dân dựng vội rồi bỏ chạy vào nhà. Vài cột đèn gió cũ (loại đèn của vùng này, thả theo gió) đứng xiêu vẹo. Một tấm biển "CẤM RA NGOÀI" bằng gỗ cắm ở đây, chữ khắc vội vàng. Phong Quái mạnh hơn ở đây — chúng bảo vệ rìa đồng như bảo vệ lãnh thổ.

**🎨 Background Assets:**
- Hàng rào gỗ đổ nát, một số thanh bay mất
- Cột đèn gió cũ: tre thân mỏng, đèn giấy rách
- Biển gỗ "CẤM RA NGOÀI": chữ khắc thô, mực đỏ phai
- Cỏ ngắn hơn ở đây — dấu vết người đã dẫm qua nhiều
- Xa background: mái nhà làng nhìn mờ sau cỏ lau

---

### SCENE V1-L3 — "GIỮA GIÓ XOÁY" *(Loop C — Sâu thẳm)*

**Truyện ngắn:**
Phía đông đồng mây, nơi gió mạnh nhất và quái nhiều nhất. Những tảng đá vân trắng bị bào mòn thành hình dạng kỳ lạ bởi gió liên tục hàng trăm năm. Cây không mọc được — chỉ có cỏ thấp và đá. Phong Quái ở đây là T2 Tinh Nhuệ — to hơn, lốc xoáy của chúng tạo ra hiện tượng gọi là "mắt gió" (vùng tĩnh lặng bên trong, người rơi vào bị trói đứng yên).

**🎨 Background Assets:**
- Đá vân trắng bào mòn thành hình tròn/oval kỳ lạ, nhẵn bóng
- Cỏ thấp, ép sát đất vì gió
- Không có cây
- Bầu trời: mây xoáy, khác với mây bình thường
- Lốc gió nhỏ di chuyển trên nền từ xa

---

### SCENE V1-S1 — "LÀNG GIÓ" *(Story 1 — Dân cư)*

**Truyện ngắn:**
Ngôi làng nhỏ của Đồng Mây — nhà gỗ và tre, mái lợp lá, xây rải rác không theo quy hoạch vì người vùng này không thích ngay thẳng. Cổng làng có hình đầu chim lớn làm bằng tre đan. Mỗi nhà có cột gió (cột tre treo đèn giấy và phong linh bằng đồng) — khi gió thổi, cả làng ngân tiếng nhạc nhẹ.

**BEFORE Clear:** Tất cả cửa đóng. Phong linh bị gỡ xuống (vì gió độc). Đèn giấy xé rách. Cổng làng có thanh chắn. Một vài đứa trẻ nhìn ra qua kẽ cửa sổ hé nhỏ.

**AFTER Clear:** Cổng mở, phong linh treo lại ngân tiếng. Người dân ngồi trước nhà, trẻ em chạy nhảy. Bà già phơi vải trên dây. Người đàn ông sửa hàng rào. Khói bếp bay lên.

**🎨 Background Assets:**
- Nhà gỗ/tre: mái thấp, vách không đều, màu ấm
- CỔNG LÀNG: cổng tre có hình đầu chim lớn — đặc trưng của vùng này
- Cột gió: tre thân cao, treo phong linh đồng nhỏ + đèn giấy nhiều màu
- BEFORE: cửa đóng, phong linh gỡ, đèn rách, thanh chắn cổng
- AFTER: cửa mở, phong linh ngân (animation lay nhẹ), đèn thắp, người ra ngoài

**🔑 Key storytelling object:** Phong linh đồng — tắt khi quái còn đó, sáng + ngân khi vùng an toàn. Đây là "visual health indicator" của vùng.

---

### SCENE V1-S2 — "MIẾU GIÓ" *(Story 2 — Linh thiêng)*

**Truyện ngắn:**
Giữa đồng có một miếu nhỏ — không phải đền hoành tráng, chỉ là bệ đá cũ và mái tre thấp. Người Đồng Mây thờ Thần Gió ở đây từ ngàn đời. Không có tượng — chỉ có một cái bình đồng đặt trên bệ, lỗ bình hướng về phía gió. Bình này kêu tiếng khác nhau tùy theo hướng gió — người làng ngày xưa dùng nó để đoán thời tiết và dự báo tin tức từ xa.

Bình đồng im lặng từ khi Phong Quái xuất hiện — gió bị nhiễm độc nên tiếng bình không còn trong trẻo. Đây là Di Vật hint location.

**BEFORE Clear:** Cỏ mọc đầy sân, đèn tắt, không có hương khói. Bình đồng trên bệ tối và im lặng.

**AFTER Clear:** Sân được quét sạch, đèn thắp, bình đồng bắt đầu kêu trở lại. Người dân đến đặt hoa.

**🎨 Background Assets:**
- Miếu nhỏ: bệ đá thấp, mái tre thấp, không có tường
- BÌNH ĐỒNG: kích thước trung bình, màu đồng xỉn, lỗ miệng hướng gió — vật quan trọng nhất miếu
- Đèn dầu nhỏ trên bệ (tắt BEFORE, sáng AFTER)
- Cỏ dại (BEFORE) → quét sạch (AFTER)
- Di Vật hint: mảnh khắc trên bệ đá, đọc được khi đứng gần

---

### SCENE V1-LM — "CỐI XAY GIÓ TỔ" *(Landmark)*

**Truyện ngắn:**
Đây là công trình lớn nhất Đồng Mây — cối xay gió khổng lồ, to hơn ba ngôi nhà. Cánh quạt bằng gỗ tếch đen dài 8m mỗi cái, từng quay không ngừng cả ngày lẫn đêm cung cấp năng lượng gió cho cả vùng. Bây giờ cánh quạt đứng yên — Phong Quái lớn nhất (Boss T4) đang nghỉ trong cánh quạt như tổ chim khổng lồ.

**BEFORE Clear:** Cối xay đứng yên, cánh quạt có tổ Phong Quái, tiếng rú của gió linh phát ra từ bên trong. Quái T3/T4 bảo vệ xung quanh.

**AFTER Clear:** Cánh quạt quay trở lại — chậm rãi lúc đầu, rồi đều đặn. Tiếng quay là âm thanh đẹp nhất vùng. Ánh sáng của bầu trời thay đổi hẳn khi cánh quạt quay.

**🎨 Background Assets:**
- CỐI XAY GIÓ: cấu trúc gỗ 3 tầng, tròn, mái chóp nhọn; 4 cánh quạt dài
- CÁNH QUẠT TRƯỚC CLEAR: đứng yên, có "tổ" quái (khối tối, lông/tơ gió quấn quanh)
- CÁNH QUẠT SAU CLEAR: quay, animation loop; gió nhìn thấy được (các sợi sáng mờ theo chiều cánh quạt)
- Quái Boss: Phong Vương — lớn hơn Phong Quái thường, hình dạng như cơn lốc có mắt, khi tấn công tỏa cánh như đại bàng gió

## 🛒 NPC Unlock Sau Clear V1

| Loại | Tên/Description | Vũ khí mua | Lý do |
|---|---|---|---|
| Nông dân đồng cỏ | Người cầm liềm | Dao, liềm nhỏ | Làm ruộng + tự vệ |
| Người chăn thả | Áo rộng, cây gậy | Gậy, đoản thương | Đuổi thú hoang |
| Thợ xay gió | Tạp dề da, kính bảo hộ | Búa nhỏ, kìm | Sửa cối xay |
| Kiếm sĩ Đồng Mây | Áo nhẹ, không giáp nặng | Kiếm mỏng nhẹ, dao quăng | Chiến đấu theo gió, ưu tiên speed |
| Thương nhân gió | Áo sang, túi nhiều | Vũ khí phòng thân | Cần bảo vệ hàng hóa |

---

# PHẦN II — VÙNG 2: RỪNG TRĂM HỒN

## Tổng quan

| | |
|---|---|
| Theme | Rừng linh khí, ký ức chiến tranh, hồn không siêu thoát |
| Câu hỏi narrative | Vũ khí cứu người hay kéo dài bạo lực? |
| Tình trạng trước Clear | Rừng đầy Hồn Chiến Trận — linh hồn binh lính chết không siêu thoát, bảo vệ "lãnh địa" họ từng chiến đấu |
| Lý do quái xuất hiện | Từng là chiến trường. Khi Lò tắt, vũ khí chôn trong đất không có ai "giải phóng" → hồn theo vũ khí mà ở lại |
| Tình trạng sau Clear | Hồn được giải phóng, rừng bình thường trở lại, các binh trạm cũ có thể tiếp cận |
| Palette | Xanh tối + tím xanh + đen rêu |
| NPC VIP | Tướng Bóng Rừng |

## Câu Chuyện Tổng Quát

Rừng Trăm Hồn là nơi xảy ra "Trận Chiến Cây Rừng" — một trong những trận đánh lớn nhất trong lịch sử Xứ Lửa Thiêng, cách đây 50 năm. Hai bên chiến đấu đến người cuối cùng. Vũ khí chôn trong đất, máu ngấm vào rễ cây, và linh hồn người lính không chịu rời đi — vì họ tin chiến tranh chưa kết thúc.

Tướng Bóng Rừng là người duy nhất sống sót trận đó và ở lại giữ rừng. Ông không giải phóng các hồn — ông hiểu hơn ai hết rằng hồn cần được thừa nhận trước khi có thể ra đi.

Ẩn trong rừng là các binh trạm cũ của hai phía — bây giờ bỏ hoang, nhưng bên trong còn đầy tư liệu về trận chiến và về những vũ khí đã được rèn riêng cho trận đó.

**Khu đặc biệt:** QUÁN RƯỢU BINH TRẠM (xem cuối phần)

## 6 Scene Breakdown

---

### SCENE V2-L1 — "CÂY RÊU CỔ" *(Loop A)*

**Truyện ngắn:**
Phần nội tâm của rừng — tán cây dày, ánh sáng yếu và lạnh màu xanh. Rêu phủ đến tận thân cây, rễ trồi lên mặt đất tạo hình bàn tay. Không có đường — chỉ có những khoảng trống giữa cây mà người phải luồn qua. Hồn Chiến Trận T1 trôi giữa cây như sương mù có mắt.

**🎨 Background Assets:**
- Cây lớn thân vặn xoắn, rêu phủ cao
- Rễ nổi hình bàn tay — subtle, không lộ liễu
- Ánh sáng beam xanh lạnh lọc qua tán
- Sương mờ nhạt gần mặt đất
- Hồn T1: vật thể trong suốt xanh nhạt, hình dạng người mờ, mắt trắng

---

### SCENE V2-L2 — "ĐƯỜNG MÒN LÍNH" *(Loop B)*

**Truyện ngắn:**
Đường tuần tra cũ của binh lính — còn nhận ra vì cây 2 bên bị chặt đều nhau tạo thành hành lang thẳng, dù cây non đã mọc lại lấp đầy. Đây đó có cọc gỗ cắm xuống đất, trên có khắc ký hiệu quân sự đã mờ. Một số cọc đã đổ. Đây là nơi Hồn T2 Tinh Nhuệ tuần tra — chúng đi theo đường mòn như đang còn trong nhiệm vụ.

**🎨 Background Assets:**
- Hành lang cây: 2 bên cây đều nhau (bị chặt xưa), mặt cắt thân cây có rêu che
- Cọc gỗ quân sự: cắm thành hàng, khắc ký hiệu quân cổ, một số đổ
- Đường đất nén cứng, không có cỏ — dấu chân quân đội

---

### SCENE V2-L3 — "HỐ CHIẾN TRẬN" *(Loop C)*

**Truyện ngắn:**
Vùng đất tàn tích thật sự của trận đánh — hố chiến hào cũ đã sụt và rêu phủ, nhưng hình dạng vẫn còn. Đây đó nhô lên khỏi đất: mảnh giáp cũ, cán vũ khí gãy, không ai thu dọn. Hồn T3 Thủ Lĩnh ở đây — mạnh hơn, có Aura, nhớ rõ hơn về trận chiến.

**🎨 Background Assets:**
- Hào chiến cũ: sụt và rêu mọc, vẫn thấy hình chữ Z đặc trưng
- Mảnh giáp nhô lên từ đất: màu rỉ sét nâu đỏ, không thu dọn
- Cán vũ khí gãy cắm trong đất
- Hố nhỏ rải rác — vết bom/pháo từ trận chiến

---

### SCENE V2-S1 — "BINH TRẠM CŨ" *(Story 1 — Dân cư)*

**Truyện ngắn:**
Một binh trạm gỗ nhỏ từ thời chiến tranh — không phải làng, chỉ là trạm tạm thời. Nhưng người ta ở đó đủ lâu để biến nó thành nơi có chút hơi ấm: có bếp lửa cũ, có giá treo áo giáp (giờ trống), có bàn cờ cũ đặt trước cửa (người chơi bỏ lại giữa ván).

Trong binh trạm này có QUÁN RƯỢU BINH TRẠM — nơi lính hai phía đôi khi gặp nhau sau giờ chiến đấu (theo thỏa thuận ngầm). Câu chuyện lạ nhất rừng này.

**BEFORE Clear:** Cửa đóng, bụi phủ, Hồn bảo vệ xung quanh. Ván cờ bị lật, quân cờ vương vãi đất.

**AFTER Clear:** Cửa mở, bếp lửa được thắp lại. Ván cờ được nhặt lên, quân cờ xếp lại. Người dân từ làng lân cận cẩn thận bước vào — họ sử dụng binh trạm làm trạm dừng chân.

**🎨 Background Assets:**
- Binh trạm: nhà gỗ đơn giản kiểu quân sự, mái phẳng, cửa sổ hẹp
- BÀN CỜ trước cửa: bàn đá thấp, ván cờ khắc trên mặt đá (không xóa được), quân cờ bằng đá cuội
- Giá treo áo giáp: trống, thanh gỗ ngang, móc sắt
- Bếp lửa ngoài trời: đá xếp thành vòng, tro cũ

**🍺 QUÁN RƯỢU BINH TRẠM:**
- Đây là một PHẦN của binh trạm — không phải tòa nhà riêng, là một góc trong binh trạm
- Bên trong có kệ gỗ với bình rượu (loại bình đất nung quân sự), vài cái ghế thô
- Trên tường có tên lính hai phía khắc vào gỗ — không phải để kỷ niệm thắng lợi, để nhớ rằng có người đã uống rượu ở đây và không trở về
- **Gameplay function:** Player có thể mua rượu/đồ uống ở đây để restore stamina. Sau Clear, có NPC barkeeper (lính cũ sống sót).

---

### SCENE V2-S2 — "ĐÀI TƯỞNG NIỆM" *(Story 2 — Linh thiêng)*

**Truyện ngắn:**
Người ta không biết ai dựng cái đài này — có thể là sau trận chiến. Đài không hoành tráng: chỉ là một cột đá cao 3m giữa rừng, khắc đầy tên người. Tên của cả hai phía, xen kẽ không phân biệt. Không có tên người thắng hay người thua — chỉ là tên người.

Xung quanh đài, vũ khí cũ được cắm xuống đất thành vòng tròn — biểu tượng rằng những vũ khí này đã hoàn thành vai trò và không còn cần sử dụng nữa. Đây là nơi Di Vật #5 (Nhật Ký Dưới Rễ) cất giữ.

**BEFORE Clear:** Hồn mạnh bảo vệ đài, không tiếp cận được. Vũ khí quanh đài rung lên khi player đến gần (quái spawn).

**AFTER Clear:** Hồn tản ra, đài có thể tiếp cận. Ánh sáng xanh nhạt tỏa ra từ đài vào đêm.

**🎨 Background Assets:**
- ĐÀI ĐÁ: cột đá xám đặc, cao 3m, khắc kín tên người — tên cả hai phía xen kẽ
- Vòng vũ khí cắm xuống đất: kiếm, giáo, mã tấu cũ rỉ — cắm theo vòng tròn quanh đài
- Đất quanh đài không có cỏ — bị dẫm nhiều quá
- AFTER: ánh light ring xanh nhạt flat từ đài vào đêm

## 🛒 NPC Unlock Sau Clear V2

| Loại | Description | Vũ khí mua | Lý do |
|---|---|---|---|
| Thám tử rừng | Áo xanh rừng, tay không bụi | Dao găm, đoản cung | Trinh sát, cần nhẹ và im |
| Người trông rừng | Áo nâu đất, hiểu biết rừng | Gậy dài, rìu nhỏ | Làm việc trong rừng |
| Kiếm sĩ Rừng | Giáp nhẹ, mặt không che | Kiếm một tay, khiên nhỏ | Counter-ambush fighter |
| Lính cũ sống sót | Già, limps nhẹ, áo dân thường | Vũ khí đơn giản tin cậy | Cần bảo vệ bản thân về già |
| Barkeeper binh trạm | Tạp dề, mặt hiền | Dao bếp nhỏ (phòng thân) | Không muốn vũ khí mạnh |

---

# PHẦN III — VÙNG 3: NÚI THAN ĐỎ

## Tổng quan

| | |
|---|---|
| Theme | Núi lửa ngủ, sức mạnh thô, bản ngã |
| Câu hỏi narrative | Mạnh hơn có đồng nghĩa tốt hơn không? |
| Tình trạng trước Clear | Hỏa Quái (quái đá lửa) nổi lên từ kẽ nứt núi, đánh đuổi thợ mỏ ra khỏi hang |
| Lý do quái xuất hiện | Người đào quá sâu, đến tầng đá còn giữ ký ức lửa từ thời Lò cháy → quái sinh ra từ ký ức nhiệt |
| Tình trạng sau Clear | Thợ mỏ vào lại hang, khai thác trở lại, lò rèn nhỏ trong hang hoạt động |
| Palette | Đỏ nâu + cam than + vàng đồng |
| NPC VIP | Gã Khét Lửa |

## Câu Chuyện Tổng Quát

Núi Than Đỏ là nguồn tài nguyên khoáng sản chính của Xứ — người ta đào ở đây từ đời này sang đời khác. Thợ mỏ là dân cứng đầu, tự hào về sức khỏe và sức mạnh. Họ không hay kể về cảm xúc.

Rồi một nhóm thợ đào quá sâu — tìm đến tầng đá đỏ nhất, tầng mà người xưa nói là "nơi lửa tổ từng ngủ." Hỏa Quái nổi lên: hình dạng như con người bằng đá nóng đỏ, phun lửa, bước đi làm đất rung.

Gã Khét Lửa từng là thợ mỏ mạnh nhất — bây giờ tay bị thương, nhưng ông không nói ra. Ông ở lại núi không phải vì dũng cảm mà vì không biết mình là ai nếu không còn ở đây.

## 6 Scene Breakdown

---

### SCENE V3-L1 — "SỈ ĐÁ ĐỎ" *(Loop A)*

**Truyện ngắn:**
Sườn ngoài của núi — đá đỏ nâu lộ ra, không có cây chỉ có dây leo chịu nhiệt. Kẽ nứt trên đá bốc hơi nóng. Hỏa Quái T1 (nhỏ, dạng đá nóng di chuyển được) lang thang tìm mồi.

**🎨 Background Assets:**
- Đá đỏ nâu texture thô, vân sắt rõ
- Dây leo đặc biệt: lá dày bóng như sáp, chịu nhiệt cao
- Kẽ nứt đá: shimmer nhiệt (visual distortion nhẹ trên nền)
- Đá dăm vương vãi từ việc Gã đập đá

---

### SCENE V3-L2 — "ĐƯỜNG MỎ CŨ" *(Loop B)*

**Truyện ngắn:**
Con đường dẫn vào hang mỏ — ray xe goòng cũ chạy dọc, vài cái xe goòng bỏ lại (một số lật, một số trống). Cột gỗ chống hang đứng 2 bên. Đây là nơi Hỏa Quái T2 bảo vệ lối vào.

**🎨 Background Assets:**
- Ray xe goòng: thép gỉ, ray chạy về phía hang tối
- Xe goòng bỏ lại: 2-3 cái, một số lật, một số còn đầy quặng
- Cột gỗ chống: đen vì nhiệt, một số cháy xém
- Đèn dầu treo cột: vỡ (BEFORE) / còn nguyên và thắp (AFTER)

---

### SCENE V3-L3 — "LÒNG NÚI" *(Loop C)*

**Truyện ngắn:**
Sâu bên trong — nơi đào sâu nhất, nơi Hỏa Quái lớn nhất ở. Đá ở đây đỏ rực hơn, nhiệt độ cao hơn. Đây đó có vết quặng mithril lộ ra từ tường đá — quặng tốt nhất vùng này, nhưng nguy hiểm nhất để lấy.

**🎨 Background Assets:**
- Đá đỏ rực hơn Loop A — gần như phát sáng nhạt từ bên trong
- Tường đá có mạch quặng xanh ánh bạc (mithril) chạy dọc
- Không khí distortion rõ hơn
- Hỏa Quái T3: to hơn, thân đá đỏ có vân lửa, khi di chuyển để lại dấu nóng đỏ trên nền

---

### SCENE V3-S1 — "TRẠI THỢ MỎ" *(Story 1 — Dân cư)*

**Truyện ngắn:**
Trại của thợ mỏ — không phải làng, là trại công việc. Lán trại gỗ dài và thấp, xếp thành hàng. Trước mỗi lán có gốc cây thấp dùng làm bàn ăn. Ở góc trại có lò rèn nhỏ — thợ mỏ tự sửa công cụ sau mỗi ngày làm việc.

Đặc trưng của trại: trước mỗi lán có một tấm đá phẳng khắc tên tổ nhóm — giống như biển số nhà nhưng của tập thể. Ý nghĩa: thợ mỏ ít khi tự hào cá nhân, tự hào theo nhóm.

**BEFORE Clear:** Lán trống, cửa mở toang — thợ mỏ bỏ chạy vội không kịp đóng cửa. Đồ đạc vương vãi. Lò rèn tắt.

**AFTER Clear:** Thợ mỏ quay về, lán có người, lò rèn hoạt động, tiếng búa đục vang ra từ lán. Áo công nhân phơi trên dây.

**🎨 Background Assets:**
- Lán gỗ dài thấp: mái tôn (đặc trưng công trường), cửa kép
- TẤM ĐÁ TÊN TỔ trước mỗi lán: đá phẳng khắc chữ thô, màu xám — đặc trưng vùng này
- Lò rèn nhỏ: đơn giản, thực dụng, không trang trí
- Gốc cây làm bàn ăn tập thể: có vết dao cắt thức ăn
- **KHU VUI CHƠI NHỎ:** Góc trại có sân đấu tay đôi — vẽ vòng tròn trên đất, đá kê 2 bên làm ghế ngồi xem. Thợ mỏ giải trí bằng đấu vật và thi sức mạnh.

**KHU VUI CHƠI BIẾN THỂ — Trại Thợ Mỏ:**
- Không phải khu vui chơi trẻ em — là khu giải trí người lớn kiểu lao động thô
- Assets: Vòng tròn đấu vật vẽ trên đất + đá xếp làm ghế; Cột nâng tạ (thanh sắt + đá đục); Bảng điểm thô
- **BEFORE:** Trống, bụi, không ai
- **AFTER:** Thợ mỏ ngồi xem đấu vật, cổ vũ ồn ào (background animation)

---

### SCENE V3-S2 — "MIẾU NÚI LỬA" *(Story 2 — Linh thiêng)*

**Truyện ngắn:**
Sâu trong hang có một khoang tự nhiên rộng — người ta gọi là "Miếu Núi Lửa" dù không ai dựng lên cả. Trên tường đá có những hoa văn tự nhiên trông như mặt người — vân đá ngẫu nhiên tạo ra hình ảnh. Thợ mỏ tin đây là "mặt Thần Núi".

Thực ra: đây là nơi lửa tổ từng chạm đến trong thời Lò Thiêng cháy. Đá ghi nhớ nhiệt. Di Vật Than Tim Núi cất giữ ở đây.

**BEFORE:** Hỏa Quái lớn canh giữ khoang. Ánh sáng đỏ rực chiều ra từ khoang.

**AFTER:** Hỏa Quái tan biến, khoang mát hơn. Thợ mỏ thỉnh thoảng vào đặt đồ cúng.

**🎨 Background Assets:**
- Khoang tự nhiên: trần vòm cao, đá đỏ ấm ánh sáng từ trong
- HỌA VĂN ĐÁ TỰ NHIÊN: vân đá trông như mặt người — subtle, không quá rõ
- Than Tim Núi: viên đá đỏ đặt trên gờ đá tự nhiên, tỏa nhiệt nhìn thấy được

---

### SCENE V3-LM — "HẦM MỎ SÂU NHẤT" *(Landmark)*

**Truyện ngắn:**
Điểm cuối của đường ray — hầm đào sâu nhất, nơi Hỏa Vương (Boss T4) ngủ. Tường hầm đỏ rực hoàn toàn, không phân biệt được với lửa. Hỏa Vương trông như khối đá nóng to bằng nhà, nhưng khi thức dậy, hình dạng người khổng lồ từ từ lộ ra từ trong khối đá.

**🎨 Boss Assets:**
- Hỏa Vương: khối đá đỏ nóng, khi "thức" nứt ra lộ lõi người bằng lửa bên trong
- Phase 2: nứt nhiều hơn, cánh tay lửa lộ ra, mỗi bước rung đất

## 🛒 NPC Unlock Sau Clear V3

| Loại | Description | Vũ khí mua | Lý do |
|---|---|---|---|
| Thợ mỏ | Mũ cứng, áo da dày | Cuốc chiến, búa mỏ | Sửa thành vũ khí từ công cụ |
| Thợ rèn núi | Tạp dề dày, đeo kẹp lớn | Vũ khí nặng, high ATK | Quen dùng đồ nặng |
| Đội trưởng mỏ | To lớn, sẹo nhiều | Vũ khí boss killer | Cần hạ quái lớn |
| Kiếm sĩ Núi | Giáp nặng, chậm nhưng bền | Vũ khí defense, DEF cao | Chịu đòn tốt |
| Phu khuân vác | Thân to, ít trang bị | Đoản kiếm đơn giản | Tự vệ trên đường vận chuyển |

---

# PHẦN IV — VÙNG 4: BÃI CÁT THẦN VÀNG

## Tổng quan

| | |
|---|---|
| Theme | Sa mạc cổ, đánh đổi, giá của lựa chọn |
| Câu hỏi narrative | Hóa đơn của quyết định nằm ở đâu? |
| Tình trạng trước Clear | Cát Quái (quái cát đá hổ phách) chặn các con đường thương mại — đoàn hàng không qua được |
| Lý do quái xuất hiện | Hổ phách của vùng này từng giữ ký ức cổ đại. Khi Lò tắt, ký ức bị giải phóng không kiểm soát → Cát Quái |
| Tình trạng sau Clear | Con đường thương mại mở lại, chợ nổi ốc đảo hoạt động, thương nhân qua lại |
| Palette | Vàng nhạt + trắng ngà + xanh ngọc |
| NPC VIP | Ông Cát Thần |
| Công trình đặc biệt | QUÁN RƯỢU ỐC ĐẢO (xem phần dưới) |

## Câu Chuyện Tổng Quát

Bãi Cát Thần Vàng là ngã tư của mọi con đường thương mại. Không trồng được gì, không có nước mặt, nhưng lại là điểm trung chuyển không thể tránh. Ông Cát Thần hiểu điều đó — ông ngồi đây hàng chục năm, chứng kiến mọi giao dịch, mọi quyết định, mọi hóa đơn chưa được thanh toán.

Khi Cát Quái xuất hiện, con đường tắc nghẽn hoàn toàn. Thương nhân mắc kẹt. Đoàn hàng chờ. Ở đây có "Ốc Đảo Giữa Cát" — điểm dừng chân duy nhất — và ốc đảo đó hiện là nơi tất cả người bị kẹt tụ lại.

Bên trong ốc đảo: người thì vui mừng (cơ hội buôn bán), người thì lo lắng (hàng hóa hư), người thì tính toán (thời gian = tiền). QUÁN RƯỢU Ở ĐÂY là trung tâm giao dịch ngầm và kể chuyện.

## 6 Scene Breakdown

---

### SCENE V4-L1 — "SA MẠC MỞ" *(Loop A)*

**Truyện ngắn:**
Cồn cát lớn thay đổi hình dạng theo gió. Không có dấu hiệu đường đi — mọi con đường bị cát xóa. Cát Quái T1 (nhỏ, nằm dưới cát, phóng lên khi player đến gần) ẩn rải rác.

**🎨 Background Assets:**
- Cồn cát 5-10m, mép sắc nét
- Cát vàng mica: subtle specular nhỏ
- Không có thực vật, không có bóng người
- Xa horizon: cồn cát lớn hơn xếp thành silhouette

---

### SCENE V4-L2 — "CON ĐƯỜNG TẮC" *(Loop B)*

**Truyện ngắn:**
Con đường thương mại cũ — nhận ra vì dấu bánh xe sâu trong đất nén cứng (ở sa mạc này đất nén bởi triệu bánh xe theo thời gian). Nhưng đường bị chặn bởi Cát Quái và đoàn hàng bỏ lại. Xe goòng hàng đứng yên, một số lật, hàng hóa vương vãi (không phải phá hoại, chỉ là người bỏ chạy để lại).

**🎨 Background Assets:**
- Đường đất nén cứng: nhận ra bởi màu khác và không có cát trôi
- Xe goòng thương mại bỏ lại: 2-3 cái, vải phủ bị gió thổi tung
- Hàng hóa vương vãi: bình đất nung vỡ, cuộn vải, túi gia vị

---

### SCENE V4-L3 — "PHÍA SAU CỒN" *(Loop C)*

**Truyện ngắn:**
Phía sau cồn cát lớn nhất — nơi ít người biết đến. Đây là nơi cổ vật cát được chôn sâu và nơi Cát Quái T3 Thủ Lĩnh cư trú. Khi đào đất ở đây, đôi khi tìm thấy mảnh hổ phách lớn chứa vật thể cổ đại bên trong.

**🎨 Background Assets:**
- Cồn cát cao nhất vùng
- Đá hổ phách lộ ra từ cát: màu vàng cam, trong suốt nhìn thấy bóng vật bên trong
- Cát Quái T3: hình người làm từ cát đá hổ phách, to 2x T1, di chuyển nặng nề hơn

---

### SCENE V4-S1 — "ỐC ĐẢO GIỮA CÁT" *(Story 1 — Dân cư + Quán Rượu)*

**Truyện ngắn:**
Ốc đảo thật sự — có cây cọ lớn, có giếng nước, có vài lều kiên cố. Đây là điểm dừng chân trên con đường thương mại, có từ hàng trăm năm. Hiện tại ốc đảo là nơi tất cả người bị kẹt tụ lại: thương nhân, người dẫn đường, lính bảo vệ đoàn hàng, người buôn lẻ.

Quan trọng nhất: QUÁN RƯỢU ỐC ĐẢO — lều lớn nhất ốc đảo, vải bạt nhiều lớp chống cát, đèn dầu nhiều ngọn. Đây không phải quán bình thường — đây là nơi mọi giao dịch ngầm được thực hiện, mọi thông tin được trao đổi.

**BEFORE Clear:** Ốc đảo đông người nhưng không vui — ai cũng lo. Quán rượu tối và ít tiếng cười. Mọi người ngồi chờ.

**AFTER Clear:** Đường mở, người bắt đầu di chuyển. Quán rượu rộn ràng hơn vì người đến tiệc ăn mừng. Một số người ở lại — họ đã quyết định đây là nhà.

**🎨 Background Assets:**
- Cây cọ: 3-4 cây cao, tán phủ bóng
- Giếng nước: đá xây, xô dây, bóng mát
- Lều thương nhân: nhiều màu (đặc trưng từng nhóm buôn khác nhau)
- **QUÁN RƯỢU ỐC ĐẢO:**
  - Lều lớn nhất, vải bạt đỏ/cam nhiều lớp
  - Đèn dầu đặc biệt: đèn treo hình ngôi sao (đặc trưng văn hóa cát)
  - Bàn thấp + gối ngồi (không có ghế — phong cách ngồi thương nhân sa mạc)
  - Bên ngoài: biển hiệu đơn giản — bình rượu vẽ trên vải cắm trên sào
  - **Gameplay:** Mua đồ uống restore stamina; nghe tin đồn từ các thương nhân (lore tidbits); gặp NPC đặc biệt

---

### SCENE V4-S2 — "THÁP CÁT THẦN" *(Story 2 — Linh thiêng)*

**Truyện ngắn:**
Một tháp đá cổ đứng giữa cát — không ai biết ai dựng, không ai biết bao nhiêu tuổi. Kiến trúc không giống bất kỳ phong cách nào trong xứ. Trên tháp có những cái cân khổng lồ khắc bằng đá — cân không hoạt động được, chỉ là biểu tượng.

Ông Cát Thần hay ngồi dưới chân tháp này. Không thờ phụng — chỉ ngồi. Ông nói: "Tháp này nhắc ta rằng mọi thứ sẽ được cân bằng cuối cùng."

**🎨 Background Assets:**
- Tháp cổ: đá sa thạch vàng nhạt, 4 tầng, hình vuông thon dần, không cửa sổ ở tầng cao
- Hoa văn cân khắc trên tường: cân đòn 2 đĩa, đơn giản
- Bóng tháp trên cát: dài và rõ ràng vào buổi sáng/chiều (shadow visual cue cho player về thời gian)
- Chân tháp: đá Ông Cát Thần thường ngồi có dấu mòn rõ

## 🛒 NPC Unlock Sau Clear V4

| Loại | Description | Vũ khí mua | Lý do |
|---|---|---|---|
| Thương nhân | Áo nhiều lớp, túi nhiều | Dao thương nhân, khiên tay | Bảo vệ hàng hóa |
| Người dẫn đường | Biết địa hình, da đen nắng | Dao tiện dụng, cung nhỏ | Dẫn đoàn hàng qua vùng nguy hiểm |
| Lính bảo tiêu | Áo giáp nhẹ, dễ di chuyển | Vũ khí linh hoạt, balanced | Bảo vệ đoàn trong khi di chuyển |
| Kiếm sĩ Cát | Trang phục che cát, mắt hẹp | Scimitar (kiếm cong) | Đặc trưng chiến đấu trong cát |
| Thầy bói/nhà tiên tri | Áo rộng, nhiều nhẫn | Không mua vũ khí — mua thuốc hoặc tool lạ | Quan tâm đến tri thức hơn chiến đấu |

---

# PHẦN V — VÙNG 5: THÀNH NGỌC BÍCH

## Tổng quan

| | |
|---|---|
| Theme | Thành phồn hoa, danh tiếng, xa xỉ, bất công |
| Câu hỏi narrative | Khi nghề thành luxury, ai bị bỏ lại? |
| Tình trạng trước Clear | Thành bị Ngọc Quái (quái làm từ đá ngọc corrupted) phong tỏa một số khu vực — đặc biệt khu dân nghèo |
| Lý do quái xuất hiện | Thành Ngọc khai thác ngọc bích quá mức để xây thành. Đá ngọc có linh hồn (theo luật huyền ảo) — khi bị khai thác không có lễ cúng tế (Lò tắt = không có tổ nghề làm lễ) → quái sinh ra |
| Tình trạng sau Clear | Khu dân nghèo mở lại, cả 2 tầng lớp có thể đi lại tự do hơn |
| Palette | Xanh nhạt + trắng sữa + vàng ánh |
| NPC VIP | Bà Thiên Kim |
| Công trình đặc biệt | KHU VUI CHƠI THÀNH NGỌ (xem chi tiết) |

## Câu Chuyện Tổng Quát

Thành Ngọc Bích là thành phố duy nhất có tường đá thật và đèn đường. Nhưng bên trong tường đó là hai thế giới song song: Khu Thượng (đẹp, sáng, người giàu) và Khu Hạ (tối, chật, người lao động thường ngày).

Ngọc Quái xuất hiện không phải ở Khu Thượng — mà ở Khu Hạ, nơi người thợ thủ công, người giúp việc, người bán hàng rong sinh sống. Khu Hạ bị phong tỏa. Khu Thượng tiếp tục tổ chức tiệc tùng.

Bà Thiên Kim biết điều này — nhưng bà không nói ra. Bà tự hỏi: nếu Khu Hạ bị phong tỏa mãi mãi, Khu Thượng có đẹp được không?

## 6 Scene Breakdown

---

### SCENE V5-L1 — "ĐƯỜNG PHỐ THƯỢNG" *(Loop A)*

**Truyện ngắn:**
Đường phố Khu Thượng — không có quái nhiều (đây là khu giàu có), nhưng Ngọc Quái nhỏ đôi khi lọt vào từ Khu Hạ qua đường cống. Cảnh quan đẹp: đường đá trắng, nhà 2 tầng, đèn đường thắp. Nhưng cửa đóng hết — vì sợ.

**🎨 Background Assets:**
- Đường đá trắng xám, sạch
- Nhà 2 tầng cửa sổ kính, mái ngói tráng men xanh
- Đèn đường trụ đồng — thắp cả ngày lẫn đêm (sang trọng)
- Cửa nhà đóng kín + khóa lớn — khác với V1 (ở V1 cửa đóng vì sợ gió, ở đây cửa đóng + khóa = sự kiêu ngạo của người giàu khi sợ hãi)

---

### SCENE V5-L2 — "ĐƯỜNG CẦU NỐI" *(Loop B)*

**Truyện ngắn:**
Khu trung gian giữa Khu Thượng và Khu Hạ — cầu đá cũ nối 2 khu. Đây là nơi Ngọc Quái T2 tập trung nhất — chúng "khóa" cầu, không cho qua lại. Một số đồ vật bị bỏ lại giữa cầu bởi người bỏ chạy.

**🎨 Background Assets:**
- Cầu đá cũ: tường lan can thấp, rêu ở mép
- Phân chia rõ: Khu Thượng phía sau (sáng, đẹp) | Khu Hạ phía trước (tối, chật)
- Đồ vật bỏ lại giữa cầu: giỏ hàng đổ, gánh gánh bỏ

---

### SCENE V5-L3 — "KHU HẠ TỐI" *(Loop C)*

**Truyện ngắn:**
Sâu trong Khu Hạ — hẹp, tối, nhà sát nhau. Đây là nơi Ngọc Quái mạnh nhất tập trung. Trên tường Khu Hạ có nhiều graffiti — vẽ bằng than, vẽ bằng vôi — hình ảnh và chữ của người dân thể hiện sự bất mãn và nỗi sợ hãi.

**🎨 Background Assets:**
- Nhà thấp, sát nhau, hẻm hẹp
- Đèn đường không có — chỉ đèn dầu nhỏ treo trước cửa nhà
- GRAFFITI trên tường: hình ảnh đơn giản (vẽ bằng than/vôi) — người cầm vũ khí, quái, cổng đóng
- Ngọc Quái T3: hình người làm bằng ngọc bích vỡ, mảnh ngọc nhọn tỏa ra khi di chuyển

---

### SCENE V5-S1 — "KHU PHỐ NGHỀ TRUYỀN THỐNG" *(Story 1 — Dân cư)*

**Truyện ngắn:**
Một khu trong Khu Hạ — nơi thợ thủ công và nghệ nhân sinh sống. Mỗi nhà có "hiệu" nhỏ phía trước: thợ dệt, thợ gốm, thợ làm giày, thợ khắc ngọc. Đây là những người thật sự làm ra hàng hóa mà Khu Thượng mua và bán lại với giá gấp mười.

Cũng ở đây có KHU VUI CHƠI THÀNH NGỌ — không phải khu giải trí sang trọng của Khu Thượng, mà là sân chơi của người dân Khu Hạ.

**BEFORE Clear:** Cửa tiệm đóng, biển hiệu gỡ xuống, vải che cửa sổ. Người dân trốn trong nhà. Không tiếng búa, không tiếng thoi.

**AFTER Clear:** Cửa tiệm mở, nghệ nhân ngồi làm việc trước hiệu (để khách thấy). Tiếng thoi dệt, tiếng búa khắc ngọc, mùi đất gốm. Trẻ em ra đường.

**🎨 Background Assets:**
- Nhà nghệ nhân: nhà thấp 1 tầng, phía trước mở thành "quầy" nhỏ (như shop nhỏ)
- Biển hiệu từng nghề: hình vẽ đơn giản (con thoi = thợ dệt, bình = thợ gốm, giày = thợ giày)
- BEFORE: biển hiệu úp xuống, không tiếng động, vải che
- AFTER: biển hiệu dựng lên, nghệ nhân làm việc visible

**🎮 KHU VUI CHƠI THÀNH NGỌ (Khu Hạ):**
- Không phải sân vui chơi trẻ em đơn thuần — là sân cộng đồng đa thế hệ
- Assets:
  - Bàn cờ ngoài trời: bàn đá, cờ bằng ngọc bích nhỏ phế phẩm (không đủ chuẩn để bán lên Khu Thượng)
  - Sân nhảy dây / chơi chun cho trẻ em
  - Giếng cộng đồng + bậc đá xung quanh — nơi người già ngồi kể chuyện
  - Tường vẽ màu: một bức tường được phép vẽ thoải mái — đầy hình ảnh vui của trẻ em
- **BEFORE:** Trống, không ai
- **AFTER:** Đông vui, nhiều thế hệ, tiếng cười
- **Gameplay:** Có thể mua đồ chơi đặc biệt (item nhỏ), gặp NPC trẻ em có quest nhỏ

---

### SCENE V5-S2 — "ĐỀN NGỌC CỔ" *(Story 2 — Linh thiêng)*

**Truyện ngắn:**
Đền ngọc cổ nhất thành — không phải đền của người giàu, đền của người thợ khắc ngọc. Người thợ dựng đền để tế lễ trước khi đào ngọc — "xin phép" đá trước khi lấy. Khi Lò tắt, tục lệ này bỏ dần. Khi việc khai thác ngọc không còn được tế lễ → Ngọc Quái.

Đền có một vật đặc biệt: bức phù điêu ngọc bích nguyên khối, khắc hình 6 vùng đất + Lò Thiêng ở trung tâm. Đây là bản đồ cổ nhất còn tồn tại của Xứ Lửa Thiêng.

**🎨 Background Assets:**
- Đền đá ngọc: nhỏ hơn đền Khu Thượng nhưng cũ hơn và thật hơn; cột đá xanh nhạt, mái ngói cong
- PHÙ ĐIÊU NGỌC BÍCH: bức chạm khắc lớn trên tường chính — 6 vùng + Lò Thiêng trung tâm; nhìn rõ 6 biểu tượng vùng quanh hình lò lửa
- BEFORE: Ngọc Quái lớn canh trước đền
- AFTER: Đền mở, người dân vào cúng lễ, đèn nến thắp

---

### SCENE V5-LM — "SÀN ĐẤU GIÁ + TÒNG THÀNH" *(Landmark)*

**Truyện ngắn:**
Tòa nhà lớn nhất Khu Thượng — Sảnh Đấu Giá, nơi Bà Thiên Kim làm việc. Kiến trúc hoành tráng: cửa kép cao 5m, đèn chùm nhìn thấy qua cửa sổ kính lớn, thảm đỏ trải ra ngoài.

Nhưng ngay bên cạnh Sảnh Đấu Giá, có thứ mà người Khu Thượng cố tình không nhìn: một ngôi nhà nhỏ cũ, tường đen vì khói, cửa thấp — đây là xưởng của người thợ khắc ngọc đầu tiên của thành. Bây giờ bỏ hoang. Ngọc Quái Boss trú trong xưởng đó.

**Thông điệp visual:** Grandeur của Sảnh Đấu Giá + sự bỏ hoang của Xưởng cũ đứng cạnh nhau — không cần dialogue.

**🎨 Boss Assets:**
- Ngọc Rồng: rồng làm từ ngọc bích corrupted, mảnh ngọc vỡ nhọn tỏa ra khi di chuyển, mắt mờ (không biết mình là gì nữa)

## 🛒 NPC Unlock Sau Clear V5

| Loại | Description | Vũ khí mua | Lý do |
|---|---|---|---|
| Thợ khắc ngọc | Tay cẩn thận, mắt tinh | Dao khắc chính xác, nhỏ | Cần dao precision |
| Cận vệ Khu Thượng | Giáp bóng, cứng nhắc | Vũ khí hào nhoáng (đắt) | Cần trông đẹp + mạnh |
| Lính Khu Hạ | Không đồng phục, tự trang bị | Bất kỳ vũ khí dùng được | Tự bảo vệ không có ngân sách |
| Kiếm sĩ Ngọc | Giáp ngọc, không thực dụng | Kiếm ceremonial đắt | Status symbol |
| Nghệ nhân | Áo đẹp nhưng tay chai | Dao nghề (dùng trong công việc) | Công cụ, không phải vũ khí thật |

---

# PHẦN VI — VÙNG 6: LÀNG TỔ NGHỀ

## Tổng quan

| | |
|---|---|
| Theme | Làng cổ, ký ức tổ tiên, sự thật, quyết định cuối |
| Câu hỏi narrative | Kế thừa là giữ nguyên hay dám sửa? |
| Tình trạng trước Clear | Tàn Quái (quái làm từ công cụ rèn bị bỏ lại) bảo vệ khu vực lõi của Làng Tổ |
| Lý do quái xuất hiện | Công cụ rèn tổ nghề bỏ lại khi họ chia Lò — không có chủ, không có lửa, không có ký ức → công cụ tự hóa quái để "tìm" chủ |
| Tình trạng sau Clear | Các lão thợ rèn ẩn trong làng dám ra mặt, chia sẻ kiến thức cổ đại |
| Palette | Nâu đất + xám + xanh rêu + vàng nhạt (hoa văn) |
| NPC VIP | Lão Thôi Cổ |

## Câu Chuyện Tổng Quát

Làng Tổ Nghề là nơi mọi thứ bắt đầu và mọi thứ sẽ kết thúc. Đây không phải làng bình thường — người ở đây không "sống" theo nghĩa thông thường, họ "giữ" — giữ ký ức, giữ công thức, giữ câu hỏi.

Khi player đến đây, mọi bí ẩn đã có đủ mảnh để ghép lại. Làng Tổ không "cần được cứu" theo nghĩa hành động — nó cần được nghe. Và player đến đây không phải để đánh quái mà để hiểu.

Tàn Quái là công cụ rèn cũ tự hóa quái — chúng không tấn công vô nghĩa, chúng tấn công ai không đủ "tư cách" tiếp cận khu vực cốt lõi.

## 6 Scene Breakdown

---

### SCENE V6-L1 — "CON ĐƯỜNG VÀO LÀNG" *(Loop A)*

**Truyện ngắn:**
Đường đất nén cứng dẫn vào làng — hai bên là cây cổ thụ già, rễ nổi cao. Cây được trồng theo hàng khi làng thành lập. Trên vỏ cây có khắc những dấu hiệu nhỏ — không phải chữ, là ký hiệu của từng tổ thợ rèn đã đi qua đây.

Tàn Quái T1: búa cũ tự đứng dậy đi, không có người điều khiển.

**🎨 Background Assets:**
- Cây cổ thụ hàng đôi, rễ nổi cao
- Vỏ cây có ký hiệu khắc nhỏ: không chữ, hình dạng đơn giản (vòng tròn, dấu X, hình thoi — mỗi tổ một dấu riêng)
- Đường đất nén cứng, không cỏ mọc giữa đường

---

### SCENE V6-L2 — "RÌA LÀNG CŨ" *(Loop B)*

**Truyện ngắn:**
Nhà bỏ hoang của các thợ rèn đã ra đi — cửa rơi xuống, mái thủng, cỏ mọc trong nhà. Nhưng không hoàn toàn trống: trên mỗi ngưỡng cửa có để lại một thứ — biểu tượng "đã ra đi nhưng không quên". Người ta đặt một mảnh sắt nhỏ hoặc một hòn than lên ngưỡng cửa khi rời làng.

Tàn Quái T2: kìm rèn cũ tự di chuyển, kẹp bất cứ thứ gì trong tầm với.

**🎨 Background Assets:**
- Nhà bỏ hoang: cửa rơi, mái thủng, cỏ mọc TRONG nhà
- Ngưỡng cửa: mỗi nhà có một mảnh sắt nhỏ hoặc hòn than đặt ở ngưỡng cửa
- Tàn Quái T2: kìm đen, to, di chuyển như sinh vật có xương nhưng không có thịt

---

### SCENE V6-L3 — "SÂN LÒ CŨ" *(Loop C)*

**Truyện ngắn:**
Sân rộng xung quanh Lò Tổ — nơi thợ rèn từng làm việc ngoài trời. Đây đó còn dấu vết: vòng đá kê lò tạm, bệ đặt đồ nước tôi, gốc cây cụt (cây cổ thụ bị chặt để lấy chỗ làm việc). Tàn Quái mạnh nhất ở đây vì gần Lò Tổ nhất.

**🎨 Background Assets:**
- Vòng đá kê lò tạm: đá xếp thành vòng tròn, tro cũ bên trong
- Gốc cây cụt: to, cưa bằng phẳng, rêu phủ trên mặt
- Bệ đặt đồ tôi: gỗ mục, còn nhận ra hình dạng

---

### SCENE V6-S1 — "NHÀ THỢ RÈN CÒN Ở LẠI" *(Story 1 — Dân cư)*

**Truyện ngắn:**
Vài ngôi nhà trong làng vẫn còn người — những lão thợ rèn không thể rời đi hoặc không muốn. Nhà họ khác với nhà bỏ hoang xung quanh: cửa đóng nhưng không đổ, có đèn dầu nhỏ sau cửa sổ, có khói bếp mờ nhạt buổi sáng.

Họ không ra ngoài — không phải vì sợ Tàn Quái, mà vì họ đã quen sống khép kín khi mọi người rời đi.

**BEFORE Clear:** Nhà có người nhưng không ai ra. Cửa sổ hé nhỏ.

**AFTER Clear:** Cửa mở. Lão thợ ngồi trước nhà. Không nói nhiều — chỉ nhìn Người Giữ Lò và gật đầu. Đó là đủ rồi.

**🎨 Background Assets:**
- Nhà còn người: cửa đóng nhưng không mục, đèn dầu sau cửa sổ
- AFTER: Lão thợ ngồi trên bậc thềm, không làm gì, chỉ ngồi — dáng người đã làm việc cả đời và giờ chỉ nghỉ ngơi

---

### SCENE V6-S2 — "BẢNG TÊN VÀ MIẾU TỔ" *(Story 2 — Linh thiêng)*

**Truyện ngắn:**
Bảng tên thợ rèn + Miếu Tổ Nghề. Đây là scene thiêng liêng nhất game.

Bảng tên: đá phẳng khắc tên tất cả người đã giữ lò — chữ đều nhau, không tên nào to hơn, không tên nào được sơn khác màu. Chỗ cuối bảng, dòng cuối — trống.

Miếu Tổ: không có tượng, không có bàn thờ hoa mỹ. Chỉ có một cái lò nhỏ — bản sao thu nhỏ của Lò Thiêng — luôn cháy, không bao giờ tắt dù không có ai đổ than. Người ta nói lò nhỏ này cháy bằng ký ức.

**🎨 Background Assets:**
- Bảng tên: đá phẳng lớn, khắc kín tên, dòng cuối trống — đây là chỗ dành cho Người Giữ Lò
- Miếu Tổ: nhỏ và đơn giản, lò nhỏ bên trong lúc nào cũng có lửa nhỏ — không dramatic, chỉ ổn định
- Không bụi trên bảng, không rêu trên miếu — ai đó vẫn lau dọn

---

### SCENE V6-LM — "LÒ TỔ VÀ LÒ GỐC" *(Landmark)*

**Truyện ngắn:**
Hai công trình cuối cùng của game: Lò Tổ trên mặt đất (to, tắt, chờ đợi) và lối vào Lò Gốc dưới lòng đất (cầu thang đá dẫn xuống). Đây là điểm kết của hành trình.

Tàn Quái Boss (Tàn Vương): không phải một quái đơn giản — là TẤT CẢ công cụ rèn tổ nghề bỏ lại, ghép lại thành một hình dạng khổng lồ. Búa, kìm, bễ, đe, tất cả tạo thành một "người thợ rèn" khổng lồ không có chủ.

Khi player thắng, Tàn Vương tan ra — và tất cả công cụ cũ rơi xuống nhẹ nhàng, sắp xếp ngay ngắn trên sàn như ai đó vừa đặt xuống cẩn thận.

**🎨 Boss Assets:**
- Tàn Vương: cấu trúc ghép công cụ rèn cũ; không kinh dị, không xấu xí — thật ra trông như một người thợ rèn cổ đại; khi đánh ra mảnh thì mảnh đó nhận ra là búa/kìm/bễ

## 🛒 NPC Unlock Sau Clear V6

| Loại | Description | Vũ khí mua | Lý do |
|---|---|---|---|
| Lão thợ rèn | Già, tay chai dày, ít nói | Không mua — bán nguyên liệu cổ | Không cần vũ khí, có recipe |
| Học trò tổ nghề | Trẻ, tò mò, đang học | Vũ khí practice | Đang học cầm vũ khí |
| Người giữ ký ức | Áo đơn giản, sổ sách nhiều | Không mua vũ khí — mua Di Vật | Thu thập lịch sử |
| Thợ rèn cuối cùng | Không còn trẻ, tay vẫn chai | Vũ khí tốt, craft-level | Vẫn cần dùng |

---

# PHẦN VII — TỔNG HỢP CÔNG TRÌNH ĐẶC BIỆT

---

## 🍺 QUÁN RƯỢU — Vị trí: Rừng Trăm Hồn (V2-S1) + Bãi Cát Thần Vàng (V4-S1)

Hai quán với tính cách hoàn toàn khác nhau:

### Quán Rượu Binh Trạm (V2 — Rừng)
| | |
|---|---|
| Tên | "Ván Cờ Chưa Xong" |
| Vị trí | Góc của Binh Trạm cũ trong V2-S1 |
| Tông | Nặng nề, lặng lẽ, buồn theo kiểu lính già |
| Khách | Người sống sót, người tìm ký ức, lính về hưu |
| Đặc trưng visual | Tên người khắc trên gỗ tường, ván cờ bỏ dở, đèn ít |
| Gameplay | Mua rượu gạo/trà chiến +stamina; nghe lore về Trận Cây Rừng; NPC quest giver |
| Assets | Kệ bình rượu đất nung quân sự; ghế thô; tường khắc tên; bàn cờ dở |

### Quán Rượu Ốc Đảo (V4 — Cát)
| | |
|---|---|
| Tên | "Giữa Gió Và Cát" |
| Vị trí | Lều lớn nhất Ốc Đảo trong V4-S1 |
| Tông | Náo nhiệt, đa sắc tộc, tin đồn nhiều |
| Khách | Thương nhân, người dẫn đường, kẻ phiêu lưu |
| Đặc trưng visual | Đèn ngôi sao nhiều màu, bàn thấp gối ngồi, bản đồ trade route treo tường |
| Gameplay | Mua đồ uống sa mạc +stamina; mua thông tin (tiêu vàng để nghe tin đồn); giao dịch ngầm |
| Assets | Đèn hình ngôi sao treo trần; bàn thấp gối ngồi; bình rượu lớn (amphora); bản đồ thương mại vẽ tay |

---

## 🎮 KHU VUI CHƠI — Vị trí: Núi Than Đỏ (V3-S1) + Thành Ngọc Bích (V5-S1)

Hai khu với triết lý giải trí hoàn toàn khác nhau:

### Sân Đấu Trại Mỏ (V3 — Núi)
| | |
|---|---|
| Tên | "Vòng Sắt" |
| Vị trí | Góc Trại Thợ Mỏ trong V3-S1 |
| Tông | Thô, sức mạnh, cộng đồng lao động |
| Người dùng | Thợ mỏ, nam giới trung niên, dân lao động nặng |
| Đặc trưng visual | Vòng đấu vật đất nện, cột nâng tạ sắt, ghế đá cho người xem |
| Gameplay | Watch combat (NPC đấu vật, có thể cược); mini-game sức mạnh (nâng tạ); NPC thợ mỏ có thể mua vũ khí ở đây |
| Assets | Vòng tròn vẽ trên đất; cột gỗ treo thanh sắt nâng tạ; đá xếp làm khán đài; bảng điểm thô trên gỗ |
| BEFORE | Trống, bụi |
| AFTER | Thợ mỏ tụ tập, tiếng hò hét cổ vũ (background animation) |

### Sân Cộng Đồng Khu Hạ (V5 — Thành Ngọc)
| | |
|---|---|
| Tên | "Ngọc Vụn" |
| Vị trí | Góc Khu Phố Nghề trong V5-S1 |
| Tông | Đa thế hệ, ấm áp, phản kháng ngầm (người nghèo vẫn tìm được vui) |
| Người dùng | Trẻ em, người già, nghệ nhân — dân Khu Hạ |
| Đặc trưng visual | Bàn cờ ngọc vụn, tường vẽ màu tự do, giếng cộng đồng làm trung tâm |
| Gameplay | Gặp NPC trẻ em (quest nhỏ); mua đồ chơi/vật kỷ niệm (không combat item); nghe câu chuyện người dân Khu Hạ |
| Assets | Bàn đá + quân cờ ngọc bích phế phẩm; giếng đá + bậc ngồi; tường vẽ đầy màu sắc tự do; dây nhảy, vòng đất nung làm đồ chơi |
| BEFORE | Trống, không ai |
| AFTER | Đông vui, tiếng trẻ em, người già kể chuyện |

**Ý nghĩa narrative:**
- V3 Sân Đấu = "Vui theo cách người lao động" → sức mạnh, cạnh tranh lành mạnh
- V5 Sân Cộng Đồng = "Vui theo cách người bị bỏ lại" → cộng đồng, sáng tạo, bằng những thứ không ai muốn (ngọc vụn)

---

# PHẦN VIII — MASTER ASSET LIST (Cần vẽ cho cả 6 vùng)

## Shared Assets (Dùng cho tất cả vùng)

### Visual Language Markers (PHẢI nhất quán)
| Asset | Mô tả | Vùng |
|---|---|---|
| 🔴 BEFORE indicator | Cửa đóng + thanh chắn | Tất cả Story Scenes |
| 🔴 AFTER indicator | Cửa mở + người ra ngoài | Tất cả Story Scenes |
| 🔴 Loop scene marker | Không có công trình, chỉ tự nhiên | Tất cả Loop Scenes |
| 🔴 Story scene marker | Ít nhất 1 công trình có cửa | Tất cả Story Scenes |
| 🔴 Landmark marker | Công trình chiếm 60%+ background | Tất cả Landmark Scenes |

## Per-Region Unique Assets

| Vùng | Landmark duy nhất | Vật linh thiêng | Quái đặc trưng |
|---|---|---|---|
| V1 Đồng Mây | Cối xay gió khổng lồ | Bình đồng Miếu Gió | Phong Quái (lốc xoáy nhỏ) |
| V2 Rừng Bóng | Đài Tưởng Niệm đá | Đài tên người | Hồn Chiến Trận (hình người mờ) |
| V3 Núi Than | Hầm Mỏ Sâu Nhất | Khoang Miếu tự nhiên | Hỏa Quái (người đá nóng đỏ) |
| V4 Cát Thần | Tháp Cát Thần cổ | Cân đá trên tháp | Cát Quái (người cát hổ phách) |
| V5 Thành Ngọc | Sảnh Đấu Giá + Xưởng cũ | Phù điêu ngọc bích 6 vùng | Ngọc Quái (người ngọc vỡ) |
| V6 Làng Tổ | Lò Tổ + lối vào Lò Gốc | Lò nhỏ cháy vĩnh cửu | Tàn Quái (công cụ rèn tự đi) |

---

# PHẦN IX — THAY ĐỔI VISUAL THEO PROGRESSION

## Khi Player Clear Vùng — Background State Changes Summary

```
V1 Clear → Phong Linh đồng ngân, Cối Xay Gió quay → Người dân ra đồng
V2 Clear → Đài Tưởng Niệm tỏa sáng đêm, Ván cờ được xếp lại → Lính cũ ra mặt  
V3 Clear → Lò rèn trại mỏ cháy, Sân đấu vật ồn ào → Thợ mỏ quay vào hang
V4 Clear → Quán rượu ốc đảo náo nhiệt, Đường thương mại mở → Đoàn hàng qua lại
V5 Clear → Sân cộng đồng Khu Hạ vui vẻ, Đền Ngọc mở → Nghệ nhân làm việc
V6 Clear → Lão thợ ngồi trước nhà, Bảng tên có chỗ trống → Lò Gốc có thể tiếp cận
```

## Khi Player Clear Toàn Bộ 6 Vùng

Nếu player về thăm lại bất kỳ vùng nào sau Ending A:
- Tất cả Story Scene: hoàn toàn mở, đông người
- Tất cả Loop Scene: thưa quái, nhiều gathering node mới
- Tất cả Landmark: trở thành điểm giao lưu (người dân tụ tập xung quanh, không còn là nơi nguy hiểm)

---

*End of Document — LÒ THIÊNG SCENE MAP SYSTEM v1.0*
*Tiếp theo: Scene Asset Reference Sheet chi tiết cho từng vùng (tileset, character sprite per region)*
