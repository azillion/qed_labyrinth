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

export class OutputEvent extends jspb.Message {
  clearTargetUserIdsList(): void;
  getTargetUserIdsList(): Array<string>;
  setTargetUserIdsList(value: Array<string>): void;
  addTargetUserIds(value: string, index?: number): string;

  hasChatMessage(): boolean;
  clearChatMessage(): void;
  getChatMessage(): ChatMessage | undefined;
  setChatMessage(value?: ChatMessage): void;

  hasAreaUpdate(): boolean;
  clearAreaUpdate(): void;
  getAreaUpdate(): AreaUpdate | undefined;
  setAreaUpdate(value?: AreaUpdate): void;

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
    chatMessage?: ChatMessage.AsObject,
    areaUpdate?: AreaUpdate.AsObject,
  }

  export enum PayloadCase {
    PAYLOAD_NOT_SET = 0,
    CHAT_MESSAGE = 3,
    AREA_UPDATE = 4,
  }
}

