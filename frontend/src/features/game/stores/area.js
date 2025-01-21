import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";

// Core area state
const [area, setArea] = createStore({
    name: null,
    description: null,
    exits: [],
    objects: [], // For future implementation
    characters: [] // For future implementation
});

// Loading and error states
const [isLoading, setIsLoading] = createSignal(false);
const [error, setError] = createSignal(null);

// Message handlers that will be registered with WebSocket system
export const areaHandlers = {
    'Area': (payload) => {
        setArea({
            name: payload.area.name,
            description: payload.area.description,
            exits: payload.area.exits
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
export let areaActions = null;

export const initializeAreaActions = (messageHandlers) => {
    areaActions = {
        move: async (direction) => {
            try {
                setIsLoading(true);
                setError(null);
                await messageHandlers.game.move(direction);
            } catch (error) {
                setError(error.message);
                setIsLoading(false);
                throw error;
            }
        },

        examine: async (target) => {
            try {
                setError(null);
                await messageHandlers.game.action('examine', target);
            } catch (error) {
                setError(error.message);
                throw error;
            }
        }
    };
};

// Helper functions
export const hasExit = (direction) => {
    return area.exits.some(exit => exit.direction === direction);
};

export const getAvailableExits = () => {
    return area.exits.map(exit => exit.direction);
};

export {
    area,
    setArea,
    isLoading,
    error
};