import axios, { AxiosProgressEvent, AxiosResponse } from "axios";
import camelcaseKeys from "camelcase-keys";

const BASE_URL = "/admin/v2/api";

export const client = axios.create({
  baseURL: BASE_URL,
  validateStatus: () => true, // 将所有响应状态码视为有效
});

type PayloadType<T> = Promise<ApiResponse<T>>;

export async function getServerInfo(): PayloadType<ServerData.ServerInfo> {
  return strictify(await client.get(""));
}

export async function getProfile(): PayloadType<ServerData.Profile> {
  return strictify(await client.get("/profile"));
}

export async function updateDefaultScheme(scheme: InputData.Scheme): PayloadType<ServerData.Scheme> {
  return strictify(
    await client.put("/schemes/default", {
      type: scheme.type,
      timeout: scheme.timeout,
      kill_strategy: scheme.killStrategy,
      fallback_kill_strategy: scheme.fallbackKillStrategy,
      mention_text: scheme.mentionText,
      image_choices_count: scheme.imageChoicesCount,
      cleanup_messages: scheme.cleanupMessages,
      delay_unban_secs: scheme.delayUnbanSecs,
    }),
  );
}

export async function getStats(): PayloadType<ServerData.Stats> {
  return strictify(await client.get("/stats"));
}

export async function getCustomize(): PayloadType<ServerData.Customize> {
  return strictify(await client.get("/customize"));
}

export async function getManagement(
  params: { page?: number | string; keywords?: string },
): PayloadType<ServerData.Management> {
  const searchParams = new URLSearchParams();
  searchParams.append("page", (params.page || 1).toString());
  if (params.keywords) {
    searchParams.append("keywords", params.keywords);
  }

  return strictify(await client.get(`/management?${searchParams.toString()}`));
}

export async function syncChat(chatId: number): PayloadType<ServerData.Chat> {
  return strictify(await client.put(`/chats/${chatId}/sync`));
}

export async function leaveChat(chatId: number): PayloadType<ServerData.Chat> {
  return strictify(await client.put(`/chats/${chatId}/leave`));
}

export async function getAssets(): PayloadType<ServerData.Assets> {
  return strictify(await client.get("/assets"));
}

export async function getTasks(): PayloadType<ServerData.Tasks> {
  return strictify(await client.get("/tasks"));
}

export async function resetStats(range: InputData.ResetStatsRange): PayloadType<ServerData.Bee<unknown>> {
  return strictify(await client.post(`/bees/reset_stats`, { range }));
}

export async function uploadAlbums(
  file: File,
  onUploadProgress: (progressEvent: AxiosProgressEvent) => void,
): PayloadType<ServerData.ArchiveInfo> {
  const formData = new FormData();
  formData.append("archive", file);

  return strictify(
    await client.post("/provider/upload", formData, {
      onUploadProgress,
      headers: {
        "Content-Type": "multipart/form-data",
      },
    }),
  );
}

export async function deleteUploadedAlbums(): PayloadType<void> {
  return strictify(await client.delete("/provider/uploaded"));
}

export async function deployUploadedAlbums(): PayloadType<void> {
  return strictify(await client.put("/provider/deploy"));
}

export async function getTerm(): PayloadType<ServerData.Term> {
  return strictify(await client.get("/term"));
}

export async function saveTerm(content: string): PayloadType<ServerData.Term> {
  return strictify(await client.put("/term", { content }));
}

export async function previewTerm(content: string): PayloadType<ServerData.Term> {
  return strictify(await client.post("/term/preview", { content }));
}

export async function deleteTerm(): PayloadType<void> {
  return strictify(await client.delete("/term"));
}

export async function queryStats(range: string): PayloadType<ServerData.Stats> {
  return strictify(await client.get(`/stats/query?range=${range}`));
}

async function strictify<T extends Record<string, unknown> | readonly Record<string, unknown>[]>(
  resp: AxiosResponse<T>,
) {
  return camelcaseKeys(resp.data, { deep: true });
}
