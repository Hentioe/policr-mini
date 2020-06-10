defmodule PolicrMini.VerificationBusiness do
  use PolicrMini, business: PolicrMini.Schema.Verification

  def create(params) do
    %Verification{} |> Verification.changeset(params) |> Repo.insert()
  end

  def update(%Verification{} = verification, params) do
    verification |> Verification.changeset(params) |> Repo.update()
  end
end
