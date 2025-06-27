with import <nixpkgs> { };

mkShell {
  buildInputs = [ python3 inotify-tools nodejs_22 pkg-config imagemagick lato ];
  shellHook = ''
    export ERL_AFLAGS="+C multi_time_warp";
  '';

  LIBCLANG_PATH =
    pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
}
