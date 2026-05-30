class_name QuestData
extends Resource

enum QuestType { MAIN, ARTIFACT, NPC_PERSONAL, DAILY, HIDDEN }
enum QuestStatus { LOCKED, AVAILABLE, ACTIVE, COMPLETED, FAILED }

@export var quest_id: String = ""
@export var quest_name: String = ""
@export var quest_type: QuestType = QuestType.MAIN
@export var giver_npc_id: String = ""       # NPC ID trong NPCData

# Trigger — khi nào quest này xuất hiện
@export var trigger_type: String = ""       # "enter_region", "talk_npc", "day_reached", "event"
@export var trigger_value: String = ""      # "DongMay", "co_long_gio", "5", "artifact_3"

# Objectives — mỗi objective là 1 Dictionary
# Format: { "type": "forge_prefix", "value": "Kiet_Tac", "count": 1, "current": 0 }
# Types: forge_prefix, sell_weapon, kill_enemy, collect_item,
#        pay_gold, reach_reputation, own_artifacts, talk_npc, clear_region
@export var objectives: Array[Dictionary] = []

# Hint hiện khi player kẹt
@export var hint_text: String = ""

# Rewards
@export var reward_gold: int = 0
@export var reward_reputation: int = 0
@export var reward_artifact_id: int = -1    # -1 = không có artifact
@export var reward_item_ids: Array[String] = []
@export var reward_recipe_id: String = ""

# Failure
@export var has_time_limit: bool = false
@export var time_limit_days: int = 0        # 0 = không giới hạn
@export var failure_condition: String = ""  # "kill_wrong_npc", "timeout", etc.

# Display
@export var description: String = ""
@export var journal_summary: String = ""    # Dòng ngắn hiển thị trong Journal
@export var icon: Texture2D
