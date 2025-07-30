declare namespace InputData {
  type Scheme = {
    type: string | null;
    timeout: number | null;
    killStrategy: string | null;
    fallbackKillStrategy: string | null;
    mentionText: string | null;
    imageChoicesCount: string | null;
    cleanupMessages: MessageKind[] | null;
    delayUnbanSecs: number | null;
  };

  type StatsRange = "today" | "7d" | "28d" | "90d";

  type Custom = {
    chatId?: number | null;
    title: string;
    answers: string[];
    attachment: string | null;
  };

  type VerificationKillAction = "manual_ban" | "manual_kick" | "unban";
}
