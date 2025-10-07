extends Button

signal tile_pressed(position: Vector2i)

@export var grid_position: Vector2i = Vector2i.ZERO
var terrain: String = "plain"
var occupant: Variant = null

func _ready() -> void:
    pressed.connect(_on_pressed)
    _update_visual()

func set_terrain(value: String) -> void:
    terrain = value
    _update_visual()

func set_occupant(unit) -> void:
    occupant = unit
    _update_visual()

func highlight(can_interact: bool, is_target: bool=false) -> void:
    if can_interact:
        self.modulate = Color(0.8, 1.0, 0.8)
    elif is_target:
        self.modulate = Color(1.0, 0.8, 0.8)
    else:
        self.modulate = Color(1, 1, 1)

func reset_highlight() -> void:
    self.modulate = Color(1, 1, 1)

func _on_pressed() -> void:
    tile_pressed.emit(grid_position)

func _update_visual() -> void:
    var label_text := ""
    if occupant:
        label_text = "%s%d" % [occupant.unit_type.substr(0, 1), occupant.owner + 1]
    text = label_text

    match terrain:
        "water":
            self.add_theme_color_override("font_color", Color(0.2, 0.4, 0.9))
            self.self_modulate = Color(0.6, 0.7, 1.0, 0.9)
        "shrine":
            self.add_theme_color_override("font_color", Color(0.8, 0.6, 0.1))
            self.self_modulate = Color(1.0, 0.95, 0.7, 0.9)
        "base0":
            self.self_modulate = Color(0.9, 0.6, 0.6, 0.95)
        "base1":
            self.self_modulate = Color(0.6, 0.9, 0.6, 0.95)
        _:
            self.self_modulate = Color(1, 1, 1, 0.95)
