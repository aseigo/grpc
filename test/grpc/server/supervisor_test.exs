defmodule GRPC.Server.SupervisorTest do
  use ExUnit.Case, async: false

  alias GRPC.Server.Supervisor

  defmodule MockEndpoint do
    def __meta__(:interceptors), do: []
    def __meta__(:servers), do: [FeatureServer]
    def __meta__(:server_interceptors), do: %{}
  end

  describe "init/1" do
    test "does not start children if opts sets false" do
      assert {:ok, {%{strategy: :one_for_one}, []}} =
               Supervisor.init(endpoint: MockEndpoint, port: 1234, start_server: false)
    end

    test "fails if a tuple is passed" do
      assert_raise FunctionClauseError,
                   fn ->
                     Supervisor.init({MockEndpoint, 1234})
                   end

      assert_raise FunctionClauseError,
                   fn ->
                     Supervisor.init({MockEndpoint, 1234, start_server: true})
                   end
    end

    test "starts children if opts sets true" do
      endpoint_str = "#{Macro.to_string(MockEndpoint)}"

      assert {:ok,
              {%{strategy: :one_for_one},
               [
                 %{
                   id: {:ranch_listener_sup, ^endpoint_str},
                   start: _,
                   type: :supervisor
                 }
               ]}} = Supervisor.init(endpoint: MockEndpoint, port: 1234, start_server: true)
    end
  end
end
