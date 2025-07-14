// package: qed.schemas.input
// file: input.proto

import * as jspb from "google-protobuf";

export class MoveCommand extends jspb.Message {
  getDirection(): DirectionMap[keyof DirectionMap];
  setDirection(value: DirectionMap[keyof DirectionMap]): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): MoveCommand.AsObject;
  static toObject(includeInstance: boolean, msg: MoveCommand): MoveCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: MoveCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): MoveCommand;
  static deserializeBinaryFromReader(message: MoveCommand, reader: jspb.BinaryReader): MoveCommand;
}

export namespace MoveCommand {
  export type AsObject = {
    direction: DirectionMap[keyof DirectionMap],
  }
}

export class SayCommand extends jspb.Message {
  getContent(): string;
  setContent(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): SayCommand.AsObject;
  static toObject(includeInstance: boolean, msg: SayCommand): SayCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: SayCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): SayCommand;
  static deserializeBinaryFromReader(message: SayCommand, reader: jspb.BinaryReader): SayCommand;
}

export namespace SayCommand {
  export type AsObject = {
    content: string,
  }
}

export class CreateCharacterCommand extends jspb.Message {
  getName(): string;
  setName(value: string): void;

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
  toObject(includeInstance?: boolean): CreateCharacterCommand.AsObject;
  static toObject(includeInstance: boolean, msg: CreateCharacterCommand): CreateCharacterCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: CreateCharacterCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): CreateCharacterCommand;
  static deserializeBinaryFromReader(message: CreateCharacterCommand, reader: jspb.BinaryReader): CreateCharacterCommand;
}

export namespace CreateCharacterCommand {
  export type AsObject = {
    name: string,
    might: number,
    finesse: number,
    wits: number,
    grit: number,
    presence: number,
  }
}

export class ListCharactersCommand extends jspb.Message {
  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): ListCharactersCommand.AsObject;
  static toObject(includeInstance: boolean, msg: ListCharactersCommand): ListCharactersCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: ListCharactersCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): ListCharactersCommand;
  static deserializeBinaryFromReader(message: ListCharactersCommand, reader: jspb.BinaryReader): ListCharactersCommand;
}

export namespace ListCharactersCommand {
  export type AsObject = {
  }
}

export class SelectCharacterCommand extends jspb.Message {
  getCharacterId(): string;
  setCharacterId(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): SelectCharacterCommand.AsObject;
  static toObject(includeInstance: boolean, msg: SelectCharacterCommand): SelectCharacterCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: SelectCharacterCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): SelectCharacterCommand;
  static deserializeBinaryFromReader(message: SelectCharacterCommand, reader: jspb.BinaryReader): SelectCharacterCommand;
}

export namespace SelectCharacterCommand {
  export type AsObject = {
    characterId: string,
  }
}

export class TakeCommand extends jspb.Message {
  getCharacterId(): string;
  setCharacterId(value: string): void;

  getItemEntityId(): string;
  setItemEntityId(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): TakeCommand.AsObject;
  static toObject(includeInstance: boolean, msg: TakeCommand): TakeCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: TakeCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): TakeCommand;
  static deserializeBinaryFromReader(message: TakeCommand, reader: jspb.BinaryReader): TakeCommand;
}

export namespace TakeCommand {
  export type AsObject = {
    characterId: string,
    itemEntityId: string,
  }
}

export class DropCommand extends jspb.Message {
  getCharacterId(): string;
  setCharacterId(value: string): void;

  getItemEntityId(): string;
  setItemEntityId(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): DropCommand.AsObject;
  static toObject(includeInstance: boolean, msg: DropCommand): DropCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: DropCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): DropCommand;
  static deserializeBinaryFromReader(message: DropCommand, reader: jspb.BinaryReader): DropCommand;
}

export namespace DropCommand {
  export type AsObject = {
    characterId: string,
    itemEntityId: string,
  }
}

export class RequestInventoryCommand extends jspb.Message {
  getCharacterId(): string;
  setCharacterId(value: string): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): RequestInventoryCommand.AsObject;
  static toObject(includeInstance: boolean, msg: RequestInventoryCommand): RequestInventoryCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: RequestInventoryCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): RequestInventoryCommand;
  static deserializeBinaryFromReader(message: RequestInventoryCommand, reader: jspb.BinaryReader): RequestInventoryCommand;
}

