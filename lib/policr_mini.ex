defmodule PolicrMini do
  @moduledoc """
  PolicrMini keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  defmacro __using__(business: schema_module) do
    quote do
      alias unquote(schema_module)
      alias PolicrMini.Repo

      @spec get(any, keyword) :: {:ok, Ecto.Schema.t()} | {:error, :not_found, map}
      def get(id, options \\ []) do
        preload = Keyword.get(options, :preload, [])
        record = unquote(schema_module) |> Repo.get(id) |> Repo.preload(preload)

        case record do
          nil -> {:error, :not_found, %{params: %{entry: unquote(schema_module), id: id}}}
          r -> {:ok, r}
        end
      end

      @type params :: %{optional(atom) => any} | %{optional(String.t()) => any}
      @type written_returns :: {:ok, unquote(schema_module).t()} | {:error, Ecto.Changeset.t()}
    end
  end

  def mix_env, do: Application.get_env(:policr_mini, :environment)

  @opts ["--independent", "--disable-image-rewrite"]

  @doc """
  检查可选项是否存在。

  ## 当前存在以下可选项：
    - `--independent`: 启用独立运营。
    - `--disable-image-rewrite`: 禁用图片重写。

  ## 例子
      iex> PolicrMini.opt_exists?("--independent")
      false
      iex> PolicrMini.opt_exists?("--disable-image-rewrite")
      false
  """
  def opt_exists?(opt_name) when opt_name in @opts do
    :opts |> config_get([]) |> Enum.member?(opt_name)
  end

  def opt_exists?(_opt_name), do: false

  def config_get(key, default \\ nil) do
    Application.get_env(:policr_mini, key, default)
  end
end
