defmodule GRPC.Server.Interceptors.LoggerTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias GRPC.Server.Interceptors.Logger, as: LoggerInterceptor
  alias GRPC.Server.Stream

  defmodule FakeRequest do
    defstruct []
  end

  @server_name :server
  @rpc {1, 2, 3}

  setup do
    log_level = Logger.level()
    on_exit(fn -> Logger.configure(level: log_level) end)
  end

  test "request id is only set if not previously set" do
    assert Logger.metadata() == []

    request_id = to_string(System.monotonic_time())
    request = %FakeRequest{}
    stream = %Stream{server: @server_name, rpc: @rpc, request_id: request_id}

    LoggerInterceptor.call(
      request,
      stream,
      LoggerInterceptor.init(level: :info)
    )

    assert [request_id: request_id] == Logger.metadata()

    stream = %{stream | request_id: nil}

    LoggerInterceptor.call(
      :request,
      stream,
      LoggerInterceptor.init(level: :info)
    )

    assert request_id == Logger.metadata()[:request_id]
  end

  test "logs info-level by default" do
    Logger.configure(level: :all)

    request = %FakeRequest{}
    stream = %Stream{server: @server_name, rpc: @rpc, request_id: nil}
    opts = LoggerInterceptor.init([])

    logs =
      capture_log(fn ->
        {:after, {m, f, a}, _request, _stream} = LoggerInterceptor.call(request, stream, opts)
        apply(m, f, a ++ [{:ok, :ok}])
      end)

    assert logs =~ ~r/\[info\]\s+Handled by #{inspect(@server_name)}/
  end

  test "allows customizing log level" do
    Logger.configure(level: :all)

    request = %FakeRequest{}
    stream = %Stream{server: @server_name, rpc: @rpc, request_id: nil}
    opts = LoggerInterceptor.init(level: :warning)

    logs =
      capture_log(fn ->
        {:after, {m, f, a}, _request, _stream} = LoggerInterceptor.call(request, stream, opts)
        apply(m, f, a ++ [{:ok, :ok}])
      end)

    assert logs =~ ~r/\[warn(?:ing)?\]\s+Handled by #{inspect(@server_name)}/
  end

  @tag capture_log: true
  test "returns :after when above :logger level" do
    Logger.configure(level: :all)

    request = %FakeRequest{}
    stream = %Stream{server: @server_name, rpc: @rpc, request_id: nil}
    opts = LoggerInterceptor.init(level: :info)

    assert({:after, _mfa, ^request, ^stream} = LoggerInterceptor.call(request, stream, opts))
  end

  test "returns :cont when below :logger level" do
    Logger.configure(level: :warning)

    request = %FakeRequest{}
    stream = %Stream{server: @server_name, rpc: @rpc, request_id: nil}
    opts = LoggerInterceptor.init(level: :info)

    assert({:cont, ^request, ^stream} = LoggerInterceptor.call(request, stream, opts))
  end
end
