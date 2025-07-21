defmodule PolicrMiniWeb.AdminV2.API.PageController do
  use PolicrMiniWeb, :controller

  alias PolicrMini.{Uses, Paginated}

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
end
