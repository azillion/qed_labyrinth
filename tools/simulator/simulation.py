import pandas as pd
import random
from player import SimulatedPlayer
from config import ACTIONS, MOB_TEMPLATES, ITEM_TEMPLATES, CARD_DROPS


def calculate_fight_outcome(player_power, mob_template):
    mob_power = mob_template.get('power_score', 1)
    power_ratio = max(0.1, player_power / max(1, mob_power))

    # Time cost is now based on the mob's definition, adjusted by power ratio
    time_cost = mob_template["base_time_cost"] / power_ratio

    # XP reward logic
    base_xp = mob_template['xp_reward']
    if power_ratio < 1.0:  # Punching up
        xp_modifier = 1.0 + 0.5 * (1.0 - power_ratio)
    else:  # Punching down
        xp_modifier = max(0.1, 1.0 - (power_ratio - 1.0) * 0.25)

    xp_gain = int(base_xp * xp_modifier)

    return {"time_cost": time_cost, "xp_gain": xp_gain}


def choose_mob_for_player(player_level):
    eligible_mobs = [
        (mob_id, template) for mob_id, template in MOB_TEMPLATES.items()
        if abs(template['level'] - player_level) <= 7
    ]
    if not eligible_mobs:
        return min(MOB_TEMPLATES.items(), key=lambda item: abs(item[1]['level'] - player_level))
    return random.choice(eligible_mobs)


def choose_action_for_archetype(archetype):
    if archetype == "PowerGamer":
        return "kill_orc" if random.random() < 0.8 else "kill_goblin"
    elif archetype == "Roleplayer":
        return "social_quest" if random.random() < 0.9 else "kill_goblin"
    else:  # Balanced
        return random.choice(list(ACTIONS.keys()))


def run_single_simulation(archetype, total_hours):
    player = SimulatedPlayer(archetype)
    history = []
    current_time = 0.0

    while current_time < total_hours:
        action_id = choose_action_for_archetype(player.archetype)
        action_details = ACTIONS[action_id]

        if action_id.startswith("kill_"):
            mob_id, mob_template = choose_mob_for_player(player.level)
            outcome = calculate_fight_outcome(player.player_power_score, mob_template)

            player.gain_xp(outcome['xp_gain'])
            # We still use the original action for its IP reward and card drop chance
            player.ip += action_details.get('ip_gain', 0)
            current_time += outcome['time_cost']

            for item_id, probability in mob_template.get("loot_table", {}).items():
                if random.random() < probability:
                    player.earn_item(item_id)
        else:
            player.gain_xp(action_details['xp_gain'])
            player.ip += action_details['ip_gain']
            current_time += action_details['time_cost']

        if action_id in CARD_DROPS:
            for card_id, probability in CARD_DROPS[action_id].items():
                if random.random() < probability:
                    player.earn_card(card_id)

        history.append({
            "hour": current_time,
            "level": player.level,
            "xp": player.xp,
            "ip": player.ip,
            "player_power_score": player.player_power_score,
            "total_gear_score": player.total_gear_score,
            "might": player.total_might,
            "finesse": player.total_finesse,
            "wits": player.total_wits,
            "grit": player.total_grit,
            "presence": player.total_presence,
        })

    return pd.DataFrame(history) 