import { redisSubscriber } from '../redisClient';
import { connectionManager } from '../connectionManager';
import { OutputEvent } from '../schemas_generated/output_pb';

export function startEgressService() {
  redisSubscriber.subscribe('engine_events', (message) => {
    try {
      // Convert the message string to a Buffer for deserialization
      const buffer = Buffer.from(message, 'binary');
      const outputEvent = OutputEvent.deserializeBinary(buffer);
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
          }
        }
      }
    } catch (error) {
      console.error('Error processing engine event:', error);
    }
  });
}