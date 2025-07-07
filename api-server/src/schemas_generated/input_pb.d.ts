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

export class PlayerCommand extends jspb.Message {
  hasMove(): boolean;
  clearMove(): void;
  getMove(): MoveCommand | undefined;
  setMove(value?: MoveCommand): void;

  hasSay(): boolean;
  clearSay(): void;
  getSay(): SayCommand | undefined;
  setSay(value?: SayCommand): void;

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
  }

  export enum CommandCase {
    COMMAND_NOT_SET = 0,
    MOVE = 1,
    SAY = 2,
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

