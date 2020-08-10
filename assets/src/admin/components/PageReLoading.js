import React from "react";
import "twin.macro";
import RetryButton from "./RetryButton";

export default ({ mutate }) => {
  return (
    <div tw="flex justify-center mt-6">
      <RetryButton onClick={() => mutate(undefined)} />
    </div>
  );
};
