defmodule FeatureEndpoint do
  use GRPC.Endpoint
  run(FeatureServer)
end
