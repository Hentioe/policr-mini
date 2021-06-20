import React, { useEffect, useCallback, useState } from "react";
import useSWR from "swr";
import "twin.macro";
import Switch from "react-switch";
import fetch from "unfetch";

import {
  PageHeader,
  PageLoading,
  PageReLoading,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
  ActionButton,
} from "../components";
import { Table, Thead, Tr, Th, Tbody, Td } from "../components/Tables";
import {
  camelizeJson,
  toastErrors,
  toastMessage,
  updateInNewArray,
} from "../helper";
import { useDispatch, useSelector } from "react-redux";
import { loadSelected } from "../slices/chats";
import PageBody from "../components/PageBody";

const makeEndpoint = (chat_id) => `/admin/api/chats/${chat_id}/permissions`;

const switchHeight = 18;
const switchWidth = 36;

function makeFullname({ firstName, lastName }) {
  let name = firstName;
  if (lastName && lastName.trim() != "") name += ` ${lastName}`;

  return name;
}

async function changeBoolField(field, id, value) {
  const endpoint = `/admin/api/permissions/${id}/${field}?value=${value}`;

  return fetch(endpoint, { method: "PUT" }).then((r) => camelizeJson(r));
}

async function withdraw(id) {
  const endpoint = `/admin/api/permissions/${id}/withdraw`;

  return fetch(endpoint, { method: "DELETE" }).then((r) => camelizeJson(r));
}

async function sync(chat_id) {
  const endpoint = `/admin/api/permissions/chats/${chat_id}/sync`;

  return fetch(endpoint, { method: "PUT" }).then((r) => camelizeJson(r));
}

export default () => {
  const dispatch = useDispatch();
  const chatsState = useSelector((state) => state.chats);

  const { data, error, mutate } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected)
      : null
  );
  const [permissions, setPermissions] = useState([]);

  const handleSwitchChange = useCallback(
    async (field, index, value) => {
      // 先切换开关
      const newPermissions = updateInNewArray(
        permissions,
        { ...permissions[index], [field]: value },
        index
      );

      setPermissions(newPermissions);

      const result = await changeBoolField(field, permissions[index].id, value);

      if (result.errors) {
        // 失败再回滚开关。
        const newPermissions = updateInNewArray(
          permissions,
          { ...permissions[index], [field]: !value },
          index
        );
        setPermissions(newPermissions);
        toastErrors(result.errors);

        return;
      }
    },
    [permissions]
  );

  const handleWithdrawClick = useCallback(
    async (index) => {
      const result = await withdraw(permissions[index].id);

      if (result.errors) {
        toastErrors(result.errors);
      } else {
        toastMessage(
          `撤销「${makeFullname(permissions[index].user)}」的管理员权限成功。`
        );

        const newPermissions = permissions.filter((_, i) => i !== index);
        setPermissions(newPermissions);
      }
    },
    [permissions]
  );

  const handleSyncClick = async () => {
    const result = await sync(chatsState.selected);

    if (result.errors) {
      toastErrors(result.errors);
    } else {
      toastMessage("同步完成，即将更新权限列表。");

      mutate();
    }
  };

  useEffect(() => {
    if (data && data.permissions) setPermissions(data.permissions);
  }, [data]);

  const isLoaded = () => chatsState.isLoaded && !error && data && !data.errors;

  let title = "管理员权限";
  if (isLoaded()) title += ` / ${data.chat.title}`;

  useEffect(() => {
    if (data && data.errors) toastErrors(data.errors);
    if (isLoaded()) dispatch(loadSelected(data.chat));
  }, [data]);

  return (
    <>
      <PageHeader title={title} />
      {isLoaded() ? (
        <PageBody>
          <PageSection>
            <PageSectionHeader>
              <PageSectionTitle>权限列表</PageSectionTitle>
            </PageSectionHeader>
            <main>
              <div tw="mt-4">
                <ActionButton onClick={handleSyncClick}>
                  ↷ 同步全部
                </ActionButton>
              </div>
              <Table tw="shadow rounded">
                <Thead>
                  <Tr>
                    <Th tw="w-3/12">用户名称</Th>
                    <Th tw="w-2/12 text-center">设置 / 可读</Th>
                    <Th tw="w-2/12 text-center">设置 / 可写</Th>
                    <Th tw="w-2/12 text-center">保持同步</Th>
                    <Th tw="w-3/12 text-right">操作</Th>
                  </Tr>
                </Thead>
                <Tbody>
                  {permissions.map((permission, index) => (
                    <Tr key={permission.id}>
                      <Td tw="w-3/12 break-all">
                        {makeFullname(permission.user)}
                      </Td>
                      <Td tw="w-2/12">
                        <div tw="flex justify-center">
                          <Switch
                            height={switchHeight}
                            width={switchWidth}
                            checked={permission.readable}
                            onChange={(v) =>
                              handleSwitchChange("readable", index, v)
                            }
                          />
                        </div>
                      </Td>
                      <Td tw="w-2/12 text-center">
                        <div tw="flex justify-center">
                          <Switch
                            height={switchHeight}
                            width={switchWidth}
                            checked={permission.writable}
                            onChange={(v) =>
                              handleSwitchChange("writable", index, v)
                            }
                          />
                        </div>
                      </Td>
                      <Td tw="w-2/12 text-center">
                        <div tw="flex justify-center">
                          <Switch
                            height={switchHeight}
                            width={switchWidth}
                            checked={!permission.customized}
                            onChange={(v) =>
                              handleSwitchChange("customized", index, !v)
                            }
                          />
                        </div>
                      </Td>
                      <Td tw="text-right">
                        <ActionButton tw="mr-1">禁用</ActionButton>
                        <ActionButton
                          onClick={() => handleWithdrawClick(index)}
                        >
                          撤销
                        </ActionButton>
                      </Td>
                    </Tr>
                  ))}
                </Tbody>
              </Table>
            </main>
          </PageSection>
        </PageBody>
      ) : error ? (
        <PageReLoading mutate={mutate} />
      ) : (
        <PageLoading />
      )}
    </>
  );
};
