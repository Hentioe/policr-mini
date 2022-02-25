with import <nixpkgs> { };

mkShell { buildInputs = [ python3 inotify-tools ]; }
