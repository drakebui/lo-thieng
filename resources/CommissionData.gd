class_name CommissionData
extends Resource

@export var commission_id: String = ""
@export var giver_npc_id: String = ""
@export var reason_text: String = ""
@export var hint_region: String = ""

@export var req_blank: String = ""
@export var req_element: String = ""
@export var req_phase2_prefix: String = ""
@export var req_min_rarity: int = 1

@export var reward_gold: int = 0
@export var reward_reputation: int = 0
@export var reward_affinity: int = 0

@export var flavor_accept: String = ""
@export var flavor_fulfilled: String = ""
