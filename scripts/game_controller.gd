extends Control

const GRID_SIZE := 9
const BASE_CP := 5
const SHRINE_BONUS_CAP := 2
const MAX_IDLE_TURNS := 50

const BoardTileScene := preload("res://scenes/BoardTile.tscn")

const WATER_TILES := [
    Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3),
    Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5)
]

const SHRINE_TILES := [Vector2i(2, 4), Vector2i(6, 4)]

const BASE_POSITIONS := {
    0: Vector2i(GRID_SIZE - 1, GRID_SIZE // 2),
    1: Vector2i(0, GRID_SIZE // 2)
}

const STARTING_UNITS := {
    0: {
        Vector2i(3, 7): "Frog",
        Vector2i(4, 7): "Crane",
        Vector2i(5, 7): "Turtle",
        Vector2i(2, 8): "Box",
        Vector2i(6, 8): "Shuriken"
    },
    1: {
        Vector2i(5, 1): "Frog",
        Vector2i(4, 1): "Crane",
        Vector2i(3, 1): "Turtle",
        Vector2i(6, 0): "Box",
        Vector2i(2, 0): "Shuriken"
    }
}

@onready var board_container: GridContainer = $"Layout/BoardWrapper/Board"
@onready var turn_label: Label = $"Layout/Header/TurnLabel"
@onready var cp_label: Label = $"Layout/Header/CPLabel"
@onready var action_log: RichTextLabel = $"Layout/ActionLog"
@onready var end_turn_button: Button = $"Layout/Header/EndTurn"

var tiles: Dictionary = {}
var terrain: Dictionary = {}
var units: Dictionary = {}
var shrine_controlled: Dictionary = {0: 0, 1: 0}
var shrine_owners: Dictionary = {}
var cp_pool: Array = [BASE_CP, BASE_CP]
var defensive_wait: Array = [0, 0]
var current_player: int = 0
var selected_position: Vector2i = Vector2i(-1, -1)
var available_moves: Dictionary = {}
var available_attacks: Dictionary = {}
var special_targets: Dictionary = {}
var carry_pending_drop: bool = false
var carried_unit: UnitState = null
var carried_origin: Vector2i = Vector2i(-1, -1)
var consecutive_idle_turns: int = 0
var total_small_turns: int = 0
var game_over: bool = false
var last_action_turn: int = 0

func _ready() -> void:
    end_turn_button.pressed.connect(_on_end_turn_pressed)
    setup_board()
    setup_units()
    start_turn(0)
    log_event("Origami Tactics v0.91 – Game start")

func setup_board() -> void:
    tiles.clear()
    terrain.clear()
    for child in board_container.get_children():
        child.queue_free()

    for y in range(GRID_SIZE):
        for x in range(GRID_SIZE):
            var tile: BoardTile = BoardTileScene.instantiate()
            var pos := Vector2i(x, y)
            tile.grid_position = pos
            tile.tile_pressed.connect(_on_tile_pressed)
            board_container.add_child(tile)
            tiles[pos] = tile
            var terrain_type := "plain"
            if pos in WATER_TILES:
                terrain_type = "water"
            elif pos in SHRINE_TILES:
                terrain_type = "shrine"
            for player in BASE_POSITIONS.keys():
                if pos == BASE_POSITIONS[player]:
                    terrain_type = "base%d" % player
            terrain[pos] = terrain_type
            tile.set_terrain(terrain_type)

func setup_units() -> void:
    units.clear()
    for player in STARTING_UNITS.keys():
        for pos in STARTING_UNITS[player].keys():
            var unit_type: String = STARTING_UNITS[player][pos]
            place_unit(pos, UnitState.new(unit_type, player))
    update_all_tiles()

func place_unit(pos: Vector2i, unit: UnitState) -> void:
    units[pos] = unit
    update_tile(pos)

func update_tile(pos: Vector2i) -> void:
    if not tiles.has(pos):
        return
    var tile: Button = tiles[pos]
    var unit := units.get(pos, null)
    tile.set_occupant(unit)

func update_all_tiles() -> void:
    for pos in tiles.keys():
        update_tile(pos)

func board_container_children() -> Array:
    return board_container.get_children()

func clear_selection(cancel_carry: bool = true) -> void:
    if selected_position != Vector2i(-1, -1) and tiles.has(selected_position):
        tiles[selected_position].reset_highlight()
    for pos in available_moves.keys():
        if tiles.has(pos):
            tiles[pos].reset_highlight()
    for pos in available_attacks.keys():
        if tiles.has(pos):
            tiles[pos].reset_highlight()
    for pos in special_targets.keys():
        if tiles.has(pos):
            tiles[pos].reset_highlight()
    available_moves.clear()
    available_attacks.clear()
    special_targets.clear()
    selected_position = Vector2i(-1, -1)
    if cancel_carry:
        carry_pending_drop = false
    if cancel_carry and carried_unit:
        log_event("Carry cancelled; returning %s." % carried_unit.unit_type)
        if not units.has(carried_origin):
            units[carried_origin] = carried_unit
            update_tile(carried_origin)
        carried_unit = null
        carried_origin = Vector2i(-1, -1)

func select_position(pos: Vector2i, cancel_carry: bool = true) -> void:
    clear_selection(cancel_carry)
    if not units.has(pos):
        return
    var unit: UnitState = units[pos]
    if unit.owner != current_player:
        return
    selected_position = pos
    var tile: Button = tiles[pos]
    tile.highlight(true)
    available_moves = compute_moves(pos, unit)
    available_attacks = compute_attacks(pos, unit)
    special_targets = compute_special_targets(pos, unit)
    for move_pos in available_moves.keys():
        if tiles.has(move_pos):
            tiles[move_pos].highlight(true)
    for attack_pos in available_attacks.keys():
        if tiles.has(attack_pos):
            tiles[attack_pos].highlight(false, true)
    for target_pos in special_targets.keys():
        if tiles.has(target_pos):
            tiles[target_pos].highlight(true)
    update_log_preview(unit)

func update_log_preview(unit: UnitState) -> void:
    action_log.append_text("[color=#66c]Selected %s[/color]\n" % unit.describe())

func _on_tile_pressed(pos: Vector2i) -> void:
    if game_over:
        return
    if carry_pending_drop:
        attempt_drop_carried_unit(pos)
        return
    if selected_position == Vector2i(-1, -1):
        if units.has(pos) and units[pos].owner == current_player:
            select_position(pos)
        return

    if pos == selected_position:
        clear_selection()
        return

    if special_targets.has(pos):
        var data: Dictionary = special_targets[pos]
        match data.get("type", ""):
            "carry":
                begin_carry(pos)
            "push":
                attempt_push(selected_position, pos)
        return

    if available_moves.has(pos):
        attempt_move(selected_position, pos, available_moves[pos])
        return

    if available_attacks.has(pos):
        attempt_attack(selected_position, pos, available_attacks[pos])
        return

    if units.has(pos) and units[pos].owner == current_player:
        select_position(pos)
    else:
        clear_selection()

func attempt_move(origin: Vector2i, destination: Vector2i, info: Dictionary) -> void:
    var unit: UnitState = units.get(origin)
    if unit == null:
        return
    var cost: int = info.get("cost", 1)
    var distance: int = info.get("distance", 1)
    if unit.current_mp < distance:
        log_event("%s lacks MP to move %d squares." % [unit.unit_type, distance])
        return
    if cp_pool[current_player] < cost:
        log_event("Not enough CP (%d) to move." % cp_pool[current_player])
        return

    cp_pool[current_player] -= cost
    unit.consume_mp(distance)
    unit.last_move_distance = distance

    var moved_path: Array = info.get("path", [])
    if moved_path.is_empty():
        moved_path = [origin, destination]

    units.erase(origin)
    update_tile(origin)
    units[destination] = unit
    update_tile(destination)

    if carried_unit:
        carry_pending_drop = true
        unit.has_carried = true
        log_event("%s carried %s to %s. Select drop tile." % [
            unit.unit_type,
            carried_unit.unit_type,
            format_position(destination)
        ])
        selected_position = destination
        select_position(destination, false)
        highlight_drop_options(destination)
    else:
        log_event("%s moved to %s." % [unit.unit_type, format_position(destination)])
        after_action_updates(unit, destination)
        selected_position = destination
        select_position(destination)

func attempt_attack(origin: Vector2i, target_pos: Vector2i, info: Dictionary) -> void:
    var attacker: UnitState = units.get(origin)
    var defender: UnitState = units.get(target_pos)
    if attacker == null or defender == null:
        return
    var cost: int = info.get("cost", 1)
    if cp_pool[current_player] < cost:
        log_event("Not enough CP to attack.")
        return
    cp_pool[current_player] -= cost

    var effective_target_pos: Vector2i = maybe_intercept(target_pos, defender, origin)
    defender = units.get(effective_target_pos)

    var damage: int = calculate_damage(attacker, defender, origin, effective_target_pos, info)
    defender.apply_fd(damage)
    log_event("%s dealt %d FD to %s." % [attacker.unit_type, damage, defender.unit_type])
    last_action_turn = total_small_turns
    if defender.is_destroyed():
        remove_unit(effective_target_pos, defender)
        log_event("%s is torn!" % defender.unit_type)
        consecutive_idle_turns = 0
        last_action_turn = total_small_turns
    else:
        maybe_counter_attack(attacker, origin, defender, effective_target_pos)

    attacker.last_move_distance = 0
    after_action_updates(attacker, origin)
    update_all_tiles()
    clear_selection()
    select_position(origin)
    check_victory_conditions()

func attempt_push(origin: Vector2i, target_pos: Vector2i) -> void:
    var frog: UnitState = units.get(origin)
    var enemy: UnitState = units.get(target_pos)
    if frog == null or enemy == null:
        return
    if cp_pool[current_player] < 1:
        log_event("Not enough CP to push.")
        return
    cp_pool[current_player] -= 1
    var direction := (target_pos - origin)
    var destination := target_pos + direction
    if not is_within_bounds(destination):
        log_event("Push blocked by edge.")
        return
    var terrain_type := terrain.get(destination, "plain")
    if units.has(destination):
        log_event("Push failed; space occupied.")
        return
    if terrain_type == "water":
        enemy.apply_fd(1)
        enemy.grant_water_bonus()
        log_event("Frog pushed %s into water (+1 FD)." % enemy.unit_type)
        last_action_turn = total_small_turns
    elif terrain_type.begins_with("base"):
        log_event("Push blocked by base marker.")
        return
    else:
        units.erase(target_pos)
        units[destination] = enemy
        log_event("Frog pushed %s to %s." % [enemy.unit_type, format_position(destination)])
        last_action_turn = total_small_turns
    after_action_updates(frog, origin)
    update_all_tiles()
    clear_selection()
    select_position(origin)

func begin_carry(target_pos: Vector2i) -> void:
    var crane: UnitState = units.get(selected_position)
    var passenger: UnitState = units.get(target_pos)
    if crane == null or passenger == null:
        return
    if crane.has_carried:
        log_event("Crane has already carried this turn.")
        return
    carried_unit = passenger
    carried_origin = target_pos
    units.erase(target_pos)
    update_tile(target_pos)
    passenger.reset_turn()
    passenger.current_mp = 0
    log_event("%s picked up %s." % [crane.unit_type, passenger.unit_type])
    select_position(selected_position, false)

func attempt_drop_carried_unit(pos: Vector2i) -> void:
    if not carry_pending_drop or carried_unit == null:
        return
    var unit: UnitState = units.get(selected_position)
    if unit == null:
        return
    if pos.distance_to(selected_position) > 1:
        log_event("Drop target must be adjacent.")
        return
    if units.has(pos):
        log_event("Drop target occupied.")
        return
    if terrain.get(pos, "plain") == "water":
        log_event("Cannot drop onto water.")
        return
    units[pos] = carried_unit
    update_tile(pos)
    log_event("%s dropped %s on %s." % [unit.unit_type, carried_unit.unit_type, format_position(pos)])
    carried_unit = null
    carried_origin = Vector2i(-1, -1)
    carry_pending_drop = false
    var crane_pos := selected_position
    after_action_updates(unit, crane_pos)
    clear_selection()
    select_position(crane_pos)
    check_victory_conditions()

func highlight_drop_options(origin: Vector2i) -> void:
    var options: Array = []
    for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]:
        var pos := origin + direction
        if not is_within_bounds(pos):
            continue
        if units.has(pos):
            continue
        if terrain.get(pos, "plain") == "water":
            continue
        options.append(pos)
    if options.is_empty():
        log_event("No available drop tiles – carry cancelled.")
        if carried_unit and not units.has(carried_origin):
            units[carried_origin] = carried_unit
            update_tile(carried_origin)
        carried_unit = null
        carried_origin = Vector2i(-1, -1)
        carry_pending_drop = false
        return
    for pos in options:
        if tiles.has(pos):
            tiles[pos].highlight(true)

func compute_moves(origin: Vector2i, unit: UnitState) -> Dictionary:
    var results: Dictionary = {}
    match unit.unit_type:
        "Crane":
            results = compute_crane_moves(origin, unit)
        "Frog":
            results = compute_frog_moves(origin, unit)
        "Box":
            results = compute_walker_moves(origin, unit, 1)
        "Turtle":
            results = compute_walker_moves(origin, unit, 1)
        "Shuriken":
            results = compute_shuriken_moves(origin, unit)
        _:
            results = compute_walker_moves(origin, unit, 1)
    return results

func compute_attacks(origin: Vector2i, unit: UnitState) -> Dictionary:
    var result: Dictionary = {}
    var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
    for direction in directions:
        var target := origin + direction
        if not is_within_bounds(target):
            continue
        if not units.has(target):
            continue
        var enemy: UnitState = units[target]
        if enemy.owner == unit.owner:
            continue
        if unit.unit_type == "Frog" and unit.last_move_distance < 2:
            continue
        result[target] = {"cost": 1}
    return result

func compute_special_targets(origin: Vector2i, unit: UnitState) -> Dictionary:
    var result: Dictionary = {}
    if unit.unit_type == "Crane" and not unit.has_carried and carried_unit == null:
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]:
            var pos := origin + offset
            if not is_within_bounds(pos):
                continue
            if units.has(pos) and units[pos].owner == current_player:
                result[pos] = {"type": "carry"}
    if unit.unit_type == "Frog":
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var pos := origin + offset
            if not is_within_bounds(pos):
                continue
            if units.has(pos) and units[pos].owner != current_player:
                result[pos] = {"type": "push"}
    return result

