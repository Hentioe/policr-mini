defmodule PolicrMini.InstancesTest do
  use PolicrMini.DataCase
  doctest PolicrMini.Instances

  alias PolicrMini.{Factory, ChatBusiness, PermissionBusiness, UserBusiness}
  alias PolicrMini.Instances.SponsorshipAddress

  import PolicrMini.Instances

  describe "terms" do
    def build_term_params(attrs \\ []) do
      term = Factory.build(:term)

      term
      |> struct(attrs)
      |> Map.from_struct()
    end

    def build_chat_params(attrs \\ []) do
      chat = Factory.build(:chat)
      chat |> struct(attrs) |> Map.from_struct()
    end

    test "fetch_term/0" do
      {:ok, term} = fetch_term()

      assert term.id == 1
    end

    test "create_term/1" do
      params = build_term_params()
      {:ok, term} = create_term(params)

      assert term.id == params.id
      assert term.content == params.content
    end

    test "update_term/2" do
      params = build_term_params()
      {:ok, term1} = create_term(params)

      updated_content = "更新后的服务条款。"

      params = %{
        "content" => updated_content
      }

      {:ok, term2} = update_term(term1, params)

      assert term2.content == updated_content
    end
  end

  describe "chats" do
    test "create_chat/1" do
      chat_params = build_chat_params()
      {:ok, chat} = create_chat(chat_params)

      assert chat.id == chat_params.id
      assert chat.type == String.to_atom(chat_params.type)
      assert chat.small_photo_id == chat_params.small_photo_id
      assert chat.big_photo_id == chat_params.big_photo_id
      assert chat.username == chat_params.username
      assert chat.description == chat_params.description
      assert chat.invite_link == chat_params.invite_link
      assert chat.is_take_over == chat_params.is_take_over
    end

    test "create_chat/2" do
      chat_params = build_chat_params()
      {:ok, chat1} = create_chat(chat_params)

      updated_type = "private"
      updated_title = "标题"
      updated_username = "新 Elixir 交流群"
      updated_description = "elixir_new_chat"
      updated_invite_link = "https://t.me/fIkcDF"

      params = %{
        "type" => updated_type,
        "title" => updated_title,
        "username" => updated_username,
        "description" => updated_description,
        "invite_link" => updated_invite_link
      }

      {:ok, chat2} = update_chat(chat1, params)

      assert chat2.type == String.to_atom(updated_type)
      assert chat2.title == updated_title
      assert chat2.username == updated_username
      assert chat2.description == updated_description
      assert chat2.invite_link == updated_invite_link
    end

    test "fetch_and_update_chat/2" do
      chat_params = build_chat_params()
      {:ok, chat} = fetch_and_update_chat(987_654_321, chat_params)

      assert chat.id == 987_654_321
      assert chat.type == String.to_atom(chat_params.type)
      assert chat.small_photo_id == chat_params.small_photo_id
      assert chat.big_photo_id == chat_params.big_photo_id
      assert chat.username == chat_params.username
      assert chat.description == chat_params.description
      assert chat.invite_link == chat_params.invite_link
      assert chat.is_take_over == chat_params.is_take_over
    end

    test "fetch_and_update_chat/2 with existing data" do
      {:ok, chat1} = create_chat(build_chat_params())
      updated_title = "新 Elixir 交流群"
      {:ok, chat2} = fetch_and_update_chat(chat1.id, build_chat_params(title: updated_title))

      assert chat2.title == updated_title
    end

    test "cancel_chat_takeover/1" do
      {:ok, chat1} = create_chat(build_chat_params())
      assert chat1.is_take_over

      {:ok, chat2} = chat1 |> cancel_chat_takeover()
      assert chat2.is_take_over == false
      assert struct(chat2, is_take_over: true) == chat1
    end

    test "reset_chat_permissions!/2" do
      chat_params = build_chat_params()
      {:ok, chat} = create_chat(chat_params)
      {:ok, user1} = UserBusiness.create(Factory.build(:user) |> Map.from_struct())

      reset_chat_permissions!(chat, [
        Factory.build(:permission, user_id: user1.id)
      ])

      users = ChatBusiness.find_administrators(chat.id)
      assert length(users) == 1
      assert hd(users) == user1

      {:ok, user2} = UserBusiness.create(Factory.build(:user, id: 1_988_756) |> Map.from_struct())

      {:ok, _} =
        reset_chat_permissions!(chat, [
          Factory.build(:permission, user_id: user1.id, tg_is_owner: false),
          Factory.build(:permission, user_id: user2.id)
        ])

      users = ChatBusiness.find_administrators(chat.id)
      assert length(users) == 2
      assert hd(users) == user1
      permission = PermissionBusiness.find(chat.id, user1.id)
      assert permission.tg_is_owner == false

      {:ok, _} = chat |> reset_chat_permissions!([])
      users = ChatBusiness.find_administrators(chat.id)
      assert Enum.empty?(users)
    end
  end

  describe "sponsors" do
    def build_sponsor_params(attrs \\ []) do
      sponsor = Factory.build(:sponsor)

      sponsor
      |> struct(attrs)
      |> Map.from_struct()
    end

    test "create_sponsor/1" do
      sponsor_params = build_sponsor_params()
      {:ok, sponsor} = create_sponsor(sponsor_params)

      assert sponsor.title == sponsor_params.title
      assert sponsor.avatar == sponsor_params.avatar
      assert sponsor.homepage == sponsor_params.homepage
      assert sponsor.introduction == sponsor_params.introduction
      assert sponsor.contact == sponsor_params.contact
      assert sponsor.uuid == sponsor_params.uuid
      assert sponsor.is_official == sponsor_params.is_official
    end

    test "update_sponsor/2" do
      sponsor_params = build_sponsor_params()
      {:ok, sponsor1} = create_sponsor(sponsor_params)

      updated_title = "宇宙电报发射中心"
      updated_avatar = "/uploaded/universe.jpg"
      updated_homepage = "https://universe.org"
      updated_introduction = "我们用电报研究外星生命"
      updated_contact = "@universe"
      updated_uuid = "yyyy-yyyy-yyyy-yyyy"
      updated_is_official = true

      params = %{
        "title" => updated_title,
        "avatar" => updated_avatar,
        "homepage" => updated_homepage,
        "introduction" => updated_introduction,
        "contact" => updated_contact,
        "uuid" => updated_uuid,
        "is_official" => updated_is_official
      }

      {:ok, sponsor2} = update_sponsor(sponsor1, params)

      assert sponsor2.title == updated_title
      assert sponsor2.avatar == updated_avatar
      assert sponsor2.homepage == updated_homepage
      assert sponsor2.introduction == updated_introduction
      assert sponsor2.contact == updated_contact
      assert sponsor2.uuid == updated_uuid
      assert sponsor2.is_official == updated_is_official
    end

    test "delete_sponsor/1" do
      {:ok, _} = create_sponsor(build_sponsor_params())
      {:ok, sponsor2} = create_sponsor(build_sponsor_params(uuid: "yyyy-yyyy-yyyy-yyyy"))

      sponsors = find_sponsors()

      assert length(sponsors) == 2

      {:ok, _} = delete_sponsor(sponsor2)

      sponsors = find_sponsors()

      assert length(sponsors) == 1
    end

    test "find_sponsors/1" do
      {:ok, _} = create_sponsor(build_sponsor_params())
      {:ok, _} = create_sponsor(build_sponsor_params(uuid: "yyyy-yyyy-yyyy-yyyy"))

      sponsors = find_sponsors()

      assert length(sponsors) == 2
    end
  end

  describe "sponsorship_histories" do
    def build_sponsorship_history_params(attrs \\ []) do
      sponsorship_history = Factory.build(:sponsorship_history)

      sponsorship_history
      |> struct(attrs)
      |> Map.from_struct()
    end

    test "create_sponsorship_histrory/1" do
      sponsorship_history_params = build_sponsorship_history_params()
      {:ok, sponsorship_history} = create_sponsorship_histrory(sponsorship_history_params)

      assert sponsorship_history.expected_to == sponsorship_history_params.expected_to
      assert sponsorship_history.amount == sponsorship_history_params.amount
      assert sponsorship_history.has_reached == sponsorship_history_params.has_reached
      assert sponsorship_history.reached_at == sponsorship_history_params.reached_at
    end

    test "update_sponsorship_histrory/2" do
      sponsorship_history_params = build_sponsorship_history_params()
      {:ok, sponsorship_history1} = create_sponsorship_histrory(sponsorship_history_params)

      now_dt = DateTime.truncate(DateTime.utc_now(), :second)

      updated_expected_to = "替作者买单一份外卖"
      updated_amount = 35
      updated_has_reached = true
      updated_reached_at = now_dt

      params = %{
        "expected_to" => updated_expected_to,
        "amount" => updated_amount,
        "has_reached" => updated_has_reached,
        "reached_at" => updated_reached_at
      }

      {:ok, sponsorship_history2} = update_sponsorship_histrory(sponsorship_history1, params)

      assert sponsorship_history2.expected_to == updated_expected_to
      assert sponsorship_history2.amount == updated_amount
      assert sponsorship_history2.has_reached == updated_has_reached
      assert sponsorship_history2.reached_at == updated_reached_at
    end

    test "sponsorship_historyship_histories/1" do
      {:ok, _} = create_sponsorship_histrory(build_sponsorship_history_params())

      {:ok, sponsorship_history2} =
        create_sponsorship_histrory(build_sponsorship_history_params())

      sponsorship_historyship_histories = find_sponsorship_histrories()

      assert length(sponsorship_historyship_histories) == 2

      {:ok, _} = delete_sponsorship_histrory(sponsorship_history2)

      sponsorship_historyship_histories = find_sponsorship_histrories()

      assert length(sponsorship_historyship_histories) == 1
    end

    test "reached_sponsorship_histrory/1" do
      {:ok, sponsorship_history} =
        create_sponsorship_histrory(build_sponsorship_history_params(has_reached: false))

      {:ok, sponsorship_history2} = reached_sponsorship_histrory(sponsorship_history)

      assert sponsorship_history2.has_reached == true
    end

    test "find_sponsorship_histrories/1" do
      {:ok, sponsorship_history1} =
        create_sponsorship_histrory(build_sponsorship_history_params(has_reached: true))

      reached_at = DateTime.add(DateTime.utc_now(), 1, :second)

      params = build_sponsorship_history_params(reached_at: reached_at, hidden: true)
      {:ok, sponsorship_history2} = create_sponsorship_histrory(params)

      sponsorship_histories = find_sponsorship_histrories()

      assert length(sponsorship_histories) == 2
      assert Enum.at(sponsorship_histories, 0) == sponsorship_history2
      assert Enum.at(sponsorship_histories, 1) == sponsorship_history1

      sponsorship_histories = find_sponsorship_histrories(has_reached: true)

      assert length(sponsorship_histories) == 1
      assert hd(sponsorship_histories) == sponsorship_history1

      sponsorship_histories = find_sponsorship_histrories(display: :hidden)

      assert length(sponsorship_histories) == 1
      assert hd(sponsorship_histories) == sponsorship_history2

      sponsorship_histories = find_sponsorship_histrories(display: :not_hidden)

      assert length(sponsorship_histories) == 1
      assert hd(sponsorship_histories) == sponsorship_history1
    end
  end

  describe "sponsorship_addresses" do
    def build_sponsorship_address_params(attrs \\ []) do
      sponsorship_address = Factory.build(:sponsorship_address)

      sponsorship_address
      |> struct(attrs)
      |> Map.from_struct()
    end

    test "create_sponsorship_address/1" do
      params = build_sponsorship_address_params()
      {:ok, sponsorship_address} = create_sponsorship_address(params)

      assert sponsorship_address.name == params.name
      assert sponsorship_address.description == params.description
      assert sponsorship_address.text == params.text
      assert sponsorship_address.image == params.image
    end

    test "delete_sponsorship_address/1" do
      params = build_sponsorship_address_params()
      {:ok, sponsorship_address} = create_sponsorship_address(params)

      {:ok, _} = delete_sponsorship_address(sponsorship_address)

      {:error, :not_found, _} = SponsorshipAddress.get(sponsorship_address.id)
    end

    test "update_sponsorship_address/2" do
      params = build_sponsorship_address_params()
      {:ok, sponsorship_address1} = create_sponsorship_address(params)

      updated_name = "USDT (ERC20)"
      updated_description = "如美元般稳定的加密货币 USDT 的转账地址，仅限 ERC20 网络。"
      updated_text = "--------------------------"
      updated_image = "usdt-erc20-qrcode.jpg"

      params = %{
        "name" => updated_name,
        "description" => updated_description,
        "text" => updated_text,
        "image" => updated_image
      }

      {:ok, sponsorship_address2} = sponsorship_address1 |> update_sponsorship_address(params)

      assert sponsorship_address2.name == updated_name
      assert sponsorship_address2.description == updated_description
      assert sponsorship_address2.text == updated_text
      assert sponsorship_address2.image == updated_image
    end

    test "find_sponsorship_address/1" do
      {:ok, _} = create_sponsorship_address(build_sponsorship_address_params())
      {:ok, _} = create_sponsorship_address(build_sponsorship_address_params())

      sponsorship_addresses = find_sponsorship_addresses()

      assert length(sponsorship_addresses) == 2
    end
  end

  describe "third_parties" do
    def build_params(attrs \\ []) do
      third_party = Factory.build(:third_party)

      third_party
      |> struct(attrs)
      |> Map.from_struct()
    end

    test "create_third_party/1" do
      third_party_params = build_params()
      {:ok, third_party} = create_third_party(third_party_params)

      assert third_party.name == third_party_params.name
      assert third_party.bot_username == third_party_params.bot_username
      assert third_party.bot_avatar == third_party_params.bot_avatar
      assert third_party.homepage == third_party_params.homepage
      assert third_party.description == third_party_params.description
      assert third_party.hardware == third_party_params.hardware
      assert third_party.running_days == third_party_params.running_days
      assert third_party.version == third_party_params.version
      assert third_party.is_forked == third_party_params.is_forked
    end

    test "update_third_party/2" do
      third_party_params = build_params()
      {:ok, third_party1} = create_third_party(third_party_params)

      updated_name = "测试实例"
      updated_bot_username = "policr_mini_beta_bot"
      updated_bot_avatar = "beta.jpg"
      updated_homepage = "https://mini-beta.gramlabs.org"
      updated_description = "这是一个修正开发分支数个 BUG 的测试版本"
      updated_hardware = "1C2GB"
      updated_running_days = 99
      updated_version = "0.0.1-beta.1"
      updated_is_forked = true

      params = %{
        "name" => updated_name,
        "bot_username" => updated_bot_username,
        "bot_avatar" => updated_bot_avatar,
        "homepage" => updated_homepage,
        "description" => updated_description,
        "hardware" => updated_hardware,
        "running_days" => updated_running_days,
        "version" => updated_version,
        "is_forked" => updated_is_forked
      }

      {:ok, third_party2} = update_third_party(third_party1, params)

      assert third_party2.name == updated_name
      assert third_party2.bot_username == updated_bot_username
      assert third_party2.bot_avatar == updated_bot_avatar
      assert third_party2.homepage == updated_homepage
      assert third_party2.description == updated_description
      assert third_party2.hardware == updated_hardware
      assert third_party2.running_days == updated_running_days
      assert third_party2.version == updated_version
      assert third_party2.is_forked == updated_is_forked
    end

    test "find_third_parties/1" do
      {:ok, third_party1} = create_third_party(build_params())
      {:ok, third_party2} = create_third_party(build_params(running_days: 2))

      [third_party3, third_party4] = find_third_parties()

      assert third_party3.id == third_party2.id
      assert third_party4.id == third_party1.id
    end
  end
end
