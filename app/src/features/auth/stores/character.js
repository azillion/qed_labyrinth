import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from '@lib/socket';

export const [character, setCharacter] = createStore({
  id: null,
  name: null,
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
    }
};

// Helper functions
export const isCharacterSelected = () => character.id !== null;
