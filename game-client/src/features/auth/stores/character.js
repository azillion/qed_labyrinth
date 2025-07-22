import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from '@lib/socket';
import { inventoryActions } from '@features/game/stores/inventory';
import { setProficiencyLevel, setPowerBudget, loreActions } from '@features/game/stores/lore';

export const [character, setCharacter] = createStore({
  id: null,
  name: null,
  health: 0,
  maxHealth: 0,
  actionPoints: 0,
  maxActionPoints: 0,
  coreAttributes: {
    might: 0,
    finesse: 0,
    wits: 0,
    grit: 0,
    presence: 0,
  },
  derivedStats: {
    physicalPower: 0,
    spellPower: 0,
    accuracy: 0,
    evasion: 0,
    armor: 0,
    resolve: 0,
  },
});

export const [characters, setCharacters] = createStore([]);
export const [loadingCharacters, setLoadingCharacters] = createSignal(false);
export const [characterError, setCharacterError] = createSignal(null);

// Export handlers that will be registered later
export const characterHandlers = {
  'CharacterList': (payload) => {
    setCharacters(payload.characters);
    setLoadingCharacters(false);
  },
  'CharacterSelected': (payload) => {
    setCharacter(payload.character_sheet);
    setProficiencyLevel(payload.character_sheet.proficiencyLevel || 1);
    setPowerBudget(payload.character_sheet.powerBudget || 0);
    inventoryActions.request();
    loreActions.requestCollection();
  },
  'CharacterSelectionFailed': (payload) => {
    setCharacterError(payload.message);
  },
  'CharacterListFailed': (payload) => {
    setCharacterError(payload.message);
  },
  'CharacterCreated': (payload) => {
    console.log('CharacterCreated', payload);
    setCharacter(payload);
  },
  'CharacterCreationFailed': (payload) => {
    if (payload.error && payload.error[0] == 'NameTaken') {
        setCharacterError('Name already taken');
    } else {
        setCharacterError('Failed to create character');
    }
  },
  'CharacterSheet': (payload) => {
    setCharacter(payload);
    setProficiencyLevel(payload.proficiencyLevel || 1);
    setPowerBudget(payload.powerBudget || 0);
  }
};

// Actions that will be initialized with messageHandlers
export const characterActions = {
    select: async (characterId) => {
        try {
            socketManager.send('SelectCharacter', { character_id: characterId });
            setCharacter('id', characterId);
        } catch (error) {
            setCharacterError(error.message);
            throw error;
        }
    },
    list: async () => {
        setLoadingCharacters(true);
        try {
            socketManager.send('ListCharacters');
            setCharacterError(null);
        } catch (error) {
            setCharacterError(error.message);
            setLoadingCharacters(false);
            throw error;
        }
    },
    create: async (characterData) => {
        try {
            socketManager.send('CreateCharacter', characterData);
            setCharacterError(null);
        } catch (error) {
            setCharacterError(error.message);
            throw error;
        }
    },
    /** Fetch latest character sheet (stats & attributes) */
    requestSheet: () => {
        const charId = character.id;
        if (!charId) {
            console.error('No active character to request sheet for.');
            return;
        }
        socketManager.send('RequestCharacterSheet', { characterId: charId });
    }
};

// Helper functions
export const isCharacterSelected = () => character.id !== null;
