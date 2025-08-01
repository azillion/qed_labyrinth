// package: qed.schemas.output
// file: output.proto

import * as jspb from "google-protobuf";

export class ChatMessage extends jspb.Message {
  getSenderName(): string;
  setSenderName(value: string): void;

  getContent(): string;
  setContent(value: string): void;

  getMessageType(): string;
  setMessageType(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): ChatMessage.AsObject;
  static toObject(includeInstance: boolean, msg: ChatMessage): ChatMessage.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: ChatMessage, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): ChatMessage;
  static deserializeBinaryFromReader(message: ChatMessage, reader: jspb.BinaryReader): ChatMessage;
}

export namespace ChatMessage {
  export type AsObject = {
    senderName: string,
    content: string,
    messageType: string,
  }
}

export class ChatHistory extends jspb.Message {
  clearMessagesList(): void;
  getMessagesList(): Array<ChatMessage>;
  setMessagesList(value: Array<ChatMessage>): void;
  addMessages(value?: ChatMessage, index?: number): ChatMessage;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): ChatHistory.AsObject;
  static toObject(includeInstance: boolean, msg: ChatHistory): ChatHistory.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: ChatHistory, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): ChatHistory;
  static deserializeBinaryFromReader(message: ChatHistory, reader: jspb.BinaryReader): ChatHistory;
}

export namespace ChatHistory {
  export type AsObject = {
    messagesList: Array<ChatMessage.AsObject>,
  }
}

export class Exit extends jspb.Message {
  getDirection(): string;
  setDirection(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): Exit.AsObject;
  static toObject(includeInstance: boolean, msg: Exit): Exit.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: Exit, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): Exit;
  static deserializeBinaryFromReader(message: Exit, reader: jspb.BinaryReader): Exit;
}

export namespace Exit {
  export type AsObject = {
    direction: string,
  }
}

export class AreaItem extends jspb.Message {
  getId(): string;
  setId(value: string): void;

  getName(): string;
  setName(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): AreaItem.AsObject;
  static toObject(includeInstance: boolean, msg: AreaItem): AreaItem.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: AreaItem, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): AreaItem;
  static deserializeBinaryFromReader(message: AreaItem, reader: jspb.BinaryReader): AreaItem;
}

export namespace AreaItem {
  export type AsObject = {
    id: string,
    name: string,
  }
}

export class AreaUpdate extends jspb.Message {
  getAreaId(): string;
  setAreaId(value: string): void;

  getName(): string;
  setName(value: string): void;

  getDescription(): string;
  setDescription(value: string): void;

  clearExitsList(): void;
  getExitsList(): Array<Exit>;
  setExitsList(value: Array<Exit>): void;
  addExits(value?: Exit, index?: number): Exit;

  clearItemsList(): void;
  getItemsList(): Array<AreaItem>;
  setItemsList(value: Array<AreaItem>): void;
  addItems(value?: AreaItem, index?: number): AreaItem;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): AreaUpdate.AsObject;
  static toObject(includeInstance: boolean, msg: AreaUpdate): AreaUpdate.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: AreaUpdate, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): AreaUpdate;
  static deserializeBinaryFromReader(message: AreaUpdate, reader: jspb.BinaryReader): AreaUpdate;
}

export namespace AreaUpdate {
  export type AsObject = {
    areaId: string,
    name: string,
    description: string,
    exitsList: Array<Exit.AsObject>,
    itemsList: Array<AreaItem.AsObject>,
  }
}

export class ListCharacter extends jspb.Message {
  getId(): string;
  setId(value: string): void;

  getName(): string;
  setName(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): ListCharacter.AsObject;
  static toObject(includeInstance: boolean, msg: ListCharacter): ListCharacter.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: ListCharacter, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): ListCharacter;
  static deserializeBinaryFromReader(message: ListCharacter, reader: jspb.BinaryReader): ListCharacter;
}

export namespace ListCharacter {
  export type AsObject = {
    id: string,
    name: string,
  }
}

