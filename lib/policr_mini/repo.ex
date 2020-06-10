defmodule PolicrMini.Repo do
  use Ecto.Repo,
    otp_app: :policr_mini,
    adapter: Ecto.Adapters.Postgres
end
