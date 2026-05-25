

# enemy_ai.gd
# Quyết định hành động của enemy mỗi lượt dựa theo archetype.
# Trả về intent Dictionary để combat_manager thực thi.
#
# Intent format:
#   { "type"    : "attack" | "defend" | "skill" | "run"
#     "label"   : String    — hiển thị trong telegraph UI
#     "skill_id": String }  — chỉ có khi type == "skill"
class_name EnemyAI
extends RefCounted

# Ngưỡng HP để trigger hành vi đặc biệt
const FLEE_HP_PCT:   float = 0.20   # aggressive bỏ chạy khi HP ≤ 20%
const ENRAGE_HP_PCT: float = 0.50   # boss enrage khi HP ≤ 50%

# ══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ══════════════════════════════════════════════════════════════════════════════

# Gọi ở đầu mỗi PLAYER_TURN trước khi hiện telegraph.
# enemy_hp_pct / player_hp_pct: float 0.0 → 1.0
static func decide(
		enemy:         EnemyCombatUnit,
		round_num:     int,
		enemy_hp_pct:  float,
		player_hp_pct: float
) -> Dictionary:
	match enemy.archetype:
		"aggressive": return _aggressive(enemy_hp_pct)
		"defensive":  return _defensive(round_num)
		"caster":     return _caster(round_num)
		"boss":       return _boss(round_num, enemy_hp_pct, player_hp_pct)
	return _atk()


# ══════════════════════════════════════════════════════════════════════════════
# ARCHETYPES
# ══════════════════════════════════════════════════════════════════════════════

# Aggressive — tấn công liên tục, có thể bỏ chạy khi HP thấp
static func _aggressive(hp_pct: float) -> Dictionary:
	if hp_pct <= FLEE_HP_PCT and randf() < 0.55:
		return { "type": "run", "label": "chuẩn bị bỏ chạy..." }
	return _atk()


# Defensive — phòng thủ mỗi 3 lượt, còn lại tấn công thường
static func _defensive(round_num: int) -> Dictionary:
	if round_num % 3 == 0:
		return { "type": "defend", "label": "đang thu mình phòng thủ..." }
	return _atk()


# Caster — xen kẽ tấn công thường và phép thuật mỗi lượt
static func _caster(round_num: int) -> Dictionary:
	if round_num % 2 == 0:
		return { "type": "skill", "skill_id": "enemy_magic",
				"label": "đang đọc thần chú!" }
	return _atk()


# Boss — phase 1 bình thường, phase 2 (≤50% HP) enrage dùng phép mạnh hơn
static func _boss(
		round_num:     int,
		enemy_hp_pct:  float,
		_player_hp_pct: float
) -> Dictionary:
	if enemy_hp_pct <= ENRAGE_HP_PCT:
		# Enrage: xen kẽ đòn cắn và phép thuật, bỏ qua lượt phòng thủ
		if round_num % 2 == 0:
			return { "type": "skill", "skill_id": "enemy_magic",
					"label": "kích hoạt phép thuật chúa tể!" }
		return { "type": "skill", "skill_id": "enemy_bite",
				"label": "chuẩn bị đòn kết liễu!" }
	# Phase 1: phòng thủ mỗi 4 lượt, không bỏ chạy
	if round_num % 4 == 0:
		return { "type": "defend", "label": "đang phục hồi..." }
	return _atk()


# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

static func _atk() -> Dictionary:
	return { "type": "attack", "label": "chuẩn bị tấn công!" }
