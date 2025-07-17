defmodule Capinde do
  @moduledoc false

  alias Capinde.Error
  alias Capinde.Generation.Input
  alias Capinde.Payload.{Generated, DeployedInfo, ServerInfo, ArchiveInfo}

  def generate(input) when is_struct(input, Input) do
    call("/generate", :post, input, &Generated.from/1)
  end

  def server_info do
    call("/server/info", :get, %{}, &ServerInfo.from/1)
  end

  def deployed do
    call("/provider/deployed", :get, %{}, &DeployedInfo.from/1)
  end

  def uploaded do
    call("/provider/uploaded", :get, %{}, &ArchiveInfo.from/1)
  end

  def upload(archive_path) do
    alias Multipart.Part

    multipart = Multipart.new()

    multipart =
      Multipart.add_part(
        multipart,
        Part.file_field(archive_path, :archive)
      )

    body_stream = Multipart.body_stream(multipart)
    content_length = Multipart.content_length(multipart)
    content_type = Multipart.content_type(multipart, "multipart/form-data")
    headers = [{"Content-Type", content_type}, {"Content-Length", to_string(content_length)}]

    Finch.build("POST", "#{endpoint()}/provider/upload", headers, {:stream, body_stream})
    |> Finch.request(__MODULE__)
    |> handle_resp(&ArchiveInfo.from/1)
  end

  def delete_uploaded do
    call("/provider/uploaded", :delete)
  end

  def deploy_uploaded do
    call("/provider/deploy", :put)
  end

  @content_type_header {"Content-Type", "application/json"}

  defp call(path, method, body \\ %{}, cast_fun \\ nil) do
    method
    |> Finch.build("#{endpoint()}#{path}", [@content_type_header], JSON.encode!(body))
    |> Finch.request(__MODULE__.Finch)
    |> handle_resp(cast_fun)
  end

  defp handle_resp({:ok, resp}, cast_fun) when resp.status == 200 do
    body = JSON.decode!(resp.body)

    if cast_fun do
      {:ok, cast_fun.(body)}
    else
      {:ok, body}
    end
  end

  defp handle_resp({:ok, resp}, _) do
    %{"message" => message} = JSON.decode!(resp.body)

    {:error, %Error{message: message}}
  end

  defp handle_resp({:error, reason}, _) do
    {:error, reason}
  end

  defp endpoint do
    # todo: 在独立项目时此处要单独设计
    base_url = Application.get_env(:policr_mini, __MODULE__, [])[:base_url]

    "#{base_url}/api"
  end
end
