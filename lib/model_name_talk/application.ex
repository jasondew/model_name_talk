defmodule ModelNameTalk.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ModelNameTalkWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:model_name_talk, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ModelNameTalk.PubSub},
      ModelNameTalk.Room,
      # Start a worker by calling: ModelNameTalk.Worker.start_link(arg)
      # {ModelNameTalk.Worker, arg},
      # Start to serve requests, typically the last entry
      ModelNameTalkWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ModelNameTalk.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ModelNameTalkWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
