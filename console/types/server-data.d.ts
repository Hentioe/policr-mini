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

  type User = {
    id: number;
    username: string;
    fullName: string;
    photoId: string;
  };

  type Paginated<T> = {
    page: number;
    pageSize: number;
    items: T[];
    total: number;
  };

  type ServerInfo = {
    version: string;
  };

  type Profile = {
    fullName: string;
    username: string;
  };

  type Stats = {
    start: string;
    every: string;
    points: StatsPoint[];
  };

  type StatsStatus = "approved" | "incorrect" | "timeout" | "other";

  type StatsPoint = {
    time: string;
    status: StatsStatus;
    count?: number;
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
    description: string;
    bigPhotoId: string;
    takenOver: boolean;
    left: boolean;
    createdAt: string;
  };
}
