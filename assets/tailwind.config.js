const colors = require("tailwindcss/colors");

module.exports = {
  theme: {
    colors: {
      transparent: colors.transparent,
      current: colors.current,
      black: colors.black,
      blue: colors.blue,
      white: colors.white,
      gray: colors.gray,
      emerald: colors.emerald,
      indigo: colors.indigo,
      red: colors.red,
      yellow: colors.yellow,
      teal: colors.teal,
      green: colors.green,
      orange: colors.orange,
      pink: colors.pink,
    },
    extend: {
      boxShadow: {
        outline: "0 0 0 1px rgb(38, 132, 255)",
      },
      borderColor: {
        "input-active": "rgb(38, 132, 255)",
      },
      spacing: {
        100: "28rem",
        110: "36rem",
      },
    },
  },
  variants: {},
  plugins: [],
};
