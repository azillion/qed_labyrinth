import { createSignal } from 'solid-js';

// TODO: Pull from environment variable
export const SOCKET_URL = 'ws://localhost:3030/websocket';

export const [socket, setSocket] = createSignal(null);
