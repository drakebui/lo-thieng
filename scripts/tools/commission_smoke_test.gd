extends Node


func _ready() -> void:
	var c: CommissionData = load("res://resources/commissions/commission_001.tres")
	var w_match := {"blank_id": "kiem_don", "element": "hoa", "rarity_tier": 1}
	var w_nomatch := {"blank_id": "bua_chien", "element": "bang", "rarity_tier": 1}
	assert(WeaponSpec.satisfies(w_match, c) == true)
	assert(WeaponSpec.satisfies(w_nomatch, c) == false)
	print("[CommissionSmokeTest] Phase A: OK")
