import React from "react";
import "twin.macro";

export default ({ children, x, y }) => (
  <div
    style={{
      left: x,
      top: y,
    }}
    tw="absolute z-50 pointer-events-none bg-white rounded-t shadow-lg"
  >
    {children}
  </div>
);
