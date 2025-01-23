import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";

// Core chat state 
const [messages, setMessages] = createStore([]);

// Loading and error states
const [isLoading, setIsLoading] = createSignal(false);
const [error, setError] = createSignal(null);

// Message handlers that will be registered with WebSocket system
export const chatHandlers = {
    'ChatMessage': (payload) => {
        console.log('ChatMessage', payload);
        const { message } = payload;
        // Only add message if it's for current room
        setMessages(msgs => [...msgs, message]);
    },
    'ChatHistory': (payload) => {
        console.log('ChatHistory', payload);
        const { messages } = payload;
        setMessages(messages);
        setIsLoading(false);
        setError(null);
    },
    'ChatError': (payload) => {
        console.log('ChatError', payload);
        setError(payload.error);
        setIsLoading(false);
    }
};

// Chat actions that will be initialized with messageHandlers
export let chatActions = null;

export const initializeChatActions = (messageHandlers) => {
    chatActions = {
        sendMessage: async (content) => {
            try {
                setError(null);
                await messageHandlers.chat.send(content);
            } catch (error) {
                setError(error.message);
                throw error;
            }
        },

        sendEmote: async (content) => {
            try {
                setError(null);
                await messageHandlers.chat.emote(content);
            } catch (error) {
                setError(error.message);
                throw error;
            }
        },
        sendSystemMessage: async (content) => {
            try {
                setError(null);
                await messageHandlers.chat.system(content);
            } catch (error) {
                setError(error.message);
                throw error;
            }
        },
        requestChatHistory: async () => {
            try {
                await messageHandlers.chat.requestChatHistory();
            } catch (error) {
                setError(error.message);
                throw error;
            }
        }
    };
};

// Room management
export const setRoom = (roomId) => {
    setCurrentRoom(roomId);
    setMessages([]); // Clear messages when changing rooms
};

// Message formatting helpers
export const formatMessage = (message) => {
    switch (message.message_type) {
        case 'Chat':
            return `${message.sender_name}: ${message.content}`;
        case 'Emote':
            return `* ${message.sender_name} ${message.content}`;
        case 'System':
            return message.content;
        default:
            return message.content;
    }
};

export {
    messages,
    setMessages,
    isLoading,
    error
};