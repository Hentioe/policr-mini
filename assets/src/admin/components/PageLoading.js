import React from "react";
import "twin.macro";
import MoonLoader from "react-spinners/MoonLoader";

export default () => {
  return (
    <div tw="flex justify-center mt-6">
      <MoonLoader size={25} color="#47A8D8" />
    </div>
  );
};
