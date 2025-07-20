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

  type Chat = {
    id: number;
    title: string;
    username: string;
    createdAt: string;
  };
}