func compute_crane_moves(origin: Vector2i, unit: UnitState) -> Dictionary:
    var result: Dictionary = {}
    for x in range(GRID_SIZE):
        for y in range(GRID_SIZE):
            var pos := Vector2i(x, y)
            if pos == origin:
                continue
            var distance := origin.distance_to(pos)
            if distance > unit.current_mp or distance > unit.max_mp():
                continue
            if terrain.get(pos, "plain") == "water":
                continue
            if units.has(pos):
                continue
            result[pos] = {"cost": distance, "distance": distance}
    return result

func compute_frog_moves(origin: Vector2i, unit: UnitState) -> Dictionary:
    var result: Dictionary = {}
    for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        for step in range(1, 4):
            var pos := origin + offset * step
            if not is_within_bounds(pos):
                break
            if units.has(pos):
                if step == 1:
                    break
                else:
                    continue
            if terrain.get(pos, "plain") == "water":
                continue
            if step > unit.current_mp:
                break
            result[pos] = {"cost": step, "distance": step}
    return result

func compute_walker_moves(origin: Vector2i, unit: UnitState, max_range: int) -> Dictionary:
    var result: Dictionary = {}
    var queue: Array = []
    var visited: Dictionary = {}
    queue.append({"pos": origin, "distance": 0, "path": [origin]})
    visited[origin] = 0
    while not queue.is_empty():
        var item = queue.pop_front()
        var pos: Vector2i = item.pos
        var distance: int = item.distance
        for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var next := pos + offset
            var next_distance := distance + 1
            if not is_within_bounds(next):
                continue
            if next_distance > unit.current_mp or next_distance > max_range:
                continue
            if terrain.get(next, "plain") == "water":
                continue
            if units.has(next):
                continue
            if visited.has(next) and visited[next] <= next_distance:
                continue
            visited[next] = next_distance
            var path := item.path.duplicate()
            path.append(next)
            result[next] = {"cost": next_distance, "distance": next_distance, "path": path}
            queue.append({"pos": next, "distance": next_distance, "path": path})
    return result

