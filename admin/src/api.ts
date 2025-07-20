import axios, { AxiosProgressEvent, AxiosResponse } from "axios";
import camelcaseKeys from "camelcase-keys";

const BASE_URL = "/admin/v2/api";

export const client = axios.create({
  baseURL: BASE_URL,
  validateStatus: () => true, // 将所有响应状态码视为有效
});

type PayloadType<T> = Promise<ApiResponse<T>>;

export async function getProfile(): PayloadType<ServerData.Profile> {
  return strictify(await client.get("/profile"));
}

export async function getStats(): PayloadType<ServerData.Stats> {
  return strictify(await client.get("/stats"));
}

export async function getCustomize(): PayloadType<ServerData.Customize> {
  return strictify(await client.get("/customize"));
}

export async function getManagement(): PayloadType<ServerData.Management> {
  return strictify(await client.get("/management"));
}

export async function getAssets(): PayloadType<ServerData.Assets> {
  return strictify(await client.get("/assets"));
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

async function strictify<T extends Record<string, unknown> | readonly Record<string, unknown>[]>(
  resp: AxiosResponse<T>,
) {
  return camelcaseKeys(resp.data, { deep: true });
}
