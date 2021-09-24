import React from "react";
import tw, { styled } from "twin.macro";

const getAttachmentTypeText = (attachmentText) => {
  if (attachmentText.startsWith("photo/")) {
    return "图片";
  } else if (attachmentText.startsWith("video/")) {
    return "视频";
  } else if (attachmentText.startsWith("audio/")) {
    return "音频";
  } else if (attachmentText.startsWith("document/")) {
    return "文件";
  } else {
    return "附件";
  }
};

const InlineKeybordButton = styled.div`
  ${tw`shadow-sm bg-blue-400 text-white rounded-md px-4 py-2 text-sm mt-1 flex justify-center bg-opacity-75 cursor-pointer`}
`;

export default ({ attachment, children, inlineKeyboard, avatarSrc }) => {
  return (
    <div tw="flex justify-center">
      <div tw="w-12 h-12 self-end">
        <img tw="w-full rounded-full" src={avatarSrc} />
      </div>
      <div tw="ml-2 self-end">
        <div tw="shadow rounded border border-solid border-gray-200 text-black">
          {attachment && attachment.trim() != "" && (
            <div tw="flex justify-center w-full py-12 bg-blue-400 rounded-t">
              <span tw="text-white text-lg">
                {getAttachmentTypeText(attachment)}
              </span>
            </div>
          )}
          <div tw="p-2 break-all" style={{ maxWidth: "31rem" }}>
            {children}
          </div>
        </div>
        <div tw="flex flex-col mt-2">
          {inlineKeyboard.map((row, i) => (
            <InlineKeybordButton key={i}>
              <span>{row[0].text}</span>
            </InlineKeybordButton>
          ))}
        </div>
      </div>
    </div>
  );
};
