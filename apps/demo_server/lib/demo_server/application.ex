defmodule DemoServer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      DemoServer.Repo,
      DemoServerWeb.Endpoint,
      {Phoenix.PubSub, name: DemoServer.PubSub},
      {Absinthe.Subscription, DemoServerWeb.Endpoint}
    ]

    opts = [strategy: :one_for_one, name: DemoServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    DemoServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
