with import <nixpkgs> { };

mkShell {
  buildInputs = [ python3 inotify-tools pkg-config imagemagick ];
  shellHook = ''
    export ERL_AFLAGS="+C multi_time_warp";
  '';

  LIBCLANG_PATH =
    pkgs.lib.makeLibraryPath [ pkgs.llvmPackages_latest.libclang.lib ];
}
