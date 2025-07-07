import { redisSubscriber } from '../redisClient';
import { connectionManager } from '../connectionManager';
import { OutputEvent } from '../schemas_generated/output_pb';

export function startEgressService() {
  redisSubscriber.subscribe('engine_events', (message) => {
    try {
      const outputEvent = OutputEvent.deserializeBinary(message);
      const targetUserIds = outputEvent.getTargetUserIdsList();
      
      for (const userId of targetUserIds) {
        const socket = connectionManager.get(userId);
        if (socket) {
          if (outputEvent.hasChatMessage()) {
            const chatMessage = outputEvent.getChatMessage()!;
            const payload = {
              type: 'ChatMessage',
              payload: {
                senderName: chatMessage.getSenderName(),
                content: chatMessage.getContent(),
                messageType: chatMessage.getMessageType()
              }
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasAreaUpdate()) {
            const areaUpdate = outputEvent.getAreaUpdate()!;
            const payload = {
              type: 'AreaUpdate',
              payload: {
                // Add area update fields here based on the proto definition
              }
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