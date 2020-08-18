import React, { useEffect, useCallback } from "react";
import useSWR from "swr";
import tw, { styled } from "twin.macro";
import Switch from "react-switch";

import {
  PageHeader,
  PageLoading,
  PageReLoading,
  PageSection,
  PageSectionHeader,
  PageSectionTitle,
} from "../components";
import { useDispatch, useSelector } from "react-redux";
import { loadSelected } from "../slices/chats";
import PageBody from "../components/PageBody";

const OperatingText = styled.span`
  ${tw`text-xs text-blue-400 font-bold cursor-pointer`}
`;

const TableHeaderCell = styled.th`
  ${tw`font-normal text-gray-500 text-left uppercase`}
`;

const TableDataRow = styled.tr``;
const TableDataCell = styled.td(() => [
  tw`border border-dashed border-0 border-t border-gray-300`,
  tw`py-2 text-sm`,
]);

const makeEndpoint = (chat_id) => `/admin/api/chats/${chat_id}/permissions`;

const switchHeight = 18;
const switchWidth = 36;

function makeFullname({ firstName, lastName }) {
  let name = firstName;
  if (lastName && lastName.trim() != "") name += ` ${lastName}`;

  return name;
}

export default () => {
  const dispatch = useDispatch();
  const chatsState = useSelector((state) => state.chats);

  const { data, error, mutate } = useSWR(
    chatsState && chatsState.isLoaded && chatsState.selected
      ? makeEndpoint(chatsState.selected)
      : null
  );

  const handleReadableChange = useCallback((permission) => {}, [data]);

  const isLoaded = () => !error && chatsState.isLoaded && data && !data.errors;

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
              <table tw="w-full border border-solid border-0 border-b border-t border-gray-300 mt-1">
                <thead>
                  <tr>
                    <TableHeaderCell tw="w-3/12">用户名称</TableHeaderCell>
                    <TableHeaderCell tw="w-2/12 text-center">
                      设置可读
                    </TableHeaderCell>
                    <TableHeaderCell tw="w-2/12 text-center">
                      设置可写
                    </TableHeaderCell>
                    <TableHeaderCell tw="w-2/12 text-center">
                      保持同步
                    </TableHeaderCell>
                    <TableHeaderCell tw="w-3/12">
                      <span tw="float-right mr-6">操作</span>
                    </TableHeaderCell>
                  </tr>
                </thead>
                <tbody>
                  {data.permissions.map((permission) => (
                    <TableDataRow key={permission.id}>
                      <TableDataCell tw="w-3/12 break-all">
                        {makeFullname(permission.user)}
                      </TableDataCell>
                      <TableDataCell tw="w-2/12">
                        <div tw="flex justify-center">
                          <Switch
                            height={switchHeight}
                            width={switchWidth}
                            checked={permission.readable}
                            onChange={handleReadableChange}
                          />
                        </div>
                      </TableDataCell>
                      <TableDataCell tw="w-2/12 text-center">
                        <div tw="flex justify-center">
                          <Switch
                            height={switchHeight}
                            width={switchWidth}
                            checked={permission.writable}
                            onChange={handleReadableChange}
                          />
                        </div>
                      </TableDataCell>
                      <TableDataCell tw="w-2/12 text-center">
                        <div tw="flex justify-center">
                          <Switch
                            height={switchHeight}
                            width={switchWidth}
                            checked={!permission.customized}
                            onChange={handleReadableChange}
                          />
                        </div>
                      </TableDataCell>
                      <TableDataCell>
                        <div tw="float-right mr-6">
                          <OperatingText tw="mr-1">同步</OperatingText>
                          <OperatingText>禁用</OperatingText>
                        </div>
                      </TableDataCell>
                    </TableDataRow>
                  ))}
                </tbody>
              </table>
            </main>
          </PageSection>
        </PageBody>
      ) : error ? (
        <PageReLoading />
      ) : (
        <PageLoading />
      )}
    </>
  );
};
