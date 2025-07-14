import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from '@lib/socket';
import { character } from '@features/auth/stores/character';

// Core inventory state
export const [inventory, setInventory] = createStore([]);

// Loading and error states
export const [isLoading, setIsLoading] = createSignal(false);
export const [error, setError] = createSignal(null);

// Handlers for WebSocket events from the server
export const inventoryHandlers = {
  'InventoryList': (payload) => {
    // payload.items is an array of { name, description, quantity }
    setInventory(payload.items);
    setIsLoading(false);
    setError(null);
  },
  'InventoryError': (payload) => {
    setError(payload.error);
    setIsLoading(false);
  }
};

// Actions that components can call
export const inventoryActions = {
  request: () => {
    const charId = character.id;
    if (!charId) {
      console.error("No active character to request inventory for.");
      return;
    }
    setIsLoading(true);
    try {
      socketManager.send('RequestInventory', { characterId: charId });
    } catch (err) {
      setError(err.message);
      setIsLoading(false);
    }
  },
  take: (itemEntityId) => {
    const charId = character.id;
    if (!charId) return;
    socketManager.send('Take', { characterId: charId, itemEntityId });
  },
  drop: (itemEntityId) => {
    const charId = character.id;
    if (!charId) return;
    socketManager.send('Drop', { characterId: charId, itemEntityId });
  }
}; 