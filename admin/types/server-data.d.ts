type ApiResponse<T> = ServerData.Success<T> | ServerData.Error;

declare namespace ServerData {
  type ErrorReason = unknown;
  type Error = {
    success: false;
    message: string;
    payload?: unknown;
  };

  type Success<T> = {
    success: true;
    payload: T;
  };

  type Profile = {
    username: string;
  };

  type Stats = {
    verification: {
      total: number;
      approved: number;
      rejected: number;
    };
  };

  type Customize = {
    scheme: Scheme;
  };

  type Scheme = {
    type: string;
    typeItems: SelectItem[];
    timeout: number;
    killStrategy: string;
    fallbackKillStrategy: string;
    killStrategyItems: SelectItem[];
    mentionText: string;
    mentionTextItems: SelectItem[];
    imageChoicesCount: number;
    imageChoicesCountItems: SelectItem[];
    cleanupMessages: MessageKind[];
    delayUnbanSecs: number;
  };

  type MessageKind = "joined" | "left";

  type Management = {
    chats: Chat[];
    page: number;
    pageSize: number;
    chatsTotal: number;
  };

  type Chat = {
    id: number;
    title: string;
    username: string;
    description: string;
    isTakeOver: boolean;
    left: boolean;
    createdAt: string;
  };

  type Assets = {
    deployed?: {
      manifest: Manifest;
      imagesTotal: number;
    };
    uploaded?: {
      manifest: Manifest;
      imagesTotal: number;
    };
  };

  type Manifest = {
    version: string;
    datetime: string;
    includeFormats: string[];
    albums: Album[];
    conflicts: string[][];
  };

  type Album = {
    id: string;
    name: object;
  };
}
