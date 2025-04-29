defmodule GRPC.Integration.ConnectionTest do
  use GRPC.Integration.TestCase

  test "reconnection works" do
    endpoint = FeatureEndpoint
    {:ok, _, port} = GRPC.Endpoint.start(endpoint, port: 0)
    point = %Routeguide.Point{latitude: 409_146_138, longitude: -746_188_906}
    {:ok, channel} = GRPC.Stub.connect("localhost:#{port}", adapter_opts: [retry_timeout: 10])
    assert {:ok, _} = channel |> Routeguide.RouteGuide.Stub.get_feature(point)
    :ok = GRPC.Endpoint.stop(endpoint)
    {:ok, _, _} = reconnect_endpoint(endpoint, port)
    assert {:ok, _} = channel |> Routeguide.RouteGuide.Stub.get_feature(point)
    :ok = GRPC.Endpoint.stop(endpoint)
  end

  test "connecting with a domain socket works" do
    socket_path = "/tmp/grpc.sock"
    endpoint = FeatureEndpoint
    File.rm(socket_path)

    {:ok, _, _} = GRPC.Endpoint.start(endpoint, port: 0, ip: {:local, socket_path})
    {:ok, channel} = GRPC.Stub.connect(socket_path, adapter_opts: [retry_timeout: 10])

    point = %Routeguide.Point{latitude: 409_146_138, longitude: -746_188_906}
    assert {:ok, _} = channel |> Routeguide.RouteGuide.Stub.get_feature(point)
    :ok = GRPC.Endpoint.stop(endpoint)
  end

  test "authentication works" do
    endpoint = FeatureEndpoint

    cred = GRPC.Factory.build(:credential, verify: :verify_peer)

    {:ok, _, port} = GRPC.Endpoint.start(endpoint, port: 0, cred: cred)

    try do
      point = %Routeguide.Point{latitude: 409_146_138, longitude: -746_188_906}

      {:ok, channel} = GRPC.Stub.connect("localhost:#{port}", cred: cred)
      assert {:ok, _} = Routeguide.RouteGuide.Stub.get_feature(channel, point)
    catch
      error ->
        refute "Caught #{inspect(error)}"
    after
      :ok = GRPC.Endpoint.stop(endpoint)
    end
  end
end
