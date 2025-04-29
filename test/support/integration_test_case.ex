defmodule GRPC.Integration.TestCase do
  use ExUnit.CaseTemplate, async: true

  require Logger

  using do
    quote do
      import GRPC.Integration.TestCase
    end
  end

  def run_endpoint(endpoint, func, opts \\ [port: 0]) when is_list(opts) do
    full_opts = Keyword.put(opts, :adapter, GRPC.Server.Adapters.Cowboy)

    port =
      case GRPC.Endpoint.start(endpoint, full_opts) do
        {:ok, _pid, port} -> port
        {:error, {:already_started, _pid}} -> :error
      end

    try do
      func.(port)
    after
      :ok = GRPC.Endpoint.stop(endpoint, adapter: GRPC.Server.Adapters.Cowboy)
    end
  end

  def reconnect_endpoint(endpoint, port, retry \\ 3) do
    result = GRPC.Endpoint.start(endpoint, port: port)

    case result do
      {:ok, _, ^port} ->
        result

      {:error, :eaddrinuse} ->
        Logger.warning("Got eaddrinuse when reconnecting to #{endpoint}:#{port}. retry: #{retry}")

        if retry >= 1 do
          Process.sleep(500)
          reconnect_endpoint(endpoint, port, retry - 1)
        else
          result
        end

      _ ->
        result
    end
  end

  def attach_events(event_names) do
    test_pid = self()

    handler_id = "handler-#{inspect(test_pid)}"

    :telemetry.attach_many(
      handler_id,
      event_names,
      fn name, measurements, metadata, [] ->
        send(test_pid, {name, measurements, metadata})
      end,
      []
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)
    end)
  end
end
