import { redisSubscriber } from '../redisClient';
import { connectionManager } from '../connectionManager';
import { OutputEvent } from '../schemas_generated/output_pb';
import { FastifyBaseLogger } from 'fastify';

export function startEgressService(log: FastifyBaseLogger) {
  // The third argument `true` tells node-redis to deliver messages as Buffer instead of string
  // @ts-ignore - the node-redis typings may not include the boolean flag
  redisSubscriber.subscribe('engine_events', (message) => {
    try {
      // The message is already a Buffer (Uint8Array), we can feed it directly to protobuf
      const outputEvent = OutputEvent.deserializeBinary(message as unknown as Uint8Array);
      const targetUserIds = outputEvent.getTargetUserIdsList();
      const traceId = outputEvent.getTraceId();

      log.info({
        traceId,
        targetUserIds,
        payloadType: outputEvent.getPayloadCase()
      }, 'Processing egress event');

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
          } else if (outputEvent.hasEquipmentUpdate && outputEvent.hasEquipmentUpdate()) {
            const equipmentUpdate = outputEvent.getEquipmentUpdate()!;
            const obj = equipmentUpdate.toObject();
            // Convert optional fields to null if missing
            const payload = {
              type: 'EquipmentUpdate',
              payload: {
                mainHand: obj.mainHand ?? null,
                offHand: obj.offHand ?? null,
                head: obj.head ?? null,
                chest: obj.chest ?? null,
                legs: obj.legs ?? null,
                feet: obj.feet ?? null,
              }
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasMetricsReport && outputEvent.hasMetricsReport()) {
            const metricsReport = outputEvent.getMetricsReport()!;
            const payload = {
              type: 'AdminMetrics',
              payload: {
                metrics: metricsReport.getJsonPayload()
              }
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasLoreCardCollection && outputEvent.hasLoreCardCollection()) {
            const coll = outputEvent.getLoreCardCollection()!;
            const payload = {
              type: 'LoreCardCollection',
              payload: coll.toObject()
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasLevelUpNotification && outputEvent.hasLevelUpNotification()) {
            const lvl = outputEvent.getLevelUpNotification()!;
            const payload = {
              type: 'LevelUpNotification',
              payload: lvl.toObject()
            };
            socket.send(JSON.stringify(payload));
          } else if (outputEvent.hasLoreCardAwarded && outputEvent.hasLoreCardAwarded()) {
            const awarded = outputEvent.getLoreCardAwarded()!;
            const payload = {
              type: 'LoreCardAwarded',
              payload: awarded.toObject()
            };
            socket.send(JSON.stringify(payload));
          }
        }
      }
    } catch (error) {
      log.error({ err: error }, 'Error processing engine event:');
    }
  }, true);
}