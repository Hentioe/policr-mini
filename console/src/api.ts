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

async function strictify<T extends Record<string, unknown> | readonly Record<string, unknown>[]>(
  resp: AxiosResponse<T>,
) {
  return camelcaseKeys(resp.data, { deep: true });
}
