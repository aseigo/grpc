defmodule GRPC.ServerInterceptor do
  @moduledoc """
  Interceptor on server side. See `GRPC.Endpoint`.
  """

  @moduledoc deprecated: "Use `GRPC.Server.Interceptor` instead"

  alias GRPC.Server.Stream

  @type options :: any()
  @type rpc_return ::
          {:ok, Stream.t(), struct()} | {:ok, Stream.t()} | {:error, GRPC.RPCError.t()}
  @type next :: (GRPC.Server.rpc_req(), Stream.t() -> rpc_return())

  @callback init(options) :: options
  @callback call(GRPC.Server.rpc_req(), stream :: Stream.t(), next, options) :: rpc_return
end

defmodule GRPC.Server.Interceptor do
  @moduledoc """
  Interceptor on server side. See `GRPC.Endpoint`.
  """
  alias GRPC.Server.Stream

  @type options :: any()
  @type after_fn :: {module(), function_name :: atom(), args :: [any]}
  @type intercept_return ::
          {:cont, GRPC.Server.rpc_req(), stream :: Stream.t()}
          | {:after, after_fn, GRPC.Server.rpc_req(), stream :: Stream.t()}
          | {:halt, reply :: any()}
          | {:error, GRPC.RPCError.t()}

  @callback init(options) :: options
  @callback call(GRPC.Server.rpc_req(), stream :: Stream.t(), options) :: intercept_return
end
