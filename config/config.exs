use Mix.Config

config :demo_server, ecto_repos: [DemoServer.Repo]
config :demo_client, ecto_repos: [DemoClient.Repo]

import_config "../apps/demo_client/config/config.exs"
import_config "../apps/demo_server/config/config.exs"
import_config "#{Mix.env()}.exs"
