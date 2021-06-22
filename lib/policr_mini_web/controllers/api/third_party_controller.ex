defmodule PolicrMiniWeb.API.ThirdPartyController do
  @moduledoc """
  第三方实例的前台 API 控制器。
  """

  use PolicrMiniWeb, :controller

  alias PolicrMini.ThirdPartyBusiness

  action_fallback PolicrMiniWeb.API.FallbackController

  plug CORSPlug, origin: &__MODULE__.load_origins/0

  @project_start_date ~D[2020-06-01]

  def offical_bot do
    %PolicrMini.Schema.ThirdParty{
      name: "Policr Mini",
      bot_username: "policr_mini_bot",
      homepage: "https://mini.telestd.me",
      description: "由 Telestd 项目组维护、POLICR 社区运营",
      running_days: Date.diff(Date.utc_today(), @project_start_date),
      is_forked: false
    }
  end

  def index(conn, _params) do
    third_parties = ThirdPartyBusiness.find_list()

    bot_username = PolicrMiniBot.username()
    offical_bot = offical_bot()

    current_index =
      if bot_username == offical_bot.bot_username do
        0
      else
        r =
          third_parties
          |> Enum.with_index()
          |> Enum.find(fn {third_party, _} -> third_party.bot_username == bot_username end)

        if r do
          elem(r, 1) + 1
        else
          1
        end
      end

    third_parties =
      case current_index do
        0 ->
          [offical_bot] ++ third_parties

        1 ->
          # 不在官方记录中。
          homepage = PolicrMiniWeb.root_url(has_end_slash: false)

          current_bot = %PolicrMini.Schema.ThirdParty{
            name: PolicrMiniBot.name(),
            bot_username: PolicrMiniBot.username(),
            homepage: homepage
          }

          [offical_bot, current_bot] ++ third_parties

        _ ->
          [offical_bot] ++ third_parties
      end

    render(conn, "index.json", %{
      third_parties: third_parties,
      official_index: 0,
      current_index: current_index
    })
  end

  # TODO: 使用专门的 Plug 缓存 `third_parties` 数据，以避免在 API 实现中出现重复查询。
  def load_origins do
    third_parties = ThirdPartyBusiness.find_list()

    Enum.map(third_parties, fn third_party -> third_party.homepage end)
  end
end
