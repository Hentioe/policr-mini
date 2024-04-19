defmodule PolicrMini.Serveds do
  @moduledoc false

  import Ecto.Query

  alias PolicrMini.Repo
  alias PolicrMini.Instances.Chat

  @doc """
  查找所有已接管群组。
  """
  def find_takeovered_chats do
    from(c in Chat, where: c.is_take_over == true) |> Repo.all()
  end
end
