class_name UnitDefinitions

const UNIT_DATA := {
    "Crane": {
        "max_mp": 4,
        "atk": 2,
        "arm": 1,
        "health": 6,
        "keywords": ["carry"],
        "description": "Flies up to 4 squares ignoring terrain; can carry an adjacent ally once per turn."
    },
    "Frog": {
        "max_mp": 3,
        "atk": 3,
        "arm": 1,
        "health": 6,
        "keywords": ["push", "leap_attack"],
        "description": "Jumps up to 3 squares orthogonally and can push enemies."
    },
    "Box": {
        "max_mp": 1,
        "atk": 2,
        "arm": 3,
        "health": 8,
        "keywords": ["armor_aura"],
        "description": "Reduces adjacent enemy armor by 1."
    },
    "Turtle": {
        "max_mp": 1,
        "atk": 2,
        "arm": 4,
        "health": 9,
        "keywords": ["intercept"],
        "description": "Can intercept attacks targeting adjacent allies."
    },
    "Shuriken": {
        "max_mp": 3,
        "atk": 4,
        "arm": 0,
        "health": 5,
        "keywords": ["piercing_charge"],
        "description": "Moves in straight lines and gains bonus damage when charging through enemies."
    }
}

static func get_unit_types() -> Array:
    return UNIT_DATA.keys()

static func get_unit_data(unit_type: String) -> Dictionary:
    return UNIT_DATA.get(unit_type, {})
