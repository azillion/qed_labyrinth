// We use environment variables with fallbacks to default values.
// In a Vite (SolidJS) project, ensure your environment variables are prefixed with VITE_.
export const DEBUG = import.meta.env.VITE_DEBUG
	? import.meta.env.VITE_DEBUG.toLowerCase() === 'true'
	: true;

export const GAME_NAME = import.meta.env.VITE_GAME_NAME || "Iron Psalm";
export const SOCKET_URL = import.meta.env.VITE_SOCKET_URL || "ws://localhost:3030/websocket";
export const API_URL = import.meta.env.VITE_API_URL || "http://localhost:3030";

export const ENDPOINTS = {
	login: "/auth/login",
	register: "/auth/register",
};
