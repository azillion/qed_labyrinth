import { createStore, produce } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from "@lib/socket";
import { character } from "@features/auth/stores/character";

// --- State Signals ---
export const [proficiencyLevel, setProficiencyLevel] = createSignal(1);
export const [powerBudget, setPowerBudget] = createSignal(0);
export const [sagaTier, setSagaTier] = createSignal("Unknown");

// --- State Store ---
export const [lore, setLore] = createStore({
  cards: [], // All earned cards
  isLoading: false,
  error: null,
});

// --- Derived State (Memoized Computations) ---
export const activeCards = () => lore.cards.filter((c) => c.isActive);
export const currentPowerUsed = () =>
  activeCards().reduce((sum, card) => sum + card.powerCost, 0);

// --- WebSocket Handlers ---
export const loreHandlers = {
  LoreCardCollection: (payload) => {
    setLore(
      produce((l) => {
        l.cards = payload.cardsList || [];
        l.isLoading = false;
      })
    );
  },
  LoreCardAwarded: (payload) => {
    setLore(
      produce((l) => {
        if (!l.cards.some((c) => c.id === payload.card.id)) {
          l.cards.push(payload.card);
        }
      })
    );
  },
  LevelUpNotification: (payload) => {
    setProficiencyLevel(payload.newLevel);
    setPowerBudget(payload.newPowerBudget);
  },
};

// --- Actions ---
export const loreActions = {
  requestCollection: () => {
    setLore("isLoading", true);
    socketManager.send("RequestLoreCollection", { characterId: character.id });
  },
  activateCard: (cardInstanceId) => {
    socketManager.send("ActivateLoreCard", {
      characterId: character.id,
      cardInstanceId,
    });
  },
  deactivateCard: (cardInstanceId) => {
    socketManager.send("DeactivateLoreCard", {
      characterId: character.id,
      cardInstanceId,
    });
  },
}; 