export class InventoryItem extends jspb.Message {
  getId(): string;
  setId(value: string): void;

  getName(): string;
  setName(value: string): void;

  getDescription(): string;
  setDescription(value: string): void;

  getQuantity(): number;
  setQuantity(value: number): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): InventoryItem.AsObject;
  static toObject(includeInstance: boolean, msg: InventoryItem): InventoryItem.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: InventoryItem, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): InventoryItem;
  static deserializeBinaryFromReader(message: InventoryItem, reader: jspb.BinaryReader): InventoryItem;
}

export namespace InventoryItem {
  export type AsObject = {
    id: string,
    name: string,
    description: string,
    quantity: number,
  }
}

export class InventoryList extends jspb.Message {
  clearItemsList(): void;
  getItemsList(): Array<InventoryItem>;
  setItemsList(value: Array<InventoryItem>): void;
  addItems(value?: InventoryItem, index?: number): InventoryItem;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): InventoryList.AsObject;
  static toObject(includeInstance: boolean, msg: InventoryList): InventoryList.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: InventoryList, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): InventoryList;
  static deserializeBinaryFromReader(message: InventoryList, reader: jspb.BinaryReader): InventoryList;
}

export namespace InventoryList {
  export type AsObject = {
    itemsList: Array<InventoryItem.AsObject>,
  }
}

export class CharacterList extends jspb.Message {
  clearCharactersList(): void;
  getCharactersList(): Array<ListCharacter>;
  setCharactersList(value: Array<ListCharacter>): void;
  addCharacters(value?: ListCharacter, index?: number): ListCharacter;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): CharacterList.AsObject;
  static toObject(includeInstance: boolean, msg: CharacterList): CharacterList.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: CharacterList, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): CharacterList;
  static deserializeBinaryFromReader(message: CharacterList, reader: jspb.BinaryReader): CharacterList;
}

export namespace CharacterList {
  export type AsObject = {
    charactersList: Array<ListCharacter.AsObject>,
  }
}

export class CoreAttributes extends jspb.Message {
  getMight(): number;
  setMight(value: number): void;

  getFinesse(): number;
  setFinesse(value: number): void;

  getWits(): number;
  setWits(value: number): void;

  getGrit(): number;
  setGrit(value: number): void;

  getPresence(): number;
  setPresence(value: number): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): CoreAttributes.AsObject;
  static toObject(includeInstance: boolean, msg: CoreAttributes): CoreAttributes.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: CoreAttributes, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): CoreAttributes;
  static deserializeBinaryFromReader(message: CoreAttributes, reader: jspb.BinaryReader): CoreAttributes;
}

export namespace CoreAttributes {
  export type AsObject = {
    might: number,
    finesse: number,
    wits: number,
    grit: number,
    presence: number,
  }
}

export class DerivedStats extends jspb.Message {
  getPhysicalPower(): number;
  setPhysicalPower(value: number): void;

  getSpellPower(): number;
  setSpellPower(value: number): void;

  getAccuracy(): number;
  setAccuracy(value: number): void;

  getEvasion(): number;
  setEvasion(value: number): void;

  getArmor(): number;
  setArmor(value: number): void;

  getResolve(): number;
  setResolve(value: number): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): DerivedStats.AsObject;
  static toObject(includeInstance: boolean, msg: DerivedStats): DerivedStats.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: DerivedStats, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): DerivedStats;
  static deserializeBinaryFromReader(message: DerivedStats, reader: jspb.BinaryReader): DerivedStats;
}

export namespace DerivedStats {
  export type AsObject = {
    physicalPower: number,
    spellPower: number,
    accuracy: number,
    evasion: number,
    armor: number,
    resolve: number,
  }
}

export class CharacterSheet extends jspb.Message {
  getId(): string;
  setId(value: string): void;

  getName(): string;
  setName(value: string): void;

  getHealth(): number;
  setHealth(value: number): void;

  getMaxHealth(): number;
  setMaxHealth(value: number): void;

  getActionPoints(): number;
  setActionPoints(value: number): void;

