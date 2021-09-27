import React from "react";
import "twin.macro";

export default ({
  children,
  x,
  y,
  noneShadow = false,
  transparentBackground = false,
}) => (
  <div
    style={{
      left: x,
      top: y,
      boxShadow: noneShadow && "unset",
      background: transparentBackground && "transparent",
    }}
    tw="absolute z-50 pointer-events-none bg-white rounded-t shadow-lg"
  >
    {children}
  </div>
);
