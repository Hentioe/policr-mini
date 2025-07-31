alias PolicrMini.Chats.Verification
alias PolicrMini.Schema.User
alias PolicrMini.Seeds.Support.FakeOperationGenerator

defmodule PolicrMini.Seeds.Support.FakeVerificationGenerator do
  def generate(chat_id, user, stop_secs) when is_integer(stop_secs) and is_struct(user, User) do
    # 随机生成状态
    status = Enum.random([:approved, :timeout, :incorrect, :expired, :manual_kick, :manual_ban])
    # 随机创建截止时间前至今的时间戳
    timestamp =
      DateTime.utc_now() |> DateTime.add(-:rand.uniform(stop_secs), :second)

    params = %{
      chat_id: chat_id,
      target_user_id: user.id,
      target_user_name: User.full_name(user),
      # 随机生成30到120秒的验证时间
      seconds: :rand.uniform(90) + 30,
      status: status,
      source: Enum.random([:joined, :join_request]),
      inserted_at: timestamp,
      updated_at: timestamp
    }

    fields =
      Verification.required_fields() ++
        Verification.optional_fields() ++ [:inserted_at, :updated_at]

    {:ok, _} =
      %Verification{}
      |> Ecto.Changeset.cast(params, fields)
      |> PolicrMini.Repo.insert()
  end

  def generate_all_with_operations(chat_id, user, stop_secs) do
    for _ <- 1..300 do
      {:ok, v} = okr = generate(chat_id, user, stop_secs)
      {:ok, _} = FakeOperationGenerator.generate(chat_id, v.id, stop_secs)

      okr
    end
  end
end