  getMaxActionPoints(): number;
  setMaxActionPoints(value: number): void;

  hasCoreAttributes(): boolean;
  clearCoreAttributes(): void;
  getCoreAttributes(): CoreAttributes | undefined;
  setCoreAttributes(value?: CoreAttributes): void;

  hasDerivedStats(): boolean;
  clearDerivedStats(): void;
  getDerivedStats(): DerivedStats | undefined;
  setDerivedStats(value?: DerivedStats): void;

  getProficiencyLevel(): number;
  setProficiencyLevel(value: number): void;

  getPowerBudget(): number;
  setPowerBudget(value: number): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): CharacterSheet.AsObject;
  static toObject(includeInstance: boolean, msg: CharacterSheet): CharacterSheet.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: CharacterSheet, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): CharacterSheet;
  static deserializeBinaryFromReader(message: CharacterSheet, reader: jspb.BinaryReader): CharacterSheet;
}

export namespace CharacterSheet {
  export type AsObject = {
    id: string,
    name: string,
    health: number,
    maxHealth: number,
    actionPoints: number,
    maxActionPoints: number,
    coreAttributes?: CoreAttributes.AsObject,
    derivedStats?: DerivedStats.AsObject,
    proficiencyLevel: number,
    powerBudget: number,
  }
}

export class EquippedItem extends jspb.Message {
  getId(): string;
  setId(value: string): void;

  getName(): string;
  setName(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): EquippedItem.AsObject;
  static toObject(includeInstance: boolean, msg: EquippedItem): EquippedItem.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: EquippedItem, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): EquippedItem;
  static deserializeBinaryFromReader(message: EquippedItem, reader: jspb.BinaryReader): EquippedItem;
}

export namespace EquippedItem {
  export type AsObject = {
    id: string,
    name: string,
  }
}

export class EquipmentUpdate extends jspb.Message {
  hasMainHand(): boolean;
  clearMainHand(): void;
  getMainHand(): EquippedItem | undefined;
  setMainHand(value?: EquippedItem): void;

  hasOffHand(): boolean;
  clearOffHand(): void;
  getOffHand(): EquippedItem | undefined;
  setOffHand(value?: EquippedItem): void;

  hasHead(): boolean;
  clearHead(): void;
  getHead(): EquippedItem | undefined;
  setHead(value?: EquippedItem): void;

  hasChest(): boolean;
  clearChest(): void;
  getChest(): EquippedItem | undefined;
  setChest(value?: EquippedItem): void;

  hasLegs(): boolean;
  clearLegs(): void;
  getLegs(): EquippedItem | undefined;
  setLegs(value?: EquippedItem): void;

  hasFeet(): boolean;
  clearFeet(): void;
  getFeet(): EquippedItem | undefined;
  setFeet(value?: EquippedItem): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): EquipmentUpdate.AsObject;
  static toObject(includeInstance: boolean, msg: EquipmentUpdate): EquipmentUpdate.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: EquipmentUpdate, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): EquipmentUpdate;
  static deserializeBinaryFromReader(message: EquipmentUpdate, reader: jspb.BinaryReader): EquipmentUpdate;
}

export namespace EquipmentUpdate {
  export type AsObject = {
    mainHand?: EquippedItem.AsObject,
    offHand?: EquippedItem.AsObject,
    head?: EquippedItem.AsObject,
    chest?: EquippedItem.AsObject,
    legs?: EquippedItem.AsObject,
    feet?: EquippedItem.AsObject,
  }
}

export class MetricsReport extends jspb.Message {
  getJsonPayload(): string;
  setJsonPayload(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): MetricsReport.AsObject;
  static toObject(includeInstance: boolean, msg: MetricsReport): MetricsReport.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: MetricsReport, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): MetricsReport;
  static deserializeBinaryFromReader(message: MetricsReport, reader: jspb.BinaryReader): MetricsReport;
}

export namespace MetricsReport {
  export type AsObject = {
    jsonPayload: string,
  }
}

