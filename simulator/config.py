# --- Power Score Calculation Weights ---
STAT_POWER_WEIGHTS = {
    "might": 2.5,
    "finesse": 2.5,
    "wits": 2.0,
    "grit": 2.0,
    "presence": 1.5,
}

# --- Gear Score Calculation Weights ---
GEAR_SCORE_WEIGHTS = {
    "physical_power": 2.0,
    "armor": 1.5,
    "might": 5.0,
    "finesse": 5.0,
    "wits": 4.0,
    "grit": 4.0,
    "presence": 3.0,
}

# A list of all stat keys for programmatic access
STAT_BONUS_KEYS = ["might", "finesse", "wits", "grit", "presence"]


def calculate_gear_score(item_stats):
    score = 0
    for stat, value in item_stats.items():
        score += value * GEAR_SCORE_WEIGHTS.get(stat, 1.0)  # Default weight of 1 for unlisted stats
    return int(score)


# --- Proficiency Level / XP ---
XP_CURVE = {level: int(100 * (1.2 ** (level - 1))) for level in range(1, 101)} 

# --- Power Budget per Level ---
POWER_BUDGET = {
    1: 5, 2: 8, 3: 11, 4: 15, 5: 18, 6: 21, 7: 24, 8: 28, 9: 32, 10: 36,
    11: 40, 12: 44, 13: 48, 14: 52, 15: 57, 16: 62, 17: 67, 18: 72, 19: 78, 20: 84,
    # (Remaining levels can be populated later)
} 

# --- Lore Card Definitions ---
LORE_CARD_TEMPLATES = {
    "common_might": {"power_cost": 2, "might_bonus": 1},
    "common_finesse": {"power_cost": 2, "finesse_bonus": 1},
    "common_wits": {"power_cost": 2, "wits_bonus": 1},
    "common_grit": {"power_cost": 2, "grit_bonus": 1},
    "common_presence": {"power_cost": 2, "presence_bonus": 1},
    "rare_might": {"power_cost": 5, "might_bonus": 3},
    "rare_grit": {"power_cost": 5, "grit_bonus": 3},
    "epic_might_core": {"power_cost": 10, "might_bonus": 7},
} 

# --- Player Action Definitions ---
ACTIONS = {
    "kill_goblin": {"xp_gain": 50, "ip_gain": 5, "time_cost": 0.1},  # 0.1 hours = 6 minutes
    "kill_orc": {"xp_gain": 150, "ip_gain": 10, "time_cost": 0.25}, # 0.25 hours = 15 minutes
    "social_quest": {"xp_gain": 20, "ip_gain": 100, "time_cost": 0.5},
}

# --- Card Drop Definitions ---
CARD_DROPS = {
    "kill_goblin": {"common_might": 0.02, "common_grit": 0.02},
    "kill_orc": {"common_might": 0.05, "rare_might": 0.01},
    "social_quest": {"common_presence": 0.05, "rare_grit": 0.01},
}

# --- Item Definitions ---
_item_definitions = {
    "rusty_dagger": {"slot": "main_hand", "stats": {"physical_power": 5}},
    "iron_helm": {"slot": "head", "stats": {"armor": 8}},
    "goblin_slayer_sword": {"slot": "main_hand", "stats": {"physical_power": 12, "might": 1}},
    "orcish_greaves": {"slot": "legs", "stats": {"armor": 15, "grit": 1}},
    "elven_gloves": {"slot": "hands", "stats": {"finesse": 2}},
    "scholars_circlet": {"slot": "head", "stats": {"wits": 2}},
}

# Automatically calculate and add gear_score to each item
ITEM_TEMPLATES = {
    item_id: {**data, "gear_score": calculate_gear_score(data["stats"])}
    for item_id, data in _item_definitions.items()
}


# --- Mob Definitions ---
MOB_TEMPLATES = {
    "goblin": {
        "level": 5,
        "power_score": 50,
        "xp_reward": 50,
        "base_time_cost": 0.1,  # 6 minutes for an even fight
        "loot_table": {
            "rusty_dagger": 0.20,  # 20% chance to drop
        }
    },
    "orc": {
        "level": 15,
        "power_score": 180,
        "xp_reward": 150,
        "base_time_cost": 0.25,  # 15 minutes for an even fight
        "loot_table": {
            "iron_helm": 0.15,
            "goblin_slayer_sword": 0.05,
            "orcish_greaves": 0.10,
        }
    }
} 