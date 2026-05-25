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
signal gold_changed(new_val: int)
signal reputation_changed(new_val: int)
signal stamina_changed(current: int, maximum: int)
signal day_phase_changed(day: int, phase: int)
signal debt_updated(amount: int, days_left: int)
signal hint_requested(text: String)
signal tutorial_step_changed(step: int)
signal debt_notice_closed
signal shop_opened
signal shop_closed(session_stats: Dictionary)  # gold_earned, customers_served, customers_visited
signal customer_served(customer_id: String, gold: int)
signal game_over_triggered(reason: String)
signal guide_book_opened
signal forge_book_opened
signal forge_book_closed

# Exploration
signal region_entered(region_id: String)
signal region_exited(region_id: String)
signal region_cleared(region_id: String)
signal gathering_node_collected(material: Dictionary)
signal travel_stamina_depleted()
signal encounter_triggered(enemy_data: Dictionary)
