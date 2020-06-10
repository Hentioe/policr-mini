defmodule PolicrMini.Bot.Helper do
  defdelegate bot_id(), to: PolicrMini.Bot, as: :id
  defdelegate bot_username(), to: PolicrMini.Bot, as: :username

  def fullname(%{first_name: first_name, last_name: last_name}), do: "#{first_name} #{last_name}"
  def fullname(%{first_name: first_name}), do: first_name
  def fullname(%{last_name: last_name}), do: last_name
end
