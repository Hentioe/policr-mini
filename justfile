format:
    just mix-format front-format

mix-format:
    mix format

front-format:
    assets/node_modules/.bin/prettier --write assets/

setup:
    mix deps.get
    just front-setup dev-env up -d
    mix ecto.setup

front-setup:
    pnpm install --prefix assets

dev-env +args:
    docker compose -f dev.docker-compose.yml --env-file dev.env {{args}}

run +args='':
    iex -S mix {{args}}

test:
    mix test

mix-clean:
    mix clean
    rm -rf deps _build

front-clean:
    rm -rf assets/node_modules
    rm -rf priv/static

clean:
    just mix-clean front-clean

destory:
    just clean dev-env down -v