import { createStore } from "solid-js/store";
import { createSignal } from "solid-js";
import { socketManager } from '@lib/socket';
import { area } from './area';
import { inventoryActions } from './inventory';

// Core chat state 
export const [messages, setMessages] = createStore([]);

// Loading and error states
export const [isLoading, setIsLoading] = createSignal(false);
export const [error, setError] = createSignal(null);

// Message handlers that will be registered with WebSocket system
export const chatHandlers = {
    'ChatMessage': (payload) => {
        // payload is a single message object coming from protobuf .toObject()
        // Fields: senderName, content, messageType
        const msg = {
            sender_name: payload.senderName,
            content: payload.content,
            message_type: payload.messageType,
            timestamp: Date.now()
        };
        setMessages(msgs => [...msgs, msg]);
    },
    'ChatHistory': (payload) => {
        // Expect payload.messagesList from protobuf object
        const msgs = (payload.messagesList || []).map(m => ({
            sender_name: m.senderName,
            content: m.content,
            message_type: m.messageType,
            timestamp: Date.now()
        }));
        setMessages(msgs);
        setIsLoading(false);
        setError(null);
    },
    'ChatError': (payload) => {
        setError(payload.error);
        setIsLoading(false);
    },
    'CommandSuccess': (payload) => {
        const { message } = payload;
        setMessages(msgs => [...msgs, message]);
    },
    'CommandFailed': (payload) => {
        const { error } = payload;
        setMessages(msgs => [...msgs, {
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
            socketManager.send('Say', { content: content });
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
            // Parse the command
            const parts = content.trim().split(' ');
            const command = parts[0].toLowerCase();
            
            // Handle movement commands
            if (command === '/north' || command === '/n') {
                socketManager.send('Move', { direction: 'NORTH' });
            } else if (command === '/south' || command === '/s') {
                socketManager.send('Move', { direction: 'SOUTH' });
            } else if (command === '/east' || command === '/e') {
                socketManager.send('Move', { direction: 'EAST' });
            } else if (command === '/west' || command === '/w') {
                socketManager.send('Move', { direction: 'WEST' });
            } else if (command === '/up' || command === '/u') {
                socketManager.send('Move', { direction: 'UP' });
            } else if (command === '/down' || command === '/d') {
                socketManager.send('Move', { direction: 'DOWN' });
            } else if (command === '/say') {
                // Handle say command
                const message = parts.slice(1).join(' ');
                if (message) {
                    socketManager.send('Say', { content: message });
                }
            } else if (command === '/get') {
                const itemName = parts.slice(1).join(' ').toLowerCase();
                if (!itemName) {
                    setError("Usage: /get <item name>");
                    return;
                }
                const item = area.items.find(i => i.name.toLowerCase() === itemName);
                if (item) {
                    inventoryActions.take(item.id);
                } else {
                    setError("You don't see that here.");
                }
            } else {
                // Unknown command - could add error handling here
                setError(`Unknown command: ${command}`);
            }
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