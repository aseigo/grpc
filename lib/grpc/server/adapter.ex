defmodule GRPC.Server.Adapter do
  @moduledoc """
  HTTP server adapter for GRPC.
  """
  @type adapter :: module

  @spec default() :: adapter
  def default(), do: GRPC.Server.Adapters.Cowboy

  @spec from_opts(opts :: Keyword.t()) :: adapter
  def from_opts(opts), do: Keyword.get(opts, :adapter, default())

  @type state :: %{
          pid: pid,
          handling_timer: reference | nil,
          resp_trailers: map,
          compressor: atom | nil,
          pending_reader: nil
        }

  @callback start(
              endpoint :: module(),
              opts :: keyword()
            ) ::
              {atom(), any(), non_neg_integer()}

  @callback stop(endpoint :: module()) :: :ok | {:error, :not_found}

  @callback send_reply(state, content :: binary(), opts :: keyword()) :: any()

  @callback send_headers(state, headers :: map()) :: any()
end
