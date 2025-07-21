defmodule PolicrMiniWeb.AdminV2.API.PaginatedJSON do
  alias PolicrMini.Paginated

  def render(paginated, items_renderer)
      when is_struct(paginated, Paginated) and is_function(items_renderer) do
    %{
      page: paginated.page,
      page_size: paginated.page_size,
      items: items_renderer.(paginated.items),
      total: paginated.total
    }
  end
end
