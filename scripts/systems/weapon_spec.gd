# Từ vựng canonical dùng id runtime để mọi hệ thống khớp đơn cùng một ngôn ngữ.
# So khớp theo field cố định để tránh trùng giá trị giữa blank_id / element / prefix.
class_name WeaponSpec
extends RefCounted


static func tags_of(w: Dictionary) -> Array[String]:
	var tags: Array[String] = []
	var blank_id := String(w.get("blank_id", ""))
	if not blank_id.is_empty():
		tags.append("blank:%s" % blank_id)
	var element := String(w.get("element", ""))
	if not element.is_empty():
		tags.append("element:%s" % element)
	var prefix := String(w.get("phase2_prefix", ""))
	if not prefix.is_empty():
		tags.append("prefix:%s" % prefix)
	var rarity_tier := int(w.get("rarity_tier", 0))
	if rarity_tier > 0:
		tags.append("rarity:%d" % rarity_tier)
	return tags


static func satisfies(w: Dictionary, c: CommissionData) -> bool:
	if c == null:
		return false
	if not c.req_blank.is_empty() and String(w.get("blank_id", "")) != c.req_blank:
		return false
	if not c.req_element.is_empty() and String(w.get("element", "")) != c.req_element:
		return false
	if not c.req_phase2_prefix.is_empty() \
			and String(w.get("phase2_prefix", "")) != c.req_phase2_prefix:
		return false
	if int(w.get("rarity_tier", 0)) < c.req_min_rarity:
		return false
	return true
