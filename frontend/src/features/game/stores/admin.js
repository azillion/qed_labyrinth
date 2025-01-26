import { socketManager } from '@lib/socket';

export const adminHandlers = {
};

export const adminActions = {
    requestAdminMap: async () => {
        socketManager.send('RequestAdminMap');
    }
  };