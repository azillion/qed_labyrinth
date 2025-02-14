import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from "../../../lib/socket";

export const [status, setStatus] = createStore({
    health: 0,
    mana: 0,
    level: 0,
    experience: 0,
    time_of_day: "day",
});

export const [isLoading, setIsLoading] = createSignal(true);
export const [error, setError] = createSignal(null);

export const statusHandlers = {
    'Status': (payload) => {
        setStatus(prev => ({
            ...prev,
            ...payload.status
        }));
        setIsLoading(false);
    },
    'StatusUpdateFailed': (payload) => {
        setError(payload.error);
        setIsLoading(false);
    }
};

export const statusActions = {
    requestStatus: () => {
        setIsLoading(true);
        socketManager.send('RequestStatus');
    }
};