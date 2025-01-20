import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";

const [character, setCharacter] = createStore({
  id: null,
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
  'CharacterSelect': (payload) => {
    setCharacter(payload);
  },
  'CharacterUpdate': (payload) => {
    setCharacter(c => ({ ...c, ...payload }));
  },
  'CharacterError': (payload) => {
    setCharacterError(payload.message);
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
      } catch (error) {
        setCharacterError(error.message);
        throw error;
      }
    },

    list: async () => {
      setLoadingCharacters(true);
      try {
        await messageHandlers.list();
      } catch (error) {
        setCharacterError(error.message);
        setLoadingCharacters(false);
        throw error;
      }
    },

    create: async (characterData) => {
      try {
        await messageHandlers.create(characterData);
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
  character,
  setCharacter,
  characters,
  setCharacters,
  loadingCharacters,
  characterError
};