defmodule GRPC.Server.Adapters.CowboyTest do
  use ExUnit.Case, async: false

  alias GRPC.Server.Adapters.Cowboy

  describe "child_spec/4" do
    test "produces the correct socket opts for ranch_tcp for inet" do
      spec =
        Cowboy.child_spec(
          endpoint: FeatureEndpoint,
          port: 8080,
          foo: :bar,
          ip: {127, 0, 0, 1},
          ipv6_v6only: false,
          net: :inet,
          baz: :foo
        )

      socket_opts = get_socket_opts_from_child_spec(spec)

      assert Enum.sort(socket_opts) ==
               Enum.sort([:inet, {:ip, {127, 0, 0, 1}}, {:ipv6_v6only, false}, {:port, 8080}])
    end

    test "produces the correct socket opts for ranch_tcp for inet6" do
      spec =
        Cowboy.child_spec(
          endpoint: FeatureEndpoint,
          port: 8081,
          foo: :bar,
          ip: {0, 0, 0, 0, 0, 0, 0, 1},
          ipv6_v6only: true,
          net: :inet6,
          baz: :foo
        )

      socket_opts = get_socket_opts_from_child_spec(spec)

      assert Enum.sort(socket_opts) ==
               Enum.sort([
                 :inet6,
                 {:ip, {0, 0, 0, 0, 0, 0, 0, 1}},
                 {:ipv6_v6only, true},
                 {:port, 8081}
               ])
    end
  end

  defp get_socket_opts_from_child_spec(spec) do
    {_Cowboy, _start_link, start_opts} = spec.start
    [_endpoint, _protocol, %{socket_opts: socket_opts}, _http, _env] = start_opts
    socket_opts
  end
end
