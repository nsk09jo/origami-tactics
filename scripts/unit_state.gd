class_name UnitState
extends RefCounted

const UNIT_LIBRARY := preload("res://scripts/unit_definitions.gd")

var unit_type: String
var owner: int
var fd_taken: int = 0
var current_mp: int = 0
var has_countered: bool = false
var has_carried: bool = false
var carried_unit: UnitState = null
var last_move_distance: int = 0

func _init(unit_type: String, owner: int) -> void:
    self.unit_type = unit_type
    self.owner = owner
    reset_turn()

func get_data() -> Dictionary:
    return UNIT_LIBRARY.get_unit_data(unit_type)

func get_stat(stat: String) -> int:
    var data := get_data()
    return data.get(stat, 0)

func max_mp() -> int:
    return get_stat("max_mp")

func atk() -> int:
    return get_stat("atk")

func arm() -> int:
    return get_stat("arm")

func health() -> int:
    return get_stat("health")

func keywords() -> Array:
    return get_data().get("keywords", [])

func reset_turn() -> void:
    current_mp = max_mp()
    has_countered = false
    has_carried = false
    carried_unit = null
    last_move_distance = 0

func apply_fd(amount: int) -> void:
    fd_taken += amount

func is_destroyed() -> bool:
    return fd_taken >= health()

func can_counter_attack() -> bool:
    return not has_countered

func mark_countered() -> void:
    has_countered = true

func consume_mp(amount: int) -> void:
    current_mp = max(0, current_mp - amount)

func grant_water_bonus() -> void:
    current_mp += 1

func describe() -> String:
    var data := get_data()
    return "%s (MP %d, ATK %d, ARM %d, FD %d/%d)" % [
        unit_type,
        current_mp,
        atk(),
        arm(),
        fd_taken,
        health()
    ]