func compute_shuriken_moves(origin: Vector2i, unit: UnitState) -> Dictionary:
    var result: Dictionary = {}
    var directions := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
    for direction in directions:
        var pos := origin
        for step in range(1, unit.max_mp() + 1):
            pos += direction
            if not is_within_bounds(pos):
                break
            if terrain.get(pos, "plain") == "water":
                break
            if units.has(pos):
                if units[pos].owner == unit.owner:
                    break
                else:
                    # Can move through enemies; continue but cannot end on occupied
                    continue
            result[pos] = {"cost": step, "distance": step, "path": build_line_path(origin, pos)}
    return result

func build_line_path(origin: Vector2i, destination: Vector2i) -> Array:
    var path: Array = [origin]
    var direction := (destination - origin).sign()
    var pos := origin
    while pos != destination:
        pos += direction
        path.append(pos)
    return path

func calculate_damage(attacker: UnitState, defender: UnitState, origin: Vector2i, target: Vector2i, info: Dictionary) -> int:
    var effective_arm := defender.arm() + defensive_wait[defender.owner]
    if is_adjacent_to_enemy_box(target, defender.owner):
        effective_arm = max(0, effective_arm - 1)
    var base_damage := max(1, attacker.atk() - effective_arm)
    if attacker.unit_type == "Shuriken":
        var path: Array = info.get("path", build_line_path(origin, target))
        var enemies_passed := count_enemies_passed(attacker.owner, path)
        if enemies_passed >= 2:
            base_damage += 1
    return base_damage

