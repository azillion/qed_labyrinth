import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";

const [character, setCharacter] = createStore({
  id: null,
  name: null,
});

const [characters, setCharacters] = createStore([]);
const [loadingCharacters, setLoadingCharacters] = createSignal(false);
const [characterError, setCharacterError] = createSignal(null);

// Export handlers that will be registered later
export const characterHandlers = {
  'CharacterList': (payload) => {
    console.log('CharacterList', payload);
    setCharacters(payload.characters);
    setLoadingCharacters(false);
  },
  'CharacterSelected': (payload) => {
    console.log('CharacterSelected', payload);
    setCharacter(payload.character);
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
  }
};

// Actions that will be initialized with messageHandlers
export let characterActions = null;

export const initializeCharacterActions = (messageHandlers) => {
  characterActions = {
    select: async (characterId) => {
      try {
        await messageHandlers.select(characterId);
        setCharacter('id', characterId);
        setCharacterError(null);
      } catch (error) {
        setCharacterError(error.message);
        throw error;
      }
    },

    list: async () => {
      setLoadingCharacters(true);
      try {
        await messageHandlers.list();
        setCharacterError(null);
      } catch (error) {
        setCharacterError(error.message);
        setLoadingCharacters(false);
        throw error;
      }
    },

    create: async (characterData) => {
      try {
        await messageHandlers.create(characterData);
        setCharacterError(null);
      } catch (error) {
        setCharacterError(error.message);
        throw error;
      }
    }
  };
};

// Helper functions
export const isCharacterSelected = () => character.id !== null;

export {
  characters,
  setCharacters,
  loadingCharacters,
  characterError
};