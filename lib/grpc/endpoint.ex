defmodule GRPC.Endpoint do
  @moduledoc """
  GRPC endpoint for multiple servers and interceptors.

  ## Usage

      defmodule Your.Endpoint do
        use GRPC.Endpoint

        intercept GRPC.Server.Interceptors.Logger, level: :info
        intercept Other.Interceptor
        run HelloServer, interceptors: [HelloHaltInterceptor]
        run FeatureServer
      end

  Interceptors will be run around your rpc calls from top to bottom. And you can even set
  interceptors for specific servers. In the above example, `[GRPC.Server.Interceptors.Logger, Other.Interceptor,
  HelloHaltInterceptor]` will be run for `HelloServer`, and `[GRPC.Server.Interceptors.Logger, Other.Interceptor]`
  will be run for `FeatureServer`.
  """

  @type initialized_intercepter :: {module(), term()}
  @type intercepters :: %{
          endpoint: [initialized_intercepter()],
          servers: %{[module()] => [initialized_intercepter()]}
        }

  @doc false
  defmacro __using__(_opts) do
    quote do
      import GRPC.Endpoint, only: [intercept: 1, intercept: 2, run: 1, run: 2]

      Module.register_attribute(__MODULE__, :interceptors, accumulate: true)
      Module.register_attribute(__MODULE__, :servers, accumulate: true)
      @before_compile GRPC.Endpoint
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    interceptors =
      Module.get_attribute(env.module, :interceptors)
      |> Macro.escape()
      |> Enum.reverse()

    servers =
      Module.get_attribute(env.module, :servers)
      |> Enum.map(fn {server, opts} ->
        run_args =
          if interceptors = opts[:interceptors] do
            %{interceptors: interceptors}
          else
            %{}
          end

        {server, run_args}
      end)

    server_interceptors = server_interceptors(servers, %{})
    server_modules = server_module_names(servers)

    quote do
      def __meta__(:interceptors), do: unquote(interceptors)
      def __meta__(:servers), do: unquote(server_modules)
      def __meta__(:server_interceptors), do: unquote(Macro.escape(server_interceptors))
    end
  end

  defmacro intercept(name) do
    quote do
      @interceptors unquote(name)
    end
  end

  @doc """
  ## Options

  `opts` keyword will be passed to Interceptor's init/1
  """
  defmacro intercept(name, opts) do
    quote do
      @interceptors {unquote(name), unquote(opts)}
    end
  end

  @doc """
  ## Options

    * `:interceptors` - custom interceptors for these servers
  """
  defmacro run(servers, opts \\ []) do
    quote do
      @servers {unquote(servers), unquote(opts)}
    end
  end

  @doc false
  @spec start(atom(), Keyword.t()) :: any()
  def start(endpoint, opts \\ []) do
    adapter = GRPC.Server.Adapter.from_opts(opts)

    if :code.ensure_loaded(adapter) == {:module, adapter} do
      adapter.start(endpoint, opts)
    end
  end

  @doc false
  @spec stop(atom(), Keyword.t()) :: any()
  def stop(endpoint, opts \\ []) do
    adapter = GRPC.Server.Adapter.from_opts(opts)

    if :code.ensure_loaded(adapter) == {:module, adapter} do
      adapter.stop(endpoint)
    end
  end

  @spec interceptors(endpoint :: module()) :: intercepters()
  def interceptors(endpoint) do
    %{
      endpoint: init_endpoint_interceptors(endpoint),
      servers: init_server_interceptors(endpoint)
    }
  end

  defp init_interceptor({module, opts}), do: {module, module.init(opts)}
  defp init_interceptor(module), do: {module, module.init([])}

  defp init_endpoint_interceptors(endpoint) do
    :interceptors
    |> endpoint.__meta__()
    |> Enum.map(&init_interceptor/1)
  end

  defp init_server_interceptors(endpoint) do
    :server_interceptors
    |> endpoint.__meta__()
    |> Enum.reduce(%{}, fn {module, interceptors}, acc ->
      interceptors = Enum.map(interceptors, &init_interceptor/1)
      Map.put(acc, module, interceptors)
    end)
  end

  defp server_interceptors([], acc), do: acc

  defp server_interceptors([{servers, %{interceptors: interceptors}} | tail], acc)
       when is_list(interceptors) do
    acc =
      Enum.reduce(List.wrap(servers), acc, fn server, acc ->
        Map.put(acc, server, interceptors)
      end)

    server_interceptors(tail, acc)
  end

  defp server_interceptors([_ | tail], acc) do
    server_interceptors(tail, acc)
  end

  defp server_module_names(servers) do
    servers
    |> Enum.map(fn {server, _} -> server end)
    |> List.flatten()
  end
end
