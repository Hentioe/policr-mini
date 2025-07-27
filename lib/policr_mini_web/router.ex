defmodule PolicrMiniWeb.Router do
  use PolicrMiniWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
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

  pipeline :admin_v2 do
    plug PolicrMiniWeb.AdminV2.TokenAuth, from: :page
  end

  pipeline :admin_v2_api do
    plug :accepts, ["json"]
    plug PolicrMiniWeb.AdminV2.TokenAuth, from: :api
  end

  pipeline :console_v2 do
    plug PolicrMiniWeb.ConsoleV2.TMAAuth, from: :page
  end

  pipeline :console_v2_api do
    plug :accepts, ["json"]
    plug PolicrMiniWeb.ConsoleV2.TMAAuth, from: :api
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
    get "/terms", TermController, :index
  end

  scope "/api/v1", PolicrMiniWeb.API.V1 do
    pipe_through :api

    get "/totals", IndexController, :totals
  end

  scope "/console/api", PolicrMiniWeb.Console.API do
    pipe_through [:console_api]

    get "/:chat_id/stats", StatsController, :query
  end

  scope "/admin/v2/api", PolicrMiniWeb.AdminV2.API do
    pipe_through [:admin_v2_api]

    get "/", PageController, :index

    get "/profile", ProfileController, :index
    get "/stats", StatsController, :index
    get "/customize", CustomizeController, :index
    get "/management", PageController, :management
    get "/assets", PageController, :assets
    get "/tasks", PageController, :tasks

    put "/schemes/default", SchemeController, :update_default

    post "/provider/upload", ProviderController, :upload
    delete "/provider/uploaded", ProviderController, :delete
    put "/provider/deploy", ProviderController, :deploy

    put "/chats/:id/sync", ChatController, :sync
    put "/chats/:id/leave", ChatController, :leave

    post "/bees/reset_stats", BeeController, :reset_stats

    get "/term", TermController, :show
    put "/term", TermController, :save
    delete "/term", TermController, :delete
    post "/term/preview", TermController, :preview

    get "/stats/query", StatsController, :query
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

    put "/verifications/:id/kill", VerificationController, :kill

    get "/profile", ProfileController, :index
  end

  scope "/admin/v2", PolicrMiniWeb.AdminV2 do
    pipe_through [:browser, :admin_v2]

    get "/*path", PageController, :home
  end

  scope "/console/v2/api", PolicrMiniWeb.ConsoleV2.API do
    pipe_through [:console_v2_api]

    get "/users/me", UserController, :me

    get "/chats", ChatController, :index
    get "/chats/:id/stats", ChatController, :stats
    get "/chats/:id/scheme", ChatController, :scheme
    get "/chats/:id/customs", ChatController, :customs
    get "/chats/:id/verifications", ChatController, :verifications
    get "/chats/:id/operations", ChatController, :operations

    put "/schemes/:id", SchemeController, :update

    post "/customs", CustomController, :add
    put "/customs/:id", CustomController, :update
    delete "/customs/:id", CustomController, :delete
  end

  scope "/console/v2", PolicrMiniWeb.ConsoleV2 do
    pipe_through [:browser, :console_v2]

    get "/user_photo", PageController, :user_photo
    get "/*path", PageController, :home
  end

  scope "/admin", PolicrMiniWeb.Admin do
    pipe_through [:browser, :admin]

    get "/logout", PageController, :logout
    get "/*path", PageController, :index
  end

  scope "/console", PolicrMiniWeb.Console do
    pipe_through [:browser, :console]

    get "/photo", PageController, :photo
    get "/logout", PageController, :logout
    get "/*path", PageController, :index
  end

  scope "/", PolicrMiniWeb do
    pipe_through :browser

    # 此 API 被 admin 依赖
    get "/own_photo", PageController, :own_photo
    # 此 API 是否存在依赖未知
    get "/uploaded/:name", PageController, :uploaded
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
