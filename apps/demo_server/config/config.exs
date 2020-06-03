use Mix.Config

config :demo_server,
  ecto_repos: [DemoServer.Repo]

config :demo_server, DemoServerWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "siOr3HD93qmNy+XZ0g6W7nnCnjl/JJS1voMvClh5724cdS80/eia3n9CvPycmE9u",
  render_errors: [view: DemoServerWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: DemoServer.PubSub

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
