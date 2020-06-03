defmodule DemoClient.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      DemoClient.Repo,
      {Phoenix.PubSub, name: DemoClient.PubSub},
      DemoClientWeb.Endpoint
    ] ++ [DemoServerQLApi.Client.supervisor()]

    opts = [strategy: :one_for_one, name: DemoClient.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    DemoClientWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
