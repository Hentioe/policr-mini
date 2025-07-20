import axios, { AxiosResponse } from "axios";
import camelcaseKeys from "camelcase-keys";

const BASE_URL = "/admin/v2/api";

const api = axios.create({
  baseURL: BASE_URL,
  validateStatus: () => true, // 将所有响应状态码视为有效
});

type PayloadType<T> = Promise<ApiResponse<T>>;

export async function getProfile(): PayloadType<ServerData.Profile> {
  return strictify(await api.get("/profile"));
}

export async function getStats(): PayloadType<ServerData.Stats> {
  return strictify(await api.get("/stats"));
}

export async function getCustomize(): PayloadType<ServerData.Customize> {
  return strictify(await api.get("/customize"));
}

async function strictify<T extends Record<string, unknown> | readonly Record<string, unknown>[]>(
  resp: AxiosResponse<T>,
) {
  return camelcaseKeys(resp.data, { deep: true });
}
