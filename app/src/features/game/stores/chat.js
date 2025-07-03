import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from '@lib/socket';

// Core chat state 
export const [messages, setMessages] = createStore([]);

// Loading and error states
export const [isLoading, setIsLoading] = createSignal(false);
export const [error, setError] = createSignal(null);

// Message handlers that will be registered with WebSocket system
export const chatHandlers = {
    'ChatMessage': (payload) => {
        const { message } = payload;
        // Only add message if it's for current room
        setMessages(prev => [...prev, message]);
    },
    'ChatHistory': (payload) => {
        const { messages } = payload;
        setMessages(messages);
        setIsLoading(false);
        setError(null);
    },
    'ChatError': (payload) => {
        setError(payload.error);
        setIsLoading(false);
    },
    'CommandSuccess': (payload) => {
        const { message } = payload;
        setMessages(prev => [...prev, message]);
    },
    'CommandFailed': (payload) => {
        const { error } = payload;
        setMessages(prev => [...prev, {
            sender_id: null,
            message_type: 'CommandFailed',
            content: error,
            timestamp: Date.now(),
            area_id: null
        }]);
    }
};

// Chat actions that will be initialized with messageHandlers
export const chatActions = {
    sendMessage: async (content) => {
        try {
            setError(null);
            socketManager.send('SendChat', { message: content });
        } catch (error) {
            setError(error.message);
            throw error;
        }
    },
    sendEmote: async (content) => {
        try {
            setError(null);
            socketManager.send('SendEmote', { message: content });
        } catch (error) {
            setError(error.message);
            throw error;
        }
    },
    sendSystemMessage: async (content) => {
        try {
            setError(null);
            socketManager.send('SendSystem', { message: content });
        } catch (error) {
            setError(error.message);
            throw error;
        }
    },
    command: async (content) => {
        try {
            socketManager.send('Command', { command: content });
        } catch (error) {
            setError(error.message);
            throw error;
        }
    },
    requestChatHistory: async () => {
        try {
            socketManager.send('RequestChatHistory');
        } catch (error) {
            setError(error.message);
            throw error;
        }
    }
};

// Room management
export const setRoom = (roomId) => {
    setCurrentRoom(roomId);
    setMessages([]); // Clear messages when changing rooms
};