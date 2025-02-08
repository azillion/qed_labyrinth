import { socketManager } from '@lib/socket';
import { createSignal } from 'solid-js';

export const [worldMap, setWorldMap] = createSignal(null);

export const mapHandlers = {
    'AdminMap': (payload) => {
        const rooms = payload.world.rooms.map(room => ({
            id: room.id,
            name: room.name,
            x: room.coordinate.x,
            y: room.coordinate.y,
            z: room.coordinate.z
        }));

        const connections = payload.world.connections.map(conn => ({
            from: conn.from,
            to: conn.to_
        }));

        worldMap().updateWorld({
            rooms,
            connections,
            currentLocation: payload.world.current_location
        });
    },
};

export const mapActions = {
    requestAdminMap: async () => {
        socketManager.send('RequestAdminMap');
    }
};
