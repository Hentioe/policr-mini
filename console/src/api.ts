import { retrieveRawInitData } from "@telegram-apps/sdk";
import axios, { AxiosResponse } from "axios";
import camelcaseKeys from "camelcase-keys";
import { toaster } from "./utils";

type PayloadType<T> = Promise<ApiResponse<T>>;

const BASE_URL = "/console/v2/api";

export const client = axios.create({
  baseURL: BASE_URL,
  validateStatus: () => true, // 将所有响应状态码视为有效
});

// 添加 TMA 认证
client.interceptors.request.use((config) => {
  const authorization = tmaAuthorization();
  if (authorization) {
    config.headers.Authorization = authorization;
  }

  return config;
});

// 处理 403 错误
client.interceptors.response.use((response) => {
  if (response.status === 403) {
    let body = response.data;
    // 如果 body 是一个 json 字符串
    if (typeof body === "string") {
      try {
        body = JSON.parse(body);
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
      } catch (_e) {
        // 如果解析失败，保持原样
      }
    } else {
      body = "服务端响应了一个错误。";
    }

    if ("success" in body && body.success === false) {
      toaster.error({ title: "被禁止", description: "您没有访问或操作此资源的权限。" });
    } else {
      toaster.error({ title: "403 Forbidden", description: body });
    }
  }

  return response;
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
  return strictify(await client.get(`/chats/${chatId}/scheme`));
}

export async function getCustoms(chatId: number): PayloadType<ServerData.CustomItem[]> {
  return strictify(await client.get(`/chats/${chatId}/customs`));
}

export async function deleteCustom(id: number): PayloadType<ServerData.CustomItem> {
  return strictify(await client.delete(`/customs/${id}`));
}

export async function saveCustom({ id, custom }: { id: number | null; custom: InputData.Custom }) {
  if (id !== null) {
    return updateCustom(id, custom);
  } else {
    return createCustom(custom);
  }
}

export async function createCustom(custom: InputData.Custom) {
  return strictify(
    await client.post("/customs", {
      chat_id: custom.chatId,
      title: custom.title,
      answers: custom.answers,
      attachment: custom.attachment,
    }),
  );
}

export async function updateCustom(id: number, custom: InputData.Custom) {
  return strictify(
    await client.put(`/customs/${id}`, {
      title: custom.title,
      answers: custom.answers,
      attachment: custom.attachment,
    }),
  );
}

export async function getVerifications(chatId: number, range: string): PayloadType<ServerData.Verification[]> {
  return strictify(await client.get(`/chats/${chatId}/verifications?range=${range}`));
}

export async function getOperations(chatId: number, range: string): PayloadType<ServerData.Operation[]> {
  return strictify(await client.get(`/chats/${chatId}/operations?range=${range}`));
}

export async function updateScheme(id: number, scheme: InputData.Scheme): PayloadType<ServerData.Scheme> {
  return strictify(
    await client.put(`/schemes/${id}`, {
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

export async function killFromVerification(
  id: number,
  action: InputData.VerificationKillAction,
): PayloadType<ServerData.Verification> {
  return strictify(
    await client.put(`/verifications/${id}/kill`, {
      action,
    }),
  );
}

async function strictify<T extends Record<string, unknown> | readonly Record<string, unknown>[]>(
  resp: AxiosResponse<T>,
) {
  return camelcaseKeys(resp.data, { deep: true });
}
