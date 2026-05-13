class_name WeaponData
extends Resource

@export var weapon_name: String = ""
@export var blank_type: String = ""      # Phôi: KiemDon, SongDao, etc.
@export var atk: int = 0
@export var def_stat: int = 0
@export var magic: int = 0
@export var speed: int = 0
@export var durability: int = 50
@export var max_durability: int = 50
@export var prefix: String = ""          # Bén Ngọt, Kiên Cố, etc.
@export var suffix_element: String = ""  # Hoa, Bang, Set, etc.
@export var is_mastery: bool = false
@export var is_cursed: bool = false
@export var curse_type: String = ""
@export var rarity_tier: int = 1         # 1-5
@export var base_price: int = 0
@export var icon: Texture2D
