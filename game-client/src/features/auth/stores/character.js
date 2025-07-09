import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from '@lib/socket';

export const [character, setCharacter] = createStore({
  id: null,
  name: null,
  health: 0,
  max_health: 0,
  action_points: 0,
  max_action_points: 0,
  core_attributes: {
    might: 0,
    finesse: 0,
    wits: 0,
    grit: 0,
    presence: 0,
  },
  derived_stats: {
    physical_power: 0,
    spell_power: 0,
    accuracy: 0,
    evasion: 0,
    armor: 0,
    resolve: 0,
  },
});

export const [characters, setCharacters] = createStore([]);
export const [loadingCharacters, setLoadingCharacters] = createSignal(false);
export const [characterError, setCharacterError] = createSignal(null);

// Helper to map server camelCase payload to client snake_case state
function mapCharacterPayload(payload) {
  if (!payload) return {};
  return {
    id: payload.id ?? null,
    name: payload.name ?? null,
    health: payload.health ?? 0,
    max_health: payload.maxHealth ?? 0,
    action_points: payload.actionPoints ?? 0,
    max_action_points: payload.maxActionPoints ?? 0,
    core_attributes: payload.coreAttributes ? {
      might: payload.coreAttributes.might ?? 0,
      finesse: payload.coreAttributes.finesse ?? 0,
      wits: payload.coreAttributes.wits ?? 0,
      grit: payload.coreAttributes.grit ?? 0,
      presence: payload.coreAttributes.presence ?? 0,
    } : {
      might: 0, finesse: 0, wits: 0, grit: 0, presence: 0
    },
    derived_stats: payload.derivedStats ? {
      physical_power: payload.derivedStats.physicalPower ?? 0,
      spell_power: payload.derivedStats.spellPower ?? 0,
      accuracy: payload.derivedStats.accuracy ?? 0,
      evasion: payload.derivedStats.evasion ?? 0,
      armor: payload.derivedStats.armor ?? 0,
      resolve: payload.derivedStats.resolve ?? 0,
    } : {
      physical_power: 0, spell_power: 0, accuracy: 0, evasion: 0, armor: 0, resolve: 0
    },
  };
}

// Export handlers that will be registered later
export const characterHandlers = {
  'CharacterList': (payload) => {
    setCharacters(payload.characters);
    setLoadingCharacters(false);
  },
  'CharacterSelected': (payload) => {
    setCharacter(mapCharacterPayload(payload.character_sheet));
  },
  'CharacterSelectionFailed': (payload) => {
    setCharacterError(payload.message);
  },
  'CharacterListFailed': (payload) => {
    setCharacterError(payload.message);
  },
  'CharacterCreated': (payload) => {
    console.log('CharacterCreated', payload);
    setCharacter(mapCharacterPayload(payload));
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
