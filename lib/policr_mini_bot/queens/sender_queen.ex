defmodule PolicrMiniBot.SenderQueen do
  @moduledoc false

  require Logger
  alias Honeycomb.FailureMode.Retry

  use Honeycomb.Queen,
    id: :smart_sender,
    concurrency: 30,
    failure_mode: %Retry{max_times: 3, ensure: &ensure/1}

  def ensure(error) do
    case error do
      %MatchError{term: {:error, %Telegex.RequestError{reason: :timeout}}} ->
        # 请求超时，执行重试
        :continue

      %MatchError{
        term:
          {:error,
           %Telegex.Error{
             description: <<"Too Many Requests: retry after " <> second>>,
             error_code: 429
           }}
      } ->
        # 按照错误消息中的秒数等待重试
        {:continue, String.to_integer(second) * 1000}

      _ ->
        :continue
    end
  end
end
