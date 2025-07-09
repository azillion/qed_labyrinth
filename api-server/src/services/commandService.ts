import { randomUUID } from 'crypto';
import redisClient from '../redisClient';
import { InputEvent, PlayerCommand, MoveCommand, SayCommand, CreateCharacterCommand, ListCharactersCommand, Direction } from '../schemas_generated/input_pb';

export async function publishPlayerCommand(userId: string, command: any): Promise<void> {
  try {
    // Generate a unique trace ID for this command
    const traceId = randomUUID();
    
    // Create the InputEvent message structure
    const inputEvent = new InputEvent();
    inputEvent.setUserId(userId);
    inputEvent.setTraceId(traceId);
    
    // Create PlayerCommand based on the command type
    const playerCommand = new PlayerCommand();
    
    switch (command.type) {
      case 'Move': {
        const moveCommand = new MoveCommand();
        // Map direction string to Direction enum
        const directionMap: { [key: string]: typeof Direction[keyof typeof Direction] } = {
          'NORTH': Direction.NORTH,
          'SOUTH': Direction.SOUTH,
          'EAST': Direction.EAST,
          'WEST': Direction.WEST,
          'UP': Direction.UP,
          'DOWN': Direction.DOWN
        };
        moveCommand.setDirection(directionMap[command.payload.direction] || Direction.NORTH);
        playerCommand.setMove(moveCommand);
        break;
      }
      case 'Say': {
        const sayCommand = new SayCommand();
        sayCommand.setContent(command.payload.content);
        playerCommand.setSay(sayCommand);
        break;
      }
      case 'CreateCharacter': {
        const createCharacterCommand = new CreateCharacterCommand();
        createCharacterCommand.setName(command.payload.name);
        createCharacterCommand.setMight(command.payload.might);
        createCharacterCommand.setFinesse(command.payload.finesse);
        createCharacterCommand.setWits(command.payload.wits);
        createCharacterCommand.setGrit(command.payload.grit);
        createCharacterCommand.setPresence(command.payload.presence);
        playerCommand.setCreateCharacter(createCharacterCommand);
        break;
      }
      case 'ListCharacters': {
        const listCharactersCommand = new ListCharactersCommand();
        // No fields to set – empty message
        playerCommand.setListCharacters(listCharactersCommand);
        break;
      }
      default:
        throw new Error(`Unknown command type: ${command.type}`);
    }
    
    inputEvent.setPayload(playerCommand);
    
    // Serialize the InputEvent to binary format
    const serializedEvent = inputEvent.serializeBinary();
    
    // Publish to the player_commands channel
    await redisClient.publish(
      'player_commands',
      Buffer.from(serializedEvent).toString('latin1')   // preserves raw bytes 0–255
    );
    
    console.log(`Published command for user ${userId} with trace ID ${traceId}`);
  } catch (error) {
    console.error('Error publishing player command:', error);
    throw error;
  }
}