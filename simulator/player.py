from config import XP_CURVE, POWER_BUDGET, LORE_CARD_TEMPLATES, STAT_POWER_WEIGHTS, ITEM_TEMPLATES, STAT_BONUS_KEYS
import random 


class SimulatedPlayer:
    def __init__(self, archetype="Balanced"):
        self.level = 1
        self.xp = 0
        self.ip = 0
        self.power_budget = POWER_BUDGET[1]
        self.cards_owned = []
        self.active_loadout = []
        self.total_might = 0
        self.total_finesse = 0
        self.total_wits = 0
        self.total_grit = 0
        self.total_presence = 0
        self.archetype = archetype
        self.player_power_score = 0

        # Inventory and equipment
        self.inventory = []
        self.equipment = {
            "main_hand": None, "off_hand": None, "head": None, "chest": None,
            "legs": None, "feet": None, "hands": None, "ring1": None, "ring2": None,
        }
        self.total_gear_score = 0

        # Initialize power score once
        self.recalculate_power_score()

    def gain_xp(self, amount):
        """Add XP and handle level ups if thresholds are crossed."""
        self.xp += amount
        # Loop to handle multiple potential level-ups
        while self.level in XP_CURVE and self.xp >= XP_CURVE[self.level]:
            self.xp -= XP_CURVE[self.level]
            self.level_up() 

    def level_up(self):
        """Increase level, update power budget, and refresh loadout."""
        self.level += 1
        # Update power budget; default to current budget if level not specified
        self.power_budget = POWER_BUDGET.get(self.level, self.power_budget)
        # Reevaluate loadout with potentially larger power budget
        self.update_loadout() 

    def earn_card(self, card_id):
        """Add a card to the player's collection and refresh loadout."""
        card_template = LORE_CARD_TEMPLATES.get(card_id)
        if card_template:
            self.cards_owned.append(card_template)
            self.update_loadout() 

    def earn_item(self, item_id):
        """Add an item to inventory and attempt to equip if it's an upgrade."""
        if item_id in ITEM_TEMPLATES:
            self.inventory.append(item_id)
            self.update_equipment()

    def update_equipment(self):
        """Automatically equip best-in-slot items based on gear_score."""
        for item_id in self.inventory:
            template = ITEM_TEMPLATES[item_id]
            slot = template["slot"]
            new_score = template["gear_score"]

            current_item_id = self.equipment.get(slot)
            if current_item_id is None:
                # Slot empty, equip
                self.equipment[slot] = item_id
            else:
                current_score = ITEM_TEMPLATES[current_item_id]["gear_score"]
                if new_score > current_score:
                    self.equipment[slot] = item_id

        # After equipping, recalc power score
        self.recalculate_power_score()

    def update_loadout(self):
        """Equip the best combination of cards based on available power budget."""
        sorted_cards = sorted(self.cards_owned, key=lambda c: c["power_cost"], reverse=True)

        new_loadout = []
        current_cost = 0

        for card in sorted_cards:
            cost = card["power_cost"]
            if current_cost + cost <= self.power_budget:
                new_loadout.append(card)
                current_cost += cost

        self.active_loadout = new_loadout

        # The single source of truth for stat and power updates
        self.recalculate_power_score()

    # --- Power Calculation ---
    def _update_total_stats(self):
        """Aggregate total stats from active cards and equipped gear."""
        # Reset totals
        for stat in STAT_BONUS_KEYS:
            setattr(self, f"total_{stat}", 0)

        # Sum bonuses from cards
        for card in self.active_loadout:
            for stat in STAT_BONUS_KEYS:
                setattr(
                    self,
                    f"total_{stat}",
                    getattr(self, f"total_{stat}") + card.get(f"{stat}_bonus", 0),
                )

        # Sum bonuses from gear
        for item_id in self.equipment.values():
            if item_id:
                stats = ITEM_TEMPLATES[item_id].get("stats", {})
                for stat in STAT_BONUS_KEYS:
                    setattr(
                        self,
                        f"total_{stat}",
                        getattr(self, f"total_{stat}") + stats.get(stat, 0),
                    )

    def recalculate_power_score(self):
        """Recalculate power score after stats or gear change."""
        # 1. Update combined stats
        self._update_total_stats()

        # 2. Power from stats
        power_from_stats = sum(
            getattr(self, f"total_{stat}") * STAT_POWER_WEIGHTS.get(stat, 1.0)
            for stat in STAT_BONUS_KEYS
        )

        # 3. Gear score (quality bonus)
        self.total_gear_score = sum(
            ITEM_TEMPLATES[item_id]["gear_score"] for item_id in self.equipment.values() if item_id
        )

        # 4. Final power score combines both components
        self.player_power_score = power_from_stats + self.total_gear_score 