export class LoreCardInstance extends jspb.Message {
  getId(): string;
  setId(value: string): void;

  getTemplateId(): string;
  setTemplateId(value: string): void;

  getTitle(): string;
  setTitle(value: string): void;

  getDescription(): string;
  setDescription(value: string): void;

  getIsActive(): boolean;
  setIsActive(value: boolean): void;

  getPowerCost(): number;
  setPowerCost(value: number): void;

  clearBonusesList(): void;
  getBonusesList(): Array<LoreCardBonus>;
  setBonusesList(value: Array<LoreCardBonus>): void;
  addBonuses(value?: LoreCardBonus, index?: number): LoreCardBonus;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): LoreCardInstance.AsObject;
  static toObject(includeInstance: boolean, msg: LoreCardInstance): LoreCardInstance.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: LoreCardInstance, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): LoreCardInstance;
  static deserializeBinaryFromReader(message: LoreCardInstance, reader: jspb.BinaryReader): LoreCardInstance;
}

export namespace LoreCardInstance {
  export type AsObject = {
    id: string,
    templateId: string,
    title: string,
    description: string,
    isActive: boolean,
    powerCost: number,
    bonusesList: Array<LoreCardBonus.AsObject>,
  }
}

export class LoreCardBonus extends jspb.Message {
  getType(): string;
  setType(value: string): void;

  getValue(): number;
  setValue(value: number): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): LoreCardBonus.AsObject;
  static toObject(includeInstance: boolean, msg: LoreCardBonus): LoreCardBonus.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: LoreCardBonus, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): LoreCardBonus;
  static deserializeBinaryFromReader(message: LoreCardBonus, reader: jspb.BinaryReader): LoreCardBonus;
}

export namespace LoreCardBonus {
  export type AsObject = {
    type: string,
    value: number,
  }
}

export class LoreCardCollection extends jspb.Message {
  clearCardsList(): void;
  getCardsList(): Array<LoreCardInstance>;
  setCardsList(value: Array<LoreCardInstance>): void;
  addCards(value?: LoreCardInstance, index?: number): LoreCardInstance;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): LoreCardCollection.AsObject;
  static toObject(includeInstance: boolean, msg: LoreCardCollection): LoreCardCollection.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: LoreCardCollection, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): LoreCardCollection;
  static deserializeBinaryFromReader(message: LoreCardCollection, reader: jspb.BinaryReader): LoreCardCollection;
}

export namespace LoreCardCollection {
  export type AsObject = {
    cardsList: Array<LoreCardInstance.AsObject>,
  }
}

export class LevelUpNotification extends jspb.Message {
  getNewLevel(): number;
  setNewLevel(value: number): void;

  getNewPowerBudget(): number;
  setNewPowerBudget(value: number): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): LevelUpNotification.AsObject;
  static toObject(includeInstance: boolean, msg: LevelUpNotification): LevelUpNotification.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: LevelUpNotification, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): LevelUpNotification;
  static deserializeBinaryFromReader(message: LevelUpNotification, reader: jspb.BinaryReader): LevelUpNotification;
}

export namespace LevelUpNotification {
  export type AsObject = {
    newLevel: number,
    newPowerBudget: number,
  }
}

export class LoreCardAwarded extends jspb.Message {
  hasCard(): boolean;
  clearCard(): void;
  getCard(): LoreCardInstance | undefined;
  setCard(value?: LoreCardInstance): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): LoreCardAwarded.AsObject;
  static toObject(includeInstance: boolean, msg: LoreCardAwarded): LoreCardAwarded.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: LoreCardAwarded, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): LoreCardAwarded;
  static deserializeBinaryFromReader(message: LoreCardAwarded, reader: jspb.BinaryReader): LoreCardAwarded;
}

export namespace LoreCardAwarded {
  export type AsObject = {
    card?: LoreCardInstance.AsObject,
  }
}

export class OutputEvent extends jspb.Message {
  clearTargetUserIdsList(): void;
  getTargetUserIdsList(): Array<string>;
  setTargetUserIdsList(value: Array<string>): void;
  addTargetUserIds(value: string, index?: number): string;

