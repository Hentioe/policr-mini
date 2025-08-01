defmodule PolicrMiniWeb.AdminV2.API.PageController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.{Uses, Paginated}
  alias PolicrMiniBot.Runner

  action_fallback PolicrMiniWeb.AdminV2.API.FallbackController

  def index(conn, _params) do
    with {:ok, capinde} <- Capinde.server_info() do
      version = Version.parse!(Application.get_env(:policr_mini, :version))

      version =
        if Enum.empty?(version.pre) do
          to_string(version.patch)
        else
          to_string(version.patch) <> "-" <> Enum.join(version.pre, ".")
        end

      server = %{
        version: version
      }

      render(conn, "index.json", server: server, capinde: capinde)
    end
  end

  def assets(conn, _params) do
    deployed =
      case Capinde.deployed() do
        {:ok, deployed} -> deployed
        _ -> nil
      end

    uploaded =
      case Capinde.uploaded() do
        {:ok, uploaded} -> uploaded
        _ -> nil
      end

    render(conn, "assets.json", deployed: deployed, uploaded: uploaded)
  end

  @fallback_page_size "10"
  @fallback_page "1"

  def management(conn, params) do
    page = String.to_integer(params["page"] || @fallback_page)
    page_size = String.to_integer(params["page_size"] || @fallback_page_size)

    conds =
      [
        limit: page_size,
        offset: (page - 1) * page_size,
        order_by: [desc: :inserted_at]
      ]

    {total, chats} =
      if keywords = params["keywords"] do
        {condition, chats} = Uses.search_chats(keywords, conds)
        total = Uses.count_chats(condition)

        {total, chats}
      else
        chats = Uses.list_chats(conds)
        total = Uses.count_chats()

        {total, chats}
      end

    render(conn, "management.json",
      chats: %Paginated{
        page: page,
        page_size: page_size,
        items: chats,
        total: total
      }
    )
  end

  def tasks(conn, _params) do
    jobs = Runner.jobs()
    bees = Honeycomb.bees(:background)

    render(conn, "tasks.json", jobs: jobs, bees: bees)
  end
end