func is_adjacent_to_enemy_box(pos: Vector2i, owner: int) -> bool:
    for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(-1, -1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(1, 1)]:
        var check := pos + offset
        if units.has(check):
            var unit: UnitState = units[check]
            if unit.owner != owner and unit.unit_type == "Box":
                return true
    return false

func count_enemies_passed(owner: int, path: Array) -> int:
    var count := 0
    for pos in path:
        if not units.has(pos):
            continue
        var unit: UnitState = units[pos]
        if unit.owner != owner and pos != path.back():
            count += 1
    return count

func maybe_counter_attack(attacker: UnitState, attacker_pos: Vector2i, defender: UnitState, defender_pos: Vector2i) -> void:
    if attacker_pos.distance_to(defender_pos) > 1:
        return
    if not defender.can_counter_attack():
        return
    defender.mark_countered()
    var effective_arm := attacker.arm() + defensive_wait[attacker.owner]
    if is_adjacent_to_enemy_box(attacker_pos, attacker.owner):
        effective_arm = max(0, effective_arm - 1)
    var damage := max(1, defender.atk() - effective_arm)
    attacker.apply_fd(damage)
    last_action_turn = total_small_turns
    log_event("%s counter-attacked for %d FD." % [defender.unit_type, damage])
    if attacker.is_destroyed():
        remove_unit(attacker_pos, attacker)
        log_event("%s is torn during counter!" % attacker.unit_type)
        consecutive_idle_turns = 0
        last_action_turn = total_small_turns

