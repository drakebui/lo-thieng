# 🔥 LÒ THIÊNG: TIẾNG GỌI TỔ NGHỀ
## GAME DESIGN DOCUMENT — PHIÊN BẢN PC

**Phiên bản:** 1.0 — Pre-production GDD
**Ngày:** Tháng 5/2026
**Tác giả:** Solo dev (1 người)
**Engine đề xuất:** Godot 4 hoặc Unity 2D
**Thể loại:** Shop Management + Crafting + Light RPG (turn-based combat)
**Cảm hứng tham khảo:** Recettear, Moonlighter, Potion Craft
**Khác biệt cốt lõi:** Hệ thống rèn 3-phase + 6 vùng exploration + combat lượt với skill từ vũ khí tự rèn

---

## MỤC LỤC

1. Tóm Tắt Điều Hành
2. Tầm Nhìn Sản Phẩm & Đối Tượng
3. Phân Tích & Quyết Định Combat
4. Vòng Lặp Cốt Lõi
5. Hệ Thống Combat
6. Hệ Thống Rèn
7. Hệ Thống Cửa Hàng & Mặc Cả
8. Hệ Thống Vùng Đất & Khám Phá
9. Hệ Thống Nhân Vật
10. Hệ Thống NPC
11. Hệ Thống Quest
12. Hệ Thống Tutorial
13. Hệ Thống Vật Phẩm
14. Tính Năng Chính (tóm tắt)
15. Kinh Tế & Tiến Trình
16. Kết Thúc & Replayability
17. Hướng Đi Nghệ Thuật & Âm Thanh
18. Cân Nhắc Kỹ Thuật & Phạm Vi Solo Dev
19. Lịch Trình Phát Triển
20. Phụ Lục

---

# 1. TÓM TẮT ĐIỀU HÀNH

## 1.1. Pitch một câu

> *Bạn là thợ rèn trẻ thừa kế xưởng cũ ở Xứ Lửa Thiêng — vừa quản lý cửa hàng, vừa đi khám phá 6 vùng đất săn nguyên liệu, vừa tự tay rèn từng vũ khí có sức mạnh và lai lịch riêng — để trả nợ Bà Trùm Hắc Nguyệt và phục dựng Lò Thiêng Tổ Nghề từ 18 mảnh Di Vật rải rác.*

## 1.2. USP (Unique Selling Points)

Có ba điều game này làm khác phần lớn shop-management games trên thị trường:

**Vũ khí có "lai lịch", không chỉ có chỉ số.** Mỗi cây kiếm bạn rèn ra mang theo 2 kỹ năng từ Prefix + Suffix. Vũ khí cùng tên có thể có gameplay rất khác nhau. Người chơi sẽ nhớ "cây kiếm Hỏa Thần Bén Ngọt mà tôi rèn ngày 7" như một character chứ không phải một cục số.

**Hệ thống rèn 3-phase với rủi ro thật.** Không phải craft là xong. Phase 2 (Rèn Búa) có thể tạo ra Lời Nguyền — vũ khí thành phế phẩm. Cảm giác "tay chân bồn chồn khi gõ búa" là core experience, không phải gimmick.

**6 vùng đất, 6 NPC VIP, 6 hệ kinh tế cục bộ.** Mỗi vùng có nguyên liệu riêng, khách quen riêng, giá thị trường riêng, và một quest line riêng. Người chơi không "farm" — họ "nhận diện cơ hội" theo từng vùng.

## 1.3. Phạm vi mục tiêu (cho solo dev)

- **Thời lượng playthrough chính:** 12-15 giờ
- **Replayability:** Cao (3-4 endings + nhiều build vũ khí khác nhau)
- **Số lượng region:** 6 (đã định sẵn từ thiết kế)
- **Số lượng NPC có tên:** ~30 (10 VIP/quest + 20 khách hàng đặc biệt)
- **Số lượng quest:** ~25 main + 30 side
- **Pool combat skill:** ~25 skill (đủ chiến thuật, không quá nặng cân bằng)
- **Pool item:** ~80 items (rút gọn từ 158 thẻ board game)
- **Engine:** Godot 4 (free, 2D-first, dễ cho solo dev)

---

# 2. TẦM NHÌN SẢN PHẨM & ĐỐI TƯỢNG

## 2.1. Cảm xúc cốt lõi muốn tạo ra

Khi người chơi đang chơi tốt, họ cảm thấy như đang **vận hành một workshop sống**: sáng đi nhặt nguyên liệu, trưa về rèn, chiều mở cửa bán hàng, tối tổng kết và chuẩn bị cho ngày mai. Mỗi ngày là một câu chuyện nhỏ với mở-thân-kết.

Khi người chơi gặp khó khăn, họ cảm thấy **áp lực có ý nghĩa**: nợ Bà Trùm đang đến, vũ khí gần đây toàn nhận Curse, khách kén chọn liên tục. Nhưng cảm giác này không "đè bẹp" — luôn có cách thoát ra (đi vùng khác, học công thức mới, đổi chiến lược bán).

Khi người chơi đạt được kiệt tác (Mastery + Perfect Prefix), họ cảm thấy **niềm tự hào của thợ thủ công** — không chỉ vì stats cao, mà vì *họ tự tay rèn ra vật đó*, qua may rủi và chiến lược.

## 2.2. Đối tượng mục tiêu

**Primary:** Người chơi yêu thích shop-management cozy games (Recettear, Potion Craft, Moonlighter) nhưng muốn nhiều chiều sâu chiến lược hơn cozy đơn thuần.

**Secondary:** Fan của crafting deep games (Atelier series, Stardew Valley artisan playstyle).

**Tertiary:** Người chơi Việt Nam/Đông Nam Á muốn game có theme văn hóa thân thuộc nhưng không phải copy lịch sử (theme hư cấu "Xứ Lửa Thiêng").

## 2.3. Phong cách nghệ thuật (định hướng cao cấp)

2D pixel art top-down isometric, palette ấm, gợi vibe "Đông Nam Á cổ tích" — nhưng không sa vào sáo rỗng. Tham khảo: Eastward (palette + atmosphere), Sea of Stars (pixel art quality), Stardew Valley (UI clarity). Tránh: anime style, generic medieval-Western.

---

# 3. PHÂN TÍCH & QUYẾT ĐỊNH COMBAT

Đây là phần quan trọng nhất của GDD vì nó định scope toàn dự án. Phần này ghi lại lý do chọn hệ thống combat hiện tại để **tránh design drift về sau**.

## 3.1. Yêu cầu đặt ra

Hệ thống combat phải:

- Đủ chiến thuật để giữ chân người chơi 12-15 giờ
- Kết nối trực tiếp với hệ thống Rèn (vì Rèn là USP)
- Solo dev một người làm được trong 4-6 tháng
- Không trở thành "game thứ 2 trong game" về complexity
- Cho phép vũ khí khác nhau = trải nghiệm khác nhau

## 3.2. Các phương án đã cân nhắc

**Phương án A — Card combat (Slay the Spire-like):** Hấp dẫn về mặt cảm xúc nhưng yêu cầu pool 50-100 thẻ cân bằng + AI + animation system. Ước tính 500-800h chỉ riêng combat. **Loại.**

**Phương án B — Tactical grid (Into the Breach-like):** Quá phức tạp về AI và pathing. Yêu cầu level design cho mỗi encounter. **Loại.**

**Phương án C — Real-time action (Moonlighter-like):** Yêu cầu animation, hitbox, AI tốt. Solo dev khó polish đến mức acceptable. Cũng phá vibe "thợ rèn cẩn thận" của game. **Loại.**

**Phương án D — Auto-battler:** Quá ít agency cho người chơi. Phá feel "tự tay rèn → tự tay dùng". **Loại.**

