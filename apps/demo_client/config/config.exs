use Mix.Config

config :demo_client, ecto_repos: [DemoClient.Repo]

config :demo_client, DemoClientWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "ythVxs0rJ1cLzYkh/eVojSFloU6bmtDT3z0CwW4HEIxpZ/Zbz9O/LUtH4dmspE29",
  render_errors: [view: DemoClientWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: DemoClient.PubSub

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
