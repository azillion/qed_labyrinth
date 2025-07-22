import { randomUUID } from 'crypto';
import redisClient from '../redisClient';
import { InputEvent, PlayerCommand, MoveCommand, SayCommand, CreateCharacterCommand, ListCharactersCommand, Direction, SelectCharacterCommand, TakeCommand, DropCommand, RequestInventoryCommand, RequestAdminMetricsCommand, EquipCommand, UnequipCommand, ItemSlot, RequestCharacterSheetCommand, ActivateLoreCardCommand, DeactivateLoreCardCommand, RequestLoreCollectionCommand } from '../schemas_generated/input_pb';

export async function publishPlayerCommand(userId: string, command: any): Promise<void> {
  const traceId = randomUUID();
  try {
    const inputEvent = new InputEvent();
    inputEvent.setUserId(userId);
    inputEvent.setTraceId(traceId);
    
    const playerCommand = new PlayerCommand();
    
    switch (command.type) {
      case 'Move': {
        const moveCommand = new MoveCommand();
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
        playerCommand.setListCharacters(listCharactersCommand);
        break;
      }
      case 'SelectCharacter': {
        const selectCharacterCommand = new SelectCharacterCommand();
        selectCharacterCommand.setCharacterId(command.payload.character_id ?? command.payload.characterId);
        playerCommand.setSelectCharacter(selectCharacterCommand);
        break;
      }
      case 'Take': {
        const takeCommand = new TakeCommand();
        takeCommand.setCharacterId(command.payload.characterId);
        takeCommand.setItemEntityId(command.payload.itemEntityId);
        playerCommand.setTake(takeCommand);
        break;
      }
      case 'Drop': {
        const dropCommand = new DropCommand();
        dropCommand.setCharacterId(command.payload.characterId);
        dropCommand.setItemEntityId(command.payload.itemEntityId);
        playerCommand.setDrop(dropCommand);
        break;
      }
      case 'RequestInventory': {
        const requestInvCommand = new RequestInventoryCommand();
        requestInvCommand.setCharacterId(command.payload.characterId);
        playerCommand.setRequestInventory(requestInvCommand);
        break;
      }
      case 'RequestAdminMetrics': {
        const metricsCommand = new RequestAdminMetricsCommand();
        playerCommand.setRequestAdminMetrics(metricsCommand);
        break;
      }
      case 'Equip': {
        const equipCommand = new EquipCommand();
        equipCommand.setCharacterId(command.payload.characterId);
        equipCommand.setItemEntityId(command.payload.itemEntityId);
        playerCommand.setEquip(equipCommand);
        break;
      }
      case 'Unequip': {
        const unequipCommand = new UnequipCommand();
        unequipCommand.setCharacterId(command.payload.characterId);
        
        // The client now sends the correct enum string (e.g., "MAIN_HAND")
        const slotEnumValue = (ItemSlot as any)[command.payload.slot] ?? ItemSlot.NONE;
        unequipCommand.setSlot(slotEnumValue);
        
        playerCommand.setUnequip(unequipCommand);
        break;
      }
      case 'ActivateLoreCard': {
        const actCmd = new ActivateLoreCardCommand();
        actCmd.setCharacterId(command.payload.characterId ?? command.payload.character_id);
        actCmd.setCardInstanceId(command.payload.cardInstanceId ?? command.payload.card_instance_id);
        playerCommand.setActivateLoreCard(actCmd);
        break;
      }
      case 'DeactivateLoreCard': {
        const deactCmd = new DeactivateLoreCardCommand();
        deactCmd.setCharacterId(command.payload.characterId ?? command.payload.character_id);
        deactCmd.setCardInstanceId(command.payload.cardInstanceId ?? command.payload.card_instance_id);
        playerCommand.setDeactivateLoreCard(deactCmd);
        break;
      }
      case 'RequestLoreCollection': {
        const reqCmd = new RequestLoreCollectionCommand();
        reqCmd.setCharacterId(command.payload.characterId ?? command.payload.character_id);
        playerCommand.setRequestLoreCollection(reqCmd);
        break;
      }
      case 'RequestCharacterSheet': {
        const reqSheetCmd = new RequestCharacterSheetCommand();
        reqSheetCmd.setCharacterId(command.payload.characterId ?? command.payload.character_id);
        playerCommand.setRequestCharacterSheet(reqSheetCmd);
        break;
      }
      default:
        throw new Error(`Unknown command type: ${command.type}`);
    }
    
    inputEvent.setPayload(playerCommand);
    
    const serializedEvent = inputEvent.serializeBinary();
    
    await redisClient.publish(
      'player_commands',
      Buffer.from(serializedEvent).toString('latin1')
    );
    
    console.log(JSON.stringify({
      level: 'info',
      timestamp: new Date().toISOString(),
      message: 'Published player command',
      userId,
      traceId,
      commandType: command.type
    }));

  } catch (error) {
    const err = error as Error;
    console.error(JSON.stringify({
        level: 'error',
        timestamp: new Date().toISOString(),
        message: 'Error publishing player command',
        userId,
        traceId,
        commandType: command.type,
        error: { message: err.message, stack: err.stack }
    }));
    throw error;
  }
}