**Phương án E (chọn) — Turn-based + Weapon Skill Slots:** Đơn giản về kiến trúc, sâu về chiến thuật, kết nối trực tiếp với Rèn. Pool skill nhỏ (~25). Combat 3-5 lượt mỗi trận.

## 3.3. Quyết định chốt

**Chọn Phương án E** vì 4 lý do:

Thứ nhất, nó **biến Rèn thành choice gameplay** chứ không chỉ stats grind. Rèn vũ khí Hỏa khác Rèn vũ khí Thánh là khác hoàn toàn về cách đánh.

Thứ hai, **scope quản lý được**: ~25 skills × 4-5 stats mỗi skill = bảng cân bằng ~100 ô, có thể test bằng spreadsheet trước khi vào engine.

Thứ ba, **rút ngắn combat loop**: 3-5 lượt mỗi trận, 30-60 giây thực tế, không làm chậm vòng lặp ngày-đêm của shop management.

Thứ tư, **dễ feedback visual**: turn-based không cần animation phức tạp, chỉ cần icon + screen shake + particle là đủ "juicy".

---

# 4. VÒNG LẶP CỐT LÕI (CORE GAME LOOP)

## 4.1. Vòng lặp Macro (Một ngày trong game)

Mỗi ngày kéo dài khoảng 15-25 phút thực tế và đi qua 4 giai đoạn cố định:

**Sáng (Exploration phase) — 5-10 phút.** Player chọn 1 vùng đất để đi. Gameplay top-down: di chuyển, thu thập gathering nodes, gặp random encounter (combat). Có thể tìm thấy quest objective, NPC ngoài chợ, hoặc Di Vật fragment. Kết thúc khi player chọn về xưởng hoặc hết stamina.

**Trưa (Crafting phase) — 5-7 phút.** Player về xưởng, chọn nguyên liệu để rèn. Đi qua 3 phase rèn (Nung, Rèn Búa, Tôi Luyện) với mini-game/RNG. Có thể rèn 1-2 vũ khí mỗi ngày tùy stamina.

**Chiều (Shop phase) — 5-10 phút.** Mở cửa hàng. Khách vào ngẫu nhiên. Player điều khiển nhân vật để nói chuyện, bày vũ khí lên kệ, mặc cả. Pha bán hàng tự động kết thúc sau ~5-7 khách hoặc khi player đóng cửa sớm.

**Đêm (Planning phase) — 1-3 phút.** Tổng kết ngày. Trả nợ nếu đến hạn. Học công thức mới. Đọc thư từ NPC. Lưu game.

## 4.2. Vòng lặp Micro (Trong từng pha)

**Trong Exploration:** Move → Gather node hoặc Combat → Decide tiếp tục hay về.

**Trong Crafting:** Choose materials → Phase 1 mini-game → Phase 2 mini-game → Auto Phase 3 → Inspect kết quả → Quyết định bán hay test.

**Trong Shop:** Customer enters → Inspect items → Player engages → Negotiation mini-game → Sale or rejection.

**Trong Combat:** Choose action → Resolve action → Enemy turn → Repeat 3-5 lần → Win/Lose state.

## 4.3. Vòng lặp Meta (Tiến trình toàn game)

Người chơi tiến qua 3 giai đoạn lớn:

**Tutorial Arc (Ngày 1-5):** Mở khóa cơ chế cơ bản, trả Stage Nợ 1 (5,000G), thu thập 1-2 Di Vật đầu tiên.

**Mid Game Arc (Ngày 6-15):** Mở khóa các vùng khó hơn, gặp NPC VIP, thu thập 5-10 Di Vật, đối mặt Stage Nợ 2 (15,000G).