func maybe_intercept(target_pos: Vector2i, defender: UnitState, attacker_pos: Vector2i) -> Vector2i:
    if defender.unit_type == "Turtle":
        return target_pos
    for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
        var check := target_pos + offset
        if not units.has(check):
            continue
        var turtle: UnitState = units[check]
        if turtle.owner != defender.owner:
            continue
        if turtle.unit_type != "Turtle":
            continue
        if units.has(target_pos):
            units[target_pos] = turtle
        units[check] = defender
        log_event("Turtle intercepts, swapping with %s." % defender.unit_type)
        update_tile(target_pos)
        update_tile(check)
        return target_pos
    return target_pos

func remove_unit(pos: Vector2i, unit: UnitState) -> void:
    units.erase(pos)
    update_tile(pos)
    if terrain.get(pos, "plain") == "water":
        unit.grant_water_bonus()

func after_action_updates(unit: UnitState, position: Vector2i) -> void:
    update_tile(position)
    check_water_effects(position, unit)
    update_ui()

func check_water_effects(pos: Vector2i, unit: UnitState) -> void:
    var terrain_type := terrain.get(pos, "plain")
    if terrain_type == "water":
        log_event("%s is in water: +1 MP until it leaves." % unit.unit_type)
        unit.grant_water_bonus()
    else:
        pass

