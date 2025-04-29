defmodule GRPC.EndpointTest do
  use ExUnit.Case, async: true

  defmodule Interceptor1 do
    def init(_), do: nil
  end

  defmodule Interceptor2 do
    def init(opts), do: opts
  end

  defmodule Interceptor3 do
    def init(_), do: [foo: :bar]
  end

  defmodule Interceptor4 do
    def init(opts), do: opts
  end

  defmodule FooEndpoint do
    use GRPC.Endpoint

    intercept Interceptor1
    intercept Interceptor2, foo: 1

    run Server1, interceptors: [Interceptor3]
    run [Server2, Server3], interceptors: [{Interceptor4, []}]
  end

  test "intercept works" do
    interceptors = GRPC.Endpoint.interceptors(FooEndpoint)
    assert [{Interceptor1, nil}, {Interceptor2, [foo: 1]}] == interceptors.endpoint
  end

  test "run creates servers" do
    assert [Server2, Server3, Server1] == FooEndpoint.__meta__(:servers)
  end

  test "run creates server_interceptors" do
    mw = [{Interceptor4, []}]
    interceptors = GRPC.Endpoint.interceptors(FooEndpoint)

    assert %{Server1 => [{Interceptor3, [foo: :bar]}], Server2 => mw, Server3 => mw} ==
             interceptors.servers
  end

  test "stop/2 works" do
    assert {FeatureEndpoint} =
             GRPC.Endpoint.stop(FeatureEndpoint, adapter: GRPC.Test.ServerAdapter)
  end
end
