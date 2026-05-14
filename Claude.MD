# 🔥 LÒ THIÊNG: TIẾNG GỌI TỔ NGHỀ — Project Context

## Tổng quan
- **Engine:** Godot 4.x
- **Ngôn ngữ:** GDScript
- **Thể loại:** Shop Management + Crafting + Turn-based RPG
- **Solo dev** — ưu tiên đơn giản, data-driven design
- **GDD đầy đủ:** đọc docs/GDD.md trước khi đề xuất tính năng mới

## Triết lý code
- Data-driven: Items, NPCs, Quests, Skills là .tres resource files, KHÔNG hard-code
- Nodes giao tiếp qua signals hoặc EventBus autoload
- Mỗi region, NPC, UI panel là 1 scene độc lập
- Chỉ dùng autoload cho: EventBus, GameManager, AudioManager, SaveSystem

## Quy ước đặt tên
- Tên file script: snake_case.gd (vd: forge_manager.gd)
- Tên file scene: PascalCase.tscn (vd: ForgeScene.tscn)
- Tên biến: snake_case (vd: player_health)
- Tên hằng số: SCREAMING_SNAKE_CASE (vd: MAX_STAMINA)
- Tên signal: snake_case dạng quá khứ (vd: weapon_forged, sale_completed)
- Hàm private: bắt đầu bằng _ (vd: _calculate_damage())

## Cấu trúc thư mục
- scenes/main/        — Scene chính, Main Menu
- scenes/player/      — Player scene
- scenes/ui/          — Inventory, Shop UI, Forge UI, HUD
- scenes/regions/     — 6 vùng đất exploration
- scenes/npcs/        — NPC scenes
- scenes/combat/      — Combat scene
- scripts/core/       — GameManager, EventBus, SaveSystem
- scripts/player/     — Player controller, stats
- scripts/combat/     — Combat manager, enemy AI, skills
- scripts/forge/      — Hệ thống rèn 3 phase
- scripts/shop/       — Shop manager, customer AI, negotiation
- scripts/npc/        — NPC schedule, affinity
- scripts/ui/         — UI controllers
- resources/items/    — .tres files cho items
- resources/npcs/     — NPC data
- resources/quests/   — Quest data
- resources/skills/   — Combat skill data
- assets/sprites/     — Hình ảnh
- assets/audio/       — Âm thanh
- autoloads/          — Global singletons
- docs/               — GDD.md và tài liệu

## Autoloads (Singletons toàn game)
- EventBus.gd         — Trung tâm signals, mọi giao tiếp cross-system
- GameManager.gd      — Game state, ngày hiện tại, tiền, reputation
- SaveSystem.gd       — Lưu/đọc file JSON
- AudioManager.gd     — Nhạc nền và hiệu ứng âm thanh
- InventorySystem.gd  — Quản lý kho và túi đồ
- QuestSystem.gd      — Theo dõi tiến trình quest

## 6 Hệ thống chính (theo GDD)
1. Forge System (USP cốt lõi): 3 phase — Nung / Rèn Búa / Tôi Luyện
2. Combat System: Turn-based side-view, 3-5 lượt/trận, 25 skills
3. Shop System: Customer AI + Negotiation mini-game
4. Region System: 6 vùng top-down exploration
5. NPC System: Schedule theo giờ + Affinity 0-100
6. Quest System: Main + Di Vật (18) + Personal + Daily + Hidden

## Scope số lượng
- ~80 items (resource files)
- ~30 NPCs có tên
- ~55 quests tổng (25 main + 30 side)
- ~25 combat skills
- 6 regions

## Quy tắc bắt buộc
1. Luôn đọc GDD trước khi implement hệ thống mới
2. Nếu tính năng KHÔNG có trong GDD → cảnh báo trước khi code
3. Ưu tiên giải pháp đơn giản nhất trước
4. Break thành steps nhỏ, làm từng phần
5. **BẮT BUỘC cuối mỗi session:** cập nhật NOTES.md theo đúng template (session number tăng dần, ngày hiện tại). Ghi đủ 6 mục: Task đã làm / Files tạo mới / Files đã sửa / Vấn đề gặp phải / Chưa làm được / Cần Engineering Lead chú ý. KHÔNG được kết thúc session mà không cập nhật NOTES.md.

## Ngôn ngữ
- Comment trong code: tiếng Việt
- Tên biến/hàm: tiếng Anh
- Text trong game (UI, dialogue): tiếng Việt

## Trạng thái hiện tại
- [ ] EventBus
- [ ] GameManager
- [ ] SaveSystem
- [ ] Forge System
- [ ] Combat System
- [ ] Shop System
- [ ] Region System
- [ ] NPC System
- [ ] Quest System
