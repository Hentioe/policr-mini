import { retrieveRawInitData } from "@telegram-apps/sdk";
import axios, { AxiosResponse } from "axios";
import camelcaseKeys from "camelcase-keys";

type PayloadType<T> = Promise<ApiResponse<T>>;

const BASE_URL = "/console/v2/api";

export const client = axios.create({
  baseURL: BASE_URL,
  validateStatus: () => true, // 将所有响应状态码视为有效
});

client.interceptors.request.use((config) => {
  const authorization = tmaAuthorization();
  if (authorization) {
    config.headers.Authorization = authorization;
  }

  return config;
});

function tmaAuthorization(): string | undefined {
  try {
    return `tma ${retrieveRawInitData()}`;
  } catch (error) {
    if (error instanceof Error && error.name === "LaunchParamsRetrieveError") {
      return undefined;
    } else {
      throw error;
    }
  }
}

export async function getServerInfo(): PayloadType<ServerData.ServerInfo> {
  return strictify(await client.get(""));
}

export async function getMe(): PayloadType<ServerData.User> {
  return strictify(await client.get("/users/me"));
}

export async function getChats(): PayloadType<ServerData.Chat[]> {
  return strictify(await client.get("/chats"));
}

export async function queryStats(chatId: number, range: InputData.StatsRange): PayloadType<ServerData.Stats> {
  return strictify(await client.get(`/chats/${chatId}/stats?range=${range}`));
}

export async function getScheme(chatId: number): PayloadType<ServerData.Scheme> {
  return strictify(await client.get(`/schemes/${chatId}`));
}

export async function getCustoms(chatId: number): PayloadType<ServerData.CustomItem[]> {
  return strictify(await client.get(`/chats/${chatId}/customs`));
}

export async function getVerifications(chatId: number): PayloadType<ServerData.Verification[]> {
  return strictify(await client.get(`/chats/${chatId}/verifications`));
}

export async function getOperations(chatId: number): PayloadType<ServerData.Operation[]> {
  return strictify(await client.get(`/chats/${chatId}/operations`));
}

async function strictify<T extends Record<string, unknown> | readonly Record<string, unknown>[]>(
  resp: AxiosResponse<T>,
) {
  return camelcaseKeys(resp.data, { deep: true });
}
