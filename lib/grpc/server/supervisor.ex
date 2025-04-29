defmodule GRPC.Server.Supervisor do
  @moduledoc """
  A simple supervisor to start your servers.

  You can add it to your OTP tree as below.
  To start the server, pass `start_server: true` and an option defining at a minimum the Endpoint to use.

      defmodule Your.App do
        use Application

        def start(_type, _args) do
          children = [
            {GRPC.Server.Supervisor, endpoint: Your.Endpoint, port: 443, start_server: true, ...}]

          Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
        end
      end
  """

  use Supervisor

  require Logger

  def start_link(endpoint) do
    Supervisor.start_link(__MODULE__, endpoint)
  end

  @type endpoint_opt :: {:endpoint, module}
  @type port_opt :: {:port, pos_integer}
  @type credentials_opt :: {:cred, GRPC.Credential.t()}
  @type start_server_opt :: {:start_server, boolean}
  @type grpc_server_supervisor_opts ::
          endpoint_opt | port_opt | credentials_opt | start_server_opt

  @doc """
  ## Options

    * `:endpoint` - the name of the Endpoint module this Supervisor will use
    * `:start_server` - boolean, determines if the server will be started.
      If present, has more precedence then the `config :gprc, :start_server`
      config value (i.e. `start_server: false` will not start the server in any case).
    * `:cred` - a credential created by functions of `GRPC.Credential`. An insecure HTTP server will be created without this option, while a server with TLS enabled will be started if provided.
    * `:port` - the port to use for the HTTP service, defaults to port 80 or 443 depending on whether SSL is enabled or not
  """
  @spec init([grpc_server_supervisor_opts]) ::
          {:ok, {Supervisor.sup_flags(), [Supervisor.child_spec()]}} | :ignore
  def init(opts)

  def init(opts) when is_list(opts) do
    start_directive = if opts[:start_server], do: :start_server, else: :noop
    children = child_spec(start_directive, opts[:endpoint], opts)
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Return a child_spec to start server.
  """
  @spec child_spec(
          start_directive :: :stert_server | term,
          endpoint_module :: atom(),
          opts :: keyword()
        ) ::
          Supervisor.Spec.spec()
  def child_spec(start_directive, endpoint, opts \\ [])

  def child_spec(:start_server, endpoint, opts) when is_atom(endpoint) do
    sanitized_opts =
      opts
      |> Keyword.put(:port, Keyword.get(opts, :port, default_port(opts)))
      |> Keyword.put(:endpoint, endpoint)

    adapter = Keyword.get(opts, :adapter, GRPC.Server.Adapter.default())
    [adapter.child_spec(sanitized_opts)]
  end

  def child_spec(_do_not_start_server, _endpoint, _opts), do: []

  defp default_port(opts) do
    case Keyword.get(opts, :cred) do
      nil -> 80
      _some_value -> 443
    end
  end
end
