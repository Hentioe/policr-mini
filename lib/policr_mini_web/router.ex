defmodule PolicrMiniWeb.Router do
  use PolicrMiniWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug PolicrMiniWeb.TokenAuthentication, from: :admin
    plug :put_layout, {PolicrMiniWeb.LayoutView, :admin}
  end

  pipeline :console do
    plug PolicrMiniWeb.TokenAuthentication, from: :console
    plug :put_layout, {PolicrMiniWeb.LayoutView, :console}
  end

  pipeline :console_api do
    plug :accepts, ["json"]
    plug PolicrMiniWeb.TokenAuthentication, from: :console_api
  end

  pipeline :admin_api do
    plug :accepts, ["json"]
    plug PolicrMiniWeb.TokenAuthentication, from: :admin_api
  end

  scope "/api", PolicrMiniWeb.API do
    pipe_through :api

    get "/index", IndexController, :index
    get "/third_parties", ThirdPartyController, :index
    get "/terms", TermController, :index
    get "/sponsorship_histories", SponsorshipHistoryController, :index
    post "/sponsorship_histories", SponsorshipHistoryController, :add
  end

  scope "/console/api", PolicrMiniWeb.Console.API do
    pipe_through [:console_api]

    get "/:chat_id/stats", StatsController, :query
  end

  scope "/admin/api", PolicrMiniWeb.Admin.API do
    pipe_through [:admin_api]

    get "/chats", ChatController, :index
    get "/chats/:id/photo", ChatController, :photo
    get "/chats/:id/customs", ChatController, :customs
    get "/chats/:id/scheme", ChatController, :scheme
    put "/chats/:id/leave", ChatController, :leave
    put "/chats/:id/sync", ChatController, :sync
    put "/chats/:chat_id/scheme", ChatController, :update_scheme
    put "/chats/:chat_id/takeover", ChatController, :change_takeover
    get "/chats/:chat_id/permissions", ChatController, :permissions
    get "/chats/:chat_id/verifications", ChatController, :verifications
    get "/chats/:chat_id/operations", ChatController, :operations
    get "/chats/list", ChatController, :list
    get "/chats/search", ChatController, :search

    post "/customs", CustomKitController, :add
    put "/customs/:id", CustomKitController, :update
    delete "/customs/:id", CustomKitController, :delete

    put "/permissions/:id/readable", PermissionController, :change_readable
    put "/permissions/:id/writable", PermissionController, :change_writable
    put "/permissions/:id/customized", PermissionController, :change_customized
    delete "/permissions/:id/withdraw", PermissionController, :withdraw
    put "/permissions/chats/:chat_id/sync", PermissionController, :sync

    get "/statistics/find_recently", StatisticController, :find_recently

    put "/verifications/:id/kill", VerificationController, :kill

    get "/third_parties", ThirdPartyController, :index
    post "/third_parties", ThirdPartyController, :add
    put "/third_parties/:id", ThirdPartyController, :update
    delete "/third_parties/:id", ThirdPartyController, :delete

    get "/tasks", TaskController, :index

    get "/terms", TermController, :index
    put "/terms", TermController, :add_or_update
    delete "/terms", TermController, :delete
    post "/terms/preview", TermController, :preview

    get "/sponsorship_histories", SponsorshipHistoryController, :index
    post "/sponsorship_histories", SponsorshipHistoryController, :add
    put "/sponsorship_histories/:id", SponsorshipHistoryController, :update
    delete "/sponsorship_histories/:id", SponsorshipHistoryController, :delete
    put "/sponsorship_histories/:id/hidden", SponsorshipHistoryController, :hidden

    get "/sponsorship_addresses", SponsorshipAddressController, :index
    post "/sponsorship_addresses", SponsorshipAddressController, :add
    put "/sponsorship_addresses/:id", SponsorshipAddressController, :update
    delete "/sponsorship_addresses/:id", SponsorshipAddressController, :delete

    get "/profile", ProfileController, :index
    put "/profile/scheme", ProfileController, :update_scheme
    delete "/profile/temp_albums", ProfileController, :delete_temp_albums
    post "/profile/temp_albums", ProfileController, :upload_temp_albums
    put "/profile/albums", ProfileController, :update_albums
  end

  scope "/admin", PolicrMiniWeb.Admin do
    pipe_through [:browser, :admin]

    get "/logout", PageController, :logout
    get "/*path", PageController, :index
  end

  scope "/console", PolicrMiniWeb.Console do
    pipe_through [:browser, :console]

    get "/logout", PageController, :logout
    get "/*path", PageController, :index
  end

  scope "/", PolicrMiniWeb do
    pipe_through :browser

    get "/own_photo", PageController, :own_photo
    get "/uploaded/:name", PageController, :uploaded

    get "/*path", PageController, :index
  end
end
