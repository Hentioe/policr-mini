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
    plug PolicrMiniWeb.TokenAuthentication, from: :page
    plug :put_layout, {PolicrMiniWeb.LayoutView, :admin}
  end

  pipeline :admin_api do
    plug :accepts, ["json"]
    plug PolicrMiniWeb.TokenAuthentication, from: :api
  end

  scope "/api", PolicrMiniWeb.API do
    pipe_through :api

    get "/index", IndexController, :index
  end

  scope "/admin/api", PolicrMiniWeb.Admin.API do
    pipe_through [:admin_api]

    get "/chats", ChatController, :index
    get "/chats/:id/photo", ChatController, :photo
    get "/chats/:id/customs", ChatController, :customs
    get "/chats/:id/scheme", ChatController, :scheme
    put "/chats/:id/leave", ChatController, :leave
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

    put "/verifications/:id/kick", VerificationController, :kick

    get "/logs", LogController, :index
  end

  scope "/admin", PolicrMiniWeb.Admin do
    pipe_through [:browser, :admin]

    get "/*path", PageController, :index
  end

  scope "/", PolicrMiniWeb do
    pipe_through :browser

    get "/*path", PageController, :index
  end
end
