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

  type StatsRange = "today" | "7d" | "30d" | "all";
  type ResetStatsRange = "last_30d" | "all";
}
