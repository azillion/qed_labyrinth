import { randomUUID } from 'crypto';
import redisClient from '../redisClient';
// Note: Generated types will be available after running the proto:gen script
// import { InputEvent } from '../schemas_generated/input_pb';

export async function publishPlayerCommand(userId: string, command: any): Promise<void> {
  try {
    // Generate a unique trace ID for this command
    const traceId = randomUUID();
    
    // Create the InputEvent message structure
    // This will be replaced with proper Protobuf serialization once types are generated
    const inputEvent = {
      user_id: userId,
      trace_id: traceId,
      payload: command
    };
    
    // For now, publish as JSON string - this will be replaced with Protobuf serialization
    const serializedEvent = JSON.stringify(inputEvent);
    
    // Publish to the player_commands channel
    await redisClient.publish('player_commands', serializedEvent);
    
    console.log(`Published command for user ${userId} with trace ID ${traceId}`);
  } catch (error) {
    console.error('Error publishing player command:', error);
    throw error;
  }
}