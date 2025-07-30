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

  type Scheme = {
    id: number;
    type: string | null;
    typeItems: SelectItem[];
    timeout: number | null;
    killStrategy: string | null;
    fallbackKillStrategy: string | null;
    killStrategyItems: SelectItem[];
    mentionText: string | null;
    mentionTextItems: SelectItem[];
    imageChoicesCount: string | null;
    imageChoicesCountItems: SelectItem[];
    cleanupMessages: MessageKind[] | null;
    delayUnbanSecs: number | null;
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

  type CustomItem = {
    id: number;
    title: string;
    answers: CustomItemAnswer[];
    attachment?: string;
  };

  type CustomItemAnswer = {
    text: string;
    correct: boolean;
  };

  type Verification = {
    id: number;
    userId: number;
    userFullName: string;
    status: VerificationStatus;
    source: string;
    durationSecs: number;
    insertedAt: string;
    updatedAt: string;
  };

  type VerificationStatus =
    | "pending"
    | "approved"
    | "incorrect"
    | "timeout"
    | "expired"
    | "manual_kick"
    | "manual_ban";

  type Operation = {
    id: number;
    action: OperationAction;
    role: OperationRole;
    verification: Verification;
    insertedAt: string;
    updatedAt: string;
  };

  type OperationAction = "ban" | "kick" | "unban" | "verify";
  type OperationRole = "system" | "admin";
}
