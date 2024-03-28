format:
    just mix-format assets-format
    just cargo-for imgkit fmt
    just cargo-for ziputil fmt

mix-format:
    mix format

assets-format:
    assets/node_modules/.bin/prettier --write assets/

front-setup:
    just front-pnpm install

front-format:
    just front-pnpm run format

front-lint:
    just front-pnpm run lint

front-clean:
    rm -rf webapps/node_modules

front-pnpm +args:
    (cd webapps && pnpm {{args}})

setup:
    mix deps.get
    just assets-setup
    just dev-env up -d
    just cargo-for imgkit build
    just cargo-for ziputil build
    mix ecto.setup

assets-setup:
    pnpm install --prefix assets

dev-env +args:
    docker compose -f docker-compose.dev.yml --env-file dev.env {{args}}

run +args='':
    iex -S mix {{args}}

test:
    mix test
    just cargo-for imgkit test
    just cargo-for ziputil test

cargo-for $native_mod='' +args='':
     (cd native/$native_mod && cargo {{args}})

mix-clean:
    mix clean
    rm -rf deps _build

assets-clean:
    rm -rf assets/node_modules
    rm -rf priv/static

clean-assets-output:
    rm -rf test/assets/output/*
    rm -rf _assets/_cache/*

clean:
    just mix-clean assets-clean
    just cargo-for imgkit clean
    just cargo-for ziputil clean
    rm -rf priv/native

destory:
    just clean dev-env down -v
