declare namespace InputData {
  type Scheme = {
    type?: string;
    timeout?: number;
    killStrategy?: string;
    fallbackKillStrategy?: string;
    mentionText?: string;
    imageChoicesCount?: number;
    cleanupMessages?: MessageKind[];
    delayUnbanSecs?: number;
  };

  type StatsRange = "today" | "7d" | "28d" | "90d";
}
