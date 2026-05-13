# Central event system — tránh coupling giữa các system
extends Node

signal phase1_completed(result_tier: String)
signal phase2_completed(score: int, prefix_tier: String)
signal phase3_completed(weapon_result: Dictionary)
signal weapon_forged(weapon_data)
signal weapon_sold(weapon_data, price: int)
signal quest_completed(quest_id: String)
signal artifact_collected(artifact_id: int)
signal combat_started(enemy_data)
signal combat_ended(result: String) # "win", "lose", "run"
signal npc_affinity_changed(npc_id: String, new_value: int)
signal shop_opened
signal shop_closed(session_stats: Dictionary)  # gold_earned, customers_served, customers_visited
signal customer_served(customer_id: String, gold: int)

# Exploration
signal region_entered(region_id: String)
signal region_exited(region_id: String)
signal gathering_node_collected(material: Dictionary)
signal travel_stamina_depleted()
signal encounter_triggered(enemy_data: Dictionary)
