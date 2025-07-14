import { redisSubscriber } from '../redisClient';
import { connectionManager } from '../connectionManager';
import { OutputEvent, CharacterList, CharacterSheet, ChatHistory, InventoryList } from '../schemas_generated/output_pb';

export function startEgressService() {
  // The third argument `true` tells node-redis to deliver messages as Buffer instead of string
  redisSubscriber.subscribe('engine_events', (message) => {
    try {
      // The message is already a Buffer (Uint8Array), we can feed it directly to protobuf
      const outputEvent = OutputEvent.deserializeBinary(message as unknown as Uint8Array);
      const targetUserIds = outputEvent.getTargetUserIdsList();
      
      for (const userId of targetUserIds) {
        const socket = connectionManager.get(userId);
        if (socket) {
          if (outputEvent.hasChatMessage()) {
            const chatMessage = outputEvent.getChatMessage()!;
            const payload = {
              type: 'ChatMessage',
              payload: chatMessage.toObject()
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasAreaUpdate()) {
            const areaUpdate = outputEvent.getAreaUpdate()!;
            const payload = {
              type: 'AreaUpdate',
              payload: areaUpdate.toObject()
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasCharacterList()) {
            const characterList = outputEvent.getCharacterList()!;
            const obj = characterList.toObject();
            const payload = {
              type: 'CharacterList',
              payload: {
                characters: obj.charactersList ?? []
              }
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasChatHistory && outputEvent.hasChatHistory()) {
            const chatHistory = outputEvent.getChatHistory()!;
            const payload = {
              type: 'ChatHistory',
              payload: chatHistory.toObject()
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasCharacterSheet()) {
            const characterSheet = outputEvent.getCharacterSheet()!;
            const obj = characterSheet.toObject();
            const payload = {
              type: 'CharacterSelected',
              payload: {
                character_sheet: obj
              }
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasInventoryList()) {
            const inventoryList = outputEvent.getInventoryList()!;
            const obj = inventoryList.toObject();
            const payload = {
              type: 'InventoryList',
              payload: {
                items: obj.itemsList ?? []
              }
            };
            socket.send(JSON.stringify(payload));
          }
        }
      }
    } catch (error) {
      console.error('Error processing engine event:', error);
    }
  }, true);
}