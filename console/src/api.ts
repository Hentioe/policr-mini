import axios, { AxiosResponse } from "axios";
import camelcaseKeys from "camelcase-keys";

const BASE_URL = "/console/v2/api";

export const client = axios.create({
  baseURL: BASE_URL,
  validateStatus: () => true, // 将所有响应状态码视为有效
});

type PayloadType<T> = Promise<ApiResponse<T>>;

export async function getServerInfo(): PayloadType<ServerData.ServerInfo> {
  return strictify(await client.get(""));
}

export async function getMe(): PayloadType<ServerData.User> {
  return strictify(await client.get("/users/me"));
}

export async function getChats(): PayloadType<ServerData.Chat[]> {
  return strictify(await client.get("/chats"));
}

export async function queryStats(range: string): PayloadType<ServerData.Stats> {
  return strictify(await client.get(`/stats/query?range=${range}`));
}

export async function getScheme(chatId: number): PayloadType<ServerData.Scheme> {
  return strictify(await client.get(`/schemes/${chatId}`));
}

export async function getCustoms(chatId: number): PayloadType<ServerData.CustomItem[]> {
  return strictify(await client.get(`/chats/${chatId}/customs`));
}

async function strictify<T extends Record<string, unknown> | readonly Record<string, unknown>[]>(
  resp: AxiosResponse<T>,
) {
  return camelcaseKeys(resp.data, { deep: true });
}
