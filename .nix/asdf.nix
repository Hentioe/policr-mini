# TODO: 解决和 wx 相关的构建错误。
# 当前通过此环境所构建的 erlang 无法启动 observer 等模块的图形功能。

with import <nixpkgs> { };

stdenv.mkDerivation {
  name = "asdf-erlang-build-environment";
  buildInputs = [
    pkg-config
    gnumake
    autoconf269
    ncurses
    openssl
    libxslt
    fop
    libxml2
    openjdk11
    unixODBC
    libGL
    libGLU
    wxGTK
    xorg.libX11
  ];

  KERL_CONFIGURE_OPTIONS =
    "--with-ssl=${lib.getOutput "out" openssl} --with-ssl-incl=${
      lib.getDev openssl
    } --with-odbc=${unixODBC} --enable-wx";
}
