defmodule PolicrMiniBot.CleanerQueen do
  @moduledoc false

  require Logger
  alias Honeycomb.FailureMode.Retry

  use Honeycomb.Queen,
    id: :cleaner,
    concurrency: 50,
    failure_mode: %Retry{max_times: 5, ensure: &ensure/1}

  def ensure(error) do
    case error do
      %MatchError{term: {:error, %Telegex.RequestError{reason: :timeout}}} ->
        # 请求超时，执行重试
        :continue

      %MatchError{term: {:error, reason}} ->
        # 删除消息出错
        Logger.warning("Delete message failed: #{inspect(reason)}")

        :halt
    end
  end
end