  hasChatHistory(): boolean;
  clearChatHistory(): void;
  getChatHistory(): ChatHistory | undefined;
  setChatHistory(value?: ChatHistory): void;

  hasChatMessage(): boolean;
  clearChatMessage(): void;
  getChatMessage(): ChatMessage | undefined;
  setChatMessage(value?: ChatMessage): void;

  hasAreaUpdate(): boolean;
  clearAreaUpdate(): void;
  getAreaUpdate(): AreaUpdate | undefined;
  setAreaUpdate(value?: AreaUpdate): void;

  hasCharacterList(): boolean;
  clearCharacterList(): void;
  getCharacterList(): CharacterList | undefined;
  setCharacterList(value?: CharacterList): void;

  hasCharacterSheet(): boolean;
  clearCharacterSheet(): void;
  getCharacterSheet(): CharacterSheet | undefined;
  setCharacterSheet(value?: CharacterSheet): void;

  hasInventoryList(): boolean;
  clearInventoryList(): void;
  getInventoryList(): InventoryList | undefined;
  setInventoryList(value?: InventoryList): void;

  hasMetricsReport(): boolean;
  clearMetricsReport(): void;
  getMetricsReport(): MetricsReport | undefined;
  setMetricsReport(value?: MetricsReport): void;

  hasEquipmentUpdate(): boolean;
  clearEquipmentUpdate(): void;
  getEquipmentUpdate(): EquipmentUpdate | undefined;
  setEquipmentUpdate(value?: EquipmentUpdate): void;

  hasLoreCardCollection(): boolean;
  clearLoreCardCollection(): void;
  getLoreCardCollection(): LoreCardCollection | undefined;
  setLoreCardCollection(value?: LoreCardCollection): void;

  hasLevelUpNotification(): boolean;
  clearLevelUpNotification(): void;
  getLevelUpNotification(): LevelUpNotification | undefined;
  setLevelUpNotification(value?: LevelUpNotification): void;

  hasLoreCardAwarded(): boolean;
  clearLoreCardAwarded(): void;
  getLoreCardAwarded(): LoreCardAwarded | undefined;
  setLoreCardAwarded(value?: LoreCardAwarded): void;

  getTraceId(): string;
  setTraceId(value: string): void;

  getPayloadCase(): OutputEvent.PayloadCase;
  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): OutputEvent.AsObject;
  static toObject(includeInstance: boolean, msg: OutputEvent): OutputEvent.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: OutputEvent, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): OutputEvent;
  static deserializeBinaryFromReader(message: OutputEvent, reader: jspb.BinaryReader): OutputEvent;
}

export namespace OutputEvent {
  export type AsObject = {
    targetUserIdsList: Array<string>,
    chatHistory?: ChatHistory.AsObject,
    chatMessage?: ChatMessage.AsObject,
    areaUpdate?: AreaUpdate.AsObject,
    characterList?: CharacterList.AsObject,
    characterSheet?: CharacterSheet.AsObject,
    inventoryList?: InventoryList.AsObject,
    metricsReport?: MetricsReport.AsObject,
    equipmentUpdate?: EquipmentUpdate.AsObject,
    loreCardCollection?: LoreCardCollection.AsObject,
    levelUpNotification?: LevelUpNotification.AsObject,
    loreCardAwarded?: LoreCardAwarded.AsObject,
    traceId: string,
  }

  export enum PayloadCase {
    PAYLOAD_NOT_SET = 0,
    CHAT_HISTORY = 2,
    CHAT_MESSAGE = 3,
    AREA_UPDATE = 4,
    CHARACTER_LIST = 5,
    CHARACTER_SHEET = 6,
    INVENTORY_LIST = 7,
    METRICS_REPORT = 8,
    EQUIPMENT_UPDATE = 9,
    LORE_CARD_COLLECTION = 11,
    LEVEL_UP_NOTIFICATION = 12,
    LORE_CARD_AWARDED = 13,
  }
}

