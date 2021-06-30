const path = require("path");
const glob = require("glob");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const CssMinimizerPlugin = require("css-minimizer-webpack-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = (_env, options) => {
  const devMode = options.mode !== "production";

  const terserPlugin = (compiler) => {
    const TerserPlugin = require("terser-webpack-plugin");
    new TerserPlugin({
      terserOptions: {
        compress: {},
      },
    }).apply(compiler);
  };

  // 如果是开发模式，不压缩代码。
  const minimizer = [
    !devMode && terserPlugin,
    new CssMinimizerPlugin({}),
  ].filter(Boolean);

  return {
    optimization: {
      minimize: true,
      minimizer,
    },
    entry: {
      user: glob.sync("./vendor/**/*.js").concat(["./src/user.js"]),
      admin: glob.sync("./vendor/**/*.js").concat(["./src/admin.js"]),
    },
    output: {
      filename: "[name].js",
      path: path.resolve(__dirname, "../priv/static/js"),
    },
    devtool: devMode ? "source-map" : undefined,
    module: {
      rules: [
        {
          test: /\.m?js/,
          resolve: {
            fullySpecified: false,
          },
        },
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader",
          },
        },
        {
          test: /\.[s]?css$/,
          use: [MiniCssExtractPlugin.loader, "css-loader", "sass-loader"],
        },
        {
          test: /\.svg/,
          type: "asset/inline",
        },
      ],
    },
    plugins: [
      new MiniCssExtractPlugin({ filename: "../css/[name].css" }),
      new CopyWebpackPlugin({ patterns: [{ from: "static/", to: "../" }] }),
    ],
  };
};
