with import <nixpkgs> { };

mkShell {
  buildInputs = [ python3 inotify-tools nodejs_22 ];
  shellHook = ''
    export ERL_AFLAGS="+C multi_time_warp";
  '';
}
