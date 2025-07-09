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
  }

  export enum PayloadCase {
    PAYLOAD_NOT_SET = 0,
    CHAT_HISTORY = 2,
    CHAT_MESSAGE = 3,
    AREA_UPDATE = 4,
    CHARACTER_LIST = 5,
    CHARACTER_SHEET = 6,
  }
}

