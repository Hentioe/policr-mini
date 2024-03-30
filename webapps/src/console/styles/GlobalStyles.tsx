import { createGlobalStyles, StylesArg } from "solid-styled-components";
import { merge } from "ts-deepmerge";
import tw, { globalStyles } from "twin.macro";

const CustomStyles = {
  body: {
    ...tw`antialiased`,
  },
};

const GlobalStyles = createGlobalStyles(
  merge(globalStyles, CustomStyles) as StylesArg,
);

export default GlobalStyles;
