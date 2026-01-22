import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from '@lib/socket';

// Core area state
export const [area, setArea] = createStore({
    name: null,
    description: null,
    coordinates: null,
    exits: [],
    elevation: null,
    temperature: null,
    moisture: null,
    items: [],
    objects: [], // For future implementation
    characters: [] // For future implementation
});

// Loading and error states
export const [isLoading, setIsLoading] = createSignal(false);
export const [error, setError] = createSignal(null);

// Message handlers that will be registered with WebSocket system
export const areaHandlers = {
    'Area': (payload) => {
        setArea(prev => {
            const newState = {
                ...prev,
                name: payload.area.name,
                description: payload.area.description,
                coordinate: payload.area.coordinate,
                exits: payload.area.exits,
                elevation: payload.area.elevation,
                temperature: payload.area.temperature,
                moisture: payload.area.moisture,
                objects: [],
                characters: []
            };
            return newState;
        });
        setIsLoading(false);
        setError(null);
    },
    'AreaUpdate': (payload) => {
        // payload comes directly from protobuf .toObject(); fields are camelCase
        setArea(prev => {
            const exits = (payload.exitsList || []).map(e => ({ direction: e.direction }));
            const items = (payload.itemsList || []).map(i => ({ id: i.id, name: i.name }));
            return {
                ...prev,
                name: payload.name,
                description: payload.description,
                exits,
                items,
                // Additional optional fields could be added here later
            };
        });
        setIsLoading(false);
        setError(null);
    },
    'AreaUpdateFailed': (payload) => {
        setError(payload.error);
        setIsLoading(false);
    }
};

// Area actions that will be initialized with messageHandlers
export const areaActions = {
    move: (direction) => {
      setIsLoading(true);
      socketManager.send('Move', { direction });
    }
  };

// Helper functions
export const hasExit = (direction) => {
    return area.exits.some(exit => exit.direction === direction);
};

export const getAvailableExits = () => {
    return area.exits.map(exit => exit.direction);
};