func update_ui() -> void:
    turn_label.text = "Player %d turn" % (current_player + 1)
    cp_label.text = "CP: %d" % cp_pool[current_player]

func format_position(pos: Vector2i) -> String:
    return "(%d, %d)" % [pos.x + 1, pos.y + 1]

func is_within_bounds(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.y >= 0 and pos.x < GRID_SIZE and pos.y < GRID_SIZE

func log_event(text: String) -> void:
    action_log.append_text(text + "\n")

func start_turn(player: int) -> void:
    current_player = player
    refresh_cp(player)
    refresh_units(player)
    defensive_wait[player] = 0
    update_ui()
    clear_selection()
    check_victory_conditions()

func refresh_cp(player: int) -> void:
    var shrine_bonus := min(shrine_controlled[player], SHRINE_BONUS_CAP)
    cp_pool[player] = BASE_CP + shrine_bonus

func refresh_units(player: int) -> void:
    for pos in units.keys():
        var unit: UnitState = units[pos]
        if unit.owner == player:
            unit.reset_turn()

func _on_end_turn_pressed() -> void:
    end_turn()

func end_turn() -> void:
    if game_over:
        return
    if cp_pool[current_player] > 0:
        defensive_wait[current_player] = 1
        log_event("Player %d assumes Defensive Wait (+1 ARM)." % (current_player + 1))
    update_shrine_control()
    check_victory_conditions()
    total_small_turns += 1
    if total_small_turns - last_action_turn >= MAX_IDLE_TURNS:
        log_event("50 turns without action – draw.")
        game_over = true
        return
    var next_player := (current_player + 1) % 2
    start_turn(next_player)

func update_shrine_control() -> void:
    shrine_controlled = {0: 0, 1: 0}
    for shrine_pos in SHRINE_TILES:
        var owner := -1
        if units.has(shrine_pos):
            owner = units[shrine_pos].owner
        if owner >= 0:
            shrine_controlled[owner] += 1
            if shrine_owners.get(shrine_pos, -1) != owner:
                log_event("Player %d captures shrine at %s." % [owner + 1, format_position(shrine_pos)])
        shrine_owners[shrine_pos] = owner

func check_victory_conditions() -> void:
    for player in [0, 1]:
        var base_pos: Vector2i = BASE_POSITIONS[player]
        var opponent := 1 - player
        if units.has(base_pos) and units[base_pos].owner == opponent:
            log_event("Player %d occupies Player %d base and wins!" % [opponent + 1, player + 1])
            game_over = true
            return
    var owners_present := {}
    for unit in units.values():
        owners_present[unit.owner] = true
    if owners_present.size() < 2:
        if owners_present.has(0):
            log_event("Player 1 wins by elimination!")
        elif owners_present.has(1):
            log_event("Player 2 wins by elimination!")
        else:
            log_event("Draw: no units remain.")
        game_over = true

