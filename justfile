setup:
    mix deps.get
    just assets-setup front-setup
    just dev-env up -d
    just cargo-for imgkit build
    just cargo-for ziputil build
    mix ecto.setup

run +args='':
    iex -S mix {{args}}

check:
    just mix-check
    just front-check

format:
    just mix-format assets-format front-format
    just cargo-for imgkit fmt
    just cargo-for ziputil fmt


lint:
    just mix-lint front-lint
    just cargo-for imgkit clippy
    just cargo-for ziputil clippy

clean:
    just mix-clean assets-clean front-clean assets-output-clean
    just cargo-for imgkit clean
    just cargo-for ziputil clean
    rm -rf priv/native

mix-check:
    just mix-format mix-lint

mix-lint:
    mix credo --strict --mute-exit-status
    mix dialyzer

mix-format:
    mix format

mix-clean:
    mix clean
    rm -rf deps _build

assets-setup:
    pnpm install --prefix assets

assets-format:
    prettier --write assets/

assets-clean:
    rm -rf assets/node_modules
    rm -rf priv/static

front-setup:
    just front-pnpm install

front-check:
    just front-format front-lint

front-format:
    just front-pnpm run format

front-lint:
    just front-pnpm run lint

front-clean:
    rm -rf webapps/node_modules

front-pnpm +args:
    (cd webapps && pnpm {{args}})

dev-env +args:
    docker compose -f docker-compose.dev.yml --env-file dev.env {{args}}

test:
    mix test
    just cargo-for imgkit test
    just cargo-for ziputil test

cargo-for $native_mod='' +args='':
     (cd native/$native_mod && cargo {{args}})

assets-output-clean:
    rm -rf test/assets/output/*
    rm -rf _assets/_cache/*

destory:
    just clean
    just dev-env down -v