export namespace RequestInventoryCommand {
  export type AsObject = {
    characterId: string,
  }
}

export class PlayerCommand extends jspb.Message {
  hasMove(): boolean;
  clearMove(): void;
  getMove(): MoveCommand | undefined;
  setMove(value?: MoveCommand): void;

  hasSay(): boolean;
  clearSay(): void;
  getSay(): SayCommand | undefined;
  setSay(value?: SayCommand): void;

  hasCreateCharacter(): boolean;
  clearCreateCharacter(): void;
  getCreateCharacter(): CreateCharacterCommand | undefined;
  setCreateCharacter(value?: CreateCharacterCommand): void;

  hasListCharacters(): boolean;
  clearListCharacters(): void;
  getListCharacters(): ListCharactersCommand | undefined;
  setListCharacters(value?: ListCharactersCommand): void;

  hasSelectCharacter(): boolean;
  clearSelectCharacter(): void;
  getSelectCharacter(): SelectCharacterCommand | undefined;
  setSelectCharacter(value?: SelectCharacterCommand): void;

  hasTake(): boolean;
  clearTake(): void;
  getTake(): TakeCommand | undefined;
  setTake(value?: TakeCommand): void;

  hasDrop(): boolean;
  clearDrop(): void;
  getDrop(): DropCommand | undefined;
  setDrop(value?: DropCommand): void;

  hasRequestInventory(): boolean;
  clearRequestInventory(): void;
  getRequestInventory(): RequestInventoryCommand | undefined;
  setRequestInventory(value?: RequestInventoryCommand): void;

  getCommandCase(): PlayerCommand.CommandCase;
  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): PlayerCommand.AsObject;
  static toObject(includeInstance: boolean, msg: PlayerCommand): PlayerCommand.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: PlayerCommand, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): PlayerCommand;
  static deserializeBinaryFromReader(message: PlayerCommand, reader: jspb.BinaryReader): PlayerCommand;
}

export namespace PlayerCommand {
  export type AsObject = {
    move?: MoveCommand.AsObject,
    say?: SayCommand.AsObject,
    createCharacter?: CreateCharacterCommand.AsObject,
    listCharacters?: ListCharactersCommand.AsObject,
    selectCharacter?: SelectCharacterCommand.AsObject,
    take?: TakeCommand.AsObject,
    drop?: DropCommand.AsObject,
    requestInventory?: RequestInventoryCommand.AsObject,
  }

  export enum CommandCase {
    COMMAND_NOT_SET = 0,
    MOVE = 1,
    SAY = 2,
    CREATE_CHARACTER = 3,
    LIST_CHARACTERS = 4,
    SELECT_CHARACTER = 5,
    TAKE = 6,
    DROP = 7,
    REQUEST_INVENTORY = 8,
  }
}

export class InputEvent extends jspb.Message {
  getUserId(): string;
  setUserId(value: string): void;

  getTraceId(): string;
  setTraceId(value: string): void;

  hasPayload(): boolean;
  clearPayload(): void;
  getPayload(): PlayerCommand | undefined;
  setPayload(value?: PlayerCommand): void;

  serializeBinary(): Uint8Array;
  toObject(includeInstance?: boolean): InputEvent.AsObject;
  static toObject(includeInstance: boolean, msg: InputEvent): InputEvent.AsObject;
  static extensions: {[key: number]: jspb.ExtensionFieldInfo<jspb.Message>};
  static extensionsBinary: {[key: number]: jspb.ExtensionFieldBinaryInfo<jspb.Message>};
  static serializeBinaryToWriter(message: InputEvent, writer: jspb.BinaryWriter): void;
  static deserializeBinary(bytes: Uint8Array): InputEvent;
  static deserializeBinaryFromReader(message: InputEvent, reader: jspb.BinaryReader): InputEvent;
}

export namespace InputEvent {
  export type AsObject = {
    userId: string,
    traceId: string,
    payload?: PlayerCommand.AsObject,
  }
}

export interface DirectionMap {
  UNSPECIFIED: 0;
  NORTH: 1;
  SOUTH: 2;
  EAST: 3;
  WEST: 4;
  UP: 5;
  DOWN: 6;
}

export const Direction: DirectionMap;