**End Game Arc (Ngày 16-25):** Săn Mastery weapons, hoàn thành quest line cuối cùng, đạt Stage Nợ 3 hoặc thắng game qua đường Di Vật (12/18 + Mảnh Cuối #158).

---

# 5. HỆ THỐNG COMBAT (CHI TIẾT)

## 5.1. Cấu trúc chung

Combat khởi đầu khi player gặp encounter trong vùng (random encounter, scripted boss, hoặc test arena). UI chuyển sang side-view giống Octopath Traveler — player ở trái, enemy ở phải.

**Stat của Player trong combat:**

| Stat | Nguồn | Vai trò |
|---|---|---|
| HP | Base 50 + items + buff | Chết = thua |
| Stamina | Base 5 + items | Chi phí dùng skill |
| ATK | Vũ khí trang bị | Damage cơ bản |
| DEF | Vũ khí + giáp | Giảm damage nhận |
| Magic | Vũ khí + items | Damage skill phép |
| Speed | Vũ khí (Prefix có Speed) | Quyết định turn order |

**Stat của Enemy:** giống player nhưng giản lược, không có Stamina.

## 5.2. Hành động mỗi lượt

Mỗi lượt, player chọn 1 trong 4 hành động:

**Tấn công thường (Basic Attack)** — Damage = ATK + 1d4. Cost 0 Stamina. Luôn dùng được.

**Skill 1 (Prefix Skill)** — Skill từ Prefix của vũ khí đang trang bị. Cost 1-2 Stamina. Effect đặc biệt.

**Skill 2 (Suffix Skill)** — Skill từ Suffix (Linh Lực) của vũ khí. Cost 1-2 Stamina. Effect đặc biệt.

**Vật phẩm (Item)** — Dùng potion, food, smoke bomb để chạy. Cost 0 Stamina nhưng tốn item.

Player có thể **đổi vũ khí** giữa lượt (mất 1 lượt) — vì player carry 3 vũ khí. Đổi vũ khí = đổi bộ skill 1+2 hoàn toàn. Đây là chiều sâu chiến thuật quan trọng.

## 5.3. Pool kỹ năng

### Skills từ Prefix (12 skills, 1 cho mỗi Prefix)

Tóm tắt vài ví dụ tiêu biểu:

| Prefix | Skill | Effect | Cost |
|---|---|---|---|
| Bén Ngọt | Slash | +50% damage | 1 STA |
| Kiên Cố | Iron Wall | +5 DEF cho 2 lượt | 1 STA |
| Nặng Tay | Crushing Blow | +100% damage, mất lượt sau | 2 STA |
| Thần Tốc | Double Strike | Đánh 2 lần | 2 STA |
| Kiệt Tác | Master's Form | +30% damage + 10 HP | 2 STA |
| Cân Bằng | Balanced Stance | +15% mọi stat 2 lượt | 1 STA |
| Tổ Nghề | Ancestral Echo | +25% damage; thưởng 50G nếu thắng | 1 STA |
| Huyền Bí | Arcane Blade | Damage = Magic không phải ATK | 1 STA |
| Cứng Như Đá | Stone Form | Miễn 1 đòn | 2 STA |
| Khí Phách | Heroic Shout | -1 enemy ATK 3 lượt | 1 STA |
| Trường Sinh | Eternal | Không mất Durability trong trận | 0 STA |
| Hào Kiệt | Hero's Edge | +50% damage; +1 Reputation nếu thắng | 2 STA |

### Skills từ Suffix Linh Lực (6 skills, 1 cho mỗi nguyên tố)

| Suffix | Skill | Effect | Cost |
|---|---|---|---|
| Hỏa | Burn | Gây Fire damage + Burn 2 turns (4 dmg/turn) | 2 STA |
| Băng | Freeze | Damage + 50% chance miss enemy turn | 2 STA |
| Sét | Chain Lightning | Damage; ignore 50% DEF | 2 STA |
| Độc | Poison Cloud | Stack Poison; 5% HP loss/turn | 1 STA |
| Thánh | Heal Pulse | Heal 30% max HP + cleanse debuff | 2 STA |
| Bóng Tối | Shadow Strike | Damage; ignore 100% DEF nếu enemy không có Holy | 2 STA |

### Skills universal (7 skills mở khóa qua progression)

| Skill | Effect | Mở khóa |
|---|---|---|
| Stance Switch | Đổi 2 vũ khí trong 1 lượt thay vì mất lượt | Ngày 5 |
| Forge Sense | Xem stats enemy ẩn | Ngày 8 |
| Ancestral Bond | Vũ khí Mastery: skill cost -1 STA | Sau khi rèn Mastery đầu tiên |
| Smith's Wisdom | +1 Stamina max | Đạt Reputation 5 |
| Endurance | +20 HP max | Đạt Reputation 7 |
| Counter | Phản đòn nếu DEF > enemy ATK | Khi sở hữu 5 Di Vật |
| Last Stand | HP < 20% → +50% damage | Khi sở hữu 10 Di Vật |

## 5.4. AI Enemy

AI đơn giản dựa trên enemy archetype, không cần ML hay behavior tree phức tạp:

**Aggressive (Sói, Bandit):** Luôn tấn công thường. Nếu HP < 30%, có 50% chance chạy.

**Defensive (Người Đá, Vệ Binh):** Defend 1 lượt → Attack 2 lượt → Defend 1 lượt.

**Caster (Ma Rừng, Pháp Sư):** Skill phép mỗi 2 lượt; lượt khác attack thường.

**Boss (Rồng, Hổ Trắng):** Telegraph hành động lớn 1 lượt trước (UI hiện icon). Có 2-3 phase HP threshold.

Enemy hành động được hiện trên UI **trước khi player chọn** (nhờ Speed stat thấp hơn) — cho phép player tactical.

## 5.5. Win/Lose

**Win:** Enemy HP = 0. Reward: gold, item drop, EXP (nếu có hệ thống level).

**Lose (HP = 0):** Player bị "knocked out", trả về xưởng, mất 30% gold mang theo, mất 1 ngày in-game (ngày kết thúc ngay). Không Game Over thực sự.

**Run:** Player có thể chạy trận thường (không boss) bằng Smoke Bomb item hoặc skill Bóng Tối.

## 5.6. Encounter design

Mỗi vùng có ~5-8 enemy types. Encounter rate 1 trận / 30-45 giây di chuyển. Boss encounter là scripted, gắn với quest. Tổng cộng game có ~30 enemy unique + 6 boss (mỗi vùng 1 boss).

---

# 6. HỆ THỐNG RÈN (FORGING)

Đây là **USP cốt lõi** — cần đầu tư polish nhất.

## 6.1. Phase 1: Nung Thép

UI: lò rèn ấm với thanh nhiệt độ. Player nhấn giữ phím để bơm ống bễ, thanh nhiệt độ tăng. Có "sweet spot" — dừng đúng → kết quả tốt.

Mini-game cụ thể:
- Thanh nhiệt 0-100, sweet spot 60-80
- Nhả phím ở 60-80 → Cam (+20% stats gốc)
- Nhả phím ở 80-100 → Vàng Kim (+40%)
- Nhả phím dưới 60 hoặc quá 100 → Đỏ (-30%) hoặc Vàng = (no change)
- Khó nhanh dần khi player có Reputation cao (thanh chạy nhanh hơn)

Một số nguyên liệu tự bypass phase này: Thép Hỏa Sơn (#12) → tự động Cam.

## 6.2. Phase 2: Rèn Búa

UI: đe rèn với phôi. Player nhấn phím theo nhịp — 5 nhát búa liên tục. Mỗi nhát có timing window, hit "Perfect" → +1 điểm, "Good" → 0, "Miss" → -1.

Tổng điểm 5 nhát = -5 đến +5, mapping sang bảng 2D6 cũ:

| Tổng điểm | Map sang 2D6 | Kết quả |
|---|---|---|
| -5, -4 | 2 | Phản Chủ |
| -3, -2 | 3-4 | Curse khác |
| -1 | 5 | Curse nhẹ |
| 0 | 6-7 | Prefix thường |
| +1 | 8 | Prefix tốt |
| +2 | 9 | Prefix Kiệt Tác/Cân Bằng |
| +3 | 10 | Prefix Tổ Nghề/Huyền Bí |
| +4 | 11 | Prefix Cứng/Khí Phách |
| +5 | 12 | PERFECT (Trường Sinh/Hào Kiệt) |

Đây là điểm mấu chốt: **kỹ năng người chơi (rhythm timing) thay thế dice**. Vẫn có RNG nhẹ (timing window biến thiên ngẫu nhiên), nhưng player giỏi sẽ rèn ra vũ khí tốt hơn theo thời gian.

Khi player rèn nhiều, họ sẽ "vào nhịp" và phase này trở thành **moment of flow** — đây chính là cảm xúc thợ rèn mà game muốn tạo.

## 6.3. Phase 3: Tôi Luyện

Tự động — không có mini-game. Linh Lực bạn đã chọn từ Phase Thu Thập trở thành Suffix.

Tuy nhiên, phase này có UI animation **giàu cảm xúc**: vũ khí được nhúng vào nguyên tố tương ứng (lửa cho Hỏa, sương cho Băng, sét đánh cho Sét...) — đây là moment of arrival, không cần mechanics nhưng cần feel tốt.

## 6.4. Kết quả vũ khí

Vũ khí hoàn chỉnh hiển thị card UI giống board game:

```
KIẾM HUYỀN BÍ THIÊU ĐỐT ★ MASTERY
ATK: 16  DEF: 0  Magic: 6
Skill 1 (Prefix Huyền Bí): Arcane Blade — damage = Magic
Skill 2 (Suffix Hỏa): Burn — Fire damage + Burn 2 turns
Durability: 50/50
Giá thị trường ước tính: 2,000-2,500G
```

## 6.5. Mastery Test

Nếu player muốn thăng hạng vũ khí lên Mastery, họ phải đem nó đánh thắng 1 boss test trong vùng tương ứng. Đây là decision risky:

- Thắng → vũ khí lên Mastery, stats × 1.5, giá bán × 2.5-3
- Thua → vũ khí mất 30% Durability, có 30% nhận Curse Affix

---

# 7. HỆ THỐNG CỬA HÀNG & MẶC CẢ

## 7.1. Layout cửa hàng

Phòng nhỏ (16x12 tile) với:
- 3 kệ trưng bày (mỗi kệ 1 ô vũ khí)
- 1 quầy thu ngân (player đứng ở đây khi mặc cả)
- 1 cửa ra vào (khách đi vào)
- Tường + decoration unlock theo Reputation

## 7.2. Quy trình bán hàng (Recettear-style)

Tham khảo chặt chẽ từ Recettear — player **không bị gắn sau quầy**, mà tự do di chuyển trong shop như một nhân vật game thật sự.

### Bước 1 — Bày hàng trước khi mở cửa

Trước khi nhấn "Mở Cửa", player đặt vũ khí từ kho lên 3 ô kệ trưng bày. Đây là quyết định chiến lược: bày vũ khí đắt tiền để câu khách VIP, hay bày vũ khí rẻ để xoay vòng nhanh? Có thể đổi hàng trên kệ ngay cả khi shop đang mở (tốn 1–2 giây animation).

### Bước 2 — Khách vào, player chủ động tiếp cận

Khi mở cửa, timer buổi chiều bắt đầu (~10 phút thực). Khách vào ngẫu nhiên, mỗi 30–90 giây 1 người. Khách AI tự di chuyển, dừng trước các kệ, quan sát. **Lúc này player phải chủ động đi đến gần khách** — giống hệt Recettear.

Khi player áp sát 1 khách đang đứng nhìn kệ → popup nhỏ hiện ra cho phép **"Gợi Ý"** (recommend item). Nếu item trên kệ gần đó đúng tag sở thích của khách → khách phản ứng tốt, Mood tăng nhẹ trước khi mặc cả. Nếu sai tag hoàn toàn → Mood giảm nhẹ, khách ít có khả năng mua hơn.

Player có thể bỏ qua không tiếp cận — khách sẽ tự quyết định có mua không, nhưng tỷ lệ mua thấp hơn và giá chốt thấp hơn.

### Bước 3 — Khách đưa ra giá TRƯỚC (không phải player)

Khi khách quyết định mua, họ bước lại gần player và **tự đưa ra một mức giá đề nghị** — luôn thấp hơn giá thị trường thật của vũ khí, dao động 60–80% tùy personality. Đây là điểm khác biệt cốt lõi so với thiết kế cũ: **khách chủ động trả giá, không phải player hét giá trước**.

```
[Hiệp Khách Lang Bạt tiến lại gần]
"Cây kiếm này... trông ổn đấy. Tôi trả 800G."
[Giá thị trường thật của vũ khí: ~1,100G]
```

### Bước 4 — Player chọn hệ số nhân để counter

Player không nhập số tiền thủ công. Thay vào đó, một **thanh hệ số nhân** xuất hiện với các mốc:

```
[×1.0]  [×1.1]  [×1.2]  [×1.3]  [×1.4]  [×1.5]
  880G    968G   1,056G  1,144G  1,232G  1,320G
```

Player dùng phím trái/phải (hoặc scroll) để chọn mức, rồi xác nhận. Mỗi mức hiển thị ngay số tiền tương ứng dựa trên giá đề nghị của khách.

**Mood Gauge** hiển thị ngay bên cạnh mặt khách — một vòng tròn biểu cảm thay đổi real-time khi player kéo thanh hệ số. Kéo lên cao → mặt khách dần từ vui sang bực. Kéo về thấp → mặt khách dịu lại.

### Bước 5 — Khách phản ứng theo Mood & Personality

Kết quả phụ thuộc vào **personality type** của khách (ghi trên thẻ NPC) kết hợp với mức hệ số player chọn:

| Hệ số | Khách dễ tính (Patience cao) | Khách khó tính (Patience thấp) |
|---|---|---|
| ×1.0 | Mua ngay, hài lòng | Mua ngay |
| ×1.1–×1.2 | Mua, khen hàng tốt | Ngần ngại nhưng mua |
| ×1.3 | Counter lại ×1.1 | Counter lại ×1.0 hoặc bỏ |
| ×1.4 | Counter lại ×1.0, Mood giảm | Bỏ đi |
| ×1.5+ | Bỏ đi | Bỏ đi ngay lập tức |

Khi khách **counter lại**, player lại được chọn hệ số lần nữa. Mỗi vòng counter làm Patience -1. Hết Patience → khách bỏ đi dù giá đã hợp lý.

### Bước 6 — Kết thúc giao dịch

Sale chốt → tiền cộng vào, vũ khí rời kệ, khách cảm ơn và ra về (có animation nhỏ). Reputation có thể tăng tùy personality khách và loại vũ khí bán được.

Khách bỏ đi → không mất gì ngoài thời gian. Vũ khí vẫn còn trên kệ cho khách tiếp theo.

**Có thể phục vụ nhiều khách cùng lúc** — trong lúc đang mặc cả với khách A, khách B vẫn tiếp tục ngắm kệ. Nếu bỏ mặc quá lâu, khách B tự rời đi.

## 7.3. Mood Gauge & Personality Types

Mood Gauge là trái tim của hệ thống bán hàng — thay thế hoàn toàn "thanh 4 vùng màu" của thiết kế cũ.

**Hiển thị:** Vòng tròn nhỏ phía trên đầu khách, có 5 mức biểu cảm:

```
😄 Rất vui   → Mua ngay với bất kỳ mức hợp lý
😊 Vui       → Mua hoặc counter nhẹ
😐 Trung tính → Counter, Patience -1
😠 Khó chịu  → Counter mạnh hoặc bỏ
😤 Tức giận  → Bỏ đi, không thể cứu vãn
```

Mood bắt đầu ở mức **😊 Vui** nếu player đã gợi ý đúng item trước đó, hoặc **😐 Trung tính** nếu khách tự tìm đến.

**5 Personality Types ảnh hưởng Mood:**

| Type | Đặc điểm | Ví dụ NPC |
|---|---|---|
| **Hào Phóng** | Mood ít bị ảnh hưởng, chấp nhận ×1.3 dễ dàng | Đại Tướng #104, Hội Đồng #110 |
| **Thực Dụng** | Mood thay đổi đều, counter 1 lần rồi chốt | Thương Nhân #105, Thợ Săn #94 |
| **Kỹ Tính** | Mood giảm nhanh, chỉ chấp nhận ×1.1 tối đa | Trùm Thích Khách #88, Vệ Binh #103 |
| **Xúc Cảm** | Mood tăng mạnh nếu đúng sở thích, giảm mạnh nếu sai | Đứa Trẻ Mồ Côi #108, Đạo Sĩ Phái Lửa #91 |
| **Bí Ẩn** | Mood không hiện ra — player phải đoán | Kẻ Lậu Bí Ẩn #106, Lái Buôn Di Vật #107 |

Mỗi khách có Budget cứng (không thể bán quá số này dù mặc cả thành công) và Patience (số vòng counter tối đa). Hai thông tin này **không hiển thị trực tiếp** — player học qua kinh nghiệm và Affinity.

## 7.4. Mass production vs. craft riêng

Player có 2 chiến lược:

**Mass production:** Rèn 2-3 vũ khí cơ bản/ngày, bán cho khách thường, dòng tiền ổn định.

**Craft riêng:** Đầu tư 1-2 ngày rèn 1 vũ khí Mastery, bán cho VIP với giá cực cao.

Game balance để cả hai đều viable, tùy phong cách player.

---

# 8. HỆ THỐNG VÙNG ĐẤT & KHÁM PHÁ

## 8.1. Tổng quan 6 vùng

| Vùng | Theme | Mở khóa | Nguyên liệu chủ yếu | NPC VIP |
|---|---|---|---|---|
| Đồng Mây Trắng | Thảo nguyên gió | Default | Sắt, da, bạc | Cô Lộng Gió |
| Rừng Trăm Hồn | Rừng linh khí | Ngày 3 | Gỗ, pha lê | Tướng Bóng Rừng |
| Núi Than Đỏ | Núi lửa ngủ | Ngày 6 | Quặng, mithril | Gã Khét Lửa |
| Bãi Cát Thần Vàng | Sa mạc cổ | Ngày 9 | Cát, hổ phách | Ông Cát Thần |
| Thành Ngọc Bích | Thành phồn hoa | Reputation 5 | Thép trắng, ngọc | Bà Thiên Kim |
| Làng Tổ Nghề | Làng cổ thiêng | Quest cuối | Di vật, công thức | Lão Thôi Cổ |

## 8.2. Cấu trúc một vùng

Mỗi vùng là một map ~50x40 tile (đủ lớn để không cảm thấy lặp, đủ nhỏ để không lost). Có:

- 8-12 gathering nodes (NL respawn sau 2-3 ngày)
- 1 gathering node hiếm (Rarity 1, respawn 5-7 ngày)
- 5-8 enemy spawn point
- 1 boss arena (cuối map)
- 2-3 NPC ngoài chợ (quest giver hoặc thương nhân)
- 1 shrine/landmark (có thể tương tác — quest hint)

## 8.3. Stamina & Travel

Player có **Stamina Travel** (riêng với Combat Stamina). Mỗi vùng 1 ngày = consume Stamina theo thời gian. Khi cạn → ép về xưởng.

Stamina max tăng theo Reputation và items (food). Đây là cơ chế **soft time-limit** giúp pacing.

## 8.4. Random vs. scripted events

Vùng có cả random events (gặp thương lái lang thang bán đồ giá cao, gặp boy mất đồ tặng quest) và scripted events (gắn với main quest progression).

---

# 9. HỆ THỐNG NHÂN VẬT (PLAYER CHARACTER)

## 9.1. Tạo nhân vật

Đầu game, player chọn:

- **Tên** (default: tùy bạn — VD "Minh", "An", "Hà")
- **Avatar** (4-6 portrait options, không có gameplay impact)
- **Background story** (3 lựa chọn, ảnh hưởng nhỏ Tutorial dialogue):
  - "Cháu của thợ rèn Lò Thiêng cũ" — bonus 500G start
  - "Học việc dở dang ở Thành Ngọc Bích" — bắt đầu Reputation 1
  - "Người ngoài cuộc tò mò" — bonus 1 NL Rarity 3 random start

3 background không tạo class khác nhau — chỉ flavor text + bonus nhỏ. Đây là quyết định scope-conscious: **không tạo branching content khổng lồ** cho mỗi background.

## 9.2. Stats & Progression

Player không có Level (RPG-style). Thay vào đó, có 3 trục progression:

**Reputation (0-10):** Tăng khi bán vũ khí cho VIP, hoàn thành quest, sự kiện đặc biệt. Mở khóa region, NPC, recipe.

**Smithing Mastery (0-100):** Tăng mỗi khi rèn xong 1 vũ khí. Ảnh hưởng độ khó Phase 1 (skill ceiling) và unlock skill universal.

**Quest Progress:** Số Di Vật / 18. Đây là "level visible" cho player.

## 9.3. Inventory

- **Tay (Hand) limit:** 12 slot trong dungeon (nguyên liệu thu nhặt). Khi đầy, force return về xưởng.
- **Kho (Warehouse) ở xưởng:** Vô hạn slot. Tổ chức theo type (Material / Force / Weapon / Consumable / Quest).
- **Equipment slots:** 3 vũ khí (carry combat) + 1 giáp + 1 trang sức (sau khi unlock).

---

# 10. HỆ THỐNG NPC

## 10.1. Phân loại NPC

| Loại | Số lượng | Vai trò |
|---|---|---|
| VIP (boss/quest givers) | 6 | Mỗi vùng 1 — Cô Lộng Gió, Tướng Bóng Rừng, Gã Khét Lửa, Ông Cát Thần, Bà Thiên Kim, Lão Thôi Cổ |
| Antagonist | 2 | Bà Trùm Hắc Nguyệt (chủ nợ), Lão Gà Chọi (collector) |
| Recurring customers | 12 | Khách đặc biệt xuất hiện nhiều lần, có quest line riêng (ví dụ Đại Đạo Sĩ #92, Đại Tướng #104, Hội Đồng Thợ Rèn #110, Đứa Trẻ Mồ Côi #108) |
| Regular customers | 30+ | Khách thường, random pool, không quest |
| Background NPC | 10-15 | Trong shop town, talk-to-only, không bán mua |

## 10.2. NPC Schedule

VIP NPCs có **schedule** — họ chỉ xuất hiện ở vùng/giờ cố định. Ví dụ:
- Cô Lộng Gió: chỉ ở Đồng Mây Trắng, sáng và chiều
- Đại Đạo Sĩ: lang thang giữa Núi Than Đỏ và Rừng Trăm Hồn
- Bà Trùm Hắc Nguyệt: chỉ xuất hiện tại shop khi đến Cơn Nợ Tháng

Recurring customers ngẫu nhiên hơn — có 30-50% chance xuất hiện mỗi ngày dựa trên Reputation và sự kiện.

## 10.3. Affinity & Relationships

Mỗi recurring NPC có Affinity 0-100 với player. Tăng qua:
- Bán đúng loại vũ khí họ thích (+5)
- Tặng quà (item phù hợp tag — +10 đến +20)
- Hoàn thành quest cá nhân (+30)

Affinity cao mở khóa:
- Recipe đặc biệt
- Discount khi mua nguyên liệu từ NPC
- Quest line cá nhân (10 NPCs có 1 unique quest mỗi)
- Cutscene cuối game

## 10.4. NPC Voice & Personality

Mỗi NPC chính có:
- Portrait pixel art (16-24 expression sprites)
- Voice "barks" (1-2 từ tiếng Việt giả ngữ — thử nghiệm AI voice acting nếu budget cho phép, hoặc text-only như Stardew)
- Dialogue tree đơn giản: 3-5 nhánh trong đa số tình huống

Tổng số dialogue lines ước tính: ~3,000 lines. Đây là content biggest task — solo dev nên viết script song song với code.

---

# 11. HỆ THỐNG QUEST

## 11.1. Phân loại Quest

**Main Quest (Story spine):** ~10 quest lớn, tạo thành xương sống câu chuyện. Mở khóa vùng mới, advance plot, dẫn đến win condition.

**Di Vật Quest:** 18 quest — mỗi Di Vật là 1 quest cá nhân với điều kiện cụ thể (xem Phụ Lục). Hoàn thành để thắng game.

**NPC Personal Quest:** ~10 quest cá nhân từ NPC recurring — mở khóa khi Affinity đủ cao.

**Daily/Weekly Quest:** Random tasks (mỗi tuần 2-3) như "Mang 5 Quặng Sắt cho Cô Lộng Gió", "Bán 3 vũ khí Hỏa trong tuần". Reward nhỏ nhưng đều đặn.

**Hidden Quest:** ~5 quest ẩn, kích hoạt qua tương tác environment (đọc tablet, tìm secret door, etc.) hoặc combination of actions. Reward: Di Vật ẩn hoặc lore lớn.

## 11.2. Quest Structure

Mỗi quest có:

```
QUEST: [Tên]
Giver: [NPC]
Trigger: [Khi nào bắt đầu — vào vùng, gặp NPC, đạt event]
Objectives:
  1. [Step 1]
  2. [Step 2]
Hint: [Gợi ý ẩn nếu player kẹt]
Reward: [Gold / Item / Reputation / Di Vật]
Failure conditions: [Nếu có — VD timeout, kill wrong NPC]
```

Hầu hết quest **không có timer** — player có thể quay lại làm sau. Trừ vài quest gắn với event game-wide (Cơn Nợ Tháng).

## 11.3. Quest UI

- Journal (mở bằng J) chia tab: Main / Side / Daily / Hidden
- Compass HUD chỉ hướng quest current target
- Quest marker trên minimap (có thể tắt cho hardcore players)

## 11.4. Quest Examples (3 mẫu)

**Main Quest #1 — "Tiệm Cũ":** Khám phá xưởng kế thừa, gặp Bà Trùm Hắc Nguyệt, ký hợp đồng nợ Stage 1. Tutorial steps: di chuyển, nhặt nguyên liệu cơ bản, rèn vũ khí đầu tiên, bán cho khách đầu tiên. Reward: 500G, mở khóa Pha Bán Hàng.

**Di Vật Quest — "Búa Tổ Đồng Cỏ" (#141):** Cô Lộng Gió yêu cầu rèn 1 vũ khí Prefix Kiệt Tác hoặc Tổ Nghề (tức Phase 2 đạt 9 hoặc 10). Mang đến cô để chứng minh. Cô giữ Búa Tổ trong 1 chiếc rương dưới gốc cây cổ. Reward: Di Vật #141 + recipe đặc biệt.

**NPC Personal Quest — "Đứa Trẻ Mồ Côi và Giấc Mơ Kiếm Sĩ":** Đứa Trẻ Mồ Côi (#108) sau 5 lần mua hàng giá rẻ sẽ kể chuyện anh trai bị bandits giết, muốn học cầm kiếm. Player chọn: Tặng kiếm cũ + dạy → Affinity +50 + reputation +1. Hoặc từ chối → -10 affinity. Quest line tiếp tục 3 ngày sau với boss fight chống bandit gang.

---

# 12. HỆ THỐNG TUTORIAL

## 12.1. Triết lý

Tutorial **không phải** một segment cô lập đầu game. Nó là **3-4 ngày đầu game trong story** với hand-holding nhẹ, rồi tự nhiên fade out.

Tham khảo: Stardew Valley dạy player qua 3-5 ngày đầu mà không feel như tutorial. Tránh: Recettear (info dump dày đặc trong 30 phút đầu).

## 12.2. Cấu trúc Tutorial 3 ngày

**Ngày 1 — Cơ bản di chuyển + Shop:**
- Bà Trùm Hắc Nguyệt giới thiệu story và nợ (cutscene 2 phút)
- Đi đến Đồng Mây Trắng (vùng đầu, có hand-holding) — học gather node
- Combat đầu (Hình Nộm Rơm, scripted) — học turn-based UI
- Về xưởng — học Crafting với Phase 1 + Phase 2 mini-game (slowed-down version)
- Mở shop — 1 khách scripted (Hiệp Khách Lang Bạt #81), bán bằng giá cố định
- Trail tip: "Ngày mai, Bà Trùm sẽ thăm. Trả 500G hoặc xin gia hạn."

**Ngày 2 — Khám phá thực sự + Mặc cả:**
- Bà Trùm xuất hiện đầu ngày, gia hạn nợ
- Player tự chọn vùng (default Đồng Mây mở, Rừng Trăm Hồn unlock)
- Combat thật (random encounter)
- Crafting với full mini-game (timing thật, có thể fail → Curse, dạy bài học)
- Shop với 3-4 khách — pha mặc cả thực tế đầu tiên (UI hint xuất hiện 1-2 lần)

**Ngày 3 — Hoàn tất learning:**
- Lão Gà Chọi đến lần đầu — học event system
- Mở khóa Quest Journal lần đầu (cốt cần đến slot thứ 3 mới mở)
- Hint về Di Vật system (lore drop từ Cô Lộng Gió)

**Sau ngày 3:** Tutorial hint hệ thống tắt. Player tự do.

## 12.3. Contextual hints (always-on)

- New mechanic xuất hiện lần đầu → tooltip popup giải thích, có nút "Đừng hiện lại"
- Rèn lần đầu với loại nguyên liệu đặc biệt → hint nhỏ
- Gặp enemy archetype mới → tip box trước combat (skip được)

## 12.4. Optional advanced tutorial

Trong xưởng có "Bí Kíp Rèn" — book object. Đọc → menu in-game về advanced mechanics (Mastery, Skill combos, NPC affinity). Player nâng cao tự đọc, không ép.

## 12.5. Difficulty selection

Đầu game (sau intro) cho chọn 3 difficulty:

| Level | Khác biệt |
|---|---|
| Story (Easy) | Phase 2 timing window rộng hơn 50%; combat damage giảm 30% |
| Normal | Default |
| Hardcore | Phase 2 timing window hẹp hơn 30%; permadeath weapons (broken = mất luôn) |

Player có thể đổi difficulty bất kỳ lúc nào trừ Hardcore (lock).

---

# 13. HỆ THỐNG VẬT PHẨM

## 13.1. Phân loại item

Dựa trên 158 thẻ board game, rút gọn còn ~80 items cho PC version:

| Loại | Số lượng PC | Tóm tắt |
|---|---|---|
| Nguyên Liệu Thô | 24 | 4 mỗi vùng × 6 vùng (rút từ 30) |
| Linh Lực | 18 | 3 rarity × 6 nguyên tố (rút từ 20) |
| Phôi Vũ Khí | 12 | Giữ nguyên |
| Affix (Prefix + Curse) | Internal | Không phải item, là property của vũ khí |
| Vũ Khí Hoàn Chỉnh | Generated | Procedural từ Phôi + NL + Affix + Suffix |
| Consumable | 12 | Potion, food, smoke bomb (mới — chưa có ở board game) |
| Quest item | 14 | Di Vật + special quest items |
| Recipe | 10 | Học công thức đặc biệt từ NPC |

Tổng item types unique: ~80. Nhưng **vũ khí hoàn chỉnh** là procedural — số lượng combination thực tế lên đến hàng nghìn.

## 13.2. Item cards UI

Mỗi item có:
- Icon 32×32 pixel
- Name + flavor text 1 dòng
- Stats (cho NL và Phôi)
- Effect description
- Use button (cho consumable)

UI inventory dạng grid 6 cột, scroll dọc, filter theo loại.

## 13.3. Consumable system (mới)

Đây là thêm so với board game, để combat có thêm chiều:

| Consumable | Effect | Giá |
|---|---|---|
| Bánh Mật | +20 HP | 100G |
| Bình Sương | +1 Stamina | 150G |
| Trà Thảo Mộc | Cleanse 1 debuff | 200G |
| Khói Trốn | Escape combat thường | 300G |
| Đá Hồi Sinh | Hồi sinh 1 lần với 50% HP | 1,500G |
| Tro Lò Thiêng (mini) | Phase 2 +1 Perfect timing | 500G |

Player crafts hoặc mua từ NPC chuyên (Bà Bán Thuốc, mỗi vùng có 1).

## 13.4. Rarity tiers

5 tier: Phổ Thông (xám) → Thường (trắng) → Hiếm (xanh) → Cực Hiếm (tím) → Huyền Thoại (vàng).

Vũ khí Mastery + Perfect Prefix + Suffix Rarity 1 = Huyền Thoại tier (cực hiếm, ~5-10 lần per playthrough).

## 13.5. Durability

Vũ khí có Durability 50/50 (default). Mỗi combat dùng skill = -1 Durability. Hết → vũ khí "broken", giảm 50% stats. Sửa ở xưởng: 200G + 1 nguyên liệu cùng loại nguyên liệu chính.

Vũ khí có Prefix Trường Sinh: không mất Durability — cực giá trị end game.

## 13.6. Equipment Slots

3 vũ khí trang bị (carry combat) + 1 giáp + 1 phụ kiện (sau ngày 10 unlock).

Giáp: Giảm damage nhận, có 6 loại tương ứng 6 vùng. Mua hoặc craft (sau khi unlock).

Phụ kiện: Bonus passive (VD "+1 Stamina", "+5% Gold drop", "+10% Mastery success rate"). Mua từ NPC hoặc reward quest.

---

# 14. TÍNH NĂNG CHÍNH (TÓM TẮT)

Tổng kết 8 trụ cột tính năng:

**Crafting 3-Phase với Skill-based Mini-game.** Phase 1 timing meter, Phase 2 rhythm action, Phase 3 auto. Vũ khí ra mang theo skill từ Prefix + Suffix.

**Turn-based Combat với 25 Skills.** Player carry 3 vũ khí = 6 active skills. AI enemy đơn giản, telegraph hành động. 3-5 lượt mỗi trận.

**Shop Management với Mặc Cả mini-game.** Customer AI walking, Patience system, negotiation slider. Real-time clock cho buổi chiều.

**6 Vùng Đất với gathering + combat exploration.** Mỗi vùng layout riêng, NPC riêng, kinh tế riêng. Mở khóa progressive.

**Quest System đa tầng.** 10 main + 18 Di Vật + 10 NPC personal + daily + 5 hidden. Compass + journal navigate.

**NPC Affinity & Schedule.** 30 NPCs có schedule, 12 recurring có affinity 0-100, mở khóa quest cá nhân.

**Reputation 0-10 + Smithing Mastery 0-100.** Hai trục progression không phải level RPG truyền thống.

**Tutorial Diegetic 3 ngày.** Học qua story, không pop-up tutorial dày đặc.

---

# 15. KINH TẾ & TIẾN TRÌNH

## 15.1. Đường cong tiền

Player bắt đầu: 2,000G + nợ 5,000G.

Ngày 5: Cần ~5,000G để trả Stage 1. Đường cong dự kiến (Normal difficulty):

| Ngày | Tiền dự kiến | Notes |
|---|---|---|
| 1 | 2,000-3,500G | Bán vũ khí đầu |
| 3 | 4,000-6,000G | Đủ để trả Stage 1 |
| 5 | 6,000-10,000G | Sau khi trả Stage 1 |
| 10 | 12,000-18,000G | Tích lũy cho Stage 2 |
| 15 | Variable | Trả Stage 2 (15,000G) |
| 20 | 20,000G+ | Hướng đến Stage 3 |
| 25 | 30,000G+ | Trả Stage 3 |

## 15.2. Sink & Source

**Sources:** Bán vũ khí (chính), quest reward, monster drop, sự kiện tốt.

**Sinks:** Mua nguyên liệu, mua Linh Lực, sửa vũ khí, học recipe, trả nợ, mua giáp/phụ kiện, mua consumable.

Game balance để player luôn cảm thấy "đủ tiền cho hôm nay nhưng phải tính cho ngày mai". Không bao giờ overflow tiền (boring) hoặc starve (frustrating).

## 15.3. Progression Gates

| Gate | Yêu cầu mở | Mở ra cái gì |
|---|---|---|
| Vùng 2 (Rừng) | Trả Stage 1 nợ | Map mới, NPC mới |
| Vùng 3 (Núi) | Reputation 3 + Quest "Tin Đồn Núi Lửa" | Map + recipe Hỏa cao cấp |
| Vùng 4 (Cát) | Reputation 5 | Map + Đạo Sĩ cao cấp |
| Vùng 5 (Thành Ngọc) | Reputation 7 + Quest VIP | Map + Vệ Binh + giáp cao cấp |
| Vùng 6 (Làng Tổ) | 8 Di Vật + Reputation 8 | Map + Lão Thôi Cổ + endgame |

---

# 16. KẾT THÚC & REPLAYABILITY

## 16.1. 4 Endings

**Ending A — "Tiếng Gọi Được Đáp Lời" (True Ending):** Đủ 12/18 Di Vật + sở hữu #158 + Reputation 10. Lò Thiêng phục hồi, player được công nhận thợ rèn truyền thống.

**Ending B — "Người Thợ Tự Do":** Trả hết nợ Stage 3 + Reputation 7+ + không đủ Di Vật. Player có shop thành công nhưng không trở thành huyền thoại.

**Ending C — "Bóng Đêm Lò Cũ":** Tích nợ 2 lần liên tiếp với Lão Gà Chọi → bị tịch thu shop. Game continues nhưng với route ngầm: làm việc cho Bà Trùm Hắc Nguyệt như "thợ rèn ngầm". Mở khóa các quest illegal mới.

**Ending D — "Phá Sản":** 3 ngày liên tiếp tiền = 0. Player bị đuổi khỏi xứ. Game over thật sự.

Mỗi ending có epilogue cutscene riêng (~2 phút) + leaderboard score.

## 16.2. New Game+ (post v1.0 nếu có)

Sau khi clear, có thể bắt đầu lại với:
- Toàn bộ recipe đã học
- Reputation 3 starting
- 5,000G starting
- Difficulty cứng hơn (boss damage +30%)

## 16.3. Replayability factors

- 3 background → 3 starting bonus khác nhau
- 4 endings → ít nhất 4 playthrough
- Build vũ khí khác nhau (Hỏa vs Băng, Tank vs DPS) = combat khác nhau
- Achievement system (50+ achievements)
- Random events biến mỗi ván chơi khác nhau

---

# 17. HƯỚNG ĐI NGHỆ THUẬT & ÂM THANH

## 17.1. Visual style

**Pixel art 2D, isometric ¾ angle.** Sprite hero 32×48px, environment tiles 32×32. Animation 4-8 frames per action. Color palette ấm với accent màu vùng (đỏ Núi Than, xanh Rừng, vàng Cát).

**UI design:** Khung sách cổ + paper texture. Font tiêu đề: serif Việt-style (gợi vibe "thư pháp nhẹ"). Font body: rounded sans-serif dễ đọc.

**Lighting:** Day/night cycle ảnh hưởng tonality (sáng warm, chiều orange-pink, tối deep blue + lantern accents).

## 17.2. Music

**8-10 tracks chính:**
- Main theme (xưởng) — solemn, hopeful
- 6 region themes (mỗi vùng 1 motif)
- Combat theme — tense but melodic
- Boss theme — escalation
- Shop theme — light, busy
- Night theme — calm, reflective

Style: Acoustic instruments + light synth, gợi Folk-Asian-Fantasy. Tham khảo: Fantasian OST, Ori soundtracks.

Solo dev option: License sử dụng từ Fesliyan Studios hoặc OpenGameArt nếu không tự compose. Hoặc thuê freelance composer 1 lần ($1,500-3,000 USD cho 10 tracks).

## 17.3. Sound effects

~60-80 SFX tổng cộng:
- Footsteps (3 surface types)
- Combat hits (3 weapon types)
- Forge sounds (hammer, fire, quench)
- UI clicks
- NPC dialogue blips
- Ambient (wind, fire crackle, market chatter)

Solo dev tip: Freesound.org + ZapSplat đủ cho most SFX.

## 17.4. Voice Acting

**Không full VA** (quá đắt cho solo dev). Thay vào:
- "Mood barks" 1-2 từ cho NPC chính (~50 lines × 6 NPC = 300 lines, $500-1000 freelance)
- Hoặc text-only như Stardew Valley (zero VA cost)

Recommend: Text-only cho v1.0, có thể add VA cho DLC/Update sau.

---

# 18. CÂN NHẮC KỸ THUẬT & PHẠM VI SOLO DEV

## 18.1. Tech stack đề xuất

**Engine:** Godot 4.x — Free, 2D-first, GDScript dễ học, export multi-platform tốt.

Lý do không chọn Unity: License risk gần đây + overhead cho 2D project. Không chọn Game Maker: Less powerful state management. Không chọn raw code: Solo dev nên đứng trên vai engine.

**Language:** GDScript (Godot native) cho gameplay; có thể dùng C# nếu cần performance (combat AI hoặc inventory queries).

**Version control:** Git + GitHub (private repo).

**Asset pipeline:** Aseprite cho pixel art, Tiled cho map (Godot import tốt).

**Save system:** JSON file local (đơn giản, dễ debug). Encrypt nếu lo speedrun cheating.

## 18.2. Architecture đề xuất

**Pattern:** State machine cho game flow (Day → Phase → Sub-phase).

**Data-driven design:** Items, NPCs, Quests, Skills đều trong .tres resource files, không hard-code. Solo dev có thể edit content bằng spreadsheet → export sang resource.

**Modular scenes:** Mỗi region là 1 scene độc lập. Mỗi NPC là 1 prefab/scene. Combat là 1 scene activate khi cần.

**Dependency injection:** Avoid global singletons trừ khi thực sự cần (Audio, Save, EventBus).

## 18.3. Risks (solo dev specific)

**Risk 1 — Content writing burnout.** ~3,000 dialogue lines + 80 item descriptions + 25 quest texts. Mitigation: Viết content song song với code, mỗi tuần 1 batch. Outsource một phần nếu budget cho phép.

**Risk 2 — Art bottleneck.** Solo dev không phải artist. Mitigation: Hire commissioned pixel art (~$3,000-5,000 USD cho character + tilesets), giữ scope animation đơn giản.

**Risk 3 — Combat balance.** 25 skills × variable enemies = nightmare cân bằng. Mitigation: Spreadsheet trước khi vào engine. Playtest gắt sau 6 tháng.

**Risk 4 — Scope creep.** Easy to add "just one more feature". Mitigation: GDD này là contract với chính mình. Cứ 2 tuần review GDD, refuse mọi feature mới trừ khi cut feature khác.

**Risk 5 — Burnout.** 18-24 tháng solo dev là marathon. Mitigation: Schedule 1 tuần off mỗi 2 tháng. Có người playtest từ tháng 6 trở đi.

## 18.4. Multi-platform

Target launch: PC (Steam) + có thể Switch port sau.

Godot export: Windows, Mac, Linux out-of-the-box. Switch cần dev kit + Nintendo approval (post-launch consideration).

---

# 19. LỊCH TRÌNH PHÁT TRIỂN ĐỀ XUẤT

## 19.1. Phase chính

| Phase | Tháng | Output |
|---|---|---|
| Pre-production | M1-M2 | GDD final, prototype rèn + combat |
| Vertical slice | M3-M5 | 1 vùng playable, 1 ngày complete loop |
| Content production | M6-M14 | 5 vùng còn lại, tất cả NPC, all quest |
| Polish & balance | M15-M18 | Playtest, balance, polish |
| Beta & marketing | M19-M21 | Closed beta, demo Steam Next Fest |
| Launch prep | M22-M24 | Bug fix, localization, release |

**Tổng dự kiến: 24 tháng.** Solo dev part-time có thể x1.5-2.

## 19.2. Milestones quan trọng

- **M2 End:** Playable prototype với 1 phase rèn + 1 combat encounter
- **M5 End:** Vertical slice — 1 ngày đầy đủ loop chơi được
- **M9 End:** 3 vùng playable, 50% main quest
- **M14 End:** Feature complete (tất cả systems implemented)
- **M18 End:** Content complete (tất cả quest, NPC, dialogue)
- **M21 End:** Launch candidate
- **M24:** Public release

## 19.3. Budget gợi ý (USD)

Cho solo dev tự code + nhờ bên ngoài asset:

| Khoản | Dự kiến |
|---|---|
| Pixel art commissions | $4,000 |
| Music (10 tracks freelance) | $2,500 |
| Sound design pack | $300 |
| Localization (EN→VN, 1 ngôn ngữ thêm) | $2,000 |
| Steam page + marketing assets | $500 |
| Steam Direct fee | $100 |
| Playtest compensation (10 testers × $50) | $500 |
| **Tổng** | **~$10,000** |

Nếu zero budget: Tất cả art tự làm + free SFX/music = $0 ngoài Steam Direct fee.

---

# 20. PHỤ LỤC

## 20.1. Bảng 18 Di Vật (Win Condition)

| # | Tên | Vùng | Điều kiện |
|---|---|---|---|
| 141 | Búa Tổ Đồng Cỏ | Đồng Mây | Rèn vũ khí Prefix Kiệt Tác hoặc Tổ Nghề |
| 142 | Đe Rèn Sơ Khai | Đồng Mây | Trả 3,000G cho Cô Lộng Gió |
| 143 | Quai Búa Gió | Đồng Mây | Bán 5 vũ khí Hiệp/Thủ Vệ |
| 144 | Lõi Lò Thiêng Rừng | Rừng Trăm Hồn | Rèn vũ khí Suffix Dark/Poison |
| 145 | Ống Thổi Hồn | Rừng | Thắng Ma Rừng (#119) bằng vũ khí tự rèn |
| 146 | Mảnh Gương Soi Hồn | Rừng | Sở hữu 5 Linh Lực thuộc 5 loại |
| 147 | Cánh Bễ Hỏa Sơn | Núi Than | Rèn vũ khí Suffix Hỏa Rarity 1 |
| 148 | Than Hồng Ngàn Năm | Núi Than | Trả 4,000G + 1 Linh Lực Hỏa |
| 149 | Móng Rồng Lửa | Núi Than | Đánh bại Rồng Lửa Nhỏ (#118) |
| 150 | Bình Nước Thiêng | Bãi Cát | Bán 3 vũ khí cho Đạo Sĩ ≥ 1,500G |
| 151 | Mảnh Cổ Vật Sa Mạc | Bãi Cát | Sở hữu 3 NL Bãi Cát Rarity ≤ 2 |
| 152 | Ấn Triện Cát Thần | Bãi Cát | Reputation ≥ 7 |
| 153 | Kéo Cắt Ngọc Thành | Thành Ngọc | Bán Mastery cho Vệ Binh Hoàng Gia |
| 154 | Bản Thiết Kế Ngọc Bích | Thành Ngọc | Trả 5,000G cho Bà Thiên Kim |
| 155 | Ngọc Bích Tâm | Thành Ngọc | Có Di Vật từ ≥ 3 vùng |
| 156 | Nhật Ký Tổ Rèn | Làng Tổ | Hoàn thành 5 vũ khí Mastery (tích lũy) |
| 157 | Bếp Lò Tổ Nghề | Làng Tổ | Có Di Vật từ tất cả 6 vùng |
| 158 | Mảnh Cuối Lò Thiêng | Làng Tổ | ≥ 11 Di Vật + 10,000G — TRIGGER WIN |

## 20.2. Phôi Vũ Khí Reference

| # | Tên | Skill 1 (innate) | Khách phù hợp |
|---|---|---|---|
| 51 | Kiếm Đơn | Slash (basic) | Hiệp Khách |
| 52 | Song Đao | Twin Strike | Thích Khách |
| 53 | Giáo Dài | Reach | Thủ Vệ, Hiệp Khách |
| 54 | Búa Chiến | Crush | Võ Tăng, Thủ Vệ |
| 55 | Cung Trường | Aim | Thợ Săn |
| 56 | Khiên Đồng | Block | Thủ Vệ |
| 57 | Quyền Cụ | Combo (3 hit) | Võ Tăng |
| 58 | Côn Nhị Khúc | Whirl | Võ Tăng, Thích Khách |
| 59 | Đao Phạt | Heavy Cleave | Thủ Vệ đặc biệt |
| 60 | Gậy Phép | Cast | Đạo Sĩ |
| 61 | Liềm Song | Reap | Thích Khách |
| 62 | Phủ Việt | Sunder | Thủ Vệ, Võ Tăng |

## 20.3. Glossary các thuật ngữ

- **Phôi:** Weapon blank/template
- **NL:** Nguyên liệu (Material)
- **Linh Lực:** Force/Element infusion
- **Affix:** Prefix or Curse on weapon
- **Suffix:** Element infusion at Phase 3
- **Mastery:** Upgraded weapon (won boss test)
- **Patience:** NPC tolerance during haggling
- **Reputation:** Player's standing 0-10
- **Smithing Mastery:** Player's forge skill 0-100
- **Stage Nợ:** Debt level (1/2/3)

## 20.4. Open questions (cần resolve trước M2)

1. Có voice acting không? (gợi ý: text-only cho v1.0)
2. Multiplayer/co-op? (gợi ý: KHÔNG cho v1.0, scope quá rộng)
3. Có Photo Mode không? (nhân vật cute → có thể là feature nice-to-have post-launch)
4. Có Steam Workshop modding không? (data-driven design đã setup tốt cho cái này nhưng polish pipeline cần effort)
5. Difficulty modifier cụ thể của Hardcore? (cần playtest)
6. Cần hệ thống "Apprentice" (NPC giúp việc)? (gợi ý: Cut từ scope v1.0, có thể DLC)

---

# CAM KẾT GDD

GDD này là **contract giữa solo dev với chính mình**. Mọi feature mới sau giai đoạn pre-production cần:

1. Cut feature khác có scope tương đương
2. Hoặc dời sang post-launch DLC
3. Hoặc reject

GDD review schedule: Mỗi 2 tuần trong M1-M5, mỗi tháng từ M6 trở đi.

**Đầu tiên xây MVP, sau đó polish. Đầu tiên ship, sau đó iterate.**

---

🔥 *Lò Thiêng đang chờ được phục dựng. Tiếng Gọi Tổ Nghề sẽ vang.*

*Hết GDD v1.0 — Pre-production*
