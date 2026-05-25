class_name ForgeValidator

# Returns empty string if valid, error message string if invalid.
static func validate(blank: Dictionary, material: Dictionary, inventory_materials: Array) -> String:
	var mat_tier: int = material.get("rarity", 1)
	var required_tier: int = blank.get("required_tier", 1)
	var required_qty: int = blank.get("required_quantity", 2)

	# Gate A — tier check
	if mat_tier < required_tier:
		var tier_names := {1: "Thô (T1)", 2: "Tinh (T2)", 3: "Thượng (T3)"}
		return "Phôi này cần vật liệu %s trở lên." % tier_names.get(required_tier, str(required_tier))

	# Gate B — quantity check
	var selected_ids: Array = material.get("material_ids", [])
	if not selected_ids.is_empty():
		if selected_ids.size() < required_qty:
			return "Cần %d đơn vị vật liệu (hiện có %d)." % [
				required_qty,
				selected_ids.size(),
			]
		var selected_counts := {}
		var alias_map: Dictionary = material.get("material_inventory_aliases", {})
		for selected_id in selected_ids:
			selected_counts[selected_id] = int(selected_counts.get(selected_id, 0)) + 1
		for selected_id in selected_counts.keys():
			var accepted_ids: Array = alias_map.get(selected_id, [selected_id])
			var available := _count_inventory_units(accepted_ids, inventory_materials)
			if available < int(selected_counts[selected_id]):
				return "Cần %d đơn vị vật liệu (hiện có %d)." % [
					int(selected_counts[selected_id]),
					available,
				]
		return ""

	var mat_id: String = material.get("item_id", material.get("id", ""))
	var count := _count_inventory_units([mat_id], inventory_materials)
	if count < required_qty:
		return "Cần %d đơn vị vật liệu (hiện có %d)." % [required_qty, count]

	return ""  # valid


static func _count_inventory_units(accepted_ids: Array, inventory_materials: Array) -> int:
	var total := 0
	for entry in inventory_materials:
		if not entry is Dictionary:
			continue
		if accepted_ids.has(entry.get("item_id", "")):
			total += int(entry.get("quantity", entry.get("amount", 1)))
	return total
